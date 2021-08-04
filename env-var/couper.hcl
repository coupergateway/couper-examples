server "my-api" {
  api {
    endpoint "/example/**" {
      proxy {
        path = "/**"
        backend {
          origin = env.HTTPBIN_ORIGIN
        }
      }
    }
  }
}

defaults {
  environment_variables = {
    HTTPBIN_ORIGIN = "https://httpbin.org"
  }
}
