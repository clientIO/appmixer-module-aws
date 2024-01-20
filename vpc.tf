locals {
  vpc_enabled        = var.external_vpc == null
  vpc_id             = !local.vpc_enabled ? var.external_vpc.vpc_id : module.vpc.vpc_id
  vpc_cidr_block     = !local.vpc_enabled ? data.aws_vpc.external[0].cidr_block : module.vpc.vpc_cidr_block
  public_subnet_ids  = !local.vpc_enabled ? var.external_vpc.public_subnet_ids : module.subnets.public_subnet_ids
  private_subnet_ids = !local.vpc_enabled ? var.external_vpc.private_subnet_ids : module.subnets.private_subnet_ids
}

data "aws_vpc" "external" {
  count = local.vpc_enabled ? 0 : 1
  id    = local.vpc_id
}

module "vpc" {
  source                           = "cloudposse/vpc/aws"
  version                          = "2.1.1"
  enabled                          = local.vpc_enabled
  context                          = module.label.context
  ipv4_primary_cidr_block          = var.vpc_config.ipv4_primary_cidr_block
  assign_generated_ipv6_cidr_block = true
  internet_gateway_enabled         = true

}

module "subnets" {
  source              = "cloudposse/dynamic-subnets/aws"
  version             = "2.4.1"
  enabled             = local.vpc_enabled
  context             = module.label.context
  vpc_id              = module.vpc.vpc_id
  igw_id              = [module.vpc.igw_id]
  nat_gateway_enabled = true
  ipv4_cidr_block     = [var.vpc_config.ipv4_primary_cidr_block]
  availability_zones  = var.vpc_config.availability_zones
}
