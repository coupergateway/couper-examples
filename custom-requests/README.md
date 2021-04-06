# Custom Requests

In contrast to proxy requests (`proxy {}` blocks), custom requests
(`request {}` blocks) are not related to the client request. All request properties can be defined explicitly.

The simplest case is a naked `GET` request:

```hcl
endpoint "/get" {
  request {
    url = "https://httpbin.org/anything"
  }
}
```

This request has no label. So it becomes the _default request_.
Therefore its response is passed to the client. (The `proxy{}` works this way, too).

Call Couper:

```json
$ curl localhost:8080/get
{
  "args": {}, 
  "data": "", 
  "files": {}, 
  "form": {}, 
  "headers": {
    "Host": "httpbin.org", 
    "X-Amzn-Trace-Id": "Root=1-606c8856-0f6d7d6c0be82ccc32a1f55b"
  }, 
  "json": null, 
  "method": "GET", 
  "origin": "93.184.216.34", 
  "url": "https://httpbin.org/anything"
}
```

We see httpbin's result as Couper's response. It also shows that not much has been sent in this request. (The `X-Amzn-…` header is added by the httpbin infrastructure).

Try calling this endpoint with `curl -X "POST"` or other request methods. The upstream request will stay a `GET` request.

---

Let's make it a bit more interesting and define some request headers:

```hcl
endpoint "/headers" {
  request {
    url = "https://httpbin.org/headers"
    headers = {
      user-agent = "Couper"
      couper-id = request.id
    }
  }
}
```

Call Couper:

```json
$ curl localhost:8080/headers
{
  "headers": {
    "Couper-Id": "c1m9oaoi7qkmhs3k159g", 
    "Host": "httpbin.org", 
    "User-Agent": "Couper", 
    "X-Amzn-Trace-Id": "Root=1-606c9c2b-2bdf6e5a5962841673bb3676"
  }
}
```

Now we see that more headers were sent upstream. (You can use the `Couper-Id` to find the log lines related to this request).

---

Custom requests can also be labelled. In this case we have to specify a response. (Unless you call it `default`).

This example also shows how to explicitly set the request method and a body:

```hcl
endpoint "/post" {
  request "post" {
    url = "https://httpbin.org/anything?q=4711"
    method = "post"
    body = "hey there!"
  }

  // no default request, so an explicit response is needed
  response {
    json_body = backend_responses.post.json_body
  }
}
```

Call Couper:

```json
$ curl localhost:8080/post
{
    "args": {
        "q": "4711"
    },
    "data": "hey there!",
    "files": {},
    "form": {},
    "headers": {
        "Content-Length": "10",
        "Content-Type": "text/plain",
        "Host": "httpbin.org",
        "X-Amzn-Trace-Id": "Root=1-606c9d4f-1a200981735eb2b174359cba"
    },
    "json": null,
    "method": "POST",
    "origin": "93.184.216.34", 
    "url": "https://httpbin.org/anything?q=4711"
}
```

Note the headers: Couper has set the default content type `text/plain` for the body and has counted the content length for you.

---

Of course, custom requests can also use defined backends:

```hcl
server "custom-requests" {
  endpoint "/use-backend" {
    request {
      backend "httpbin" {
        path = "/delay/1"
      }
    }
  }
}

definitions {
  backend "httpbin" {
    origin = "https://httpbin.org"
    max_connections = 1
  }
}
```

Couper executes the request in the context of the backend `httpbin`. This is useful if you have multiple requests going to the same backend that should share settings.

In this example we use `max_connections` to limit the number of concurrent requests. Try to request `http://localhost:8080/use-backend` in parallel. Do you notice the effect?
