# Backend Configuration

A `backend` block defines the connection to a local/remote backend service.

```hcl
server {
  endpoint "/**" {
    proxy {
      backend {
        origin = "https://httpbin.org"
        path = "/**"
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
server {
  endpoint "/**" {
    proxy {
      backend {
        origin = "https://httpbin.org"
        path = "/**"
        max_connections = 10
        timeout = "5s"
      }
    }
  }
}
```

## Reusing backend configurations

You can "reuse" `backend` configurations by defining a labeled `backend` in the `definitions` block:

```hcl
definitions {
  backend "main" {
    origin = "https://httpbin.org"
    timeout = "5s"
    max_connections = 10
    ttfb_timeout = "10s"
  }
}
```

and then refer to it from an endpoint:

```hcl
  endpoint "/anything" {
    proxy {
      backend = "main"
    }
  }
```

When you start Couper and send a request to the endpoint `/anything`, you will
get a response from `https://httpbin.org/anything`:

```sh
$ curl -is localhost:8080/anything
HTTP/1.1 200 OK
Access-Control-Allow-Credentials: true
Access-Control-Allow-Origin: *
Connection: close
Content-Type: application/json
Date: Wed, 19 May 2021 10:41:13 GMT
Server: couper.io
Vary: Accept-Encoding
Content-Length: 343

{
...

  "url": "https://httpbin.org/anything"
}
```

You also have the option to refine this reference, depending on the use case in the respective `endpoint` block:

```hcl
  endpoint "/downloads/**" {
    proxy {
      backend "main" {
        path = "/anything/**"
        timeout = "10m"

        set_request_headers = {
          x-hello = "from Couper"
        }
      }
    }
  }
```

In this example we increase the request timeout for all `/download/**` routes to
`10m` and add a HTTP request header field `X-Hello: from Couper`.

The other settings (`max_connections`, `ttfb_timeout` etc.) are inherited from
the `backend` configuration in the `definitions` block.

When you request the endpoint `/downloads`, you will see the additional header:

```sh
$ curl -is localhost:8080/downloads
HTTP/1.1 200 OK
Access-Control-Allow-Credentials: true
Access-Control-Allow-Origin: *
Connection: close
Content-Type: application/json
Date: Wed, 19 May 2021 10:46:48 GMT
Server: couper.io
Vary: Accept-Encoding
Content-Length: 374

...

  "headers": {
    ...

   "X-Hello": "from Couper"

...

  "url": "https://httpbin.org/anything"
}
```

## See also

* [Backend Block](https://docs.couper.io/configuration/block/backend) (reference)
