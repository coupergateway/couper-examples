server "error-handling" {
  api {
    access_control = ["ba"]
    endpoint "/test" {
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
    error_handler {
      response {
        status = 403
        json_body = {
          error = {
            id = request.id
            message = "access control error"
            path = request.path
            status = 403
          }
        }
      }
    }
  }
}
