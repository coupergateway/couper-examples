server "my-api" {

  api {
    // uncomment the base_path to see how local paths "shift" without
    // affecting backend requests.
    //
    base_path = "/api/v1"

    // try /httpbin/headers or /httpbin/anything
    endpoint "/httpbin/**" {
      path = "/**"
      backend {
        origin = "https://httpbin.org"
      }
    }
  }
  
}
