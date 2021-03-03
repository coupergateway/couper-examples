server "query-params-example" {
  api {
    endpoint "/anything" {
      proxy {
        backend {
          remove_query_params = ["cat", "dog", "category"]

          set_query_params = {
            categories = ["animals", "birds"]
          }

          add_query_params = {
            categories = req.query.category
            sort = "dest"
          }

          origin = "https://httpbin.org"
        }
      }
    }
  }
}
