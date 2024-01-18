
# Service configuration for services merging
module "services_configuration_merge" {
  source  = "cloudposse/config/yaml//modules/deepmerge"
  version = "1.0.2"
  maps = [
    {
      engine     = local.common
      frontend   = local.common
      quota      = local.common
      backoffice = local.common
      logstash   = local.common
    },
    {
      engine     = local.engine
      frontend   = local.frontend
      quota      = local.quota
      backoffice = local.backoffice
      logstash   = local.logstash
    },
    {
      engine     = try(var.ecs_per_service_config.engine, {})
      frontend   = try(var.ecs_per_service_config.frontend, {})
      quota      = try(var.ecs_per_service_config.quota, {})
      backoffice = try(var.ecs_per_service_config.backoffice, {})
      logstash   = try(var.ecs_per_service_config.logstash, {})
    }
  ]
}

locals {

  # Environment variables
  frontend_env_container   = [for k, v in module.services_configuration_merge.merged.frontend.env : { name = k, value = v }]
  engine_env_container     = [for k, v in module.services_configuration_merge.merged.engine.env : { name = k, value = v }]
  quota_env_continer       = [for k, v in module.services_configuration_merge.merged.quota.env : { name = k, value = v }]
  backoffice_env_container = [for k, v in module.services_configuration_merge.merged.backoffice.env : { name = k, value = v }]
  logstash_env_container   = [for k, v in module.services_configuration_merge.merged.logstash.env : { name = k, value = v }]

  # ECS EC2 configuration
  user_data = <<-EOT
        #!/bin/bash

        cat <<'EOF' >> /etc/ecs/ecs.config
        ECS_CLUSTER=${module.label.id}
        ECS_LOGLEVEL=debug
        ECS_CONTAINER_INSTANCE_TAGS=${jsonencode(module.label.tags)}
        ECS_ENABLE_TASK_IAM_ROLE=true
        ECS_ENABLE_HIGH_DENSITY_ENI=true
        ECS_ENABLE_SPOT_INSTANCE_DRAINING=true
        ECS_ENGINE_AUTH_TYPE=dockercfg
        ECS_ENGINE_AUTH_DATA=${sensitive(base64decode(var.ecs_auth_data))} # pragma: allowlist secret
        EOF
      EOT
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name = module.label.id

  load_balancer_type = "application"

  vpc_id  = local.vpc_id
  subnets = local.public_subnet_ids

  enable_deletion_protection = var.enable_deletion_protection

  # Security Group
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
  } # TODO full override from var
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = local.vpc_cidr_block
    }
  }

  listeners = {
    http_listener = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = 443
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
    https_listener = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = local.acm_certificate_arn
      forward = {
        target_group_key = "frontend"
      }
      rules = {
        frontend = {
          actions = [
            {
              type             = "forward"
              target_group_key = "frontend"
            }
          ]
          conditions = [{
            host_header = {
              values = [module.services_configuration_merge.merged.frontend.url]
            }
          }]
        }
        backoffice = {
          actions = [
            {
              type             = "forward"
              target_group_key = "backoffice"
            }
          ]
          conditions = [{
            host_header = {
              values = [module.services_configuration_merge.merged.backoffice.url]
            }
          }]
        }
        engine = {
          actions = [
            {
              type             = "forward"
              target_group_key = "engine"
            }
          ]
          conditions = [{
            host_header = {
              values = [module.services_configuration_merge.merged.engine.url]
            }
          }]
        }
      }
    }
  }

  target_groups = {
    frontend = {
      name                              = "${module.label.id}-fr"
      protocol                          = "HTTP"
      port                              = 8080
      target_type                       = "ip"
      deregistration_delay              = 5
      load_balancing_cross_zone_enabled = true

      health_check = {
        enabled             = true
        healthy_threshold   = 5
        interval            = 30
        matcher             = "200"
        path                = "/"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        unhealthy_threshold = 2
      }
      create_attachment = false
    }
    engine = {
      name                              = "${module.label.id}-en"
      protocol                          = "HTTP"
      port                              = 2200
      target_type                       = "ip"
      deregistration_delay              = 5
      load_balancing_cross_zone_enabled = true

      health_check = {
        enabled             = true
        healthy_threshold   = 10
        interval            = 240
        matcher             = "200"
        path                = "/"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 120
        unhealthy_threshold = 10
      }
      create_attachment = false
    }
    backoffice = {
      name                              = "${module.label.id}-bo"
      protocol                          = "HTTP"
      port                              = 8080
      target_type                       = "ip"
      deregistration_delay              = 5
      load_balancing_cross_zone_enabled = true

      health_check = {
        enabled             = true
        healthy_threshold   = 5
        interval            = 30
        matcher             = "200"
        path                = "/"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        unhealthy_threshold = 2
      }
      create_attachment = false
    }
  }
  tags = module.label.tags
}

