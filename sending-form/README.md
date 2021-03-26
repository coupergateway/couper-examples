# Sending Form Content

The `form_body` attribute sets the body of a `request`.
The only valid value type is object.
`form_body` also sets a default value of `application/x-www-form-urlencoded`
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