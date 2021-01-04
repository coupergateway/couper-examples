server "my-api" {
  api {
    endpoint "/validate" {
      backend {
        origin = "https://httpbin.org"
        path = "/anything"
        openapi {
          file = "openapi.yaml"
          # file = "openapi_refined.yaml"
        }
      }
    }
  }
}
