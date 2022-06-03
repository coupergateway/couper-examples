server {
  api {
    endpoint "/example/**" {
      proxy {
        backend {
          origin = "https://httpbin.org"
          //origin = env.BACKEND_ORIGIN
          path = "/**"
        }
      }
    }
  }
}

//defaults {
//  environment_variables = {
//    BACKEND_ORIGIN = "http://backend:9000"
//  }
//}
