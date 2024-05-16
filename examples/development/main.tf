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

data "aws_route53_zone" "this" {
  name = "appmixer.co"
}

module "appmixer_module" {
  source = "../../"

  name        = local.name
  namespace   = local.namespace
  environment = local.environment

  root_dns_name = "ecs.${data.aws_route53_zone.this.name}"
  zone_id       = data.aws_route53_zone.this.zone_id

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
    autoscaling_min_capacity = 1
    wait_for_steady_state    = true
    force_new_deployment     = false
    ordered_placement_strategy = [ # (see more https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service)
      {
        type  = "binpack"
        field = "cpu"
      },
    ]
  }

  # Engine fix to use MongoDB TLS
  ecs_per_service_config = {
    engine = {
      entrypoint = ["/bin/bash", "-c"]
      command    = ["apt-get update; apt-get -y install wget; wget https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem; node gridd.js --http --emails"]
    }
    quota = {
      entrypoint = ["/bin/bash", "-c"]
      command    = ["apt-get update; apt-get -y install wget; wget -O /root/global-bundle.pem https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem; npm start"]
    }
  }

  elasticsearch = {
    instance_count = 1
  }

  elasticache = {
    cluster_size = 1
    parameter = [
      {
        name  = "notify-keyspace-events"
        value = "lK"
      }
    ]
  }

  document_db = {
    cluster_size = 1
  }

  rabbitmq = {
    deployment_mode = "SINGLE_INSTANCE"
  }
}

output "appmixer_module" {
  value = module.appmixer_module
}
