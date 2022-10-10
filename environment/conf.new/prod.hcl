environment "prod" {
  server {
    access_control = ["token"]
  }

  definitions {
    jwt "token" {
      signature_algorithm = "HS256"
      key = "secr3T"
    }
  }

  settings {
    beta_metrics = true
  }
}
