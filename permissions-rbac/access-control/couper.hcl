server {
  api {
    access_control = ["Token"]
    add_response_headers = {
      required-permission = request.context.required_permission
      granted-permissions = join(" ", request.context.beta_granted_permissions)
    }

    endpoint "/a" {
      required_permission = "a"
      proxy = "p"
    }

    endpoint "/b/{action}" { # send, copy
      required_permission = "b:${request.path_params.action}"
      proxy = "p"
    }

    endpoint "/c" {
      required_permission = {
        GET = ""
        DELETE = "c:del"
        "*" = "c"
      }
      proxy = "p"
    }
  }
}

definitions {
  jwt "Token" {
    signature_algorithm = "RS256"
    key_file = "pub-key.pem"
    # roles_claim = "roles"
    # beta_roles_map = {
    #   developer = ["a", "b:send", "b:copy", "c"]
    #   admin = ["a", "b:send", "b:copy", "c", "c:del"]
    #   "*" = ["a"]
    # }
  }

  proxy "p" {
    backend = "api"
  }

  backend "api" {
    origin = "http://api:8080"
  }
}
