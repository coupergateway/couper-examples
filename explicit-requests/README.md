# Explicit Requests

Modifiying the configuration from the
[Proxy API Requests](../api-proxy/README.md) example, we can add additional
requests:

```hcl
server "my-api" {
...
  api {
    endpoint "/example/**" {
      proxy {
        path = "/**"
        backend {
          origin = "https://httpbin.org"
        }
      }
      request "additional" {
        url = "https://httpbin.org/status/404"
      }
      // use the response from the proxy, and add another header
      add_response_headers = {
        x-additional-status = beresps.additional.status
      }
    }
  }
}
```

The order in which the `proxy` and the `request` blocks are written has no
influence on the sequence of the started requests. They are run in parallel.

The request labelled "additional" calls the status endpoint at httpbin.org.
The resulting status code is set as the value of an `x-additional-status`
response code.

We can also have endpoints without a `proxy` block, only `request` blocks:

```hcl
    endpoint "/headers" {
      request "first" {
        url = "https://httpbin.org/anything"
      }
      request "second" {
        url = "https://httpbin.org/status/200"
      }
      add_response_headers = {
        x-second-status = beresps.second.status
      }
      // with more than one of request or proxy combined, we have to specify a response block:
      response {
        json_body = beresps.first.json_body.headers
      }
    }
```

Now, if we have more than one of `request` or `proxy` blocks combined, we have
to explicitly add a response block. From the "first" response we only want the
`headers` property to be returned, from the "second" we use the `status` code.
