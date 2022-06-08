server {
  api {
    base_path = "/{userid}/calendars"

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
