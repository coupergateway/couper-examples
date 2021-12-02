server {
  endpoint "/request" {
    request {
      url = "https://httpbin.org/anything"
      json_body = {
        "message": "a simple request",
        "numbers": [1, "two",]
      }
    }
  }

  endpoint "/response" {
    response {
      json_body = {
        message = "a simple response"
        ID = request.id
      }
    }
  }
}
