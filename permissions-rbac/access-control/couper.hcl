server {
  api {
    access_control = ["Token"]
    add_response_headers = {
      required-permission = request.context.beta_required_permission
      granted-permissions = join(" ", request.context.beta_granted_permissions)
    }

    endpoint "/a" {
      beta_required_permission = "a"

      proxy {
        backend = "api"
      }
    }

    endpoint "/b/{action}" { # send, copy
      beta_required_permission = "b:${request.path_params.action}"

      proxy {
        backend = "api"
      }
    }

    endpoint "/c" {
      beta_required_permission = {
        GET = ""
        DELETE = "c:del"
        "*" = "c"
      }

      proxy {
        backend = "api"
      }
    }
  }
}

definitions {
  jwt "Token" {
    signature_algorithm = "RS256"
    key_file = "pub-key.pem"
    # beta_roles_claim = "roles"
    # beta_roles_map = {
    #   developer = ["a", "b:send", "b:copy", "c"]
    #   admin = ["a", "b:send", "b:copy", "c", "c:del"]
    #   "*" = ["a"]
    # }
  }

  backend "api" {
    origin = "http://api:8080"
  }
}
