server {
  api {
    base_path = "/calendars"

    endpoint "/" {
      response {
        json_body = {
          method = request.method
          path = request.path
        }
      }
    }

    endpoint "/{calendarId}" {
      response {
        json_body = {
          method = request.method
          path = request.path
        }
      }
    }

    endpoint "/{calendarId}/events" {
      response {
        json_body = {
          method = request.method
          path = request.path
        }
      }
    }
  }
}
