# Query Parameter

Query parameter can be used for manipulations of the URL query string for the upstream request.
By default, the query string is passed unchanged to the backend.

The `query` [variable](https://github.com/avenga/couper/tree/master/docs#variables) gets evaluated on client requests which matches the URL query string.
A query string `?category=insects` will make the query part value `insects` accessible under `request.query.category[0]`.
As there may be several parameters with the same name, a single value is accessed with the (0-based) index operator.
A query string `?category=insects&category=snakes` will make the query part value `insects` accessible
under `request.query.category[0]` and the `snakes` under `request.query.category[1]`.

## `remove_query_params`

The `remove_query_params` removes query parameters from the upstream request.

```hcl
server "query-params-example" {
  api {
    endpoint "/remove" {
      proxy {
        backend {
          remove_query_params = ["cat", "dog"]

          origin = "https://httpbin.org"
          path = "/anything"
        }
      }
    }
  }
}
```

A request to [http://localhost:8080/remove?cat=true&dog=true&mouse=true](http://localhost:8080/remove?cat=true&dog=true&mouse=true)
will be changed to `https://httpbin.org/anything?mouse=true`.

## `set_query_params`

The `set_query_params` sets/overrides query parameters in the upstream request.

```hcl
server "query-params-example" {
  api {
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
  }
}
```

A request to [http://localhost:8080/set](http://localhost:8080/set)
will be changed to `https://httpbin.org/anything?categories=animals&categories=birds`.

A request to [http://localhost:8080/set?categories=insects](http://localhost:8080/set?categories=insects)
will be changed to `https://httpbin.org/anything?categories=animals&categories=birds`, too.

## `add_query_params`

The `add_query_params` appends query parameters in the upstream request.

```hcl
server "remove-query-params-example" {
  api {
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
  }
}
```

A request to [http://localhost:8080/add](http://localhost:8080/add)
will be changed to `https://httpbin.org/anything?categories=animals`.

A request to [http://localhost:8080/add?categories=birds](http://localhost:8080/add?categories=birds)
will be changed to `https://httpbin.org/anything?categories=birds&categories=animals`.

## Example

Try out and see how the response body `url` property changes accordingly:

[http://localhost:8080/anything?cat=true&dog=true&category=insects&category=snakes&sort=name](http://localhost:8080/anything?cat=true&dog=true&category=insects&category=snakes&sort=name)