data "aws_ssm_parameter" "ecs_optimized_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended"
}

module "autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 6.5"

  for_each = var.ecs_autoscaling_config

  name = "${module.label.id}-${each.key}"

  image_id      = jsondecode(data.aws_ssm_parameter.ecs_optimized_ami.value)["image_id"]
  instance_type = each.value.instance_type

  security_groups = [module.autoscaling_sg.security_group_id]
  user_data       = base64encode(local.user_data)

  create_iam_instance_profile = true
  iam_role_name               = "${module.label.id}-ecs"
  iam_role_description        = "ECS role for ${module.label.id}-ecs"
  iam_role_policies = {
    AmazonEC2ContainerServiceforEC2Role = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
    AmazonSSMManagedInstanceCore        = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  vpc_zone_identifier = local.private_subnet_ids
  health_check_type   = "EC2"

  min_size = each.value.min_size
  max_size = each.value.max_size

  ignore_desired_capacity_changes = true

  # https://github.com/hashicorp/terraform-provider-aws/issues/12582
  autoscaling_group_tags = {
    AmazonECSManaged = true
  }

  # Required for  managed_termination_protection = "ENABLED"
  protect_from_scale_in = true

  # Spot instances
  use_mixed_instances_policy = each.value.use_mixed_instances_policy
  mixed_instances_policy     = each.value.mixed_instances_policy

  tags = module.label.tags
}

module "autoscaling_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${module.label.id}-autoscaling"
  description = "Autoscaling group security group"
  vpc_id      = local.vpc_id

  computed_ingress_with_source_security_group_id = [
    {
      rule                     = "http-80-tcp"
      source_security_group_id = module.alb.security_group_id
    }
  ]
  number_of_computed_ingress_with_source_security_group_id = 1

  egress_rules = ["all-all"]

  tags = module.label.tags
}

resource "aws_service_discovery_http_namespace" "appmixer" {
  name        = "appmixer"
  description = "Appmixer namespace"
}

module "ecs_cluster" {
  source       = "terraform-aws-modules/ecs/aws//modules/cluster"
  version      = "5.7.4"
  cluster_name = module.label.id

  cluster_configuration = {
    execute_command_configuration = var.ecs_cluster_configuration
  }

  cluster_service_connect_defaults = {
    namespace = aws_service_discovery_http_namespace.appmixer.arn
  }

  autoscaling_capacity_providers = {
    for k, v in var.ecs_autoscaling_config : k => {
      auto_scaling_group_arn         = module.autoscaling[k].autoscaling_group_arn
      managed_termination_protection = "ENABLED" # prevents Amazon EC2 instances that contain tasks and that are in an Auto Scaling group from being terminated during a scale-in action.

      managed_scaling = {
        maximum_scaling_step_size = v.capacity_provider.maximum_scaling_step_size
        minimum_scaling_step_size = v.capacity_provider.minimum_scaling_step_size
        status                    = "ENABLED"
        target_capacity           = v.capacity_provider.target_capacity
      }

      default_capacity_provider_strategy = {
        weight = v.capacity_provider.default_capacity_provider_strategy.weight
        base   = v.capacity_provider.default_capacity_provider_strategy.base
      }
    }
  }

  default_capacity_provider_use_fargate = false
  tags                                  = module.label.tags
}

module "ecs_service_backoffice" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "5.7.4"

  name                  = "${module.label.id}-backoffice"
  cluster_arn           = module.ecs_cluster.arn
  wait_for_steady_state = module.services_configuration_merge.merged.backoffice.wait_for_steady_state

  cpu    = module.services_configuration_merge.merged.backoffice.cpu
  memory = module.services_configuration_merge.merged.backoffice.memory


  force_new_deployment       = module.services_configuration_merge.merged.backoffice.force_new_deployment
  ordered_placement_strategy = module.services_configuration_merge.merged.backoffice.ordered_placement_strategy

  container_definition_defaults = {
    readonly_root_filesystem = false
  }

  desired_count              = module.services_configuration_merge.merged.backoffice.autoscaling_min_capacity
  autoscaling_min_capacity   = module.services_configuration_merge.merged.backoffice.autoscaling_min_capacity
  autoscaling_max_capacity   = module.services_configuration_merge.merged.backoffice.autoscaling_max_capacity
  deployment_circuit_breaker = module.services_configuration_merge.merged.backoffice.deployment_circuit_breaker

  deployment_controller = {
    type = "ECS"
  }
  capacity_provider_strategy = module.services_configuration_merge.merged.backoffice.capacity_provider_strategy

  container_definitions = {
    backoffice = {
      image = module.services_configuration_merge.merged.backoffice.image
      port_mappings = [
        {
          name          = "backoffice"
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]
      environment  = local.backoffice_env_container
      health_check = module.services_configuration_merge.merged.backoffice.health_check
    }
  }

  load_balancer = {
    service = {
      target_group_arn = module.alb.target_groups["backoffice"].arn
      container_name   = "backoffice"
      container_port   = 8080
    }
  }

  service_connect_configuration = {
    namespace = aws_service_discovery_http_namespace.appmixer.arn
    service = {
      client_alias = {
        port     = 8080
        dns_name = "backoffice"
      }
      port_name      = "backoffice"
      discovery_name = "backoffice"
    }
  }

  subnet_ids = local.private_subnet_ids
  security_group_rules = {
    alb_ingress = {
      type        = "ingress"
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      description = "Service port"
      cidr_blocks = [local.vpc_cidr_block]
    }
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }

  }

  tags = module.label.tags
}

