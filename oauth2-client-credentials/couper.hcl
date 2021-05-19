server "client" {
  hosts = ["localhost:8080"]
  api {
    endpoint "/foo" {
      proxy {
        backend {
          origin = "http://localhost:8081"
          path = "/resource"
#          oauth2 {
#            grant_type = "client_credentials"
#            token_endpoint = "http://localhost:8082/token"
#            client_id = "my-client"
#            client_secret = "my-client-secret"
#          }
        }
      }
    }
  }
}
server "resource-server" {
  hosts = ["localhost:8081"]
  api {
#    access_control = ["token"]   # protect the resource server's api
    endpoint "/resource" {
      response {
        json_body = {"foo" = 1}
      }
    }
  }
}
#server "authorization-server" {
#  hosts = ["localhost:8082"]
#  endpoint "/token" {
#    response {
#      json_body = {
#        "access_token" = jwt_sign("token", {})
#        "expires_in" = 10
#      }
#    }
#  }
#}
definitions {
#  jwt_signing_profile "token" {
#    signature_algorithm = "HS256"
#    key = "$eCr3T"
#    ttl = "10s"
#  }
  jwt "token" {
    signature_algorithm = "HS256"
    key = "$eCr3T"
    header = "Authorization"
  }
}
