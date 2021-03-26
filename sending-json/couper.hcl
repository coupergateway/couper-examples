server "api" {
  endpoint "/request" {
    request {
      url = "https://httpbin.org/anything"
      json_body = {
        param1 = 1
        param2 = "t,w:o"
      }
    }
  }
  endpoint "/response" {
    response {
      json_body = {
        message = "a simple response"
        ID = req.id
      }
    }
  }
}
