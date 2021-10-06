# Creating JWT

To create and sign JWT, you can use the `jwt_sign()` function and the
`jwt_signing_profile` block:

E.g. let's create as simple OAuth authorization server token endpoint:

```hcl
server "simple-oauth-as" {
  endpoint "/token" {
    response {
      json_body = {
        access_token = jwt_sign("myjwt", {
          sub = request.form_body.username[0]
          aud = "The_Audience"
        })
        token_type = "Bearer"
        expires_in = "600"
      }
    }
  }
}
...
```

In an endpoint for the path `/token` we use the `json_body` attribute to create
a JSON response body. The `jwt_sign()` function creates the value for
the `access_token` property. In order to sign a JWT we need a `jwt_signing_profile` which is configured in the `definitions` block and referenced by the label `myjwt`.
With the properties `sub` and `aud` we add some additional claims to the JWT.

```hcl
...
definitions {
  jwt_signing_profile "myjwt" {
    signature_algorithm = "RS256"
    key_file = "priv_key.pem"
    ttl = "600s"
    claims = {
      iss = "MyAS"
      iat = unixtime()
    }
    headers = {
      foo = "bar"
    }
  }
}
```

In the `jwt_signing_profile` block we specify the signature algorithm (`RS256`),
the file containing the private key (`priv_key.pem`), the time-to-live of the
token, some default claims and a header field. The `unixtime()` function returns the current
UNIX timestamp in seconds as a number.

Call Couper with

```sh
$ curl -s --data-urlencode "username=john.doe" http://localhost:8080/token
```

The response looks similar to

```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIsImZvbyI6ImJhciIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJUaGVfQXVkaWVuY2UiLCJleHAiOjE2MzM1MTIwNzksImlhdCI6MTYzMzUxMTQ3OSwiaXNzIjoiTXlBUyIsInN1YiI6ImpvaG4uZG9lIn0.PcTlxK2nSnufZ2A85sr3VxScCb9Qw_6DcLcIvAVvN0EYk1TDWkiM0nvvm3viialwQDGIWTZOHeJtnGPC7F283rayqv-iqe2x3EyxN1BwfG966NhRkfI-mmK8kx9C_e6lrKSHMTh9AaEQOhN_crn6OaxYc13eoG9O8sN-rY7x1mA",
  "expires_in": "600",
  "token_type": "Bearer"
}
```

When you look at the decoded `access_token`, the header contains the `alg` property as well as the `foo` field as configured in our `jwt_signing_profile`.

```json
{
  "alg": "RS256",
  "typ": "JWT",
  "foo": "bar"
}
```

Looking at the decoded payload you will find the claims `iss` and `iat` from the `jwt_signing_profile`, a calculated `exp` claim and the two additional claims `aud`and `sub`from the `jwt_sign()` function.

```json
{
  "aud": "The_Audience",
  "exp": 1616765693,
  "iat": 1616765093,
  "iss": "MyAS",
  "sub": "john.doe"
}
```
