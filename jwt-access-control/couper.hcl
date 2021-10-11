server "secured-api" {
  api {
    access_control = ["JWTToken"]
    endpoint "/private/**" {
      # remove_request_headers = ["Token"]
      proxy {
        path = "/**"
        backend {
          origin = "https://httpbin.org/"
        }
      }
    }
  }
}

definitions {
  jwt "JWTToken" {
    header = "Authorization"
    # header = "Token"
    # cookie = "token"
    signature_algorithm = "RS256"
    key_file = "pub.pem"

    # jwks_url = "http://localhost:9000/jwks.json"

    required_claims = ["iss"]
    claims = {
      sub = "some_user"
    }
  }
}
