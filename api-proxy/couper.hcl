server {
  api {
    // uncomment the base_path to see how local paths "shift" without
    // affecting backend requests:
    // base_path = "/api/v1"

    // try /example/headers or /example/anything
    endpoint "/example/**" {
      proxy {
        path = "/**"
        backend {
          origin = "https://httpbin.org"

          // uncomment to set headers on the way
          //set_request_headers = {
          //  x-foo = "request"
          //}
          //set_response_headers = {
          //  x-bar = "response"
          //}
        }
      }
    }
  }
}
