server {
  api {
    endpoint "/example/**" {
      proxy {
        backend {
          origin = "http://${env.HTTPBIN_PORT_80_TCP_ADDR}:80"
          path = "/**"
        }
      }
    }
  }
}
