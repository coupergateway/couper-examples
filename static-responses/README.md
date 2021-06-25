# Static Responses

There are situations where no backend requests are sent for an endpoint.
Nevertheless, a response is needed. So a `response` block can exist in an
`endpoint` block without any `proxy` or `request` blocks.

Consider the following example, in which the client is instructed to perform a
redirect via a `301` status code and a `location` header specifying the
redirect target:

```hcl
server "responses" {
  endpoint "/" {
    response {
      status = 301
      headers = {
        location = "/app/"
      }
    }
  }
}
```

This could be an example for the good practice of having the SPA paths not
under `/**`.

Call Couper:

```sh
$ curl -i localhost:8080/
HTTP/1.1 301 Moved Permanently
Location: /app/
...

```

---

Another example is a simple userinfo endpoint, similar to the one defined by
[OpenID Connect](https://openid.net/specs/openid-connect-core-1_0.html#UserInfo).
The endpoint is protected by the "JWTToken" access control. The token claims
are reflected to the client.

```hcl
server "responses" {
  endpoint "/userinfo" {
    access_control = ["JWTToken"]
    response {
      status = 200
      json_body = request.context.JWTToken
    }
  }
}
definitions {
  jwt "JWTToken" {
    header = "Authorization"
    signature_algorithm = "RS256"
    key_file = "pub.pem"
  }
}
```

Call Couper using the valid token from the ["JWT Access Control"](../jwt-access-control/README.md) example:

```sh
$ curl -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJzb21lX3VzZXIiLCJpc3MiOiJzb21lX3Byb3ZpZGVyIn0.bNXv28XmnFBjirPbCzBqyfpqHKo6PpoFORHsQ-80IJLi3IhBh1y0pFR0wm-2hiz_F7PkGQLTsnFiSXxCt1DZvMstbQeklZIh7O3tQGJyCAi-HRVASHKKYqZ_-eqQQhNr8Ex00qqJWD9BsWVJr7Q526Gua7ghcttmVgTYrfSNDzU" localhost:8080/userinfo

{
  "iss": "some_provider",
  "sub": "some_user"
}
```

---

As a third example we create a simple configuration endpoint that
emits some
_environment variables_. It could be used to initialize the app in the browser.

```hcl
server "responses" {
  endpoint "/app/conf" {
    response {
      json_body = {
        version = env.APP_VERSION
        env = env.APP_ENV
        debug = env.APP_DEBUG == "true"
      }
    }
  }
}
```

Start Couper with

```sh
$ docker run --rm -e APP_VERSION=1.0 -e APP_ENV=local -e APP_DEBUG=true -p 8080:8080 -v "$(pwd)":/conf avenga/couper
```

and call it with

```sh
$ curl localhost:8080/app/conf
{
  "debug": true,
  "env": "local",
  "version": "1.0"
}
```

You can play with different values for the environment variables in the `docker` command line to see how they are reflected in the response.
