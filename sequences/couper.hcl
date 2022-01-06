server "sequence" {
  hosts = ["*:8080"]
  api {
    endpoint "/connect" {
      # proxy: pass the client request body to /add
      proxy "add" {
        url = "http://localhost:8081/add"
        # store response in backend_responses.add
        expected_status = [200]
      }
      # "default" request: pass response to client
      request {
        url = "http://localhost:8081/multiply"
        json_body = [ backend_responses.add.json_body.result, 4 ]
        expected_status = [200]
      }
      error_handler "unexpected_status" {
        response {
          status = 500
          json_body = {
            error = "upstream error"
            error_description = "an upstream service responded with an unexpected status code"
          }
        }
        custom_log_fields = {
          add = backend_responses.add.body
          default = backend_responses.default.body
        }
      }
    }
  }
}

server "math" {
  hosts = ["*:8081"]
  api {
    endpoint "/add" {
      # expects an array with two numbers
      response {
        json_body = {
          result = request.json_body[0] + request.json_body[1]
        }
      }
    }
    endpoint "/multiply" {
      # expects an array with two numbers
      response {
        json_body = {
          result = request.json_body[0] * request.json_body[1]
        }
      }
    }
  }
}
