locals {
  elasticsearch_master_username = random_pet.elasticsearch.id
  elasticsearch_enabled         = var.external_elasticsearch == null
  elasticsearch_subnet_ids      = slice(local.private_subnet_ids, 0, min(length(local.private_subnet_ids), var.elasticsearch.instance_count))
}

module "elasticsearch" {
  source  = "cloudposse/elasticsearch/aws"
  version = "0.46.0"
  enabled = local.elasticsearch_enabled

  context = module.label.context

  vpc_id      = local.vpc_id
  subnet_ids  = local.elasticsearch_subnet_ids
  dns_zone_id = ""

  allowed_cidr_blocks   = [local.vpc_cidr_block]
  iam_role_arns         = []
  iam_actions           = []
  kibana_subdomain_name = ""

  zone_awareness_enabled         = false
  elasticsearch_version          = try(var.elasticsearch["elasticsearch_version"], null)
  instance_type                  = try(var.elasticsearch["instance_type"], null)
  instance_count                 = try(var.elasticsearch["instance_count"], null)
  ebs_volume_size                = try(var.elasticsearch["ebs_volume_size"], null)
  encrypt_at_rest_enabled        = try(var.elasticsearch["encrypt_at_rest_enabled"], null)
  advanced_options               = try(var.elasticsearch["advanced_options"], null)
  create_iam_service_linked_role = false

  node_to_node_encryption_enabled = try(var.elasticsearch["node_to_node_encryption_enabled"], null)

  create_security_group = false
  security_groups       = [module.sq_elasticsearch.id]

  advanced_security_options_enabled                        = true
  advanced_security_options_internal_user_database_enabled = true
  advanced_security_options_master_user_name               = local.elasticsearch_master_username
  advanced_security_options_master_user_password           = random_password.elasticsearch.result
}
resource "random_password" "elasticsearch" {
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  override_special = "-"
  length           = 16
}

resource "random_pet" "elasticsearch" {
}


module "elasticsearch_ssm_password" {
  source  = "cloudposse/ssm-parameter-store/aws"
  version = "0.11.0"
  enabled = local.elasticsearch_enabled
  context = module.label.context

  parameter_write = [
    {
      name        = "/${module.label.id}/elasticsearch/master_password"
      value       = sensitive(random_password.elasticsearch.result)
      type        = "SecureString"
      overwrite   = "true"
      description = "Master password for Elasticsearch ${module.elasticsearch.domain_name} "
    }
  ]
}

module "elasticsearch_ssm_username" {
  source  = "cloudposse/ssm-parameter-store/aws"
  version = "0.11.0"
  enabled = local.elasticsearch_enabled
  context = module.label.context

  parameter_write = [
    {
      name        = "/${module.label.id}/elasticsearch/master_username"
      value       = local.elasticsearch_master_username
      type        = "String"
      overwrite   = "true"
      description = "Master username for Elasticsearch ${module.elasticsearch.domain_name} "

    }
  ]
}

resource "aws_elasticsearch_domain_policy" "this" {
  count       = local.elasticsearch_enabled ? 1 : 0
  domain_name = module.elasticsearch.domain_name

  access_policies = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "es:*",
      "Resource": "${module.elasticsearch.domain_arn}/*"
    }
  ]
}
POLICY
}

module "sq_elasticsearch" {
  source     = "cloudposse/security-group/aws"
  version    = "2.2.0"
  enabled    = local.elasticsearch_enabled
  attributes = ["elasticsearch"]
  context    = module.label.context

  vpc_id           = local.vpc_id
  allow_all_egress = true
  rules = concat([
    {
      type        = "ingress"
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      cidr_blocks = [local.vpc_cidr_block]
      description = "Allow inbound traffic from CIDR blocks"
    }
  ], var.additional_security_group_rules)

}
