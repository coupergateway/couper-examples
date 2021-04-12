# Static Responses

There are situations where no backend requests are sent for an endpoint.
Nevertheless, a response is needed. So a `response` block can exist in an
`endpoint` block without any `proxy` or `request` blocks.

Consider the following example, in which the client is instructed to perform a
redirect via a `303` status code an a `location` header specifying the redirect
target:

```hcl
    endpoint "/redirect" {
      response {
        status = 303
        headers = {
          location = "https://www.example.com/"
        }
      }
    }
```

Call Couper:

```shell
$ curl -i http://localhost:8080/redirect
HTTP/1.1 303 See Other
Location: https://www.example.com/
...

```

Another example is a simple userinfo endpoint, similar to the one defined by
[OpenID Connect](https://openid.net/specs/openid-connect-core-1_0.html#UserInfo).
The endpoint is protected by the "JWTToken" access control. The token claims
are reflected to the client.

```hcl
    endpoint "/userinfo" {
      access_control = ["JWTToken"]
      response {
        status = 200
        json_body = request.context.JWTToken
      }
    }
...
definitions {
  jwt "JWTToken" {
    header = "Authorization"
    signature_algorithm = "RS256"
    key_file = "pub.pem"
  }
}
```

Call Couper using the valid token from the ["JWT Access Control"](../jwt-access-control/README.md) example:

```shell
$ curl -i -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJzb21lX3VzZXIiLCJpc3MiOiJzb21lX3Byb3ZpZGVyIn0.bNXv28XmnFBjirPbCzBqyfpqHKo6PpoFORHsQ-80IJLi3IhBh1y0pFR0wm-2hiz_F7PkGQLTsnFiSXxCt1DZvMstbQeklZIh7O3tQGJyCAi-HRVASHKKYqZ_-eqQQhNr8Ex00qqJWD9BsWVJr7Q526Gua7ghcttmVgTYrfSNDzU" http://localhost:8080/userinfo
HTTP/1.1 200 OK
Content-Type: application/json
...

{"iss":"some_provider","sub":"some_user"}
```
