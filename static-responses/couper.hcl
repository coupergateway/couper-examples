server "static-responses" {
  api {
    endpoint "/redirect" {
      response {
        status = 303
        headers = {
          location = "https://www.example.com/"
        }
      }
    }

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
