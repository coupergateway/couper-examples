server {
  api {
    endpoint "/" {
      proxy {
        backend = "fragile_backend"
      }
#       response {
#         headers = {
#           Health = backends.fragile_backend.health.state
#         }
#         json_body = backends.fragile_backend.health
#       }
#       error_handler "backend_unhealthy" {
#         response {
#           status = 503
#           headers = {
#             Retry-After = 15
#           }
#         }
#       }
    }
  }
}

definitions {
  backend "fragile_backend" {
    origin = "http://backend:8080"
#     use_when_unhealthy = true
#     beta_health {
#       expected_status = [200, 418]
#       interval = "3s"
#       path = "/"
#       expected_text = ""
#       failure_threshold = 2
#       timeout = "3s"
#       headers = {}
#     }
  }
}
