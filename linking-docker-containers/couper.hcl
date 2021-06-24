server "my-api" {
  api {
    endpoint "/example/**" {
      proxy {
        path = "/**"
        backend {
          origin = "http://${env.HTTPBIN_PORT_80_TCP_ADDR}:80"
        }
      }
    }
  }
}