module "ecs_service_engine" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "5.7.4"

  name = "${module.label.id}-engine"

  cluster_arn           = module.ecs_cluster.arn
  wait_for_steady_state = module.services_configuration_merge.merged.engine.wait_for_steady_state

  cpu    = module.services_configuration_merge.merged.engine.cpu
  memory = module.services_configuration_merge.merged.engine.memory


  force_new_deployment       = module.services_configuration_merge.merged.engine.force_new_deployment
  ordered_placement_strategy = module.services_configuration_merge.merged.engine.ordered_placement_strategy

  container_definition_defaults = {
    readonly_root_filesystem = false
  }

  desired_count              = module.services_configuration_merge.merged.engine.autoscaling_min_capacity
  autoscaling_min_capacity   = module.services_configuration_merge.merged.engine.autoscaling_min_capacity
  autoscaling_max_capacity   = module.services_configuration_merge.merged.engine.autoscaling_max_capacity
  deployment_circuit_breaker = module.services_configuration_merge.merged.engine.deployment_circuit_breaker
  deployment_controller = {
    type = "ECS"
  }
  capacity_provider_strategy = module.services_configuration_merge.merged.backoffice.capacity_provider_strategy


  container_definitions = {
    engine = {
      image = module.services_configuration_merge.merged.engine.image
      port_mappings = [
        {
          name          = "engine"
          containerPort = 2200
          hostPort      = 2200
          protocol      = "tcp"
        }
      ]
      environment  = local.engine_env_container
      entrypoint   = module.services_configuration_merge.merged.engine.entrypoint
      health_check = module.services_configuration_merge.merged.engine.health_check
    }
  }

  load_balancer = {
    service = {
      target_group_arn = module.alb.target_groups["engine"].arn
      container_name   = "engine"
      container_port   = 2200
    }
  }

  service_connect_configuration = {
    namespace = aws_service_discovery_http_namespace.appmixer.arn
    service = {
      client_alias = {
        port     = 2200
        dns_name = "engine"
      }
      port_name      = "engine"
      discovery_name = "engine"
    }
  }


  subnet_ids = local.private_subnet_ids
  security_group_rules = {
    alb_ingress = {
      type        = "ingress"
      from_port   = 2200
      to_port     = 2200
      protocol    = "tcp"
      description = "Service port"
      cidr_blocks = [local.vpc_cidr_block]
    }
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }


  tags = module.label.tags
}

module "ecs_service_quota" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "5.7.4"
  name    = "${module.label.id}-quota"

  cluster_arn           = module.ecs_cluster.arn
  wait_for_steady_state = module.services_configuration_merge.merged.quota.wait_for_steady_state

  cpu    = module.services_configuration_merge.merged.quota.cpu
  memory = module.services_configuration_merge.merged.quota.memory


  force_new_deployment       = module.services_configuration_merge.merged.quota.force_new_deployment
  ordered_placement_strategy = module.services_configuration_merge.merged.quota.ordered_placement_strategy

  container_definition_defaults = {
    readonly_root_filesystem = false
  }

  desired_count              = module.services_configuration_merge.merged.quota.autoscaling_min_capacity
  autoscaling_min_capacity   = module.services_configuration_merge.merged.quota.autoscaling_min_capacity
  autoscaling_max_capacity   = module.services_configuration_merge.merged.quota.autoscaling_max_capacity
  deployment_circuit_breaker = module.services_configuration_merge.merged.quota.deployment_circuit_breaker
  deployment_controller = {
    type = "ECS"
  }
  capacity_provider_strategy = module.services_configuration_merge.merged.backoffice.capacity_provider_strategy



  container_definitions = {
    quota = {
      image = module.services_configuration_merge.merged.quota.image
      port_mappings = [
        {
          name          = "quota"
          containerPort = 14415
          hostPort      = 14415
          protocol      = "tcp"
        }
      ]
      environment  = local.quota_env_continer
      health_check = module.services_configuration_merge.merged.quota.health_check
      entrypoint   = module.services_configuration_merge.merged.quota.entrypoint
    }
  }

  service_connect_configuration = {
    namespace = aws_service_discovery_http_namespace.appmixer.arn
    service = {
      client_alias = {
        port     = 14415
        dns_name = "quota"
      }
      port_name      = "quota"
      discovery_name = "quota"
    }
  }

  subnet_ids = local.private_subnet_ids
  security_group_rules = {
    alb_ingress = {
      type        = "ingress"
      from_port   = 14415
      to_port     = 14415
      protocol    = "tcp"
      description = "Service port"
      cidr_blocks = [local.vpc_cidr_block]
    }
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }



  tags = module.label.tags
}

