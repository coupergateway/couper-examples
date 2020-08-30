server "my-api" {

  api {
    // uncomment the base_path to see how local paths "shift" without
    // affecting backend requests:
    // /base_path = "/api/v1"

    // try /example/headers or /example/anything
    endpoint "/example/**" {
      path = "/**"
      backend {
        origin = "https://httpbin.org"
        // uncomment to read origin from env:
        //origin = env.HTTPBIN_ORIGIN

        // uncomment to set headers on the way
        //request_headers = {
        //  x-foo = "request"
        //}
        //response_headers = {
        //  x-bar = "response"
        //}
      }
    }
  }
}
