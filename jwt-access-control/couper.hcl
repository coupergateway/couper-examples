server {
  api {
    access_control = ["JWTToken"]
    endpoint "/private/**" {
      # remove_request_headers = ["API-Token"]
      proxy {
        backend {
          origin = "https://httpbin.org/"
          path = "/**"
        }
      }
    }
  }
}

definitions {
  jwt "JWTToken" {
    bearer = true
    # header = "API-Token"
    # cookie = "token"
    # token_value = request.form_body.token[0]
    # token_value = request.json_body.token
    signature_algorithm = "RS256"
    key_file = "pub.pem"

    required_claims = ["iss"]
    claims = {
      sub = "some_user"
    }
  }
}
