server {
  api {
    base_path = "/calendars"
    access_control = ["Token"]
    # add_response_headers = {
    #   required-permission = request.context.required_permission
    #   scope = request.context.Token.scope
    #   granted-permissions = join(" ", request.context.granted_permissions)
    # }

    endpoint "/" {
      required_permission = {
        POST = "calendar"
        GET = "calendar.readonly"
      }
      proxy = "p"
    }

    endpoint "/{calendarId}" {
      required_permission = {
        GET = "calendar.readonly"
        PATCH = "calendar"
        PUT = "calendar"
        DELETE = "calendar"
      }
      proxy = "p"
    }

    endpoint "/{calendarId}/events" {
      required_permission = {
        GET = "calendar.events.readonly"
        POST = "calendar.events"
      }
      proxy = "p"
    }
  }
}

definitions {
  jwt "Token" {
    signature_algorithm = "RS256"
    key_file = "pub-key.pem"
    # permissions_claim = "scope"
    # permissions_map = {
    #   "calendar" = ["calendar.readonly", "calendar.events"] # no need to list calendar.events.readonly here, as the map is called recursively
    #   "calendar.events" = ["calendar.events.readonly"]
    #   "calendar.readonly" = ["calendar.events.readonly"]
    # }
  }

  proxy "p" {
    backend = "api"
  }

  backend "api" {
    origin = "http://api:8080"
    path_prefix = request.context.Token.sub
  }
}
