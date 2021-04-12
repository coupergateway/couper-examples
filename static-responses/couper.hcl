server "static-responses" {
  endpoint "/" {
    response {
      status = 301
      headers = {
        location = "/app"
      }
    }
  }

  api {
    endpoint "/userinfo" {
      access_control = ["JWTToken"]
      response {
        json_body = request.context.JWTToken
      }
    }
  }
}
definitions {
  jwt "JWTToken" {
    header = "Authorization"
    signature_algorithm = "RS256"
    key_file = "pub.pem"
  }
}
