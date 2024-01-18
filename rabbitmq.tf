locals {
  rabbitmq_enabled         = var.external_rabbitmq == null
  rabbitmq_deployment_mode = try(var.rabbitmq["deployment_mode"], "SINGLE_INSTANCE")
  rabbitmq_subnet_ids      = local.rabbitmq_deployment_mode == "SINGLE_INSTANCE" ? [local.private_subnet_ids[0]] : local.private_subnet_ids
}
module "rabbit_mq" {
  source  = "cloudposse/mq-broker/aws"
  version = "3.1.0"
  enabled = local.rabbitmq_enabled

  context    = module.label.context
  attributes = ["rabbitmq"]

  vpc_id     = local.vpc_id
  subnet_ids = local.rabbitmq_subnet_ids

  apply_immediately          = true
  auto_minor_version_upgrade = try(var.rabbitmq["auto_minor_version_upgrade"], null)
  deployment_mode            = try(var.rabbitmq["deployment_mode"], null)
  engine_type                = "RabbitMQ"
  engine_version             = try(var.rabbitmq["engine_version"], null)
  host_instance_type         = try(var.rabbitmq["host_instance_type"], null)
  publicly_accessible        = try(var.rabbitmq["publicly_accessible"], null)

  audit_log_enabled   = try(var.rabbitmq["audit_log_enabled"], null)
  general_log_enabled = try(var.rabbitmq["general_log_enabled"], null)
  encryption_enabled  = try(var.rabbitmq["encryption_enabled"], null)
  use_aws_owned_key   = try(var.rabbitmq["use_aws_owned_key"], null)

  # https://github.com/hashicorp/terraform-provider-aws/issues/33514
  create_security_group           = true
  allowed_cidr_blocks             = [local.vpc_cidr_block] # TODO join var
  additional_security_group_rules = var.additional_security_group_rules

  mq_application_password                    = [random_password.rabbit_mq.result]
  ssm_path                                   = "${module.label.id}/rabbit_mq"
  mq_application_user_ssm_parameter_name     = "master_username"
  mq_application_password_ssm_parameter_name = "master_password" # pragma: allowlist secret
}

resource "random_password" "rabbit_mq" {
  keepers = {
    ami_id = module.label.id
  }
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
  special     = false
  length      = 12
}
