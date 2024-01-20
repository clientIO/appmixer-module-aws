locals {
  availability_zones = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
}

module "appmixer_module" {
  source = "../../"

  root_dns_name = "ecs.appmixer.co"
  zone_id       = "XXX"

  vpc_config = {
    ipv4_primary_cidr_block = "10.0.0.0/16"
    availability_zones      = local.availability_zones
  }

  init_user = {
    email    = "XXX"
    username = "XXX"
    password = "XXX"
  }

  ecs_registry_auth_data = "XXX"

  ecs_common_service_config = {
    wait_for_steady_state    = true
    autoscaling_min_capacity = 2
    ordered_placement_strategy = [
      # This `spread` placement strategy will ensure that the tasks are spread across Availability Zones which implies higher availability.
      {
        type  = "spread"
        field = "attribute:ecs.availability-zone"
      },
      {
        type  = "binpack"
        field = "cpu"
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
          on_demand_allocation_strategy            = "prioritized"
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

  elasticsearch = {
    instance_count = length(local.availability_zones)
  }

  elasticache = {
    cluster_size = length(local.availability_zones)
  }

  document_db = {
    cluster_size = length(local.availability_zones)
  }


}
