server {
  api {
    access_control = ["Token"]
    # add_response_headers = {
    #   required-permission = request.context.beta_required_permission
    #   granted-permissions = join(" ", request.context.beta_granted_permissions)
    # }

    # error_handler "beta_insufficient_permissions" {
    #   response {
    #     status = 403
    #     json_body = {
    #       error = "request lacking granted permission '${request.context.beta_required_permission}'"
    #     }
    #   }
    # }

    endpoint "/**" {
      proxy {
        backend = "api"
      }
    }

    # endpoint "/a" {
      # beta_required_permission = "a"
    #   proxy = "p"
    # }

    # endpoint "/b/{action}" { # send, copy
      # beta_required_permission = "b:${request.path_params.action}"
    #   proxy = "p"
    # }

    # endpoint "/c" {
      # beta_required_permission = {
      #   GET = ""
      #   DELETE = "c:del"
      #   "*" = "c"
      # }
    #   proxy = "p"
    # }
  }
}

definitions {
  jwt "Token" {
    signature_algorithm = "RS256"
    key_file = "pub-key.pem"
    # beta_permissions_claim = "permissions"
  }

  # proxy "p" {
  #   backend = "api"
  # }

  backend "api" {
    origin = "http://api:8080"
  }
}
