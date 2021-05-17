# Error Handling

Errors can occur in various places: due to invalid client requests or problems on the backend and network side. Couper specifies some generic error categories (like `configuration`, `server`, `backend` or `access_control`) to help you identify the occurring problems faster.

In this example we show Couper's standard error handling and demonstrate how you can create custom errors for a specific access control by configuring an `error_handler` block.

Suppose, we have an endpoint `/test` which we protect with a basic_auth access control:

```hcl
server "error-handling" {
  api {
    endpoint "/test" {
      access_control = ["ba"]
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

Let's start Couper and try to access the `/test` endpoint via curl:

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

You get a `401` with the message: access control error. For more detailed information let's take a look at the logs:

```json
{...,"error_type":"basic_auth_credentials_missing","handler":"error_basic_auth","level":"error","message":"access control error: ba: credentials required",...}
```

`"error_type":"basic_auth_credentials_missing"` and `"message":"access control error: ba: credentials required"`. OK, seems like we forgot the user credentials.

Try again, now with the configured credentials and voilà: you get a status `200`:

```sh
$ curl -is -u "john.doe:\$eCr3T" localhost:8080/test
HTTP/1.1 200 OK
Connection: close
Content-Type: application/json
Server: couper.io

{"ok":true}
```

## Custom errors

Now we want to demonstrate how you can change errors by configuring an `error_handler` block for a specific `access_control`.

Remember the `401` we got earlier. As we have seen, Couper logs the specific error under `"basic_auth_credentials_missing"`. 
Use this `error_type` from the logs as the label for the `error_handler` block to modify the response for the specific error. In this example we simply change the status `403` and add `error = "forbidden"` to the json body but you can also e.g. reference a custom error file here.

(delete comments in couper.hcl and restart Couper)

```hcl
  basic_auth "ba" {
    ...
    error_handler "basic_auth_credentials_missing" {
      response {
        status = 403
        json_body = {
          error = "forbidden"
        }
      }
    }
  }
```

Try again without credentials and receive the custom error:

```sh
$ curl -is localhost:8080/test
HTTP/1.1 403 Forbidden
Connection: close
Content-Type: application/json
Server: couper.io
...

{"error":"forbidden"}
```

Now, let's try a request with wrong credentials:

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

Again, you get the status code `401`. Because this time, the `error_type` in the log entry is less specific, namely `basic_auth`:

```json
{"auth_user":"john.doe",...,"error_type":"basic_auth","handler":"error_basic_auth","level":"error","message":"access control error: ba: credential mismatch",...}
```

You can either add several `error_handler` blocks with different labels or, in order to change all error responses related to the basic auth access control, omit the error handler label entirely:

```hcl
  basic_auth "ba" {
    ...
    error_handler {
      response {
        status = 403
        json_body = {
          error = "forbidden"
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

{"error":"forbidden"}
```

Error handlers can also be used in other access controls; e.g. you can try to add them to the [JWT Access Control](../jwt-access-control/README.md) example.

## See also:

* [Errors](https://github.com/avenga/couper/blob/master/docs/ERRORS.md) (reference)
