# Sending Form Content

The `form_body` attribute sets the body of a `request` in "HTML form" encoding.

`form_body` also sets a default value of `application/x-www-form-urlencoded`
for the `Content-Type` header.

```hcl
server "form" {
  endpoint "/form" {
    request {
      url = "https://httpbin.org/anything"
      form_body = {
        message = "foo & bar"
        numbers = [1, 2]
      }
    }
  }
}
```

Call Couper with

```sh
curl http://localhost:8080/form
```

The result is similar to

```json
{
  "args": {},
  "data": "",
  "files": {},
  "form": {
    "message": "foo & bar",
    "numbers": [
      "1",
      "2"
    ]
  },
  "headers": {
    "Content-Length": "39",
    "Content-Type": "application/x-www-form-urlencoded",
    "Host": "httpbin.org",
    "X-Amzn-Trace-Id": "Root=1-605dd98d-5aa621dd2731817b148b37e7"
  },
  "json": null,
  "method": "POST",
  "origin": "93.184.216.34",
  "url": "https://httpbin.org/anything"
}
```

Note how content type, content length and the method was set automatically.

The only valid value type for `form_body` is object. The properties of this object are encoded in HTML form style.

The actual transferred upstream request would look like this:

```sh
POST / HTTP/1.1
Host: httpbin.org
Content-Length: 39
Content-Type: application/x-www-form-urlencoded

message=foo+%26+bar&numbers=1&numbers=2
```

See how spaces and `&` were URL-encoded.

Even though form bodies are a flat structure we assigned an array to the `numbers` property. This is encoded as a list of key-value pairs with the same key.

If you need to create pseudo-array parameters (e.g. for some PHP application) use quotes to write the key:

```hcl
  form_body = {
    "numbers[]" = [1, 2]
  }
```
