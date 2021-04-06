server "custom-requests" {

  endpoint "/get" {
    request {
      url = "https://httpbin.org/anything"
    }
  }

  endpoint "/headers" {
    request {
      url = "https://httpbin.org/headers"
      headers = {
        user-agent = "Couper"
        couper-id = request.id
      }
    }
  }

  endpoint "/post" {
    request "post" {
      url = "https://httpbin.org/anything?q=4711"
      method = "post"
      body = "hey there!"
    }

    // no default request, so an explicit response is needed
    response {
      json_body = backend_responses.post.json_body
    }
  }


  endpoint "/use-backend" {
    request {
      // execute request in the context of a named backend
      backend "httpbin" {
        path = "/delay/1"
      }
    }
  }
}

definitions {
  backend "httpbin" {
    origin = "https://httpbin.org"
    max_connections = 1
  }
}
