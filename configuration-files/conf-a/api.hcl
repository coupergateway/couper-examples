server {
  api "serviceA" {
    base_path = "/api/v1/service-a"
    endpoint "/**" {
      proxy {
        url = "http://${env.SERVICE_A_ORIGIN}/"
      }
    }
  }
}

defaults {
  environment_variables = {
    SERVICE_A_ORIGIN = "localhost:8080"
  }
}
