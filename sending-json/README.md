# Sending JSON Content

The `json_body` attribute sets the body of either `request` or `response`.
Valid value types are null, boolean, number, string, object or tuple.
`json_body` also sets a default value of `application/json` for the
`Content-Type` header.

```hcl
server "api" {
  endpoint "/request" {
    request {
      url = "https://httpbin.org/anything"
      json_body = {
        param1 = 1
        param2 = "t,w:o"
      }
    }
  }
}
```

BTW, you can also specify the object in JSON style

```hcl
      json_body = {
        "param1": 1,
        "param2": "t,w:o"
      }
```

Call couper with

```
curl -s http://localhost:8080/request | jq
```

The result is similar to

```json
{
  "args": {},
  "data": "{\"param1\":1,\"param2\":\"t,w:o\"}",
  "files": {},
  "form": {},
  "headers": {
    "Content-Length": "29",
    "Content-Type": "application/json",
    "Host": "httpbin.org",
    "X-Amzn-Trace-Id": "Root=1-605dd985-466ef358702e1a6714eda53b"
  },
  "json": {
    "param1": 1,
    "param2": "t,w:o"
  },
  "method": "POST",
  "origin": "94.134.95.67",
  "url": "https://httpbin.org/anything"
}
```

Here is an example for using `json_body` to set the response body:

```hcl
...
  endpoint "/response" {
    response {
      json_body = {
        message = "a simple response"
        ID = req.id
      }
    }
  }
}
```

Call couper with

```
curl -s http://localhost:8080/response | jq
```

The result is similar to

```json
{
  "ID": "c1f1aj5916bgcijfjdc0",
  "message": "a simple response"
}
```