# Query Parameter

Query parameter can be used for manipulations of the URL query string for the upstream request.
By default, the query string is passed unchanged to the backend.

The `query` [variable](https://github.com/avenga/couper/tree/master/docs#variables_conf) gets evaluated on client requests which matches the URL query string.
A query string `?category=cats` will make the query part value `cats` accessible under `request.query.category`.
Parameters with the same name can be accessed with the index operator.
A query string `?category=cats&category=dogs` will make the query part value `cats` accessible
under `request.query.category[0]` and the `dogs` under `request.query.category[1]`.

## `remove_query_params`

The `remove_query_params` removes query parameters from the upstream request.

```hcl
server "remove-query-params-example" {
  api {
    endpoint "/anything" {
      proxy {
        backend {
          remove_query_params = ["cat", "dog"]

          origin = "https://httpbin.org"
        }
      }
    }
  }
}
```

A request to [http://localhost:8080/anything?cat=true&dog=true&mouse=true](http://localhost:8080/anything?cat=true&dog=true&mouse=true)
will be changed to `https://httpbin.org/anything?mouse=true`.

## `set_query_params`

The `set_query_params` sets/overrides query parameters in the upstream request.

```hcl
server "remove-query-params-example" {
  api {
    endpoint "/anything" {
      proxy {
        backend {
          set_query_params = {
            categories = ["animals", "birds"]
          }

          origin = "https://httpbin.org"
        }
      }
    }
  }
}
```

A request to [http://localhost:8080/anything](http://localhost:8080/anything)
will be changed to `https://httpbin.org/anything?categories=animals&categories=birds`.

A request to [http://localhost:8080/anything?categories=insects](http://localhost:8080/anything?categories=insects)
will be changed to `https://httpbin.org/anything?categories=animals&categories=birds`, too.

## `add_query_params`

The `add_query_params` appends query parameters in the upstream request.

```hcl
server "remove-query-params-example" {
  api {
    endpoint "/anything" {
      proxy {
        backend {
          add_query_params = {
            categories = "animals"
          }

          origin = "https://httpbin.org"
        }
      }
    }
  }
}
```

A request to [http://localhost:8080/anything](http://localhost:8080/anything)
will be changed to `https://httpbin.org/anything?categories=animals`.

A request to [http://localhost:8080/anything?categories=birds](http://localhost:8080/anything?categories=birds)
will be changed to `https://httpbin.org/anything?categories=birds&categories=animals`.

## Example

Try out and see how the response body `url` property changes accordingly:

[http://localhost:8080/anything?cat=true&dog=true&category=insects&category=snakes&sort=name](http://localhost:8080/anything?cat=true&dog=true&category=insects&category=snakes&sort=name)
