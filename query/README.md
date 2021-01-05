# Query Parameter

Query parameter can be used for manipulations of the URL query string for the upstream request.

## Configuration

The `query` [variable](https://github.com/avenga/couper/tree/master/docs#variables_conf) gets evaluated on client requests which matches the URL query string.
A query string `?category=cats` will make the query part value `cats` accessible under `req.query.category`.
Parameters with the same name can be accessed with the index operator.
A query string `?category=cats&category=dogs` will make the query part value `cats` accessible under `req.query.category[0]` and the `dogs` under `req.query.category[1]`.

```hcl
server "query-params-example" {
  api {
    endpoint "/anything" {
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
```

A request to [http://localhost:8080/anything?cat=true&dog=true&category=insects&category=snakes&sort=name](http://localhost:8080/anything?cat=true&dog=true&category=insects&category=snakes&sort=name) will be changed to `https://httpbin.org/anything?categories=animals&categories=birds&categories=insects&categories=snakes&sort=name&sort=dest` for the upstream request.  

Try out and see how the response body `url` property changes accordingly:

[http://localhost:8080/anything?cat=true&dog=true&category=insects&category=snakes&sort=name](http://localhost:8080/anything?cat=true&dog=true&category=insects&category=snakes&sort=name)
