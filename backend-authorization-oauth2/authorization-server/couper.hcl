server "authorization-server" {
  endpoint "/token" {
    response {
      json_body = {
        "access_token" = jwt_sign("token", {})
        "expires_in" = 10
      }
    }
  }
}

definitions {
  jwt_signing_profile "token" {
    signature_algorithm = "HS256"
    key = "$eCr3T"
    ttl = "10s"
  }
}
