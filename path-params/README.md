# Path Parameter

Path parameters are named, variable parts of an endpoint path, denoted in curly braces. They can be used for mapping e.g. a certain part of the endpoint path to the upstream base path or similar use-cases.

## Configuration
The `path_params` [variable](https://github.com/avenga/couper/tree/master/docs#variables_conf) gets evaluated on client requests which matches an endpoint with a related parameter definition.
An enpoint configured with `/my/{category}/view` will make the denoted part accessible under `request.path_params.category`.

```hcl
server "path-params-example" {
  api {
    endpoint "/my/{category}/view" {
      proxy {
        backend {
          path = "/${request.path_params.category}"
          origin = "https://httpbin.org"
        }
      }
    }
  }
}
```

A request to [http://localhost:8080/my/anything/view](http://localhost:8080/my/anything/view) will be changed to `https://httpbin.org/anything` for the upstream request, as the substring *anything* will be mapped to the upstream request path by using the `path_parmas` parameter `category`.  

Try out and see how the response body `url` property changes accordingly:

[http://localhost:8080/my/get/view](http://localhost:8080/my/get/view)
