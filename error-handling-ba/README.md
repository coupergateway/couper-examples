# Error Handling with the Basic Auth Access Control

Suppose, we have an API which we protect with a basic_auth access control:

```hcl
server "error-handling" {
  api {
    access_control = ["ba"]
    endpoint "/test" {
      response {
        json_body = { "ok" = true }
      }
    }
  }
}
definitions {
  basic_auth "ba" {
    user = "john.doe"
    password = "$eCr3T"
  }
}
```

We try to access the `/test` endpoint:

```sh
$ curl -is localhost:8080/test
HTTP/1.1 401 Unauthorized
Content-Type: application/json
Couper-Error: access control error
Server: couper.io
Www-Authenticate: Basic
...

{
  "error": {
    "id":      "c2cgilcg4r4lmn8lo8ig",
    "message": "access control error",
    "path":    "/test",
    "status":  401
  }
}
```

Hmm, access control error. But what is the specific problem here? Let's look into the logs:

```json
{...,"error_type":"basic_auth_credentials_missing","handler":"error_basic_auth","level":"error","message":"access control error: ba: credentials required",...}
```

Ah, `"error_type":"basic_auth_credentials_missing"` and `"message":"access control error: ba: credentials required"`. OK, we forgot the user credentials.

Try again, now with the configured credentials:

```sh
$ curl -is -u "john.doe:\$eCr3T" localhost:8080/test
HTTP/1.1 200 OK
Connection: close
Content-Type: application/json
Server: couper.io

{"ok":true}
```

Fine. But now we want to change the error response to `403` instead of `401`: we add an error handler to the basic auth access control using the `error_type` from the log entry as the label:

```hcl
  basic_auth "ba" {
    ...
    error_handler "basic_auth_credentials_missing" {
      response {
        status = 403
        json_body = {
          error = {
            id = request.id
            message = "access control error"
            path = request.path
            status = 403
          }
        }
      }
    }
  }
```

Try again the uncredentialed request to check:

```sh
$ curl -is localhost:8080/test
HTTP/1.1 403 Forbidden
Connection: close
Content-Type: application/json
Server: couper.io
...

{"error":{"id":"c2ch0v5mveodtqio2qs0","message":"access control error","path":"/test","status":403}}
```

Now, we try a credentialed request using wrong credentials:

```sh
$ curl -is -u "john.doe:foo" localhost:8080/test
HTTP/1.1 401 Unauthorized
Content-Type: application/json
Couper-Error: access control error
Server: couper.io
Vary: Accept-Encoding
Www-Authenticate: Basic
Date: Mon, 10 May 2021 10:56:03 GMT
Content-Length: 142

{
  "error": {
    "id":      "c2ch2gtmveodtqio2qsg",
    "message": "access control error",
    "path":    "/test",
    "status":  401
  }
}
```

The status code is 401, again, because this time, the `error_type` in the log entry is the less specific `basic_auth`.

```json
{"auth_user":"john.doe",...,"error_type":"basic_auth","handler":"error_basic_auth","level":"error","message":"access control error: ba: credential mismatch",...}
```

If we want to change all error responses related to our basic auth access control, we can remove the error handler label entirely:

```hcl
  basic_auth "ba" {
    ...
    error_handler {
      response {
        status = 403
        json_body = {
          error = {
            id = request.id
            message = "access control error"
            path = request.path
            status = 403
          }
        }
      }
    }
  }
```

```sh
$ curl -is -u "john.doe:foo" localhost:8080/test
HTTP/1.1 403 Forbidden
Connection: close
Content-Type: application/json
Server: couper.io
...

{"error":{"id":"c2ci73o75846jfpfirp0","message":"access control error","path":"/test","status":403}}
```

BTW, error handlers can also be used in other access controls; e.g. you can try to add them to the [JWT Access Control](../jwt-access-control/README.md) example.

See also:

* [Errors](https://github.com/avenga/couper/blob/master/docs/ERRORS.md) (reference)
