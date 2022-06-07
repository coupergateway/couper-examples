server {
  hosts = ["*:8080"]
  api {
    endpoint "/login" {
      access_control = ["ba"]
      response {
        body = jwt_sign("MyToken", { sub = request.context.ba.user })
      }
#      custom_log_fields = {
#        ev_type = "login"
#        user = request.context.ba.user
#      }
    }
  }
  api {
    base_path = "/protected"
    access_control = ["MyToken"]
    endpoint "/**" {
      proxy {
        backend "mail" {
          path = "/**"
        }
      }
    }
  }
}

server {
  hosts = ["*:8081"]
  api {
    endpoint "/send-mail" {
      response {
        json_body = {
          sent = true
        }
      }
    }
  }
}

definitions {
  basic_auth "ba" {
    user = "john.doe"
    password = "asdf"
  }
  jwt "MyToken" {
    header = "authorization"
    signature_algorithm = "HS256"
    key = "$e(R3t"
    signing_ttl = "10m"
#    custom_log_fields = {
#      sub = request.context.MyToken.sub
#    }
  }
  backend "mail" {
    origin = "http://localhost:8081"
#    custom_log_fields = {
#      recipient = request.json_body.to
#      subject = request.json_body.subject
#    }
  }
}
