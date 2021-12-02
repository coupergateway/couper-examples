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

## Poor Man's Identity Provider

To keep things simple, we leave out the identity provider. We assume
that it is a service "running elsewhere". For this example, we use
predefined JWT tokens. One has expired, and one is perpetual (i.e. it
has no expiry date).

```sh
eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImtpZCI6ImFzZGYifQ.eyJzdWIiOiJzb21lX3VzZXIiLCJpc3MiOiJzb21lX3Byb3ZpZGVyIn0.uSp2uAxubCuAGqMLS2S67aCK5DTvVVLi0LcxV5bSrTiiXE1wUb1h9IYZ4oXIKFWnCsXuIqTUl-UBn9kcJ7NJvagCaKAqk2_uRMKvFOA9lWT228FAYL58twaue-Ut_3Z5U1MfMYJxq6ADKzjgUW-bZQOceBP7yZ-Bedewmq2ZtNzLhoO-RLiCkmrLlIKcx0LCTOZOYFT7g38XLOWHcG1QQ8U9qBZMAm9j4wXgk4UoCJj1h4tS9He2YyVfB_w7y1kyXmpd_Tn3onU2z6I6qKpkRfh8sBUJ9AP50Iub85-O4mKw23gNTtw6uHhc33uBydenV9M3EMayCWkKTwEGmkpgUw
```

```sh
eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImtpZCI6ImFzZGYifQ.eyJzdWIiOiJzb21lX3VzZXIiLCJpc3MiOiJzb21lX3Byb3ZpZGVyIiwiZXhwIjoxNTkwNDkxNTI4fQ.iPO6NiiSH9ERuqDEM9xYGs0Vo3h8aHc-u9CCpmhVMp2PYafwfQXMM5MXlq1Crtw_g-jBUrB-r80a7uqOaBPvHzP0vmTzTNLXRp5U3l7I1ixUJaxSsA4g6k5CrVQ9rYPkKbABviJBw1gmfV9t5Yz8l7QYUFz0I0LTju8bmGqPLmQMOYCZyLW4KcflLGqjwbWZFNpVIXbc1WRySo-bwuBTiSfbzZ2RFvXrv6sHfNCcE4ounsjZSx9P6mpl9pyj5J5iu0Dvh_J6zeH7DMQ_WXbt0MblIuRtNRx_g025NuhuGRlOzLOeO2CYq266xcH9txWz2YIXm9ke1HDiLGL6_ORSUA
```

The tokens contain an `RS256` signature the can be validated with this public key:

```sh
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAzYkjqxZXTs657BrVmOjR
d2GqDi64XjLUbsOGAludYIxuOdAsrRQ+RLUIOSWvS5pBkfmq5ww/BWP/ovHyNZ1O
VLKoJn/WJYBQ3P5NTM691eUtvU9DvyTPIN1zH6NL3feLD1gCkET8KCZI/xWNaZlp
KJvojVrMp2NW84BfTa2p/0AwsD0+0LzPyflyH2LaOBQFNwg+EAKJzWdTOhyr1fwA
qpLzlIVUf0P4MxZellyaWlaSbYGak0wH22kwTvEsa5DMOgvUnhPntBS+CSwhTNQw
RTR2ydbZCoa0cL/OsPlAQxucnrOHrNlfhJ7t6oCR2/zK1LdQxP7GEUnWvSd1y/yU
iwIDAQAB
-----END PUBLIC KEY-----
```

In a real world setup, you would call some kind of login endpoint that
would turn your username and password into a token.

## Our API

