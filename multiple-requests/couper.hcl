server "multiple-requests" {

  endpoint "/headers" {
    request "first" {
        url = "https://httpbin.org/headers"
    }
    request "second" {
      url = "https://httpbin.org/status/404"
    }
    response {
      status = backend_responses.second.status
      headers = {
        x-first-status = backend_responses.first.status
      }
      json_body = backend_responses.first.json_body
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
      x-additional-status = backend_responses.additional.status
    }
  }

}
