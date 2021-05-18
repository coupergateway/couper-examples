server "backend-configuration" {
  endpoint "/downloads/**" {
    proxy {
      backend "main" {
        path = "/downloads/**"
        timeout = "10m"

        set_request_headers = {
          x-hello = "from Couper"
        }
      }
    }
  }

  endpoint "/data/**" {
    path = "/data/**"
    proxy {
      backend "main"
    }
  }
}

definitions {
  backend "main" {
    origin = "https://httpbin.org"
    timeout = "5s"
    max_connections = 10
    ttfb_timeout = "10s"
  }
}
