server {
  access_control = ["my-jwt"]
}

definitions {
  jwt "my-jwt" {
    jwks_url = "https://demo-idp.couper.io/jwks.json"
    required_claims = ["role", "sub", "exp"]
    claims = {
      iss = "https://demo-idp.couper.io/"
    }
  }
}
