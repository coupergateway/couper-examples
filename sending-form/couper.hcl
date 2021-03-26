server "api" {
  endpoint "/form" {
    request {
      url = "https://httpbin.org/anything"
      form_body = {
        param1 = 1
        param2 = "t,w:o"
      }
    }
  }
}
