server {
  files {
    document_root = "/htdocs"
  }

  spa {
    bootstrap_file = "/htdocs/index.html"
    paths = ["/", "/app"]
  }

  set_response_headers = {
    x-service = env.SERVICE_NAME
  }
}

defaults {
  environment_variables = {
    SERVICE_NAME = "example"
  }
}
