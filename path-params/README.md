# Path Parameter

Those parameters enabling the usage of named path elements from the endpoint path. This could be helpful for e.g. mapping
the path to another upstream base path or similar use-cases.

## Configuration

The `path_params` [variable](https://github.com/avenga/couper/tree/master/docs#variables_conf) gets evaluated on client requests which matches an endpoint with a related parameter definition like: `/my/{category}/view`.
The named `category` element is available as `req.path_params.category`.

```hcl
server "path-params-example" {
  api {
    endpoint "/my/{category}/view" {
      backend {
        path = "/${req.path_params.category}"
        origin = "https://httpbin.org"
      }
    }
  }
}
```

A request to [http://localhost:8080/my/anything/view](http://localhost:8080/my/anything/view) will be changed to `https://httpbin.org/anything` for the upstream one.

Try out and see how the response body `url` property changes accordingly:

[http://localhost:8080/my/get/view](http://localhost:8080/my/get/view)
