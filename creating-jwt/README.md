# Creating JWT

To create and sign JWT, you can use the `jwt_sign()` function and the
`jwt_signing_profile` block:

E.g. let's create a simple OAuth authorization server token endpoint:

```hcl
server {
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
      kid = "my-jwk-id"
    }
  }
}
```

In the `jwt_signing_profile` block we specify the signature algorithm (`RS256`),
the file containing the private key (`priv_key.pem`), the time-to-live of the
token, some default claims and the header field `kid`. The `unixtime()` function returns the current
UNIX timestamp in seconds as a number.

Call Couper with

```sh
$ curl -s --data-urlencode "username=john.doe" http://localhost:8080/token
```

The response looks similar to

```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIsImtpZCI6Im15LWp3ay1pZCIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJUaGVfQXVkaWVuY2UiLCJleHAiOjE2MzM1OTE0OTIsImlhdCI6MTYzMzU5MDg5MiwiaXNzIjoiTXlBUyIsInN1YiI6ImpvaG4uZG9lIn0.qv6E3ILUe_9WR7wUhN4ZU6HWR-YoyyTNdXhf7TmiteUwXXpqUqngRqw_1h4CXJbPs250AaUf3BLeK7hJTxThCwBJl5aolngmPVnHcEiby6mq-EWOMjG-XP6NkJNI_GzmtWjpRIGcQ9zS8qMONE_GHRn_QvrtxR9rudVr6vUkLbN_6UJSETEaEH-WaKWRXUc7tsSQvB5wqnX2mVvmwchDG7lDLxL5oWM7GbpuEZQVdOEBgrLv-9D1yGkzcbaP1Y0AJWH9JaS-vpWSfwfUVvCr-Yf-iTA0EyEPFLGsTi9plz-8x5Qj_17SCSHN8M1j9MXJj_aSMH4-sVgIJf85C-EgIg",
  "expires_in": "600",
  "token_type": "Bearer"
}
```

When you look at the decoded `access_token`, the header contains the `alg` property as well as the `kid` field as configured in our `jwt_signing_profile`.

```json
{
  "alg": "RS256",
  "kid": "my-jwk-id",
  "typ": "JWT"
}
```

Looking at the decoded payload you will find the claims `iss` and `iat` from the `jwt_signing_profile`, a calculated `exp` claim and the two additional claims `aud` and `sub` from the `jwt_sign()` function.

```json
{
  "aud": "The_Audience",
  "exp": 1633591492,
  "iat": 1633590892,
  "iss": "MyAS",
  "sub": "john.doe"
}
```

**Note:** If you create "local" tokens that are consumed by your API only, you can also use a `jwt` block with a `signing_ttl`, e.g.:

```hcl
...
  endpoint "/token/local" {
    response {
      json_body = {
        access_token = jwt_sign("LocalToken", {})
        token_type = "Bearer"
        expires_in = "600"
      }
    }
  }
  api {
    access_control = ["LocalToken"]
    ...
  }
}

definitions {
  ...
  jwt "LocalToken" {
    signature_algorithm = "HS256"
    key = "Th3$e(rEt"
    signing_ttl = "600s"
  }
}
```
