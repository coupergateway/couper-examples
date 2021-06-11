server "my-api" {

  api {

    endpoint "/example/**" {
      proxy {
        path = "/**"
        backend {
          origin = "https://httpbin.org"
          // uncomment to read origin from env:
          //origin = env.HTTPBIN_ORIGIN

        }
      }
    }
  }
}