module "ecs_service_frontend" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "5.7.4"

  name                  = "${module.label.id}-frontend"
  cluster_arn           = module.ecs_cluster.arn
  wait_for_steady_state = module.services_configuration_merge.merged.frontend.wait_for_steady_state

  cpu    = module.services_configuration_merge.merged.frontend.cpu
  memory = module.services_configuration_merge.merged.frontend.memory


  force_new_deployment       = module.services_configuration_merge.merged.frontend.force_new_deployment
  ordered_placement_strategy = module.services_configuration_merge.merged.frontend.ordered_placement_strategy

  container_definition_defaults = {
    readonly_root_filesystem = false
  }

  desired_count              = module.services_configuration_merge.merged.frontend.autoscaling_min_capacity
  autoscaling_min_capacity   = module.services_configuration_merge.merged.frontend.autoscaling_min_capacity
  autoscaling_max_capacity   = module.services_configuration_merge.merged.frontend.autoscaling_max_capacity
  deployment_circuit_breaker = module.services_configuration_merge.merged.frontend.deployment_circuit_breaker
  deployment_controller = {
    type = "ECS"
  }
  capacity_provider_strategy = module.services_configuration_merge.merged.backoffice.capacity_provider_strategy



  container_definitions = {
    frontend = {
      image = module.services_configuration_merge.merged.frontend.image
      port_mappings = [
        {
          name          = "frontend"
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]
      environment  = local.frontend_env_container
      health_check = module.services_configuration_merge.merged.frontend.health_check
      entrypoint   = module.services_configuration_merge.merged.frontend.entrypoint
    }
  }

  load_balancer = {
    service = {
      target_group_arn = module.alb.target_groups["frontend"].arn
      container_name   = "frontend"
      container_port   = 8080
    }
  }

  subnet_ids = local.private_subnet_ids
  security_group_rules = {
    alb_ingress = {
      type        = "ingress"
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      description = "Service port"
      cidr_blocks = [local.vpc_cidr_block]
    }
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = module.label.tags
}

module "ecs_service_logstash" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "5.7.4"

  name                  = "${module.label.id}-logstash"
  cluster_arn           = module.ecs_cluster.arn
  wait_for_steady_state = module.services_configuration_merge.merged.logstash.wait_for_steady_state

  cpu    = module.services_configuration_merge.merged.logstash.cpu
  memory = module.services_configuration_merge.merged.logstash.memory


  force_new_deployment       = module.services_configuration_merge.merged.logstash.force_new_deployment
  ordered_placement_strategy = module.services_configuration_merge.merged.logstash.ordered_placement_strategy

  container_definition_defaults = {
    readonly_root_filesystem = false
  }

  desired_count              = module.services_configuration_merge.merged.logstash.autoscaling_min_capacity
  autoscaling_min_capacity   = module.services_configuration_merge.merged.logstash.autoscaling_min_capacity
  autoscaling_max_capacity   = module.services_configuration_merge.merged.logstash.autoscaling_max_capacity
  deployment_circuit_breaker = module.services_configuration_merge.merged.logstash.deployment_circuit_breaker
  deployment_controller = {
    type = "ECS"
  }
  capacity_provider_strategy = module.services_configuration_merge.merged.backoffice.capacity_provider_strategy


  container_definitions = {
    logstash = {
      image        = module.services_configuration_merge.merged.logstash.image
      entrypoint   = module.services_configuration_merge.merged.logstash.entrypoint
      environment  = local.logstash_env_container
      health_check = module.services_configuration_merge.merged.logstash.health_check
    }
  }

  subnet_ids = local.private_subnet_ids
  security_group_rules = {
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = module.label.tags
}
