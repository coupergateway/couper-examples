server "simple-oauth-as" {
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
      foo = "bar"
    }
  }
}
