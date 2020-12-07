server "secured-api" {
  access_control = ["JWTToken"]
  api {
    endpoint "/private/**" {
      path = "/**"
      backend {
        origin = "https://httpbin.org/"
        set_request_headers = {
          x-jwt-sub = req.ctx.JWTToken.sub
        }
      }
    }
  }
}

definitions {
  jwt "JWTToken" {
    header = "Authorization"
    signature_algorithm = "HS256"
    key = "y0urS3cretT08eU5edF0rC0uPerInThe3xamp1e"
  }
}
