server "multiple-requests" {

  api {
    endpoint "/headers" {
      request "first" {
        url = "https://httpbin.org/anything"
        headers = {
          x-foo = "bar"
        }
      }
      request "second" {
        url = "https://httpbin.org/status/200"
      }
      add_response_headers = {
        x-second-status = beresps.second.status
      }
      // with more than one of request or proxy combined, we have to specify a response block:
      response {
        json_body = beresps.first.json_body.headers
      }
    }

    endpoint "/example/**" {
      proxy {
        path = "/**"
        backend {
          origin = "https://httpbin.org"
        }
      }
      request "additional" {
        url = "https://httpbin.org/status/404"
      }
      // use the response from the proxy, and add another header
      add_response_headers = {
        x-additional-status = beresps.additional.status
      }
    }
  }
}
