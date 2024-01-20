# [<img src="https://avatars.githubusercontent.com/u/882337" width=30px>](https://www.appmixer.com/) AWS appmixer Terraform module


[![Terraform validate](https://github.com/clientIO/appmixer-module-aws/actions/workflows/validate.yaml/badge.svg)](https://github.com/clientIO/appmixer-module-aws/actions/workflows/validate.yaml)
[![pre-commit](https://github.com/clientIO/appmixer-module-aws/actions/workflows/pre-commit.yml/badge.svg)](https://github.com/clientIO/appmixer-module-aws/actions/workflows/pre-commit.yml)

## Description
A Terraform module to provision appmixer application.

## Configuration

### Autoscaling configuration
Autoscaling is configured using `ecs_autoscaling_config` variable which by default defines two [capacity providers](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cluster-capacity-providers.html) used while scaling the cluster.
 - `on_demand` - capacity provider alocates on demand EC2 instances which are more expensive but are always available
 - `spot` - capacity provider alocates spot EC2 instances which are cheaper but can be terminated at any time, therefore it is recommended to use spot instances as temporary capacity

 To see more info about capacity provider configuration see [aws_autoscaling_group configuration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group)

> :warning: **Instance types**: The size of EC2 network interfaces (ENIs) for each instance type is restricted, and this limitation is directly tied to the number of containers that can be executed on the instance. To avoid this limitation, please consider using instances types that allow so-called `ENI Trunking` meaning EC2 can attach more network interfaces (see more [AWS Docs](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/container-instance-eni.html))
 Also ENI Trunking **must be allowed** in AWS account ([AWS ECS]( https://console.aws.amazon.com/ecs/v2) -> Account Settings -> AWSVPC Trunking -> Enable)

### Managed services
RabbitMQ, Opensearch (Elasticsearch), ElasticCache (Redis), DocumentDB(Mongo) are managed by AWS and can be configured through variables:
- `document_db`
- `elasticache`
- `elasticsearch`
- `rabbitmq`

Each service is running with minimal configuration, in production they might need some resizing.


### User initialization
Admin user is initialized through automated task running in ECS. Variable `init_user` needs to be set.


### Deployment
- the service `engine` is waiting for creation of index in DocumentDB which might take around 20min till service become available, therefore the **User initialization** will fail and needs to be repeated by running `terraform plan` again
-


## Examples
See [Development example](examples/development/README.md) for further information.
See [Production example](examples/production/README.md) for further information.


## Architecture
 ![arch-diagram](docs/ecs-diagram.png)


<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.6 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.32.1 |
| <a name="requirement_http"></a> [http](#requirement\_http) | 3.4.1 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.6.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_alb"></a> [alb](#module\_alb) | terraform-aws-modules/alb/aws | ~> 9.0 |
| <a name="module_autoscaling"></a> [autoscaling](#module\_autoscaling) | terraform-aws-modules/autoscaling/aws | ~> 6.5 |
| <a name="module_autoscaling_sg"></a> [autoscaling\_sg](#module\_autoscaling\_sg) | terraform-aws-modules/security-group/aws | ~> 5.0 |
| <a name="module_document_db_ssm_password"></a> [document\_db\_ssm\_password](#module\_document\_db\_ssm\_password) | cloudposse/ssm-parameter-store/aws | 0.11.0 |
| <a name="module_document_db_ssm_username"></a> [document\_db\_ssm\_username](#module\_document\_db\_ssm\_username) | cloudposse/ssm-parameter-store/aws | 0.11.0 |
| <a name="module_documentdb_cluster"></a> [documentdb\_cluster](#module\_documentdb\_cluster) | cloudposse/documentdb-cluster/aws | 0.24.0 |
| <a name="module_ecs_cluster"></a> [ecs\_cluster](#module\_ecs\_cluster) | terraform-aws-modules/ecs/aws//modules/cluster | 5.7.4 |
| <a name="module_ecs_service_backoffice"></a> [ecs\_service\_backoffice](#module\_ecs\_service\_backoffice) | terraform-aws-modules/ecs/aws//modules/service | 5.7.4 |
| <a name="module_ecs_service_engine"></a> [ecs\_service\_engine](#module\_ecs\_service\_engine) | terraform-aws-modules/ecs/aws//modules/service | 5.7.4 |
| <a name="module_ecs_service_frontend"></a> [ecs\_service\_frontend](#module\_ecs\_service\_frontend) | terraform-aws-modules/ecs/aws//modules/service | 5.7.4 |
| <a name="module_ecs_service_logstash"></a> [ecs\_service\_logstash](#module\_ecs\_service\_logstash) | terraform-aws-modules/ecs/aws//modules/service | 5.7.4 |
| <a name="module_ecs_service_quota"></a> [ecs\_service\_quota](#module\_ecs\_service\_quota) | terraform-aws-modules/ecs/aws//modules/service | 5.7.4 |
| <a name="module_elasticache"></a> [elasticache](#module\_elasticache) | cloudposse/elasticache-redis/aws | 1.0.0 |
| <a name="module_elasticache_ssm_password"></a> [elasticache\_ssm\_password](#module\_elasticache\_ssm\_password) | cloudposse/ssm-parameter-store/aws | 0.11.0 |
| <a name="module_elasticsearch"></a> [elasticsearch](#module\_elasticsearch) | cloudposse/elasticsearch/aws | 0.46.0 |
| <a name="module_elasticsearch_ssm_password"></a> [elasticsearch\_ssm\_password](#module\_elasticsearch\_ssm\_password) | cloudposse/ssm-parameter-store/aws | 0.11.0 |
| <a name="module_elasticsearch_ssm_username"></a> [elasticsearch\_ssm\_username](#module\_elasticsearch\_ssm\_username) | cloudposse/ssm-parameter-store/aws | 0.11.0 |
| <a name="module_label"></a> [label](#module\_label) | cloudposse/label/null | 0.25.0 |
| <a name="module_rabbit_mq"></a> [rabbit\_mq](#module\_rabbit\_mq) | cloudposse/mq-broker/aws | 3.1.0 |
| <a name="module_s3_bucket"></a> [s3\_bucket](#module\_s3\_bucket) | cloudposse/s3-bucket/aws | 4.0.1 |
| <a name="module_services_configuration_merge"></a> [services\_configuration\_merge](#module\_services\_configuration\_merge) | cloudposse/config/yaml//modules/deepmerge | 1.0.2 |
| <a name="module_sg_document_db_rules"></a> [sg\_document\_db\_rules](#module\_sg\_document\_db\_rules) | cloudposse/security-group/aws | 2.2.0 |
| <a name="module_sg_user_init"></a> [sg\_user\_init](#module\_sg\_user\_init) | cloudposse/security-group/aws | 2.2.0 |
| <a name="module_sq_elasticsearch"></a> [sq\_elasticsearch](#module\_sq\_elasticsearch) | cloudposse/security-group/aws | 2.2.0 |
| <a name="module_subnets"></a> [subnets](#module\_subnets) | cloudposse/dynamic-subnets/aws | 2.4.1 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | cloudposse/vpc/aws | 2.1.1 |

## Resources

| Name | Type |
|------|------|
| [aws_acm_certificate.alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_acm_certificate_validation.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation) | resource |
| [aws_cloudwatch_log_group.ecs_mongo_init_user](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_ecs_task_definition.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_elasticsearch_domain_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticsearch_domain_policy) | resource |
| [aws_route53_record.alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.cert_alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_service_discovery_http_namespace.appmixer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/service_discovery_http_namespace) | resource |
| [random_password.elasticsearch_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_password.rabbit_mq](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_password.redis_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_pet.document_db_username](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/pet) | resource |
| [random_pet.elasticsearch_username](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/pet) | resource |
| [aws_ecs_task_execution.run](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ecs_task_execution) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_ssm_parameter.ecs_optimized_ami](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |
| [aws_vpc.external](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |
| [http_http.init_user](https://registry.terraform.io/providers/hashicorp/http/3.4.1/docs/data-sources/http) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_init_user"></a> [init\_user](#input\_init\_user) | Initial user created in appmixer. Creation through appmixer API and by setting up admin scope in documentdb directly | <pre>object({<br>    email    = string<br>    username = string<br>    password = string<br>  })</pre> | n/a | yes |
| <a name="input_root_dns_name"></a> [root\_dns\_name](#input\_root\_dns\_name) | Root DNS name, must be applicable to route53 zone (zone\_id) | `string` | n/a | yes |
| <a name="input_additional_security_group_rules"></a> [additional\_security\_group\_rules](#input\_additional\_security\_group\_rules) | Additional security group rules added to security group rules of all resources, see more [Terraform docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | <pre>list(object({<br>    type              = string<br>    from_port         = number<br>    to_port           = number<br>    protocol          = string<br>    cidr_blocks       = optional(list(string))<br>    ipv6_cidr_blocks  = optional(list(string))<br>    security_group_id = optional(string)<br>  }))</pre> | `[]` | no |
| <a name="input_alb_ingress_security_group_rules"></a> [alb\_ingress\_security\_group\_rules](#input\_alb\_ingress\_security\_group\_rules) | Application Load Balancer security group ingress rules | <pre>map(object({<br>    ip_protocol                  = string<br>    from_port                    = optional(number)<br>    to_port                      = optional(number)<br>    referenced_security_group_id = optional(string)<br>    description                  = optional(string)<br>    cidr_ipv4                    = optional(string)<br>    cidr_ipv6                    = optional(string)<br>  }))</pre> | <pre>{<br>  "all_http": {<br>    "cidr_ipv4": "0.0.0.0/0",<br>    "from_port": 80,<br>    "ip_protocol": "tcp",<br>    "to_port": 80<br>  },<br>  "all_https": {<br>    "cidr_ipv4": "0.0.0.0/0",<br>    "from_port": 443,<br>    "ip_protocol": "tcp",<br>    "to_port": 443<br>  }<br>}</pre> | no |
| <a name="input_attributes"></a> [attributes](#input\_attributes) | Additional attributes (e.g. `1`) | `list(string)` | `[]` | no |
| <a name="input_availability_zones"></a> [availability\_zones](#input\_availability\_zones) | List of availability zones | `list(string)` | <pre>[<br>  "eu-central-1a",<br>  "eu-central-1b",<br>  "eu-central-1c"<br>]</pre> | no |
| <a name="input_certificate_arn"></a> [certificate\_arn](#input\_certificate\_arn) | Certificate ARN, if not set, certificate will be automatically created using '*.<root\_dns\_name>', `zone_id` must be set | `string` | `null` | no |
| <a name="input_document_db"></a> [document\_db](#input\_document\_db) | DocumentDB configuration object | <pre>object({<br>    cluster_size   = optional(number, 1)<br>    cluster_family = optional(string, "docdb5.0")<br>    instance_class = optional(string, "db.t4g.medium")<br>    engine_version = optional(string, "5.0.0")<br>    cluster_parameters = optional(list(object({<br>      apply_method = string<br>      name         = string<br>      value        = string<br>    })), [])<br>  })</pre> | <pre>{<br>  "cluster_parameters": [<br>    {<br>      "apply_method": "pending-reboot",<br>      "name": "tls",<br>      "value": "disabled"<br>    }<br>  ]<br>}</pre> | no |
| <a name="input_ecs_autoscaling_config"></a> [ecs\_autoscaling\_config](#input\_ecs\_autoscaling\_config) | n/a | `any` | <pre>{<br>  "on_demand": {<br>    "capacity_provider": {<br>      "default_capacity_provider_strategy": {<br>        "base": 1,<br>        "weight": 10<br>      },<br>      "maximum_scaling_step_size": 5,<br>      "minimum_scaling_step_size": 1,<br>      "target_capacity": 100<br>    },<br>    "instance_type": "m5.large",<br>    "max_size": 6,<br>    "min_size": 1,<br>    "mixed_instances_policy": {<br>      "instances_distribution": {<br>        "on_demand_allocation_strategy": "prioritized",<br>        "on_demand_base_capacity": 1,<br>        "on_demand_percentage_above_base_capacity": 100,<br>        "spot_allocation_strategy": "lowest-price"<br>      },<br>      "override": [<br>        {<br>          "instance_type": "m5.large",<br>          "weighted_capacity": "1"<br>        },<br>        {<br>          "instance_type": "c5.large",<br>          "weighted_capacity": "1"<br>        }<br>      ]<br>    },<br>    "use_mixed_instances_policy": true<br>  },<br>  "spot": {<br>    "capacity_provider": {<br>      "default_capacity_provider_strategy": {<br>        "base": 0,<br>        "weight": 80<br>      },<br>      "maximum_scaling_step_size": 5,<br>      "minimum_scaling_step_size": 1,<br>      "target_capacity": 100<br>    },<br>    "instance_type": "m5.large",<br>    "max_size": 6,<br>    "min_size": 1,<br>    "mixed_instances_policy": {<br>      "instances_distribution": {<br>        "on_demand_allocation_strategy": "prioritized",<br>        "on_demand_base_capacity": 0,<br>        "on_demand_percentage_above_base_capacity": 0,<br>        "spot_allocation_strategy": "lowest-price"<br>      },<br>      "override": [<br>        {<br>          "instance_type": "m5.large",<br>          "weighted_capacity": "1"<br>        },<br>        {<br>          "instance_type": "c5.large",<br>          "weighted_capacity": "1"<br>        }<br>      ]<br>    },<br>    "use_mixed_instances_policy": true<br>  }<br>}</pre> | no |
| <a name="input_ecs_cluster_config"></a> [ecs\_cluster\_config](#input\_ecs\_cluster\_config) | Cluster configuration object `execute_command_configuration`,  see more [terraform docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | `any` | <pre>{<br>  "log_configuration": {<br>    "cloud_watch_log_group_name": "/aws/ecs/aws-ec2"<br>  },<br>  "logging": "OVERRIDE"<br>}</pre> | no |
| <a name="input_ecs_common_service_config"></a> [ecs\_common\_service\_config](#input\_ecs\_common\_service\_config) | ECS service configuration:<br>    - `ordered_placement_strategy` defines how tasks are placed on instances, see more [AWS docs](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-placement-strategies.html) or [Terraform docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service)<br>    - `force_new_deployment` force service redeployment<br>    - `wait_for_steady_state` terraform apply waits for service to reach steady state, see more [Terraform docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | <pre>object({<br>    ordered_placement_strategy = optional(list(object({<br>      type  = string<br>      field = string<br>      })), [{<br>      type  = "binpack"<br>      field = "cpu"<br>    }])<br>    force_new_deployment     = optional(bool, false)<br>    wait_for_steady_state    = optional(bool, true)<br>    autoscaling_min_capacity = optional(number, 1)<br>    autoscaling_max_capacity = optional(number, 10)<br>    deployment_circuit_breaker = optional(object({<br>      enable   = bool<br>      rollback = bool<br>      }), {<br>      enable   = true<br>      rollback = true<br>    })<br>  })</pre> | `{}` | no |
| <a name="input_ecs_per_service_config"></a> [ecs\_per\_service\_config](#input\_ecs\_per\_service\_config) | Configuration per service, overrides 'ecs\_common\_service\_config'<br>    Example:<pre>{<br>      engine = {<br>        image = "registry.appmixer.com/appmixer-engine:5.2.0-nocomp"<br>        url   = "api.ecs.appmixer.co"<br>        env = {<br>          EXAMPLE_ENV = "example"<br>        }<br>        cpu          = 512<br>        memory       = 1024<br>        health_check = {}<br>        entrypoint = [ "node", "gridd.js", "--http", "--emails" ]<br>        autoscaling_min_capacity = 1<br>        autoscaling_max_capacity = 10<br>        force_new_deployment = true<br>        wait_for_steady_state = true<br>        # (see more https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service)<br>        ordered_placement_strategy = [{<br>          type  = "binpack"<br>          field = "cpu"<br>        }]<br>      }<br>      quota = {...}<br>      frontend = {...}<br>      backoffice = {...}<br>      logstash = {<br>        health_check = {<br>            retries = 10<br>            command = ["CMD-SHELL", "curl -s -XGET localhost:9600 || exit 1"]<br>            timeout : 5<br>            interval : 10<br>            startPeriod : 60<br>        }<br>        }<br>      }<br>    }</pre> | `any` | `{}` | no |
| <a name="input_ecs_registry_auth_data"></a> [ecs\_registry\_auth\_data](#input\_ecs\_registry\_auth\_data) | Docker registry credentials, base64 encoded string | `string` | `""` | no |
| <a name="input_elasticache"></a> [elasticache](#input\_elasticache) | Elastic module configuration object | <pre>object({<br>    cluster_size               = optional(number, 1)<br>    instance_type              = optional(string, "cache.t3.micro")<br>    engine_version             = optional(string, "6.2")<br>    family                     = optional(string, "redis6.x")<br>    at_rest_encryption_enabled = optional(bool, true)<br>    transit_encryption_enabled = optional(bool, true)<br>    automatic_failover_enabled = optional(bool, false)<br>    parameter = optional(list(object({<br>      name  = string<br>      value = string<br>    })), [])<br>  })</pre> | `{}` | no |
| <a name="input_elasticsearch"></a> [elasticsearch](#input\_elasticsearch) | Elasticsearch module configuration object | <pre>object({<br>    elasticsearch_version           = optional(string, "OpenSearch_2.7")<br>    instance_type                   = optional(string, "t3.medium.elasticsearch")<br>    instance_count                  = optional(number, 1)<br>    ebs_volume_size                 = optional(number, 20)<br>    encrypt_at_rest_enabled         = optional(bool, true)<br>    advanced_options                = optional(map(string), null)<br>    node_to_node_encryption_enabled = optional(bool, true)<br>  })</pre> | <pre>{<br>  "advanced_options": {<br>    "rest.action.multi.allow_explicit_index": "true"<br>  }<br>}</pre> | no |
| <a name="input_enable_deletion_protection"></a> [enable\_deletion\_protection](#input\_enable\_deletion\_protection) | Enable deletion protection for all managed resources, if true, resources can't be deleted if not explicitly set to false | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment, e.g. 'prod', 'staging', 'dev', 'pre-prod', 'UAT' | `string` | `"dev"` | no |
| <a name="input_external_documentdb"></a> [external\_documentdb](#input\_external\_documentdb) | Connection string to DocumentDB, if not set, DocumentDB will be automatically created | `string` | `null` | no |
| <a name="input_external_elasticsearch"></a> [external\_elasticsearch](#input\_external\_elasticsearch) | Connection object to Elasticsearch, if not set, Elasticsearch will be automatically created | <pre>object({<br>    url      = string<br>    username = string<br>    password = string<br>  })</pre> | `null` | no |
| <a name="input_external_rabbitmq"></a> [external\_rabbitmq](#input\_external\_rabbitmq) | Connection object to RabbitMQ, if not set, RabbitMQ will be automatically created | <pre>object({<br>    url      = string<br>    username = string<br>    password = string<br>    port     = number<br>  })</pre> | `null` | no |
| <a name="input_external_redis"></a> [external\_redis](#input\_external\_redis) | Connection string to Redis, if not set, Redis will be automatically created | `string` | `null` | no |
| <a name="input_external_vpc"></a> [external\_vpc](#input\_external\_vpc) | VPC configuration, if not set, new VPC will be created | <pre>object({<br>    vpc_id             = string<br>    public_subnet_ids  = list(string)<br>    private_subnet_ids = list(string)<br>  })</pre> | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Solution name, e.g. 'appmixer' | `string` | `"appmixer"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace, which could be your organization name or abbreviation, e.g. 'eg' or 'cp' | `string` | `"cio"` | no |
| <a name="input_rabbitmq"></a> [rabbitmq](#input\_rabbitmq) | RabbitMQ module configuration object | <pre>object({<br>    auto_minor_version_upgrade = optional(bool, true)<br>    deployment_mode            = optional(string, "SINGLE_INSTANCE")<br>    engine_version             = optional(string, "3.8.34")<br>    host_instance_type         = optional(string, "mq.t3.micro")<br>    audit_log_enabled          = optional(bool, false)<br>    general_log_enabled        = optional(bool, true)<br>    encryption_enabled         = optional(bool, true)<br>    use_aws_owned_key          = optional(bool, false)<br>    publicly_accessible        = optional(bool, false)<br>  })</pre> | `{}` | no |
| <a name="input_s3_config"></a> [s3\_config](#input\_s3\_config) | Configuration for S3 bucket | <pre>object({<br>    versioning_enabled = optional(bool, false)<br>    logging            = optional(list(object({ bucket_name = string, prefix = string })), [])<br>  })</pre> | `{}` | no |
| <a name="input_stage"></a> [stage](#input\_stage) | Stage, e.g. 'prod', 'staging', 'dev' | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags (e.g. `map('BusinessUnit','XYZ')` | `map(string)` | `{}` | no |
| <a name="input_vpc_config"></a> [vpc\_config](#input\_vpc\_config) | VPC configuration, ignored if `external_vpc` is set | <pre>object({<br>    ipv4_primary_cidr_block = string<br>    availability_zones      = list(string)<br>  })</pre> | <pre>{<br>  "availability_zones": [<br>    "eu-central-1a",<br>    "eu-central-1b",<br>    "eu-central-1c"<br>  ],<br>  "ipv4_primary_cidr_block": "10.0.0.0/16"<br>}</pre> | no |
| <a name="input_zone_id"></a> [zone\_id](#input\_zone\_id) | Route53 DNS zone ID, if not set AWS route53 will be not used | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alb_dns_name"></a> [alb\_dns\_name](#output\_alb\_dns\_name) | ## ALB, ECS |
| <a name="output_managed_services"></a> [managed\_services](#output\_managed\_services) | n/a |
| <a name="output_services_urls"></a> [services\_urls](#output\_services\_urls) | n/a |
| <a name="output_user"></a> [user](#output\_user) | n/a |
| <a name="output_vpc_config"></a> [vpc\_config](#output\_vpc\_config) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Contributing and reporting issues

Feel free to create an issue in this repository if you have questions, suggestions or feature requests.

### Validation, linters and pull-requests

We want to provide high quality code and modules. For this reason we are using
several [pre-commit hooks](.pre-commit-config.yaml) and
[GitHub Actions workflows](.github/workflows/). A pull-request to the
main branch will trigger these validations and lints automatically. Please
check your code before you will create pull-requests. See
[pre-commit documentation](https://pre-commit.com/) and
[GitHub Actions documentation](https://docs.github.com/en/actions) for further
details.

## License

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

See [LICENSE](LICENSE) for full details.

    Licensed to the Apache Software Foundation (ASF) under one
    or more contributor license agreements.  See the NOTICE file
    distributed with this work for additional information
    regarding copyright ownership.  The ASF licenses this file
    to you under the Apache License, Version 2.0 (the
    "License"); you may not use this file except in compliance
    with the License.  You may obtain a copy of the License at

      https://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing,
    software distributed under the License is distributed on an
    "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
    KIND, either express or implied.  See the License for the
    specific language governing permissions and limitations
    under the License.
