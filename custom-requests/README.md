# Custom Requests

Custom requests m

```hcl
    endpoint "/headers" {
      request {
        url = "https://httpbin.org/headers"
        headers = {
          x-foo = "bar"
        }
      }
      // use the response to the request, and add another header
      add_response_headers = {
        x-additional-status = beresp.status
      }
    }
```

The request calling the headers endpoint at httpbin.org has no label. So the
response from the request to https://httpbin.org/headers is passed to the
client - with an additional header.

Call Couper

```shell
$ curl -i localhost:8080/headers
HTTP/1.1 200 OK
...
X-Additional-Status: 200

{
  "headers": {
    "Host": "httpbin.org",
    "X-Amzn-Trace-Id": "Root=1-6061c3ef-2f5e145d5406ced93426b797",
    "X-Foo": "bar"
  }
}
```

Custom requests can also be labelled. In this case we have to specify a response.

```hcl
    endpoint "/status/200" {
      request "st" {
        url = "https://httpbin.org/status/200"
      }
      // no default request, so an explicit response is needed
      response {
        headers = {
          x-status = beresps.st.status
        }
      }
    }
```

Call Couper

```shell
$ curl -i localhost:8080/status/200
HTTP/1.1 200 OK
...
X-Status: 200

```
