server {
  api {
    endpoint "/my/{category}/view" {
      proxy {
        backend {
          path = "/${request.path_params.category}"
          origin = "https://httpbin.org"
        }
      }
    }
  }
}
