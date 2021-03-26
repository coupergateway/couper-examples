# Sending JSON or Form Content

In addition to the `request` block's `body` attribute, there are two more
attributes that set specific types of request body:

* `json_body` to set a body of type `application/json`,
* `form_body` to set an `application/x-www-form-urlencoded` body.

And to set a JSON response body, you can also use `json_body` instead of
`body` in a `response` block.

## The `json_body` attribute

The `json_body` attribute sets the body of either `request` or `response`.
Valid value types are boolean, number, string, object or tuple.
`json_body` also sets a default value of `application/json` for the
`Content-Type` header.

```hcl
server "api" {
  endpoint "/json" {
    request {
      url = "https://httpbin.org/anything"
      json_body = {
        param1 = 1
        param2 = "t,w:o"
      }
    }
    response {
      json_body = beresp.json_body
    }
  }
}
```

Call couper with

```
curl -s http://localhost:8080/json | jq
```

The result is simular to

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


## The `form_body` attribute

The `form_body` attribute sets the body of a `request`.
Valid value type is object.
`json_body` also sets a default value of `application/x-www-form-urlencoded`
for the `Content-Type` header.

```hcl
...
  endpoint "/form" {
    request {
      url = "https://httpbin.org/anything"
      form_body = {
        param1 = 1
        param2 = "t,w:o"
      }
    }
    response {
      json_body = beresp.json_body
    }
  }
}
```

Call couper with

```
curl -s http://localhost:8080/form | jq
```

The result is simular to

```json
{
  "args": {},
  "data": "",
  "files": {},
  "form": {
    "param1": "1",
    "param2": "t,w:o"
  },
  "headers": {
    "Content-Length": "25",
    "Content-Type": "application/x-www-form-urlencoded",
    "Host": "httpbin.org",
    "X-Amzn-Trace-Id": "Root=1-605dd98d-5aa621dd2731817b148b37e7"
  },
  "json": null,
  "method": "POST",
  "origin": "94.134.95.67",
  "url": "https://httpbin.org/anything"
}
```