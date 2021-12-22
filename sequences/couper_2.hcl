server "client" {
  hosts = ["*:8080"]
  api {
    endpoint "/" {
      request "token" {
        url = "http://localhost:8081/token"
        form_body = {
          sub = "myself"
        }
        expected_status = [200]
      }
      # The reference to backend_responses.token makes Couper wait for request "token"'s response.
      request {
        url = "http://localhost:8082/res"
        headers = {
          authorization = "Bearer ${backend_responses.token.json_body.access_token}"
        }
        json_body = { a = true, b = 2 }
      }
    }
  }
}

server "token-provider" {
  hosts = ["*:8081"]
  api {
    endpoint "/token" {
      response {
        json_body = {
          access_token = jwt_sign("Token", { sub = request.form_body.sub} )
        }
      }
    }
  }
}

server "protected-service" {
  hosts = ["*:8082"]
  api {
    access_control = ["Token"]
    endpoint "/res" {
      response {
        json_body = {
          you_sent = request.json_body
        }
      }
    }
  }
}

definitions {
  jwt "Token" {
    signature_algorithm = "HS256"
    key = "$e(r3T"
    signing_ttl = "10m"
    header = "authorization"
  }
}
