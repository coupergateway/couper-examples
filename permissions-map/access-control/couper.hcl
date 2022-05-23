server {
  api {
    base_path = "/calendars"
    access_control = ["Token"]
    # add_response_headers = {
    #   required-permission = request.context.beta_required_permission
    #   scope = request.context.Token.scope
    #   granted-permissions = join(" ", request.context.beta_granted_permissions)
    # }

    endpoint "/" {
      beta_required_permission = {
        POST = "calendar"
        GET = "calendar.readonly"
      }

      proxy {
        backend = "api"
      }
    }

    endpoint "/{calendarId}" {
      beta_required_permission = {
        GET = "calendar.readonly"
        PATCH = "calendar"
        PUT = "calendar"
        DELETE = "calendar"
      }

      proxy {
        backend = "api"
      }
    }

    endpoint "/{calendarId}/events" {
      beta_required_permission = {
        GET = "calendar.events.readonly"
        POST = "calendar.events"
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
    # beta_permissions_claim = "scope"
    # beta_permissions_map = {
    #   "calendar" = ["calendar.readonly", "calendar.events"]
    #   "calendar.events" = ["calendar.events.readonly"]
    #   "calendar.readonly" = ["calendar.events.readonly"]
    # }
  }

  backend "api" {
    origin = "http://api:8080"
    path_prefix = request.context.Token.sub
  }
}
