# Creating JWT

To create and sign JWT, you can use the `jwt_sign()` function and the
`jwt_signing_profile` block:

[`jwt_sign()`](https://github.com/avenga/couper/tree/master/docs#functions){: .btn .btn-green }
[`jwt_signing_profile`](https://github.com/avenga/couper/tree/master/docs#jwt-signing-profile-block){: .btn .btn-green }

E.g. let's create as simple OAuth authorization server token endpoint:

```hcl
server "simple-oauth-as" {
  endpoint "/token" {
    response {
      json_body = {
        access_token = jwt_sign("myjwt", {
          sub = req.form_body.username[0]
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
`sub`and `aud` add some additional claims to the JWT.

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
  }
}
```

In the `jwt_signing_profile` block we specify the signature algorithm (RS256),
the file containing the private key (priv_key.pem), the time-to-live of the
token and some default claims. The `unixtime()` function returns the current
UNIX timestamp in seconds as a number.

Call Couper with

```shell
$ curl -s --data-urlencode "username=john.doe" http://localhost:8080/token | jq
```

The response looks similar to
```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJUaGVfQXVkaWVuY2UiLCJleHAiOjE2MTY3NjU2OTMsImlhdCI6MTYxNjc2NTA5MywiaXNzIjoiTXlBUyIsInN1YiI6ImpvaG4uZG9lIn0.CV5BlAhyqdnVDdOF3-T1POGbdT-TK3lIdgvh8iszYxcVimPmxP3ER9NkM5ZEkgrwtTLu2AIlnXJQkWXEi4s3G7980aPDmBQhKrEldXq2yWCj8DTuA3PDLfj7giAcSf82WUI5Dhu9JORZ3iSAOwJ3f06j8Oc0qlABXWuYzf4aaVc",
  "expires_in": "600",
  "token_type": "Bearer"
}
```

When you look at the decoded version of the `access_token`, the header contains the `alg` property configured in our `jwt_signing_profile`.

```json
{
  "alg": "RS256",
  "typ": "JWT"
}
```

Looking at the decoded payload you will find the claims `iss`and `iat` form the `jwt_signing_profile`, a calculated `exp` claim and the two additional claims `aud`and `sub`from the `jwt_sign()` function.  

```json
{
  "aud": "The_Audience",
  "exp": 1616765693,
  "iat": 1616765093,
  "iss": "MyAS",
  "sub": "john.doe"
}
```
