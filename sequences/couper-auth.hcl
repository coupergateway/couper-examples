server {
  hosts = ["*:8080"]
  api {
    endpoint "/" {
      request "token" {
        url = "http://token-provider:8081/token"
        form_body = {
          sub = "myself"
        }
        expected_status = [200]
      }
      # The reference to backend_responses.token makes Couper wait for request "token"'s response.
      request "pr" {
        url = "http://resource:8082/protected-res"
        headers = {
          authorization = "Bearer ${backend_responses.token.json_body.access_token}"
        }
        json_body = { a = true, b = 2 }
      }
      response {
        json_body = {
          pr = backend_responses.pr.json_body
        }
      }
    }
  }
}
