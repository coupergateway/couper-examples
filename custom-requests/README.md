# Custom Requests

In contrast to proxy requests (`proxy {}` blocks), custom requests
(`request {}` blocks) are not related to the client request. They have to be
configured explicitly:

```hcl
    endpoint "/headers1" {
      request {
        url = "https://httpbin.org/headers"
        headers = {
          x-foo = "foo"
        }
      }
      // use the response to the request
    }
```

The request calling the headers endpoint at httpbin.org has no label. So the
response from the request to https://httpbin.org/headers is passed to the
client.

Call Couper

```shell
$ curl -i localhost:8080/headers
HTTP/1.1 200 OK
...

{
  "headers": {
    "Host": "httpbin.org",
    "X-Amzn-Trace-Id": "Root=1-60635663-4c2df9f51a7be9f73a48e648",
    "X-Foo": "foo"
  }
}
```

The response can be manipulated, e.g. by adding an additional header:

```hcl
    endpoint "/headers2" {
      request {
        url = "https://httpbin.org/headers"
        headers = {
          x-bar = "bar"
        }
      }
      // use the response to the request, and add another header
      add_response_headers = {
        x-additional-status = beresp.status
      }
    }
```

Call Couper

```shell
$ curl -i localhost:8080/headers
HTTP/1.1 200 OK
...
X-Additional-Status: 200

{
  "headers": {
    "Host": "httpbin.org",
    "X-Amzn-Trace-Id": "Root=1-6063567b-63a04f414e9a263d041c5848",
    "X-Bar": "bar"
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

Of course, custom requests can also use backends:

```hcl
    endpoint "/headers3" {
      request {
        path = "/headers"
        backend = "httpbin"
      }
    }
...
definitions {
  backend "httpbin" {
    origin = "https://httpbin.org"
    timeout = "10s"
  }
}
```
