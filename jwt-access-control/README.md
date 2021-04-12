# JWT Access Control

Most certainly you don't want your precious application to be used by
anyone without permission. Some kind of access control needs to be
deployed.

Web applications often comprise multiple components: You will need a
file server, an API, maybe more than just one backend services. In
order to initially load the necessary JavaScript code, the [file
serving](/spa-serving/README.md) is usually open to everyone – no
authorization needed. This is the equivalent of a "binary" in classic
software distribution.

When it comes to API calls, security is much more of a concern. Users
connect to your service via the Internet. How do we ensure that they
are allowed to use our service?

A common pattern that has emerged for API-driven projects is using a
separate authentication provider (either a third-party service or a
self-hosted identity provider) that reads username and password from
a client, checks the credentials against its database and in turn
issues a [JWT token](https://en.wikipedia.org/wiki/JSON_Web_Token).

JWT tokens are short, base64 coded strings that can carry small
amounts of payload. Typically, that includes user ID, email address,
maybe additional information such as access privileges
(user/admin, read/write…), and an expiry date. The token furthermore
contains a signature to prevent that any of this information is
altered by a user. 

The nifty thing about JWT tokens is, that that a server can validate
the token without database lookups or on-line communication with
the issuing system. Typically the trust between the issuer and
the resource server (your API) is built by exchanging an RSA key
pair. The issuer uses the private key to sign the token, the resource
server uses the public key to verify the signature.

This feature makes JWT so suitable for securing HTTP APIs. When every
single fetch that your SPA is firing against the API needs to be
authenticated, we cannot afford using remote lookups.

Enough theory! Let's secure our API with JWT tokens!

## Poor man's Identity Provider

To keep things simple, we leave out the identity provider. We assume
that it is a service "running elsewhere". For this example, we use
predefined JWT tokens. One has expired, and one is perpetual (i.e. it
has no expiry date).

```
eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJzb21lX3VzZXIiLCJpc3MiOiJzb21lX3Byb3ZpZGVyIn0.bNXv28XmnFBjirPbCzBqyfpqHKo6PpoFORHsQ-80IJLi3IhBh1y0pFR0wm-2hiz_F7PkGQLTsnFiSXxCt1DZvMstbQeklZIh7O3tQGJyCAi-HRVASHKKYqZ_-eqQQhNr8Ex00qqJWD9BsWVJr7Q526Gua7ghcttmVgTYrfSNDzU
```

```
eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJzb21lX3VzZXIiLCJpc3MiOiJzb21lX3Byb3ZpZGVyIiwiZXhwIjoxNTkwNDkxNTI4fQ.lJnUpBzMx84_5yigeHeLw4f8sbdSdu_7fWr1--t7EAp8v8K-kSmVYUGnR0Jx4o_ZE84N2M72Kn1pKssrzgTHsFi7txcZHHz_JqgnPgKqsZwjrmWDC-XVvdrSXjAsPO6wn0qy3KEMT1y6Z8YQA4ZyzA1dDsRRIUFiNrgF6_b5pC4
```

The tokens contain an `RS256` signature the can be validated with this public key:

```
-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDGSd+sSTss2uOuVJKpumpFAaml
t1CWLMTAZNAabF71Ur0P6u833RhAIjXDSA/QeVitzvqvCZpNtbOJVegaREqLMJqv
FOUkFdLNRP3f9XjYFFvubo09tcjX6oGEREKDqLG2MfZ2Z8LVzuJc6SwZMgVFk/63
rdAOci3W9u3zOSGj4QIDAQAB
-----END PUBLIC KEY-----
```

In areal wold setup, you would call some kind of login endpoint that
would turn your username and password into a token.

## Our API

We need some API to control its access. In the [API proxy
example](/api-proxy/README.md) we have used
[httpbin](https://httpbin.org/). Let's start with that:

```hcl
server "secured-api" {
  api {
    endpoint "/private/**" {
      proxy {
        backend {
          origin = "https://httpbin.org/"
          path = "/**"
        }
      }
    }
  }
}
```

[Start your container, ](/README.md#getting-started) and check that
the API works as expected:

```shell
$ curl http://localhost:8080/private/headers
{
  "headers": {
    "Accept": "*/*", 
    "Accept-Encoding": "gzip", 
    "Host": "httpbin.org", 
    "User-Agent": "curl/7.64.1", 
    "X-Amzn-Trace-Id": "Root=1-5f4d220c-ea9a2e00df6a360019458900"
  }
}
```

Nice, we have proxied the request to `httpbin.org`. But wait, that's not as "private".

## Define the JWT Access Control

To make the API only available to authorized users, we need to define
an Access Control mechanism.

All we need is:
* The signature algorithm
* the key (here, in case of `RS256`, we use the public key in PEM format) 
* and the request field to read the token from.

```hcl
definitions {
  jwt "JWTToken" {
    signature_algorithm = "RS256"
    key_file = "pub.pem"
    header = "Authorization"
  }
}
```


The `Authorization` header has a special meaning in HTTP. To carry
any kind of API token, the `Bearer` prefix is necessary:

```
Authorization: Bearer <token>
```


## Use Access Control in API

The plain definition of the `jwt` block doesn't do anything at the
moment. We need to use that access control in our `server` by
referencing its name in the `access_control` attribute:

```hcl
server "secured-api" {
  api {
    access_control = ["JWTToken"]
    # …
  }
}
```

By defining `access_control` in the `api` block, it applies to all
API endpoints. We could also move it to `server` or even a single `endpoint`
for finer grained access control.

## Try it out

Now we're all set to try out our access controlled API.

First, we repeat the unauthorized request from above: 

```sh
$ curl -i http://localhost:8080/private/headers

HTTP/1.1 401 Unauthorized
…

{
  "error": {
    "code":    5000,
    "id":      "bt6vrbh8d3b967b0m280",
    "message": "Authorization required",
    "path":    "/private/headers",
    "status":  401
  }
}
```

Excellent! Now that API is not open to the public anymore. But can
_we_ still use it? Use the two prepared tokens from above in your
calls:

```shell
$ curl -i http://localhost:8080/private/headers -H "authorization:Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJzb21lX3VzZXIiLCJpc3MiOiJzb21lX3Byb3ZpZGVyIiwiZXhwIjoxNTkwNDkxNTI4fQ.lJnUpBzMx84_5yigeHeLw4f8sbdSdu_7fWr1--t7EAp8v8K-kSmVYUGnR0Jx4o_ZE84N2M72Kn1pKssrzgTHsFi7txcZHHz_JqgnPgKqsZwjrmWDC-XVvdrSXjAsPO6wn0qy3KEMT1y6Z8YQA4ZyzA1dDsRRIUFiNrgF6_b5pC4"

HTTP/1.1 403 Forbidden
…

{
  "error": {
    "code":    5001,
    "id":      "bt6vrr18d3b967b0m29g",
    "message": "Authorization failed",
    "path":    "/private/headers",
    "status":  403
  }
}
```

Note how the HTTP status code (and Couper's error code) have changed
from `401` to `403`. We send an authentication token, but it is not
valid. Well, now we know that this one is the invalid one, because it
has expired.

```shell
$ curl -i http://localhost:8080/private/headers -H "authorization:Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJzb21lX3VzZXIiLCJpc3MiOiJzb21lX3Byb3ZpZGVyIn0.bNXv28XmnFBjirPbCzBqyfpqHKo6PpoFORHsQ-80IJLi3IhBh1y0pFR0wm-2hiz_F7PkGQLTsnFiSXxCt1DZvMstbQeklZIh7O3tQGJyCAi-HRVASHKKYqZ_-eqQQhNr8Ex00qqJWD9BsWVJr7Q526Gua7ghcttmVgTYrfSNDzU"

HTTP/1.1 200 OK
…
{
  "headers": {
    "Accept": "*/*", 
    "Accept-Encoding": "gzip", 
    "Host": "httpbin.org", 
    "User-Agent": "curl/7.64.1", 
    "X-Amzn-Trace-Id": "Root=1-5f4dfea7-a03e127ad8cacd18ac15c370"
  }
}
```

With the valid (perpetual) token, Couper has authenticated and
accepted the request and forwarded it to `httpbin.org`! 200 OK :)

## More transport configuration

In our example, we have read the token from the standard HTTP header `Authorization`. But we could also choose use a custom header, such as `API-Token`.


```hcl
header = "API-Token"
```

In that case no `Bearer` prefix is necessary.

We could also read the token from a cookie:

```hcl
cookie = "token"
```

This would tell Couper to read the token from a cookie named `token`. Change that in the [`couper.hcl`](couper.hcl) and play with different `curl` requests.

Cookies are a considerable alternative to HTTP headers for the token
transport. If your identity provider is proxied through Couper, it
could set a `secure`, `httpOnly` cookie. This delegates the secure
storage in the client to the browser. Furthermore, the browser will
send it automatically to our API.

## More key configuration

In our code example, we have read the key from a file with the `key_file` attribute. That is a good way, if you actually have the key in a file or if you want to mount a Kubernetes secret to a file.

Another convenient way to configure the key is with the `key`
attribute that reads it from an environment variable:

```hcl
key = env.JWT_PUB_KEY
```

For testing purposes, you could simply write the `key` into your configuration file. However, string literals in HCL may not run over multiple lines – and escaping with `\n` may feel cumbersome to you. For such cases, HCL supports _heredocs_.

The `key` and `key_file` attributes are mutually exclusive. But we
need to define one of them. We favor `key_file`.

## More JWT claims checks

To ensure that a request passes this access control, if a specific claim is present in the JWT (e.g. `iss` meaning "issuer"), we add to the `jwt` block:

```hcl
required_claims = ["iss"]
```

A JWT without an `iss` claim, will now be rejected.

If we additionally want to specify a value for a required claim (e.g. `"some_user"` for the `sub` claim), we add:

```hcl
claims = {
  sub = "some_user"
}
```

JWT Tokens shouldn't last forever as the one we used above. If you are not sure whether the issuer of your tokens always includes an `exp`iry time, you can force it like this:

```hcl
required_claims = ["exp"]
```

This renders our test token unusable.
