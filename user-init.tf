locals {
  email    = var.init_user["email"]
  username = var.init_user["username"]
  password = var.init_user["password"]
}

data "http" "init_user" {
  url = "https://${local.engine.url}/user"

  method = "POST"
  request_headers = {
    content-type = "application/json"
  }
  request_body = jsonencode({ "email" : local.email, "username" : local.username, "password" : local.password })
  depends_on   = [module.ecs_service_engine]
}

output "user" {
  value = jsondecode(data.http.init_user.response_body)
}

resource "aws_cloudwatch_log_group" "ecs_mongo_init_user" {
  #checkov:skip=CKV_AWS_158: Ensure that CloudWatch Log Group is encrypted by KMS
  #checkov:skip=CKV_AWS_338: Ensure CloudWatch log groups retains logs for at least 1 year
  name              = "/aws/ecs/${module.label.id}-mongo-init-user"
  retention_in_days = 7
}


resource "aws_ecs_task_definition" "this" {
  family = "${module.label.id}-mongo-init-user"
  container_definitions = jsonencode([
    {
      name       = "${module.label.id}-mongo-init-user"
      image      = "mongo:latest"
      cpu        = 10
      memory     = 512
      essential  = true
      entryPoint = ["mongosh"]
      command    = ["appmixer", "--host", "${module.documentdb_cluster.endpoint}:27017", "--username", module.documentdb_cluster.master_username, "--password", module.documentdb_cluster.master_password, "--retryWrites=false", "--eval", "db.users.updateOne({ email: \"${local.email}\"},{$set: {scope: [\"user\",\"admin\"]}});"]
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
  cluster         = module.ecs_cluster.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = 1
  launch_type     = "EC2"

  network_configuration {
    subnets         = local.private_subnet_ids
    security_groups = [module.sg_user_init.id]
  }

  depends_on = [data.http.init_user]
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
