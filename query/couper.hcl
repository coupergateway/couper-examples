server {
  endpoint "/remove" {
    proxy {
      backend {
        remove_query_params = ["cat", "dog"]

        origin = "https://httpbin.org"
        path = "/anything"
      }
    }
  }

  endpoint "/set" {
    proxy {
      backend {
        set_query_params = {
          categories = ["animals", "birds"]
        }

        origin = "https://httpbin.org"
        path = "/anything"
      }
    }
  }

  endpoint "/add" {
    proxy {
      backend {
        add_query_params = {
          categories = "animals"
        }

        origin = "https://httpbin.org"
        path = "/anything"
      }
    }
  }

  endpoint "/anything" {
    proxy {
      backend {
        remove_query_params = ["old", "cat", "dog", "category"]

        set_query_params = {
          categories = ["animals", "birds"]
        }

        add_query_params = {
          categories = request.query.category
          sort = "dest"
        }

        origin = "https://httpbin.org"
      }
    }
  }
}
