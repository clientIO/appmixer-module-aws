locals {
  vpc_cidr_block = "10.0.0.0/16"
  name           = "appmixer"
  environment    = "dev"
  namespace      = "cio"
}

module "vpc" {
  source                           = "cloudposse/vpc/aws"
  version                          = "2.1.1"
  name                             = local.name
  namespace                        = local.namespace
  environment                      = local.environment
  ipv4_primary_cidr_block          = local.vpc_cidr_block
  assign_generated_ipv6_cidr_block = true
  internet_gateway_enabled         = true
}

module "subnets" {
  source              = "cloudposse/dynamic-subnets/aws"
  version             = "2.4.1"
  name                = local.name
  namespace           = local.namespace
  environment         = local.environment
  vpc_id              = module.vpc.vpc_id
  igw_id              = [module.vpc.igw_id]
  nat_gateway_enabled = true
  ipv4_cidr_block     = [local.vpc_cidr_block]
  availability_zones  = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
}


module "appmixer_module" {
  source = "../../"

  name        = local.name
  namespace   = local.environment
  environment = local.environment

  root_dns_name = "ecs.appmixer.co"
  zone_id       = "XXX"

  external_vpc = {
    vpc_id             = module.vpc.vpc_id
    public_subnet_ids  = module.subnets.public_subnet_ids
    private_subnet_ids = module.subnets.private_subnet_ids
  }

  ecs_registry_auth_data = "XXX"

  init_user = {
    email    = "XXX"
    username = "XXX"
    password = "XXX"
  }

  enable_deletion_protection = false

  elasticache = {
    parameter = [
      {
        name  = "notify-keyspace-events"
        value = "lK"
      }
    ]
  }
  ecs_autoscaling_config = {
    on_demand = {
      instance_type              = "m5.large"
      use_mixed_instances_policy = true
      mixed_instances_policy = {
        instances_distribution = {
          on_demand_base_capacity                  = 1   # min 1 on demand instance
          on_demand_percentage_above_base_capacity = 100 # 100% on demand instances
          on_demand_allocation_strategy            = "lowest-price"
        }
        override = [
          {
            instance_type     = "m5.large"
            weighted_capacity = "1"
          },
          {
            instance_type     = "c5.large"
            weighted_capacity = "1"
          }
        ]
      }

      max_size = 2
      min_size = 1
      capacity_provider = {
        maximum_scaling_step_size = 1
        minimum_scaling_step_size = 1
        target_capacity           = 100
        default_capacity_provider_strategy = {
          weight = 10
          base   = 1
        }
      }
    }
    spot = {
      instance_type              = "m5.large"
      use_mixed_instances_policy = true
      mixed_instances_policy = {
        instances_distribution = {
          on_demand_base_capacity                  = 0 # min 0 on demand instance
          on_demand_percentage_above_base_capacity = 0 # 0% on demand instances
          spot_allocation_strategy                 = "lowest-price"
        }
        override = [
          {
            instance_type     = "m5.large"
            weighted_capacity = "1"
          },
          {
            instance_type     = "c5.large"
            weighted_capacity = "1"
          }
        ]
      }
      max_size = 2
      min_size = 1
      capacity_provider = {
        maximum_scaling_step_size = 1
        minimum_scaling_step_size = 1
        target_capacity           = 100
        default_capacity_provider_strategy = {
          weight = 80
          base   = 0
        }
      }
    }
  }

  ecs_common_service_config = {
    autoscaling_min_capacity = 2
    wait_for_steady_state    = true
    force_new_deployment     = true
    ordered_placement_strategy = [
      {
        type  = "spread"
        field = "attribute:ecs.availability-zone"
      },
      {
        type  = "binpack"
        field = "cpu"
      },
    ]
  }

  # Mongo DB TLS temporary disabled - to enable just remove env variables below
  ecs_per_service_config = {
    engine = {
      env = {
        DB_SSL_VALIDATE = "false"
        DB_USE_TLS      = "false"
        DB_TLS_CA_FILE  = ""
      }
    }
  }
}

output "appmixer_module" {
  value = module.appmixer_module
}
