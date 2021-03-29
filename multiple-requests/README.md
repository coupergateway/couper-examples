# Multiple Requests

You can start several custom requests in one endpoint. From the "first"
response we only want the `headers` property to be returned, from the "second"
we use the `status` code.

```hcl
    endpoint "/headers" {
      request "first" {
        url = "https://httpbin.org/anything"
        headers = {
          x-foo = "bar"
        }
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

The order in which the `request` blocks are written has no influence on the
sequence of the started requests. They are run in parallel.

Call Couper

```shell
$ curl -i localhost:8080/headers
HTTP/1.1 200 OK
...
Content-Type: application/json
...
X-Second-Status: 200

{"Host":"httpbin.org","X-Amzn-Trace-Id":"Root=1-6061c797-1f20fab738225bf70b38fca1","X-Foo":"bar"}
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
response code.

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
  "origin": "87.123.196.76",
  "url": "https://httpbin.org/anything"
}
```
