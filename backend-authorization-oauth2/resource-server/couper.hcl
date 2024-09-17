server "resource-server" {
  api {
    access_control = ["token"]   # protect the resource server's api

    endpoint "/resource" {
      response {
        json_body = {"foo" = 1}
      }
    }
  }
}

definitions {
  jwt "token" {
    signature_algorithm = "HS256"
    key = "$eCr3T"
    bearer = true
  }
}
