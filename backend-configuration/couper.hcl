server {
  endpoint "/downloads/**" {
    proxy {
      backend "httpbin" {
        path = "/anything/**"
        timeout = "10m"

        set_request_headers = {
          x-hello = "from Couper"
        }
      }
    }
  }

  endpoint "/anything" {
    proxy {
      backend = "httpbin"
    }
  }
}

definitions {
  backend "httpbin" {
    origin = "https://httpbin.org"
    timeout = "5s"
    max_connections = 10
    ttfb_timeout = "10s"
  }
}
