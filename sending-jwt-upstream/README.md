# Sending JWT Claims Upstream

Extending the example [JWT Access Control](/jwt-access-control/README.md) we now want to send certain JWT claims to the backend protected by Couper's access control.

In the following example, we use tokens created by https://jwt.io/,
which provides a handy service to create tokens. Its default setting,
it uses `HS256` as the signing algorithm. So we use that for our 
Couper configuration:

```hcl
server "secured-api" {
  access_control = ["JWTToken"]
  api {
    endpoint "/private/**" {
      path = "/**"
      backend {
        origin = "https://httpbin.org/"
      }
    }
  }
}

definitions {
  jwt "JWTToken" {
    header = "Authorization"
    signature_algorithm = "HS256"
    key = "y0urS3cretT08eU5edF0rC0uPerInThe3xamp1e"
  }
}
```

**Note:** For production setups we recommend RSA based signatures.

Now we go to https://jwt.io/ and fill our secret key into the field labeled "VERIFY SIGNATURE" in the right ("Decoded") column.

Then we use a token created by the service. We copy the JWT from the box in the left ("Encoded") column and send it in the `Authorization` header:

```sh
curl -i -H "Authorization: Bearer ey…" "localhost:8080/private/headers"
HTTP/1.1 200 OK
…

{
  "headers": {
    "Accept": "*/*",
    "Accept-Encoding": "gzip",
    "Host": "httpbin.org",
    "User-Agent": "curl/7.29.0",
    "X-Amzn-Trace-Id": "Root=1-5f71e2d7-2b6b91eaac6b24d33c166ccf"
  }
}
```

Looks good, we got access to the protected backend. And note that the `Authorization` header was consumed by Couper. It wasn't sent to the backend.

## Send request headers upstream

To send request headers upstream to the backend, we have to add some lines to the `backend` block in the configuration file:

```hcl
      backend {
        …
        set_request_headers = {
          x-foo = "Bar"
        }
      }
```

[httpbin's](https://httpbin.org/) `/headers` endpoint reflects the request headers it has received. So we can see that the new header was actually sent.

```sh
curl -i -H "Authorization: Bearer ey…" "localhost:8080/private/headers"
HTTP/1.1 200 OK
…

{
  "headers": {
    "Accept": "*/*",
    "Accept-Encoding": "gzip",
    "Host": "httpbin.org",
    "User-Agent": "curl/7.29.0",
    "X-Amzn-Trace-Id": "Root=1-5f71e4d6-5990e757763cacc0e125a7b4"
    "X-Foo": "Bar"
  }
}
```

## Send JWT claims

Claims from a JWT sent to Couper are stored in the variable `req.ctx.<access_control_name>.<claim_name>`.
E.g., the `sub` claim of the "JWTToken" JWT access control is stored in `req.ctx.JWTToken.sub`.
We can reference this claim as the value of a request header:

```hcl
        …
        set_request_headers = {
          x-jwt-sub = req.ctx.JWTToken.sub
        }
        …
```

```sh
curl -i -H "Authorization: Bearer ey…" "localhost:8080/private/headers"
HTTP/1.1 200 OK
…

{
  "headers": {
    "Accept": "*/*",
    "Accept-Encoding": "gzip",
    "Host": "httpbin.org",
    "User-Agent": "curl/7.29.0",
    "X-Amzn-Trace-Id": "Root=1-5f71e855-c997a7e42a272c6304b6f9f3",
    "X-Jwt-Sub": "1234567890"
  }
}
```
The value of `X-Jwt-Sub` is the same as the `sub` claim of the JWT created at https://jwt.io/.

To send different claim values upstream, we can adapt the `set_request_headers` in the configuration file. Note that **all** claims, not just the standard claims, are stored in `req.ctx.…`
To add different claims to the JWT, we have to modify the JSON in the "PAYLOAD" box in the right ("Decoded") column.

To send a JSON representation of all the JWT claims upstream, we use the `json_encode()` function:

```hcl
        …
        set_request_headers = {
          x-jwt-sub = req.ctx.JWTToken.sub
          x-jwt = json_encode(req.ctx.JWTToken)
        }
        …
```


```sh
curl -i -H "Authorization: Bearer ey…" "localhost:8080/private/headers"
HTTP/1.1 200 OK
…

{
  "headers": {
    "Accept": "*/*",
    "Accept-Encoding": "gzip",
    "Host": "httpbin.org",
    "User-Agent": "curl/7.29.0",
    "X-Amzn-Trace-Id": "Root=1-5f71e855-c997a7e42a272c6304b6f9f3",
    "X-Jwt": "{\"iat\":1516239022,\"name\":\"John Doe\",\"sub\":\"1234567890\"}",
    "X-Jwt-Sub": "1234567890"
  }
}
```
