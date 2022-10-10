server {
  api {
    endpoint "/" {
      proxy {
        backend = "backend"
      }
    }
  }
}

definitions {
  backend "backend" {
    origin = "https://httpbin.org/"
    path = "/anything"
  }
}

settings {
  environment = "devel"
}
