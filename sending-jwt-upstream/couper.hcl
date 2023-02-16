server {
  access_control = ["JWTToken"]

  api {
    endpoint "/private/**" {
      proxy {
        backend {
          origin = "https://httpbin.org/"
          path = "/**"

          set_request_headers = {
            x-jwt-sub = request.context.JWTToken.sub
            x-jwt = json_encode(request.context.JWTToken)
          }
        }
      }
    }
  }
}

definitions {
  jwt "JWTToken" {
    signature_algorithm = "HS256"
    key = "y0urS3cretT08eU5edF0rC0uPerInThe3xamp1e"
  }
}
