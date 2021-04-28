# Query Parameter Manipulation

Query parameter modifiers can be used for manipulations of the URL query string for the upstream proxy request.
By default, for proxy requests the query string is passed unchanged to the backend.

The `request.query` [variable](https://github.com/avenga/couper/tree/master/docs#variables) is filled with information from the client request URL's query string.
A query string `?category=insects` will make the query part value `insects` accessible under `request.query.category[0]`.
As there may be several parameters with the same name, a single value is accessed with the (0-based) index operator.
A query string `?category=insects&category=snakes` will make the query part value `insects` accessible
under `request.query.category[0]` and the `snakes` under `request.query.category[1]`.

## `remove_query_params`

The `remove_query_params` attribute removes query parameters from the backend request.

```hcl
server "query-params-example" {
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
```

A request to [http://localhost:8080/remove?cat=true&dog=true&mouse=true](http://localhost:8080/remove?cat=true&dog=true&mouse=true)
will be changed to `https://httpbin.org/anything?mouse=true`.

## `set_query_params`

The `set_query_params` attribute sets query parameters in the backend request. It won't matter what the client sends to Couper, `set_query_params` will always win.

The values of the parameters can be a string, or an array if you need to set multiple parameters with the same name:

```hcl
server "query-params-example" {
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
```

A request to [http://localhost:8080/set](http://localhost:8080/set)
will be changed to `https://httpbin.org/anything?categories=animals&categories=birds`.

A request to [http://localhost:8080/set?categories=insects](http://localhost:8080/set?categories=insects)
will be changed to `https://httpbin.org/anything?categories=animals&categories=birds`, too.

## `add_query_params`

The `add_query_params` attribute appends query parameters in the backend request. Existing parameters of the same name will not be overridden.

In this example, we add a single value parameter. Therefore we use a string

```hcl
server "remove-query-params-example" {
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
```

A request to [http://localhost:8080/add](http://localhost:8080/add)
will be changed to `https://httpbin.org/anything?categories=animals`.

A request to [http://localhost:8080/add?categories=birds](http://localhost:8080/add?categories=birds)
will be changed to `https://httpbin.org/anything?categories=birds&categories=animals`.


## Dynamic Parameters

The values of query parameters can also be dynamic. They are evaluated at runtime. You could for example rename a query parameter like this:

```hcl
…
set_query_params = {
  new = request.query.old
}
remove_query_params = ["old"]
…
```

When you use Couper to validate [JWT tokens](../jwt-access-control/README.md), you can set query parameters from claims. Here we assume that we have a `UserToken` JWT configuration in our `definitions`:

```
…
set_query_params = {
  user = request.context.UserToken.sub
}
…
definitions {
  jwt "UserToken" {
    signature_algorithm = "HS256"
    key = env.JWT_KEY
    header = "Authorization"
  }
}
```

## Exercise

Try out and see how the response body `url` property changes accordingly:

[http://localhost:8080/anything?cat=true&dog=true&category=insects&category=snakes&sort=name](http://localhost:8080/anything?cat=true&dog=true&category=insects&category=snakes&sort=name)

