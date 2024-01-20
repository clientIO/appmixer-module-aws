locals {
  elasticache_enabled = var.external_redis == null
}

module "elasticache" {
  source  = "cloudposse/elasticache-redis/aws"
  version = "1.0.0"
  enabled = local.elasticache_enabled

  context    = module.label.context
  attributes = ["elasticache"]

  availability_zones         = var.availability_zones
  zone_id                    = []
  vpc_id                     = local.vpc_id
  subnets                    = local.private_subnet_ids
  allowed_security_group_ids = []
  additional_security_group_rules = concat([{
    type        = "ingress"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr_block]
  }], var.additional_security_group_rules)

  cluster_size               = try(var.elasticache["cluster_size"], null)
  instance_type              = try(var.elasticache["instance_type"], null)
  apply_immediately          = true
  automatic_failover_enabled = try(var.elasticache["automatic_failover_enabled"], null)
  engine_version             = try(var.elasticache["engine_version"], null)
  family                     = try(var.elasticache["family"], null)
  at_rest_encryption_enabled = try(var.elasticache["at_rest_encryption_enabled"], null)
  transit_encryption_enabled = try(var.elasticache["transit_encryption_enabled"], null)
  auth_token                 = random_password.redis_password.result
  parameter                  = try(var.elasticache["parameter"], null)
}

resource "random_password" "redis_password" {
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  override_special = "-"
  length           = 128
}

module "elasticache_ssm_password" {
  source  = "cloudposse/ssm-parameter-store/aws"
  version = "0.11.0"
  enabled = local.elasticache_enabled
  context = module.label.context

  parameter_write = [
    {
      name        = "/${module.label.id}/elasticache/auth_token"
      value       = sensitive(random_password.redis_password.result)
      type        = "SecureString"
      overwrite   = "true"
      description = "Auth token for ${module.elasticache.id} Elasticache"
    }
  ]
}
