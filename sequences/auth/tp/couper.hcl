# for demonstration purposes only!
server {
  hosts = ["*:8081"]
  api {
    endpoint "/token" {
      response {
        json_body = {
          access_token = jwt_sign("Token", { sub = request.form_body.sub} )
        }
      }
    }
  }
}

definitions {
  jwt_signing_profile "Token" {
    signature_algorithm = "HS256"
    key = "$e(r3T"
    ttl = "10m"
  }
}
