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

  endpoint "/app/conf" {
    response {
      json_body = {
        version = env.APP_VERSION
        env = env.APP_ENV
        debug = env.APP_DEBUG == "true"
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
