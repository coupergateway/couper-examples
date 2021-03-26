server "api" {
  endpoint "/json" {
    request {
      url = "https://httpbin.org/anything"
      json_body = {
        param1 = 1
        param2 = "t,w:o"
      }
    }
    response {
      json_body = beresp.json_body
    }
  }
  endpoint "/form" {
    request {
      url = "https://httpbin.org/anything"
      form_body = {
        param1 = 1
        param2 = "t,w:o"
      }
    }
    response {
      json_body = beresp.json_body
    }
  }
}
