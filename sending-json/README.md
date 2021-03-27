# Sending JSON Content

The `json_body` attribute sets the body of either `request` or `response`.
Valid value types are null, boolean, number, string, object or tuple.
`json_body` also sets a default value of `application/json` for the
`Content-Type` header.

```hcl
server "json" {
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

BTW, you can also specify the object in JSON style within HCL:

```hcl
      json_body = {
        "param1": 1,
        "param2": "t,w:o"
      }
```

Call Couper with

```shell
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
  "origin": "93.184.216.34",
  "url": "https://httpbin.org/anything"
}
```

Here is an example of an `endpoint` using `json_body` to set the response body:

```hcl
endpoint "/response" {
  response {
    json_body = {
      message = "a simple response"
      ID = req.id
    }
  }
}
```

Call Couper with

```shell
curl -s http://localhost:8080/response | jq
```

The result is similar to

```json
{
  "ID": "c1f1aj5916bgcijfjdc0",
  "message": "a simple response"
}
```

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

`json_body` is convenient short cut for explicitly defining the `Content-Type`
header and serializing a JSON string with `json_encode()`. If you would want to do it manually, it would read like this:

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
