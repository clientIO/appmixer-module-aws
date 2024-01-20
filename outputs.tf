### ALB, ECS
output "alb_dns_name" {
  value = module.alb.dns_name
}

output "services_urls" {
  value = {
    backoffice = local.backoffice.url
    frontend   = local.frontend.url
    engine     = local.engine.url
  }
}
output "vpc_config" {
  value = {
    vpc_id          = local.vpc_id
    vpc_cidr_block  = local.vpc_cidr_block
    public_subnets  = local.public_subnet_ids
    private_subnets = local.private_subnet_ids
  }
}

output "managed_services" {
  value = {
    elasticache = {
      endpoint = try(module.elasticache.endpoint, "")
      ssm_credentials = {
        password = try(module.elasticache_ssm_password.names[0], "")
      }
    }
    rabbitmq = {
      endpoint = try(module.rabbit_mq.primary_console_url, "")
      ssm_credentials = {
        username = try("/${local.rabbitmq_ssm}/master_username", "")
        password = try("/${local.rabbitmq_ssm}/master_password", "")
      }
    }
    opensearch = {
      ssm_credentials = {
        endpoint = try(module.elasticsearch.domain_endpoint, "")
        username = try(module.elasticsearch_ssm_username.names[0], "")
        pasword  = try(module.elasticsearch_ssm_password.names[0], "")
      }
    }
    document_db = {
      endpoint = try(module.documentdb_cluster.endpoint, "")
      ssm_credentials = {
        username = try(module.document_db_ssm_username.names[0], "")
        password = try(module.document_db_ssm_password.names[0], "")
      }

    }
  }
}
