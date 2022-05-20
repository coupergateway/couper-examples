server {
  api {
    endpoint "/a" {
      response {
        json_body = {
          method = request.method
          path = request.path
        }
      }
    }

    endpoint "/b/send" {
      response {
        json_body = {
          method = request.method
          path = request.path
        }
      }
    }

    endpoint "/b/copy" {
      response {
        json_body = {
          method = request.method
          path = request.path
        }
      }
    }

    endpoint "/c" {
      response {
        json_body = {
          method = request.method
          path = request.path
        }
      }
    }
  }
}
