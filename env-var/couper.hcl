server "my-api" {
  api {
    endpoint "/example/**" {
      proxy {
        path = "/**"
        backend {
          origin = "https://httpbin.org"
          //origin = env.BACKEND_ORIGIN
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
