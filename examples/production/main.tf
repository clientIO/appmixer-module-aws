module "example_module" {
  source = "../../"

  root_dns_name = "ecs.appmixer.co"
  zone_id       = "XXX"

  init_user = {
    email    = "XXX"
    username = "XXX"
    password = "XXX"
  }

  ecs_auth_data = "XXX"

  ecs_common_service_config = {
    wait_for_steady_state    = true
    autoscaling_min_capacity = 2
  }
}