We need some API to control its access. In the [API proxy
example](/api-proxy/README.md) we have used
[httpbin](https://httpbin.org/). Let's start with that:

```hcl
server {
  api {
    endpoint "/private/**" {
      proxy {
        path = "/**"
        backend {
          origin = "https://httpbin.org/"
        }
      }
    }
  }
}
```

[Start your container](/README.md#getting-started) and check that
the API works as expected:

```sh
$ curl http://localhost:8080/private/headers
{
  "headers": {
    "Accept": "*/*", 
    "Couper-Request-Id": "c5hvbqr81n1t2m4d56s0",
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

* The signature algorithm,
* the key (here, in case of `RS256`, we use the public key in PEM format),
* and the request field to read the token from.

```hcl
definitions {
  jwt "JWTToken" {
    header = "Authorization"
    signature_algorithm = "RS256"
    key_file = "pub.pem"
  }
}
```

The `Authorization` header has a special meaning in HTTP. To carry
any kind of API token, the `Bearer` prefix is necessary:

```sh
Authorization: Bearer <token>
```

## Secure the API

The plain definition of the `jwt` block doesn't do anything at the
moment. We need to use that access control in our `server` by
referencing its name in the `access_control` attribute:

```hcl
server {
  api {
    access_control = ["JWTToken"]
    # …
  }
}
```

By setting `access_control` in the `api` block, it applies to all included
endpoints. We could also move it to `server` or even to a single `endpoint`
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
    "id":      "bt6vrbh8d3b967b0m280",
    "message": "access control error",
    "path":    "/private/headers",
    "status":  401
  }
}
```

Excellent! Now, our API is not open to the public anymore. But can
_we_ still use it? Use the two prepared tokens from above in your
calls:

```sh
$ curl -i http://localhost:8080/private/headers -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImtpZCI6ImFzZGYifQ.eyJzdWIiOiJzb21lX3VzZXIiLCJpc3MiOiJzb21lX3Byb3ZpZGVyIiwiZXhwIjoxNTkwNDkxNTI4fQ.iPO6NiiSH9ERuqDEM9xYGs0Vo3h8aHc-u9CCpmhVMp2PYafwfQXMM5MXlq1Crtw_g-jBUrB-r80a7uqOaBPvHzP0vmTzTNLXRp5U3l7I1ixUJaxSsA4g6k5CrVQ9rYPkKbABviJBw1gmfV9t5Yz8l7QYUFz0I0LTju8bmGqPLmQMOYCZyLW4KcflLGqjwbWZFNpVIXbc1WRySo-bwuBTiSfbzZ2RFvXrv6sHfNCcE4ounsjZSx9P6mpl9pyj5J5iu0Dvh_J6zeH7DMQ_WXbt0MblIuRtNRx_g025NuhuGRlOzLOeO2CYq266xcH9txWz2YIXm9ke1HDiLGL6_ORSUA"
HTTP/1.1 403 Forbidden
…

{
  "error": {
    "id":      "bt6vrr18d3b967b0m29g",
    "message": "access control error",
    "path":    "/private/headers",
    "status":  403
  }
}
```

Note how the HTTP status code and Couper's error code have changed
from `401` to `403`: We now send an authentication token, but an invalid one.
In fact, the token has expired, see Couper's log for details (`access control error: JWTToken: token is expired`).

```sh
$ curl -i http://localhost:8080/private/headers -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImtpZCI6ImFzZGYifQ.eyJzdWIiOiJzb21lX3VzZXIiLCJpc3MiOiJzb21lX3Byb3ZpZGVyIn0.uSp2uAxubCuAGqMLS2S67aCK5DTvVVLi0LcxV5bSrTiiXE1wUb1h9IYZ4oXIKFWnCsXuIqTUl-UBn9kcJ7NJvagCaKAqk2_uRMKvFOA9lWT228FAYL58twaue-Ut_3Z5U1MfMYJxq6ADKzjgUW-bZQOceBP7yZ-Bedewmq2ZtNzLhoO-RLiCkmrLlIKcx0LCTOZOYFT7g38XLOWHcG1QQ8U9qBZMAm9j4wXgk4UoCJj1h4tS9He2YyVfB_w7y1kyXmpd_Tn3onU2z6I6qKpkRfh8sBUJ9AP50Iub85-O4mKw23gNTtw6uHhc33uBydenV9M3EMayCWkKTwEGmkpgUw"
HTTP/1.1 200 OK
…
{
  "headers": {
    "Accept": "*/*", 
    "Couper-Request-Id": "c5hvma381n1t2m4d56ug",
    "Host": "httpbin.org", 
    "User-Agent": "curl/7.64.1", 
    "X-Amzn-Trace-Id": "Root=1-5f4dfea7-a03e127ad8cacd18ac15c370"
  }
}
```

With the valid (perpetual) token, Couper has successfully authenticated and
accepted the request and forwarded it to `httpbin.org`! 200 OK :)

Did you notice that Couper automatically dropped the `Authorization` header and did not forward it upstream?

## More Transport Configuration

In our example, we have read the token from the standard HTTP header `Authorization`. But we could also choose to use a custom header, such as `API-Token`.

```hcl
  jwt "JWTToken" {
    header = "API-Token"
    …
  }
```

In that case no `Bearer` prefix is necessary.

```sh
$ curl -i http://localhost:8080/private/headers -H "API-Token: eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImtpZCI6ImFzZGYifQ.eyJzdWIiOiJzb21lX3VzZXIiLCJpc3MiOiJzb21lX3Byb3ZpZGVyIn0.uSp2uAxubCuAGqMLS2S67aCK5DTvVVLi0LcxV5bSrTiiXE1wUb1h9IYZ4oXIKFWnCsXuIqTUl-UBn9kcJ7NJvagCaKAqk2_uRMKvFOA9lWT228FAYL58twaue-Ut_3Z5U1MfMYJxq6ADKzjgUW-bZQOceBP7yZ-Bedewmq2ZtNzLhoO-RLiCkmrLlIKcx0LCTOZOYFT7g38XLOWHcG1QQ8U9qBZMAm9j4wXgk4UoCJj1h4tS9He2YyVfB_w7y1kyXmpd_Tn3onU2z6I6qKpkRfh8sBUJ9AP50Iub85-O4mKw23gNTtw6uHhc33uBydenV9M3EMayCWkKTwEGmkpgUw"
HTTP/1.1 200 OK
…
{
  "headers": {
    "Accept": "*/*",
    "Api-Token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImtpZCI6ImFzZGYifQ.eyJ…",
    "Couper-Request-Id": "c5i02cb81n1t2m4d570g",
    "Host": "httpbin.org",
    "User-Agent": "curl/7.64.1",
    "X-Amzn-Trace-Id": "Root=1-5f4dfea7-a03e127ad8cacd18ac15c370"
  }
}
```

Now the non-standard header `API-Token` reaches the upstream server
revealing the API token which might not be what we want. To prevent that, we could
suppress that header in our private endpoint via `remove_request_headers`:

```hcl
    endpoint "/private/**" {
      remove_request_headers = ["API-Token"] # Do not send upstream!
      proxy {
        …
      }
    }
}
```

We could also tell Couper to read the token from a cookie named `token`:

```hcl
  jwt "JWTToken" {
    cookie = "token"
    …
  }
```

```sh
$ curl -i http://localhost:8080/private/headers --cookie "token=eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImtpZCI6ImFzZGYifQ.eyJzdWIiOiJzb21lX3VzZXIiLCJpc3MiOiJzb21lX3Byb3ZpZGVyIn0.uSp2uAxubCuAGqMLS2S67aCK5DTvVVLi0LcxV5bSrTiiXE1wUb1h9IYZ4oXIKFWnCsXuIqTUl-UBn9kcJ7NJvagCaKAqk2_uRMKvFOA9lWT228FAYL58twaue-Ut_3Z5U1MfMYJxq6ADKzjgUW-bZQOceBP7yZ-Bedewmq2ZtNzLhoO-RLiCkmrLlIKcx0LCTOZOYFT7g38XLOWHcG1QQ8U9qBZMAm9j4wXgk4UoCJj1h4tS9He2YyVfB_w7y1kyXmpd_Tn3onU2z6I6qKpkRfh8sBUJ9AP50Iub85-O4mKw23gNTtw6uHhc33uBydenV9M3EMayCWkKTwEGmkpgUw"
HTTP/1.1 200 OK
…
```

Cookies are a considerable alternative to HTTP headers for the token
transport. If your identity provider is proxied through Couper, it
could set a `secure`, `httpOnly` cookie. This delegates the secure
storage in the client to the browser. Furthermore, the browser will
send it automatically to our API.

Another means of getting the token is to provide an expression via the `token_value` attribute.
The following configuration tells Couper to get the token from a form field named `token`:

```hcl
  jwt "JWTToken" {
    token_value = request.form_body.token[0]
    …
  }
```

```sh
$ curl -i http://localhost:8080/private/post --data 'token=eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImtpZCI6ImFzZGYifQ.eyJzdWIiOiJzb21lX3VzZXIiLCJpc3MiOiJzb21lX3Byb3ZpZGVyIn0.uSp2uAxubCuAGqMLS2S67aCK5DTvVVLi0LcxV5bSrTiiXE1wUb1h9IYZ4oXIKFWnCsXuIqTUl-UBn9kcJ7NJvagCaKAqk2_uRMKvFOA9lWT228FAYL58twaue-Ut_3Z5U1MfMYJxq6ADKzjgUW-bZQOceBP7yZ-Bedewmq2ZtNzLhoO-RLiCkmrLlIKcx0LCTOZOYFT7g38XLOWHcG1QQ8U9qBZMAm9j4wXgk4UoCJj1h4tS9He2YyVfB_w7y1kyXmpd_Tn3onU2z6I6qKpkRfh8sBUJ9AP50Iub85-O4mKw23gNTtw6uHhc33uBydenV9M3EMayCWkKTwEGmkpgUw'
HTTP/1.1 200 OK
…
```

Finally, we transfer our token in the JSON body of the request:

```hcl
  jwt "JWTToken" {
    token_value = request.json_body.token
    …
  }
```

Note that we need to set the appropriate `Content-Type` header to have the `request.json_body` variable filled:

```sh
$ curl -i http://localhost:8080/private/post -H 'Content-Type: application/json' --data-raw '{"token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImtpZCI6ImFzZGYifQ.eyJzdWIiOiJzb21lX3VzZXIiLCJpc3MiOiJzb21lX3Byb3ZpZGVyIn0.uSp2uAxubCuAGqMLS2S67aCK5DTvVVLi0LcxV5bSrTiiXE1wUb1h9IYZ4oXIKFWnCsXuIqTUl-UBn9kcJ7NJvagCaKAqk2_uRMKvFOA9lWT228FAYL58twaue-Ut_3Z5U1MfMYJxq6ADKzjgUW-bZQOceBP7yZ-Bedewmq2ZtNzLhoO-RLiCkmrLlIKcx0LCTOZOYFT7g38XLOWHcG1QQ8U9qBZMAm9j4wXgk4UoCJj1h4tS9He2YyVfB_w7y1kyXmpd_Tn3onU2z6I6qKpkRfh8sBUJ9AP50Iub85-O4mKw23gNTtw6uHhc33uBydenV9M3EMayCWkKTwEGmkpgUw"}'
HTTP/1.1 200 OK
…
```

## More Key Configuration

In our code example, we specify a `key_file` attribute referencing a file containing the key. That is a good way, if you actually have the key in a file or if you want to mount a Kubernetes secret to a file.

Another convenient way to configure the key is
to read it from an environment variable by using the `key` attribute:

```hcl
  jwt "JWTToken" {
    …
    key = env.JWT_PUB_KEY
  }
```

For testing purposes, you could simply put the `key` from `pub.pem` directly into your configuration file:

```hcl
  jwt "JWTToken" {
    …
    # key_file = "pub.pem"

    key = "-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAzYkjqxZXTs657BrVmOjRd2GqDi64XjLUbsOGAludYIxuOdAsrRQ+RLUIOSWvS5pBkfmq5ww/BWP/ovHyNZ1OVLKoJn/WJYBQ3P5NTM691eUtvU9DvyTPIN1zH6NL3feLD1gCkET8KCZI/xWNaZlpKJvojVrMp2NW84BfTa2p/0AwsD0+0LzPyflyH2LaOBQFNwg+EAKJzWdTOhyr1fwAqpLzlIVUf0P4MxZellyaWlaSbYGak0wH22kwTvEsa5DMOgvUnhPntBS+CSwhTNQwRTR2ydbZCoa0cL/OsPlAQxucnrOHrNlfhJ7t6oCR2/zK1LdQxP7GEUnWvSd1y/yUiwIDAQAB\n-----END PUBLIC KEY-----"
  }
```

However, string literals in HCL may not run over multiple lines – and escaping with `\n` may feel cumbersome to you. For such cases, HCL supports _heredocs_:

```hcl
  jwt "JWTToken" {
    …
    key =<<-END
      -----BEGIN PUBLIC KEY-----
      MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAzYkjqxZXTs657BrVmOjR
      d2GqDi64XjLUbsOGAludYIxuOdAsrRQ+RLUIOSWvS5pBkfmq5ww/BWP/ovHyNZ1O
      VLKoJn/WJYBQ3P5NTM691eUtvU9DvyTPIN1zH6NL3feLD1gCkET8KCZI/xWNaZlp
      KJvojVrMp2NW84BfTa2p/0AwsD0+0LzPyflyH2LaOBQFNwg+EAKJzWdTOhyr1fwA
      qpLzlIVUf0P4MxZellyaWlaSbYGak0wH22kwTvEsa5DMOgvUnhPntBS+CSwhTNQw
      RTR2ydbZCoa0cL/OsPlAQxucnrOHrNlfhJ7t6oCR2/zK1LdQxP7GEUnWvSd1y/yU
      iwIDAQAB
      -----END PUBLIC KEY-----
    END
  }
```

The `key` and `key_file` attributes are mutually exclusive. But we
need to define one of them. We favor `key_file`.

If the tokens are created by a token provider, e.g. an OAuth2 authorization server, you can reference its JWK set resource via `jwks_url` and get the key from there:

```hcl
  jwt "JWTToken" {
    header = "Authorization"
    # signature_algorithm = "RS256"
    # key_file = "pub.pem"
    jwks_url = "https://demo-idp.couper.io/jwks.json"
  }
```

Couper takes the `kid` and `alg` fields from the JWT token header to select a
key from the `jwks.json`.

Note that `jwks_url` and the combination of `signature_algorithm` and `key_file` or `key` are mutually exclusive.

## Checking JWT Claims

To ensure that a request passes this access control, only if a specific claim is present in the JWT (e.g. `iss` meaning "issuer"), we add:

```hcl
  jwt "JWTToken" {
    …
    required_claims = ["iss"]
  }
```

Any JWT without an `iss` claim will now be rejected.

If we additionally want to specify a value for a required claim (e.g. `"some_user"` for the `sub` claim), we further add:

```hcl
  jwt "JWTToken" {
    …
    claims = {
      sub = "some_user"
    }
  }
```

Tokens with different `sub` claims will now be rejected.

JWT tokens shouldn't last forever – in contrast to the one we used above.
By explicitly requiring the `exp` claim, Couper won't accept any tokens that do not have an expiry time:

```hcl
  jwt "JWTToken" {
    …
    required_claims = ["iss", "exp"]
    …
  }
```

This addition renders our test token unusable.
