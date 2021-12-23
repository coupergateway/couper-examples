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
      request "pr" {
        url = "http://localhost:8082/protected-res"
        headers = {
          authorization = "Bearer ${backend_responses.token.json_body.access_token}"
        }
        json_body = { a = true, b = 2 }
      }
#      request "ur" {
#        url = "http://localhost:8082/unprotected-res"
#        json_body = { c = "foo" }
#      }
      response {
        json_body = {
          pr = backend_responses.pr.json_body
#          ur = backend_responses.ur.json_body
        }
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

server "service" {
  hosts = ["*:8082"]
  api {
    endpoint "/protected-res" {
      access_control = ["Token"]
      response {
        json_body = {
          you_sent = request.json_body
        }
      }
    }
    endpoint "/unprotected-res" {
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
  }
}
