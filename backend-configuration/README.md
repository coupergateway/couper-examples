# Backend Configuration

A `backend` block defines the connection to a local/remote backend service.

```hcl
server "backend-configuration" {
  endpoint "/**" {
    path = "/**"
    proxy {
      backend {
        origin = "https://httpbin.org"
      }
    }
  }
}
```

The connection can be modified via transport settings like `max_connections`,
`timeout`, `disable_certificate_validation` etc. You can find the complete list
of the transport settings
[here](https://github.com/avenga/couper/blob/master/DOCKER.md#transport-settings-attributes).

For example, if a backend should to be relieved, you can limit the number of
simultaneous connections (in any state - active or idle) to the backend service via
`max_connections` and limit the total request duration via the `timeout` setting:

```hcl
server "backend-configuration" {
  endpoint "/**" {
    path = "/**"
    proxy {
      backend {
        origin = "https://httpbin.org"
        max_connections = 10
        timeout = "5s"
      }
    }
  }
}
```

A named `backend` block can be defined in the `definitions` block to be able to
be reused in different `endpoint` blocks. This has the advantage that such a backend
can also be refined - depending on the purpose in each `endpoint` block.

The following example allows to use a named `backend`, to increase the request
timeout for all `/download/**` routes to `10m` and to send a HTTP request header
field `X-Hello: from Couper`. Other settings like `max_connections`, `ttfb_timeout`
etc. are inherited from the `backend` in the `definitions` block unchanged.

```hcl
server "backend-configuration" {
  endpoint "/downloads/**" {
    proxy {
      backend "main" {
        path = "/downloads/**"
        timeout = "10m"

        set_request_headers = {
          x-hello = "from Couper"
        }
      }
    }
  }

  endpoint "/data/**" {
    path = "/data/**"
    proxy {
      backend "main"
    }
  }
}

definitions {
  backend "main" {
    origin = "https://httpbin.org"
    timeout = "5s"
    max_connections = 10
    ttfb_timeout = "10s"
  }
}
```
