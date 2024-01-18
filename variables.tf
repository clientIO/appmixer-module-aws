variable "namespace" {
  type        = string
  default     = "cio"
  description = "Namespace, which could be your organization name or abbreviation, e.g. 'eg' or 'cp'"
}

variable "environment" {
  type        = string
  default     = "lablabs"
  description = "Environment, e.g. 'prod', 'staging', 'dev', 'pre-prod', 'UAT'"
}

variable "stage" {
  type        = string
  default     = "dev"
  description = "Stage, e.g. 'prod', 'staging', 'dev'"
}

variable "name" {
  type        = string
  default     = "appmixer"
  description = "Solution name, e.g. 'appmixer'"
}

variable "attributes" {
  type        = list(string)
  default     = []
  description = "Additional attributes (e.g. `1`)"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags (e.g. `map('BusinessUnit','XYZ')`"
}

variable "availability_zones" {
  type        = list(string)
  default     = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
  description = "List of availability zones"
}

variable "zone_id" {
  type        = string
  default     = ""
  description = "Route53 DNS zone ID, if not set route53 will be not used"
}

variable "root_dns_name" {
  type        = string
  description = "Root DNS name, must be applicable to route53 zone (zone_id)"
}

variable "certificate_arn" {
  type        = string
  default     = null
  description = "Certificate ARN, if not set, certificate will be automatically created using '*.<root_dns_name>', zone_id must be set"
}

variable "document_db" {
  type = object({
    cluster_size    = optional(number, 3)
    cluster_family  = optional(string, "docdb5.0")
    instance_class  = optional(string, "db.t4g.medium")
    engine_version  = optional(string, "5.0.0")
    master_username = optional(string, "admin1")
    cluster_parameters = optional(list(object({
      apply_method = string
      name         = string
      value        = string
    })), [])
  })
  default = {
    cluster_parameters = [
      {
        apply_method = "pending-reboot"
        name         = "tls"
        value        = "disabled"
      }
    ]
  }
  description = "DocumentDB module object"
}

variable "elasticache" {
  type = object({
    cluster_size               = optional(number, 1)
    instance_type              = optional(string, "cache.t3.micro")
    engine_version             = optional(string, "6.2")
    family                     = optional(string, "redis6.x")
    at_rest_encryption_enabled = optional(bool, true)
    transit_encryption_enabled = optional(bool, true)
    automatic_failover_enabled = optional(bool, false)
    parameter = optional(list(object({
      name  = string
      value = string
    })), [])
  })
  default = {
    parameter = [ # TODO remove
      {
        name  = "notify-keyspace-events"
        value = "lK"
      }
    ]
  }
  description = "Elastic module object"
}

variable "elasticsearch" {
  type = object({
    elasticsearch_version           = optional(string, "OpenSearch_2.7")
    instance_type                   = optional(string, "t3.medium.elasticsearch")
    instance_count                  = optional(number, 1)
    ebs_volume_size                 = optional(number, 20)
    encrypt_at_rest_enabled         = optional(bool, true)
    advanced_options                = optional(map(string), null)
    node_to_node_encryption_enabled = optional(bool, true)
  })
  default = {
    advanced_options = {
      "rest.action.multi.allow_explicit_index" = "true"
    }
  }
  description = "Elasticsearch module object"
}


variable "rabbitmq" {
  type = object({
    auto_minor_version_upgrade = optional(bool, true)
    deployment_mode            = optional(string, "SINGLE_INSTANCE")
    engine_version             = optional(string, "3.8.34")
    host_instance_type         = optional(string, "mq.t3.micro")
    audit_log_enabled          = optional(bool, false)
    general_log_enabled        = optional(bool, true)
    encryption_enabled         = optional(bool, true)
    use_aws_owned_key          = optional(bool, false)
    publicly_accessible        = optional(bool, false)
  })
  default     = {}
  description = "RabbitMQ module object"
}

variable "init_user" {
  type = object({
    email    = string
    username = string
    password = string
  })
  description = "Initial user created in appmixer"
}

variable "ecs_auth_data" {
  type        = string
  default     = ""
  description = "Docker registry credentials, base64 encoded string"
}

variable "external_redis" {
  type        = string
  default     = null
  description = "Connection string to Redis, if not set, Redis will be automatically created"
}

variable "external_rabbitmq" {
  # object with url, username, password, port
  type = object({
    url      = string
    username = string
    password = string
    port     = number
  })
  default     = null
  description = "Connection object to RabbitMQ, if not set, RabbitMQ will be automatically created"
}

variable "external_elasticsearch" {
  type = object({
    url      = string
    username = string
    password = string
  })
  default     = null
  description = "Connection object to Elasticsearch, if not set, Elasticsearch will be automatically created"
}

variable "external_documentdb" {
  type        = string
  default     = null
  description = "Connection string to DocumentDB, if not set, DocumentDB will be automatically created"
}

variable "external_vpc" {
  type = object({
    vpc_id             = string
    public_subnet_ids  = list(string)
    private_subnet_ids = list(string)
  })
  default     = null
  description = "VPC configuration, if not set, new VPC will be created"
}

variable "vpc_config" {
  type = object({
    ipv4_primary_cidr_block = string
    availability_zones      = list(string)
  })
  default = {
    ipv4_primary_cidr_block = "10.0.0.0/16"
    availability_zones      = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
  }
  description = "VPC configuration, ignored if external_vpc is set"
}

variable "additional_security_group_rules" {
  type = list(object({
    type              = string
    from_port         = number
    to_port           = number
    protocol          = string
    cidr_blocks       = optional(list(string))
    ipv6_cidr_blocks  = optional(list(string))
    security_group_id = optional(string)
  }))
  default     = []
  description = "Additional security group rules added to security group rules of all resources, see more https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule"
}

variable "s3_config" {
  type = object({
    versioning_enabled = optional(bool, false)
    logging            = optional(list(object({ bucket_name = string, prefix = string })), [])
  })
  default     = {}
  description = "Configuration for S3 bucket"
}

variable "enable_deletion_protection" {
  type        = bool
  default     = false
  description = "Enable deletion protection for all resources, if true, resources can't be deleted if not explicitly set to false"
}

variable "ecs_cluster_configuration" {
  type = any
  default = {
    logging = "OVERRIDE"
    log_configuration = {
      cloud_watch_log_group_name = "/aws/ecs/aws-ec2"
    }
  }
  description = "Cluster configuration object 'execute_command_configuration',  see more https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster"
}

variable "ecs_autoscaling_config" {
  type = any
  default = {
    # On-demand instances
    on_demand = {
      instance_type              = "m5.large"
      use_mixed_instances_policy = true
      mixed_instances_policy = {
        instances_distribution = {
          on_demand_base_capacity                  = 1   # min 1 on demand instance
          on_demand_percentage_above_base_capacity = 100 # 100% on demand instances
          on_demand_allocation_strategy            = "prioritized"
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

      max_size = 6
      min_size = 1
      capacity_provider = {
        maximum_scaling_step_size = 5
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
          on_demand_allocation_strategy            = "prioritized"
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
      max_size = 6
      min_size = 1
      capacity_provider = {
        maximum_scaling_step_size = 5
        minimum_scaling_step_size = 1
        target_capacity           = 100
        default_capacity_provider_strategy = {
          weight = 80
          base   = 0
        }
      }
    }
  }
}

variable "ecs_common_service_config" {
  type = object({
    ordered_placement_strategy = optional(list(object({
      type  = string
      field = string
      })), [{
      type  = "binpack"
      field = "cpu"
    }])
    force_new_deployment     = optional(bool, false)
    wait_for_steady_state    = optional(bool, true)
    autoscaling_min_capacity = optional(number, 1)
    autoscaling_max_capacity = optional(number, 10)
    deployment_circuit_breaker = optional(object({
      enable   = bool
      rollback = bool
      }), {
      enable   = true
      rollback = true
    })
  })
  default     = {}
  description = <<EOF
    ECS service configuration:
    ordered_placement_strategy defines how tasks are placed on instances, see more https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-placement-strategies.html or https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service
    force_new_deployment force service redeployment
    wait_for_steady_state terraform apply waits for service to reach steady state, see more https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service
EOF
}

variable "ecs_per_service_config" {
  type        = any
  default     = {}
  description = <<EOF
    Configuration per service, overrides 'ecs_common_service_config'
    Example:
    {
      engine = {
        image = "registry.appmixer.com/appmixer-engine:5.2.0-nocomp"
        url   = "api.ecs.appmixer.co"
        env = {
          EXAMPLE_ENV = "example"
        }
        cpu          = 512
        memory       = 1024
        health_check = {}
        entrypoint = [
          "node",
          "gridd.js",
          "--http",
          "--emails"
        ]
        autoscaling_min_capacity = 1
        autoscaling_max_capacity = 10

        force_new_deployment = true
        wait_for_steady_state = true
        ordered_placement_strategy = [{ (see more https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service)
          type  = "binpack"
          field = "cpu"
        }]
      }
      quota = {...}
      frontend = {...}
      backoffice = {...}
      logstash = {
        health_check = {
          {
            retries = 10
            command = ["CMD-SHELL", "curl -s -XGET localhost:9600 || exit 1"]
            timeout : 5
            interval : 10
            startPeriod : 60
          }
        }
      }
    }
EOF
}
