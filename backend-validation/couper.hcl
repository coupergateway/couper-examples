server "my-api" {
  api {
    backend = "validated-origin"

    endpoint "/validate" {
      path = "/anything"
      set_query_params = {
        show_env = "true"
      }
    }
  }
}

definitions {
  backend "validated-origin" {
    origin = "https://httpbin.org"
    openapi {
      file = "openapi_refined.yaml"
    }
  }
}
