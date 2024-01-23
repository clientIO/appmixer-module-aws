data "aws_region" "current" {}

locals {
  rabbitmq = var.external_rabbitmq != null ? var.external_rabbitmq : {
    url      = trimprefix(module.rabbit_mq.primary_console_url, "https://")
    username = module.rabbit_mq.application_username
    password = random_password.rabbit_mq.result

    port = reverse(split(":", module.rabbit_mq.primary_ssl_endpoint))[0]
  }

  redis = var.external_redis != null ? var.external_redis : "rediss://${random_password.redis_password.result}@${module.elasticache.endpoint}"

  elasticsearch = var.external_elasticsearch != null ? var.external_elasticsearch : {
    url      = trimprefix(module.elasticsearch.domain_endpoint, "https://")
    username = local.elasticsearch_master_username
    password = random_password.elasticsearch_password.result
  }

  documentdb = var.external_documentdb != null ? var.external_documentdb : "mongodb://${module.documentdb_cluster.master_username}:${module.documentdb_cluster.master_password}@${module.documentdb_cluster.endpoint}:27017/appmixer?replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false"

  ## Services default configuration

  # Common environment variables for all services
  common = {
    env = {
      APPMIXER_API_URL      = "https://${local.engine.url}"
      APPMIXER_DOCS_URL     = "https://docs.appmixer.com/appmixer"
      APPMIXER_FE_URL       = "https://${local.frontend.url}"
      BROKER_SERVER_API     = "https://${local.rabbitmq.url}"
      BROKER_URL            = "amqps://${local.rabbitmq.username}:${local.rabbitmq.password}@${local.rabbitmq.url}:${local.rabbitmq.port}"
      CUSTOM_COMPONENT_PATH = "/usr/src/appmixer/components/src"
      DB_CONNECTION_URI     = local.documentdb
      ELASTIC_URL           = "https://${local.elasticsearch.username}:${local.elasticsearch.password}@${local.elasticsearch.url}"
      GRIDD_URL             = "https://${local.engine.url}"
      QUOTA_URL             = "http://quota:14415"
      REDIS_URI             = local.redis
      REDIS_USE_SSL         = "true"
      REDIS_CA_PATH         = "/etc/ssl/certs/ca-certificates.crt"
    }
    force_new_deployment       = var.ecs_common_service_config.force_new_deployment
    wait_for_steady_state      = var.ecs_common_service_config.wait_for_steady_state
    ordered_placement_strategy = var.ecs_common_service_config.ordered_placement_strategy
    health_check               = {}
    entrypoint                 = []
    command                    = []
    autoscaling_min_capacity   = var.ecs_common_service_config.autoscaling_min_capacity
    autoscaling_max_capacity   = var.ecs_common_service_config.autoscaling_max_capacity
    deployment_circuit_breaker = var.ecs_common_service_config.deployment_circuit_breaker
    capacity_provider_strategy = [
      for k, v in var.ecs_autoscaling_config : {
        capacity_provider = k
        base              = v.capacity_provider.default_capacity_provider_strategy.base
        weight            = v.capacity_provider.default_capacity_provider_strategy.weight
      }
    ]
  }

  # Frontend service configuration
  frontend = {
    image = "registry.appmixer.com/appmixer-frontend:5.2.0"
    url   = "my.${var.root_dns_name}"
    env = {
      APPMIXER_BO_URL = "https://${local.backoffice.url}"
    }
    cpu    = 256
    memory = 512
  }

  # Backoffice service configuration
  backoffice = {
    image  = "registry.appmixer.com/appmixer-backoffice:5.2.0"
    url    = "bo.${var.root_dns_name}"
    env    = {}
    cpu    = 256
    memory = 512
  }

  # Engine service configuration
  engine = {
    image = "registry.appmixer.com/appmixer-engine:5.2.0-nocomp"
    url   = "api.${var.root_dns_name}"
    env = {
      SYSTEM_PLUGINS    = "minio"
      MINIO_ACCESS_KEY  = module.s3_bucket.access_key_id
      MINIO_SECRET_KEY  = module.s3_bucket.secret_access_key
      MINIO_ENDPOINT    = "s3.amazonaws.com"
      MINIO_USE_SSL     = true
      MINIO_REGION      = data.aws_region.current.name
      MINIO_BUCKET_NAME = module.s3_bucket.bucket_id
      DB_TLS_CA_FILE    = "global-bundle.pem"
      DB_USE_TLS        = "true"
      DB_SSL_VALIDATE   = "true"
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
  }

  # Quota service configuration
  quota = {
    image  = "registry.appmixer.com/appmixer-quota:5.2.0"
    env    = {}
    cpu    = 256
    memory = 512
  }

  # Logstash service configuration
  logstash_config = {
    rabbitmq_host          = local.rabbitmq.url
    rabbitmq_port          = local.rabbitmq.port
    rabbitmq_user          = local.rabbitmq.username
    rabbitmq_password      = local.rabbitmq.password
    elasticsearch_host     = "https://${module.elasticsearch.domain_endpoint}:443"
    elasticsearch_user     = local.elasticsearch_master_username
    elasticsearch_password = random_password.elasticsearch_password.result
  }
  logstash = {
    image = "opensearchproject/logstash-oss-with-opensearch-output-plugin:8.9.0"
    env = {
      LOGSTASH_CONF = templatefile("${path.module}/logstash/logstash.conf", local.logstash_config)
      LOGSTASH_YML  = file("${path.module}/logstash/logstash.yml")
    }
    cpu    = 512
    memory = 2048
    health_check = {
      retries = 10
      command = ["CMD-SHELL", "curl -s -XGET localhost:9600 || exit 1"]
      timeout : 5
      interval : 10
      startPeriod : 60
    }
    entrypoint               = ["/bin/sh", "-c", "printenv LOGSTASH_YML > /usr/share/logstash/config/logstash.yml; printenv LOGSTASH_CONF > /usr/share/logstash/pipeline/logstash.conf; /usr/local/bin/docker-entrypoint;"]
    autoscaling_max_capacity = 1
    autoscaling_min_capacity = 1
  }

}
