locals {
  email    = var.init_user["email"]
  username = var.init_user["username"]
  password = var.init_user["password"]
}

data "http" "init_user" {
  url = "https://api.${var.root_dns_name}/user"

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
      command    = ["appmixer", "--host", "cio-lablabs-dev-appmixer-documentdb.cluster-c5cjg1za18ax.eu-central-1.docdb.amazonaws.com:27017", "--username", module.documentdb_cluster.master_username, "--password", module.documentdb_cluster.master_password, "--retryWrites=false", "--eval", "db.users.updateOne({ email: \"${local.email}\"},{$set: {scope: [\"user\",\"admin\"]}});"]
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
    security_groups = [module.ecs_service_engine.security_group_id] # TODO
  }

  depends_on = [data.http.init_user]
}
