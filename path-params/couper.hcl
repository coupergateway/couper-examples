server "path-params-example" {
  api {
    endpoint "/my/{category}/view" {
      proxy {
        backend {
          path = "/${req.path_params.category}"
          origin = "https://httpbin.org"
        }
      }
    }
  }
}
