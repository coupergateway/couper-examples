server {
  endpoint "/" {
    response {
      status = 301
      headers = {
        location = "/app"
      }
    }
  }

  endpoint "/userinfo" {
    access_control = ["JWTToken"]
    response {
      json_body = request.context.JWTToken
    }
  }

  endpoint "/app/conf" {
    response {
      json_body = {
        version = env.APP_VERSION
        env = env.APP_ENV
        debug = env.APP_DEBUG == "true"
        couper = couper.version
      }
    }
  }
}

definitions {
  jwt "JWTToken" {
    signature_algorithm = "RS256"
    key_file = "pub.pem"
  }
}
