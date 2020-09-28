# Sending JWT Claims Upstream

Extending the example [JWT Access Control](/jwt-access-control/README.md) we now want to send certain JWT claims to the backend protected by Couper's access control.

In the following example we use tokens and keys from https://jwt.io/. 

First, we take the configuration file from the "JWT Access Control" example:

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
    signature_algorithm = "RS256"
    key = <<EOF
-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDGSd+sSTss2uOuVJKpumpFAaml
t1CWLMTAZNAabF71Ur0P6u833RhAIjXDSA/QeVitzvqvCZpNtbOJVegaREqLMJqv
FOUkFdLNRP3f9XjYFFvubo09tcjX6oGEREKDqLG2MfZ2Z8LVzuJc6SwZMgVFk/63
rdAOci3W9u3zOSGj4QIDAQAB
-----END PUBLIC KEY-----
        EOF
  }
}
```

Now we go to https://jwt.io/, switch the Algorithm to "RS256" and copy the content of the first textarea in the "VERIFY SIGNATURE" box in the right ("Decoded") column.

We replace the key with the copied value:

```hcl
    key = <<EOF
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAnzyis1ZjfNB0bBgKFMSv
vkTtwlvBsaJq7S5wA+kzeVOVpVWwkWdVha4s38XM/pa/yr47av7+z3VTmvDRyAHc
aT92whREFpLv9cj5lTeJSibyr/Mrm/YtjCZVWgaOYIhwrXwKLqPr/11inWsAkfIy
tvHWTxZYEcXLgAXFuUuaS3uF9gEiNQwzGTU1v0FqkqTBr4B8nW3HCN47XUu0t8Y0
e+lf4s4OxQawWD79J9/5d3Ry0vbV3Am1FtGJiJvOwRsIfVChDpYStTcHTCMqtvWb
V6L11BWkpzGXSW4Hv43qa+GSYOD2QU68Mb59oSk2OB+BtOLpJofmbGEGgvmwyCI9
MwIDAQAB
-----END PUBLIC KEY-----
    EOF
```

Now we use a token created by the service at https://jwt.io/. We copy the JWT from the box in the left ("Encoded") column and send it in the `Authorization` header:

```sh
curl -i -H "Authorization: Bearer ey..." "localhost:8080/private/headers"
HTTP/1.1 200 OK

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

Looks ok, we got access to the protected backend.

## Send request headers upstream

To send request headers upstream to the backend, we have to add some lines to the `backend` block in the configuration file:

```hcl
      backend {
        origin = "https://httpbin.org/"
        path = "/**"
        request_headers = {
          x-foo = "Bar"
        }
      }
```

httpbin's `/headers` endpoint reflects the sent request headers. So we can see that the new header was actually sent.

```sh
curl -i -H "Authorization: Bearer ey..." "localhost:8080/private/headers"
HTTP/1.1 200 OK

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
        request_headers = {
          x-jwt-sub = req.ctx.JWTToken.sub
        }
```

```sh
curl -i -H "Authorization: Bearer ey..." "localhost:8080/private/headers"
HTTP/1.1 200 OK

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

To send different claim values upstream, we can adapt the `request_headers` in the configuration file.
To add different claims to the JWT, we have to modify the JSON in the "PAYLOAD" box in the right ("Decoded") column.
