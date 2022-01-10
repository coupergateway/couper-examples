server {
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
