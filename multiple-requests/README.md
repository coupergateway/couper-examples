# Multiple Requests

You can start several custom requests in one endpoint. In the following example
we use the JSON body from the "first" and the `status` code from the "second"
response. The "first" response's `status` code is set as the value of the
`x-first-status` response header.

```hcl
    endpoint "/headers" {
      request "first" {
        url = "https://httpbin.org/anything"
      }
      request "second" {
        url = "https://httpbin.org/status/404"
      }
      response {
        status = beresps.second.status
        headers = {
          x-first-status = beresps.first.status
        }
        json_body = beresps.first.json_body
      }
    }
```

The order in which the `request` blocks are written has no influence on the
sequence of the started requests. They are run in parallel.

Call Couper

```shell
$ curl -i localhost:8080/headers
HTTP/1.1 404 Not Found
...
X-First-Status: 200
...

{"args":{},"data":"","files":{},"form":{},"headers":{"Host":"httpbin.org","X-Amzn-Trace-Id":"Root=1-606453e4-60dce76823525ed11db360f3"},"json":null,"method":"GET","origin":"93.184.216.34","url":"https://httpbin.org/anything"}
```

Proxy and custom requests can be combined:

```hcl
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
```

With the `proxy` block the client request is passed to the httpbin.org backend.
As the `proxy` block creates a "default" request, you don't have to create a
`response` block.

The request labelled "additional" calls the status endpoint at httpbin.org.
The resulting status code is set as the value of an `x-additional-status`
response header.

Again, the order of the `proxy` and `request` blocks is irrelevant.

Call Couper

```shell
$ curl -i localhost:8080/example/anything
HTTP/1.1 200 OK
...
X-Additional-Status: 404

{
  "args": {},
  "data": "",
  "files": {},
  "form": {},
  "headers": {
    "Accept": "*/*",
    "Host": "httpbin.org",
    "User-Agent": "curl/7.58.0",
    "X-Amzn-Trace-Id": "Root=1-6061c877-09fcbef87a6fc2296bf12051"
  },
  "json": null,
  "method": "GET",
  "origin": "93.184.216.34",
  "url": "https://httpbin.org/anything"
}
```
