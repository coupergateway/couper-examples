server "form" {
  endpoint "/form" {
    request {
      url = "https://httpbin.org/anything"
      form_body = {
        message = "foo & bar"
        numbers = [1, 2]
      }
    }
  }
}
