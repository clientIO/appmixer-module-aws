locals {
  documentdb_enabled    = var.external_documentdb == null
  documentdb_subnet_ids = slice(local.private_subnet_ids, 0, min(length(local.private_subnet_ids), max(2, var.document_db.cluster_size)))
}

module "documentdb_cluster" {
  source              = "cloudposse/documentdb-cluster/aws"
  version             = "0.24.0"
  enabled             = local.documentdb_enabled
  deletion_protection = var.enable_deletion_protection

  context    = module.label.context
  attributes = ["documentdb"]

  vpc_id     = local.vpc_id
  subnet_ids = local.documentdb_subnet_ids

  cluster_family = try(var.document_db["cluster_family"], null)
  cluster_size   = try(var.document_db["cluster_size"], null)
  instance_class = try(var.document_db["instance_class"], null)

  master_username = random_pet.document_db_username.id

  engine_version = try(var.document_db["engine_version"], null)

  ssm_parameter_enabled = false

  allowed_cidr_blocks = [local.vpc_cidr_block]

  cluster_parameters = try(var.document_db["cluster_parameters"], [])
}

resource "random_pet" "document_db_username" {
  length = 1
}

module "document_db_ssm_password" {
  source  = "cloudposse/ssm-parameter-store/aws"
  version = "0.11.0"
  enabled = local.documentdb_enabled
  context = module.label.context

  parameter_write = [
    {
      name        = "/${module.label.id}/documentdb/master_password"
      value       = sensitive(module.documentdb_cluster.master_password)
      type        = "SecureString"
      overwrite   = "true"
      description = "Master password for ${module.documentdb_cluster.cluster_name} DocumentDB cluster"
    }
  ]
}

module "document_db_ssm_username" {
  source  = "cloudposse/ssm-parameter-store/aws"
  version = "0.11.0"
  enabled = local.documentdb_enabled
  context = module.label.context

  parameter_write = [
    {
      name        = "/${module.label.id}/documentdb/master_username"
      value       = sensitive(module.documentdb_cluster.master_username)
      type        = "String"
      overwrite   = "true"
      description = "Master username for ${module.documentdb_cluster.cluster_name} DocumentDB cluster"
    }
  ]

}

module "sg_document_db_rules" {
  source                   = "cloudposse/security-group/aws"
  version                  = "2.2.0"
  enabled                  = local.documentdb_enabled
  vpc_id                   = local.vpc_id
  allow_all_egress         = false
  target_security_group_id = [module.documentdb_cluster.security_group_id]
  rules                    = var.additional_security_group_rules
}
