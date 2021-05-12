server "error-handling" {
  api {
    endpoint "/test" {
      access_control = ["ba"]
      response {
        json_body = { "ok" = true }
      }
    }
  }
}
definitions {
  basic_auth "ba" {
    user = "john.doe"
    password = "$eCr3T"
#    error_handler "basic_auth_credentials_missing" {
#      response {
#        status = 403
#        json_body = {
#          error = {
#            id = request.id
#            message = "access control error"
#            path = request.path
#            status = 403
#          }
#        }
#      }
#    }
  }
}
