server {
  environment "prod" {
    # production only
    access_control = ["token"]
  }
  environment "test" {
    # test only
    access_control = ["credentials"]
  }

  api {
    endpoint "/" {
      proxy {
        backend = "backend"
      }
    }

    endpoint "/info" {
      response {
        json_body = {
          version = couper.version
          environment = couper.environment
        }
      }
    }
  }
}

definitions {
  backend "backend" {
    origin = "https://httpbin.org/"
    path = "/anything"
  }

  # for prod setup
  jwt "token" {
    signature_algorithm = "HS256"
    key = "secr3T"
  }

  # for test setup
  basic_auth "credentials" {
    user     = "user"
    password = "p4ssw0rd"
  }
}

settings {
  environment "prod" {
    # enable metrics on production
    beta_metrics = true
  }
  environment = "prod"
}
