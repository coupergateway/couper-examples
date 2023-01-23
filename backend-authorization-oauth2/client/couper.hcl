server "client" {
  api {
    endpoint "/resource" {
      proxy {
        backend {
          origin = "http://resource-server:8080"
#          oauth2 {
#            grant_type = "client_credentials"
#            token_endpoint = "http://authorization-server:8080/token"
#            client_id = "my-client"
#            client_secret = "my-client-secret"
#          }
        }
      }
    }
  }
}
