# Multiple Requests

You can start several custom requests in one endpoint. In the following example
we use the JSON body from the "first" and the status code from the "second"
response. The "first" response's status code is set as the value of the
`x-first-status` response header.

```hcl
endpoint "/headers" {
  request "first" {
    url = "https://httpbin.org/headers"
  }
  request "second" {
    url = "https://httpbin.org/status/404"
  }
  response {
    status = backend_responses.second.status
    headers = {
      x-first-status = backend_responses.first.status
    }
    json_body = backend_responses.first.json_body
  }
}
```

The order in which the `request` blocks are written has no influence on the
sequence of the started requests. They are run in parallel.

Call Couper

```json
$ curl -i localhost:8080/headers
HTTP/1.1 404 Not Found
...
X-First-Status: 200
...

{
    "headers": {
        "Host": "httpbin.org",
        "X-Amzn-Trace-Id": "Root=1-606ca44b-021d6eb95736023517532aa8"
    }
}
```

(The `X-Amzn-…` header is added by httpbin internally).

`proxy` and custom requests can be combined, too:

```hcl
endpoint "/example/**" {
  proxy {
    backend {
      origin = "https://httpbin.org"
      path = "/**"
    }
  }
  request "additional" {
    url = "https://httpbin.org/status/404"
  }
  // use the response from the proxy, and add another header
  add_response_headers = {
    x-additional-status = backend_responses.additional.status
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

```json
$ curl -i localhost:8080/example/headers
HTTP/1.1 200 OK
...
X-Additional-Status: 404

{
  "headers": {
    "Accept": "*/*", 
    "Host": "httpbin.org", 
    "User-Agent": "curl/7.64.1", 
    "X-Amzn-Trace-Id": "Root=1-606d67cb-1d27e6a24c929b48089806e1"
  }
}
```
