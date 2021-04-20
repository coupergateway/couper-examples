server "file-server" {
  files {
    document_root = "htdocs"
  }

  api {
    base_path = "/api"
    endpoint "/greet" {
      request {
        url = "${env.SERVICE_ORIGIN}/ip"
      }
      response {
        json_body = {
          message = "${env.GREET_NAME} greets ${backend_responses.default.json_body.origin}!"
        }
      }
    }

  }
}
