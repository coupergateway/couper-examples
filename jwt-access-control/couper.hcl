server "secured-api" {
  api {
    access_control = ["JWTToken"]
    endpoint "/private/**" {
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
    signature_algorithm = "RS256"
    key_file = "pub.pem"
    header = "Authorization"

    required_claims = ["iss"]
    claims = {
      sub = "some_user"
    }
  }
}
