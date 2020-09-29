server "secured-api" {
  access_control = ["JWTToken"]
  api {
    endpoint "/private/**" {
      backend {
        origin = "https://httpbin.org/"
        path = "/**"
        request_headers = {
          x-jwt-sub = req.ctx.JWTToken.sub
        }
      }
    }
  }
}

definitions {
  jwt "JWTToken" {
    header = "Authorization"
    signature_algorithm = "RS256"
    key_file = "pubkey.pem"
  }
}
