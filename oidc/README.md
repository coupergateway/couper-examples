# Authentication with OIDC

OpenID Connect (OIDC) is an authentication protocol layered on top of OAuth2, where a relying party (RP) "out-sources" the actual authentication to a trusted OpenID provider (OP) by requesting a limited set of profile information about a user.

In this example we create a `docker-compose` application with two services (see docker-compose.yaml):

* `rp` acts as the relying party (on port 8080) and
* `op` acts as the (mock) OpenID provider (on port 8081).

In the real world, we will probably use an existing OpenID provider somewhere else.

```yaml
version: "3"
services:
  rp:
    image: avenga/couper
    container_name: relying-party
    ports:
      - 8080:8080
    depends_on:
      - op
    volumes:
      - ./relying-party:/conf
    environment:
      COUPER_WATCH: "true"
      RP_CLIENT_ID: "foo"
      RP_CLIENT_SECRET: "bar"
  op:
    image: avenga/couper
    container_name: openid-provider
    ports:
      - 8081:8080
    volumes:
      - ./openid-provider:/conf
    environment:
      COUPER_WATCH: "true"
```

The relying party's client ID and client secret are configured with `RP_CLIENT_ID` and `RP_CLIENT_SECRET`. In the example, these are dummy values. But in real life, we would have got ID and secret after registering a confidential relying party at the OpenID provider.

Now, let's configure Couper as an OpenID relying party (couper.hcl).

We start with the `oidc` block within the `definitions`:

```hcl
definitions {
  oidc "MyOIDC" {
    configuration_url = "http://host.docker.internal:8081/.well-known/openid-configuration"
    client_id = env.RP_CLIENT_ID
    client_secret = env.RP_CLIENT_SECRET
    redirect_uri = "/oidc/redir"
    verifier_value = request.cookies.authvv
  }
}
```

* `configuration_url` references the OpenID provider's configuration.
* `client_id` is the relying party's client ID defined in the `RP_CLIENT_ID` environment variable.
* `client_secret` is the relying party's client secret defined in the `RP_CLIENT_SECRET` environment variable.
* `redirect_uri` is the relying party's redirect endpoint registered at the OP.
* `verifier_value` provides a value for the OAuth2 verifier (here: from a cookie names `authvv`).

In the `server` block we configure an endpoint that returns the OIDC authorization URL:

```hcl
server {
  endpoint "/oidc/login" {
    response {
      headers = {
        cache-control = "no-cache,no-store"
        set-cookie = "authvv=${oauth2_verifier()};HttpOnly;Secure;Path=/oidc/redir"
      }
      json_body = {
        url = "${oauth2_authorization_url("MyOIDC")}&state=${url_encode(relative_url(request.form_body.url[0]))}"
      }
    }
  }
}
definitions {
# ...
```

The `oauth2_authorization_url()` function creates this URL from information provided in the `oidc` block.

The second endpoint is the redirect endpoint receiving the authorization code provided by the OP:

```hcl
server {
  endpoint "/oidc/login" {
# ...
  }

  endpoint "/oidc/redir" {
    access_control = ["MyOIDC"]
    response {
      status = 303
      headers = {
        set-cookie = [
          "UserToken=${jwt_sign("UserToken", {
            sub = request.context.MyOIDC.id_token_claims.sub
            name = request.context.MyOIDC.id_token_claims.name
            given_name = request.context.MyOIDC.id_token_claims.given_name
            family_name = request.context.MyOIDC.id_token_claims.family_name
            preferred_username = request.context.MyOIDC.id_token_claims.preferred_username
          })};HttpOnly;Secure;Path=/api",
          "authvv=;HttpOnly;Secure;Path=/oidc/redir;Max-Age=0"
        ]
        location = relative_url(request.query.state[0])
      }
    }
  }
}

definitions {
...
```

This endpoint is protected by the `oidc` access control, which exchanges the received authorization code with an access token and an ID token and stores some data from the token response in `request.context.MyOIDC`. From this information we create a JWT and send it to the browser via the `set-cookie` header. The `status` code `303` together with the `location` header causes the browser to load the current HTML page again.

Our simple example also has a small API which is protected by a `jwt` access control configured in the `definitions` (see [JWT Access Control](../jwt-access.control/README.md) for more information):

```hcl
server {
# ...

  api {
    base_path = "/api"
    access_control = ["UserToken"]
  }
}
definitions {
  jwt "UserToken" {
    signature_algorithm = "HS256"
    key = "Th3$e(rEt"
    cookie = "UserToken"
  }

  oidc "MyOIDC" {
# ...
  }
```

Because the API is the only consumer of the created tokens, we can use the same `jwt` block to configure the `jwt_sign` function in the `"/oidc/redir"` endpoint by adding a `signing_ttl` attribute (see [Creating JWT](../creating-jwt/README.md) for more information). The created tokens will expire after one hour:

```hcl
# ...
definitions {
  jwt "UserToken" {
    signature_algorithm = "HS256"
    key = "Th3$e(rEt"
    cookie = "UserToken"
    signing_ttl = "1h"       # add signing_ttl
  }

  oidc "MyOIDC" {
# ...
  }
```

We add an endpoint to the api block returning the claims from the JWT presented in the `UserToken` cookie:

```hcl
# ...
  api {
    base_path = "/api"
    access_control = ["UserToken"]

    endpoint "/userinfo" {
      response {
        json_body = request.context.UserToken
      }
    }
  }
# ...
```

The frontend part of our demo application has only one HTML page (index.html) which is served from the `htdocs` directory:

```hcl
server {
  files {
    document_root = "htdocs"
  }

  endpoint "/oidc/login" {
# ...
```

After loading the page, a request is sent to the API's `/userinfo` endpoint to get and show some information about a user. If the JWT access control rejects the request, a request is sent to the `/oidc/login` endpoint creating the authorization URL, which the browser then calls to start the authentication process.

As our demo application is now complete, we can start it:

```sh
$ docker-compose up
```

We point our browser to `http://localhost:8080/`. For a short time, the browser shows the OIDC Demo page with a blank textarea, indicating that no information about the user is available.

The browser is then sent to the OpenID provider for authentication. In a real case, the user would now have to authenticate e.g. via username and password and potentially some additional means, unless she already has a valid session at the OpenID provider. In our example, as the OpenID provider is only a mock, no authentication is needed.

The OpenID provider sends the browser with an authorization code in the query to Couper's redirect endpoint where Couper redeems the code for an access and and ID token. From this information Couper creates its own token, which is stored in the browser in a cookie.

The browser then loads the OIDC Demo page again, now showing some user information in JSON format in the textarea.
