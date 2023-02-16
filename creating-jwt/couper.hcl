server {
  endpoint "/token" {
    response {
      json_body = {
        access_token = jwt_sign("myjwt", {
          sub = request.form_body.username[0]
          aud = "The_Audience"
        })
        token_type = "Bearer"
        expires_in = "600"
      }
    }
  }

  endpoint "/token/local" {
    response {
      json_body = {
        access_token = jwt_sign("LocalToken", {})
        token_type = "Bearer"
        expires_in = "600"
      }
    }
  }

  api {
    access_control = ["LocalToken"]
    endpoint "/**" {
      response {
        json_body = { foo = 1}
      }
    }
  }
}

definitions {
  jwt_signing_profile "myjwt" {
    signature_algorithm = "RS256"
    key_file = "priv_key.pem"
    ttl = "600s"
    claims = {
      iss = "MyAS"
      iat = unixtime()
    }
    headers = {
      kid = "my-jwk-id"
    }
  }

  jwt "LocalToken" {
    signature_algorithm = "HS256"
    key = "Th3$e(rEt"
    signing_ttl = "600s"
  }
}
