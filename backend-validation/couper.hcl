server {
  api {
    endpoint "/validate" {
      proxy {
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
}
