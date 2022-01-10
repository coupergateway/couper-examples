server {
  hosts = ["*:8082"]
  api {
    endpoint "/protected-res" {
      access_control = ["Token"]
      response {
        json_body = {
          you_sent = request.json_body
        }
      }
    }
  }
}

definitions {
  jwt "Token" {
    signature_algorithm = "HS256"
    key = "$e(r3T"
  }
}
