# Backend Authorization using OAuth2

In this example we learn how to configure Couper to automatically authorize requests to a third-party API by requesting an access token using OAuth2, if necessary.

![OAuth2 Example Image](oauth_example.png)

OAuth2 defines (at least) three parties:

* the resource server providing resources (e.g. an API) protected by access tokens,
* the client requesting the resources,
* and the authorization server providing the access tokens.

_**Please jump to the bottom of the page to learn how to configure Couper in a real world setting**_

## The OAuth2 client credentials grant

In this example, there is a resource server located at http://resource-server:8080 with a protected endpoint `/resource` that we want to access.

First, in the `client` directory, we define a `server` block in `couper.hcl` for the client:

```hcl
server "client" {
  api {
    endpoint "/resource" {
      proxy {
        backend {
          origin = "http://resource-server:8080"
        }
      }
    }
  }
}
```

We start the example

```
$ docker-compose up
Starting resource-server      ... done
Starting authorization-server ... done
Starting client               ... done
Attaching to authorization-server, resource-server, client
...
```

and send a request to the client endpoint:

```sh
$ curl -si http://localhost:8080/resource
HTTP/1.1 401 Unauthorized
Content-Type: application/json
Couper-Error: access control error

{
  "error": {
    "id":      "cdl6lu9ji8051iuvpf3g",
    "message": "access control error",
    "path":    "/resource",
    "status":  401
  }
}
```

We get a `401` because our request did not contain a token. Yet!

In this example, there is a mock authorization server with its token endpoint at http://authorization-server:8080/token. At this authorization server our Couper client has the client_id `my-client` and the client secret `my-client-secret`.

So, in order to authorize requests to the resource server, now we reference this token endpoint in an `oauth2` block that we add to the `backend`:

```hcl
...
    endpoint "/resource" {
      proxy {
        backend {
          origin = "http://resource-server:8080"
          oauth2 {
            grant_type = "client_credentials"
            token_endpoint = "http://authorization-server:8080/token"
            client_id = "my-client"
            client_secret = "my-client-secret"
          }
        }
...
```

Here we use the OAuth2 client credentials grant, providing our client's credentials (`client_id` and `client_secret`).

We restart Couper and try again the previous request:

```sh
$ curl -is localhost:8080/resource
HTTP/1.1 200 OK
Content-Type: application/json

{"foo":1}
```

If we now look at the logs, we see five log entries.

One is the client's backend log representing the token request sent by Couper (because it had no (valid) token):

```
{"auth_user":"my-client","backend":"anonymous_7_18",...,"method":"POST",...,"token_request":"oauth2","type":"couper_backend",...,"url":"http://authorization-server:8080/token",...}
```

There is another entry for Couper's request to the resource server:
```
{"backend":"anonymous_4_13",...,"method":"GET",...,"type":"couper_backend",...,"url":"http://resource-server:8080/resource",...}
```

If we retry the request within 10 seconds,

```sh
$ curl -is localhost:8080/resource
HTTP/1.1 200 OK
Content-Type: application/json

{"foo":1}
```

we do not see any entries for a token request in the log, because Couper already has a valid token.

But if we wait for more than 10 seconds, the token is expired and again we see log entries containing the request for a new token.

## How to use the oauth2 block in a real world setting

In a real-world setting, use the `oauth2` block in your backend configuration for the
third-party API that needs a token available via the client credentials flow and configure the parameters `token_endpoint`, `client_id` and `client_secret` accordingly:

```hcl
...
        backend {
          origin = "https://example.com"
          path = "/protected_resource"
          oauth2 {
            grant_type = "client_credentials"
            token_endpoint = "..."
            client_id = env.CLIENT_ID
            client_secret = env.CLIENT_SECRET
          }
        }
...
```

By default, Couper uses basic authentication to authenticate itself at the authorization server (`token_endpoint_auth_method = "client_secret_basic"`). In some settings authorization servers require the client credentials to be sent as form parameters in the POST request body. This can be achieved by configuring the `oauth2` block:

```hcl
token_endpoint_auth_method = "client_secret_post"
```

Couper also implements the client authentication methods `"client_secret_jwt"` and `"private_key_jwt"` that use a self-signed JWT for authentication.

With `client_secret_jwt`, the JWT is signed with the `client_id` using an HS algorithm, so no additional key is necessary.

```hcl
client_id = "..."
client_secret = "..."
token_endpoint_auth_method = "client_secret_jwt"
jwt_signing_profile {
  signature_algorithm = "HS256"
  ttl = "10s"
}
```

With `private_key_jwt`, the JWT is signed with a _private_ key using an RS or EC algorithm (only the corresponding _public_ key stays at the authorization server):

```hcl
client_id = "..."
token_endpoint_auth_method = "private_key_jwt"
jwt_signing_profile {
  key_file = "private_key.pem"
  signature_algorithm = "RS256"
  ttl = "10s"
}
```

Make sure that the authorization server supports the selected client authentication method.

We can also specify the scope of the requested access token by setting the `scope` attribute in the `oauth2` block:

```hcl
scope = "foo bar"
```

## Other OAuth2 grant types

There are other OAuth2 grant types that can be configured with the `oauth2` block: password and jwt-bearer.

**Note**, that, while the grant may contain information about a specific user (e.g. username or email address), the requested token is stored _per backend_. So there is no way to "switch" between users from one request to another. But both grant types may be useful to request a token for a service account.

### The OAuth2 password grant

For the password grant, set the `grant_type` attribute accordingly and provide the service account's `username` and `password` in addition to the client's `client_id` and `client_secret`:

```hcl
    oauth2 {
      grant_type = "password"
      token_endpoint = "..."
      client_id = env.CLIENT_ID
      client_secret = env.CLIENT_SECRET
      username = env.SYSTEM_ACCOUNT_USERNAME
      password = env.SYSTEM_ACCOUNT_PASSWORD
    }
```

### The OAuth2 jwt-bearer grant

For the jwt-bearer grant, set the `grant_type` attribute accordingly. You may either specify the `assertion` attribute with a JWT containing information about the service account received from somewhere else or create one using the `jwt_sign()` function:

```hcl
    oauth2 {
      grant_type = "urn:ietf:params:oauth:grant-type:jwt-bearer"
      token_endpoint = "..."
      client_id = env.CLIENT_ID
      assertion = backend_responses.foo.json_body.id_token
#      assertion = jwt_sign("sp", {})
    }
...
#definitions {
#  jwt_signing_profile "sp" {
#    ...
#  }
#}
```

Or a self-signed JWT assertion is created with a nested `jwt_signing_profile` block. E.g. to authorize Couper to access Google's spreadsheets API using a registered service account:

```hcl
    oauth2 {
      grant_type = "urn:ietf:params:oauth:grant-type:jwt-bearer"
      token_endpoint = "https://oauth2.googleapis.com/token"
      jwt_signing_profile {
        signature_algorithm = "RS256"
        key_file = "priv_key.pem"                      # private_key from service account JSON
        ttl = "10s"
        claims = {
          iss = env.SYSTEM_ACCOUNT_EMAIL               # client_email from service account JSON
          scope = "https://www.googleapis.com/auth/spreadsheets.readonly"
          aud = "https://oauth2.googleapis.com/token"  # the authorization server's token endpoint
          iat = unixtime()
        }
      }
    }
```

## See also

* [OAuth2 Block](https://docs.couper.io/configuration/block/oauth2) (reference)
* [JWT Signing Profile Block](https://docs.couper.io/configuration/block/jwt_signing_profile) (reference)
* [jwt_sign() Function](https://docs.couper.io/configuration/functions) (reference)
