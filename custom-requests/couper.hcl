server "custom-requests" {
  api {
    endpoint "/headers1" {
      request {
        url = "https://httpbin.org/headers"
        headers = {
          x-foo = "foo"
        }
      }
      // use the response to the request
    }

    endpoint "/headers2" {
      request {
        url = "https://httpbin.org/headers"
        headers = {
          x-bar = "bar"
        }
      }
      // use the response to the request, and add another header
      add_response_headers = {
        x-additional-status = beresp.status
      }
    }

    endpoint "/status/200" {
      request "st" {
        url = "https://httpbin.org/status/200"
      }
      // no default request, so an explicit response is needed
      response {
        headers = {
          x-status = beresps.st.status
        }
      }
    }

    endpoint "/headers3" {
      request {
        path = "/headers"
        backend = "httpbin"
      }
    }
  }
}
definitions {
  backend "httpbin" {
    origin = "https://httpbin.org"
    timeout = "10s"
  }
}
