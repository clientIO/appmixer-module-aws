locals {
  user_init_enabled           = var.init_user != null
  user_init_email             = try(var.init_user.email, "")
  user_init_username          = try(var.init_user.username, "")
  user_init_password          = try(var.init_user.password, "")
  user_init_max_retry_minutes = try(var.init_user.max_retry_minutes, 10)
  user_init_mongo_task        = local.user_init_enabled && var.external_documentdb == null
}

data "http" "init_user" {
  count = local.user_init_enabled ? 1 : 0
  url   = "https://${local.engine.url}/user"

  method = "POST"
  request_headers = {
    content-type = "application/json"
  }
  request_body = jsonencode({ "email" : local.user_init_email, "username" : local.user_init_username, "password" : local.user_init_password })
  depends_on   = [module.ecs_service_engine]

  retry {
    attempts     = local.user_init_max_retry_minutes
    min_delay_ms = 60000
    max_delay_ms = 60000
  }

  lifecycle {
    postcondition {
      condition     = contains([201, 400], self.status_code)
      error_message = "Service engine not available (${local.engine.url}), try it again later. (Response: ${self.response_body})"
    }
  }
}

resource "aws_cloudwatch_log_group" "ecs_mongo_init_user" {
  #checkov:skip=CKV_AWS_158: Ensure that CloudWatch Log Group is encrypted by KMS
  #checkov:skip=CKV_AWS_338: Ensure CloudWatch log groups retains logs for at least 1 year
  name              = "/aws/ecs/${module.label.id}-mongo-init-user"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "this" {
  count  = local.user_init_mongo_task ? 1 : 0
  family = "${module.label.id}-mongo-init-user"
  container_definitions = jsonencode([
    {
      name       = "${module.label.id}-mongo-init-user"
      image      = "mongo:latest"
      cpu        = 10
      memory     = 512
      essential  = true
      entryPoint = ["/bin/bash", "-c", "apt-get update --allow-insecure-repositories; apt-get install wget; wget https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem;  mongosh appmixer --host ${module.documentdb_cluster.endpoint}:27017 --username ${module.documentdb_cluster.master_username} --password ${module.documentdb_cluster.master_password} --retryWrites=false --eval 'db.users.updateOne({ email: \"${local.user_init_email}\"},{$set: {scope: [\"user\",\"admin\"]}});' --tls --tlsCAFile global-bundle.pem"]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_mongo_init_user.name
          "awslogs-region"        = "eu-central-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }

    }]
  )
  requires_compatibilities = ["EC2"]
  network_mode             = "awsvpc"
}

# tflint-ignore: terraform_unused_declarations
data "aws_ecs_task_execution" "run" {
  count           = local.user_init_mongo_task ? 1 : 0
  cluster         = module.ecs_cluster.id
  task_definition = aws_ecs_task_definition.this[0].arn
  desired_count   = 1
  launch_type     = "EC2"

  network_configuration {
    subnets         = local.private_subnet_ids
    security_groups = [module.sg_user_init.id]
  }

  depends_on = [data.http.init_user[0]]
}

module "sg_user_init" {
  source           = "cloudposse/security-group/aws"
  context          = module.label.context
  attributes       = ["user-init-task"]
  version          = "2.2.0"
  enabled          = true
  vpc_id           = local.vpc_id
  allow_all_egress = true
}
