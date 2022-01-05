# Custom Logging

Consider an email application that you want to protect with Couper:

```hcl
server {
  hosts = ["*:8080"]
  api {
    endpoint "/login" {
      access_control = ["ba"]
      response {
        body = jwt_sign("MyToken", { sub = request.context.ba.user })
      }
    }
  }
  api {
    base_path = "/protected"
    access_control = ["MyToken"]
    endpoint "/**" {
      proxy {
        path = "/**"
        backend = "mail"
      }
    }
  }
}

definitions {
  jwt "MyToken" {
    header = "authorization"
    signature_algorithm = "HS256"
    key = "$e(R3t"
    signing_ttl = "10m"
  }
  backend "mail" {
    origin = "http://localhost:8081"
  }
}
```

(In our example, the application itself has a send-mail endpoint and is located at http://localhost:8081.)

We can log into the protected application with the following request:

```sh
$ curl -si -u "john.doe:asdf" localhost:8080/login
HTTP/1.1 200 OK
...

eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2NDEzOTYxODksInN1YiI6ImpvaG4uZG9lIn0.QCZimvBsFPSAqw70VvdtYyr5TwmeXDQfZs05hi0vJ1k
```

The login endpoint returns an access token which we will now use at the protected send-mail endpoint together with a JSON payload containing `to`, `subject` and `data` fields:

```sh
$ curl -si -H "Content-Type: application/json" -d '{"to": "jane.doe@example.com", "subject": "my first mail", "data": "hi, darling!"}' localhost:8080/protected/send-mail -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2NDEzOTYxODksInN1YiI6ImpvaG4uZG9lIn0.QCZimvBsFPSAqw70VvdtYyr5TwmeXDQfZs05hi0vJ1k"
HTTP/1.1 200 OK
...

{"sent":true}
```

The login endpoint creates a JWT containing a `sub` claim. Let's add that to the access log, whenever a protected endpoint is used. In order to achieve this we add the `custom_log_fields` attribute to the `jwt` block. The claims of a used JWT access token are stored in `request.context.MyToken`. So we assign the value by referencing `request.context.MyToken.sub`:

```hcl
  jwt "MyToken" {
#   ...
    custom_log_fields = {
      sub = request.context.MyToken.sub
    }
  }
```

We try the send-mail request again, and find a
```json
"custom": {
  "sub": "john.doe"
}
```
field in the `couper_access` log.

Now, let's add some logging to the `backend` block. From the sent JSON request body we only log the `to` and `subject` fields:

```hcl
  backend "mail" {
    origin = "http://localhost:8081"
    custom_log_fields = {
      recipient = request.json_body.to
      subject = request.json_body.subject
    }
  }
```

We try the send-mail request again, and find a
```json
"custom": {
  "recipient": "jane.doe@example.com",
  "subject": "my first mail"
}
```
field in the `couper_backend` log.

Finally, let's log some login event data containing e.g. the `user` field of the basic authentication mechanism:

```hcl
    endpoint "/login" {
#     ...
      custom_log_fields = {
        event_type = "login"
        user = request.context.ba.user
      }
    }
```

We try the login request again, and find a
```json
"custom": {
  "event_type": "login",
  "user": "john.doe"
}
```
field in the `couper_access` log.

**Note:** With Couper you can log data using the `custom_log_fields` map attribute in `server`, `files`, `spa`, `api`, `endpoint`, `backend`, `basic_auth`, `jwt`, `beta_oauth2`, `oidc` or `saml` blocks.
