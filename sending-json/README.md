# Sending JSON Content

The `json_body` attribute provides a convenient way to set a JSON
serialization as the body of either `request` or `response`.

`json_body` also sets a default value of `application/json` for the
`Content-Type` header.

```hcl
server "json" {
  endpoint "/request" {
    request {
      url = "https://httpbin.org/anything"
      json_body = {
        message = "a simple request"
        numbers = [1, "two"]
      }
    }
  }
}
```

Call Couper with

```shell
curl http://localhost:8080/request
```

The result is similar to

```json
{
  "args": {}, 
  "data": "{\"message\":\"a simple request\",\"numbers\":[1,\"two\"]}", 
  "files": {}, 
  "form": {}, 
  "headers": {
    "Content-Length": "50", 
    "Content-Type": "application/json", 
    "Host": "httpbin.org", 
    "X-Amzn-Trace-Id": "Root=1-606dd088-6d6c1a813f657cc6262d1b4b"
  }, 
  "json": {
    "message": "a simple request", 
    "numbers": [
      1, 
      "two"
    ]
  }, 
  "method": "POST", 
  "origin": "93.184.216.34",
  "url": "https://httpbin.org/anything"
}
```

Note how content type, content length and the method was set automatically.

---

Here is an example of an `endpoint` using `json_body` to set the response body:

```hcl
endpoint "/response" {
  response {
    json_body = {
      message = "a simple response"
      ID = request.id
    }
  }
}
```

Call Couper with

```shell
curl http://localhost:8080/response
```

The result is similar to

```json
{
  "ID": "c1f1aj5916bgcijfjdc0",
  "message": "a simple response"
}
```

---

If you need to send a more specific mime type than plain JSON, e.g. a [JSON API Message](https://jsonapi.org/), you can still use `json_body` and just override the header:

```hcl
endpoint "/jsonapi" {
  response {
    headers = {
      content-type = "application/vnd.api+json"
    }
    json_body = {
      data = {
        type = "link"
        id = "1"
        attributes = {}
      }
    }
  }
}
```

---

If you don't like shortcuts, you can create a JSON body manually:

```hcl
endpoint "/manual" {
  response {
    headers = {
      content-type = "application/json"
    }
    body = json_encode({
      mode = "manual"
    })
  }
}
```

However, in Couper configurations we favor `json_body` over the
manual way, because it is more concise and easier to read.
