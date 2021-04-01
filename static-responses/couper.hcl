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
        status = 200
        json_body = req.ctx.JWTToken
      }
    }
  }
}
definitions {
  jwt "JWTToken" {
    header = "Authorization"
    signature_algorithm = "RS256"
    key_file = "../jwt-access-control/pub.pem"
  }
}
