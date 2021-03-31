server "multiple-requests" {

  api {
    endpoint "/headers" {
      request "first" {
        url = "https://httpbin.org/anything"
      }
      request "second" {
        url = "https://httpbin.org/status/404"
      }
      response {
        status = beresps.second.status
        headers = {
          x-first-status = beresps.first.status
        }
        json_body = beresps.first.json_body
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
