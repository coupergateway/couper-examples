# Request Sequences

Imagine, there are two micro-services, and we want to pass to the second service data from the response of the first. With Couper, we can connect both services, without one service knowing the other, by using an implicit sequence.

Let's look at an example:

Imagine a math service with two endpoints: `/add` calculates the sum of two numbers given as a JSON array, `/multiply` also accepts an array of two numbers and multiplies the first by the second.

In `couper-math.hcl`, we set up a server connecting the two endpoints:

```hcl
server {
  hosts = ["*:8080"]
  api {
    endpoint "/connect" {
      # proxy: pass the client request body to /add
      proxy "add" {
        url = "http://math:8081/add"
        # store response in backend_responses.add
      }
      # "default" request: pass response to client
      request {
        url = "http://math:8081/multiply"
        json_body = [ backend_responses.add.json_body.result, 4 ]
      }
    }
  }
}
```

The proxy configured by the `proxy` block labelled `"add"` sends the client request to the first service endpoint (`/add`) and stores the result in `backend_responses.add`.
The request configured by the `request` block without a label (so having the implicit label `"default"`) sends a new array with two numbers: the result of the first computation, and `4`.
As the `request` block has no label, the response from this request is then passed to the client.

By using a reference to proxy `"add"` in an attribute of the `request` block, Couper knows that it has to send the default request only *after* having received the response from the proxy. Without such references `proxy` requests and an explicit `request`s are sent in parallel.

Let's start the example:

```sh
$ docker-compose -f docker-compose-math.yml up
```

And try it by sending the numbers `12` and `34`:

```sh
$ curl -si -H "Content-Type: application/json" -d '[12, 34]' localhost:8080/connect
HTTP/1.1 200 OK
Content-Type: application/json
...

{"result":184}
```

The `/add` service calculated the sum of `12` and `34` (= `46`), the `/multiply` calculated the product of the result of `/add` (`46`) and `4` (= `184`).

Fine!

What happens if we don't pass an array with two numbers, but `[12, "foo"]`?

```sh
$ curl -si -H "Content-Type: application/json" -d '[12, "foo"]' localhost:8080/connect
HTTP/1.1 500 Internal Server Error
Content-Type: application/json
...

{
  "error": {
    "id":      "c71kp4t916bht5pkuqag",
    "message": "expression evaluation error",
    "path":    "/multiply",
    "status":  500
  }
}
```

Hmm, this is an error from the `/multiply` endpoint. But looking at the logs, we see that already the request to the `/add` endpoint returned a `500`:

```json
{
  "backend":"default",
  "request": {
    "name": "add"
  },
  "status":500,
  "type":"couper_backend",
  "url":"http://math:8081/add"
}
```

Additionally, we see another entry in the `couper_backend` log:

```json
{
  "backend":"default",
  "request": {
    "name": "default"
  },
  "status":500,
  "type":"couper_backend"
  "url":"http://math:8081/multiply"
}
```

So Couper sent the second request, even though the first produced an unexpected result.

But we can stop the sequence earlier by configuring the expected status code for each request:

```hcl
# ...
      proxy "add" {
        ...
        expected_status = [200]                  # ←
      }
      # "default" request: pass response to client
      request {
        ...
        expected_status = [200]                  # ←
      }
# ...
```

```sh
$ curl -si -H "Content-Type: application/json" -d '[12, "foo"]' localhost:8080/connect
HTTP/1.1 502 Bad Gateway
Content-Type: application/json
Couper-Error: endpoint error
...

{
  "error": {
    "id":      "c71kuad916bht5pkuqb0",
    "message": "endpoint error",
    "path":    "/connect",
    "status":  502
  }
}
```

Now we see only one entry in the `couper_backend` log (for `/add`).

We also see an error in the `couper_access` log:

```json
{
  "error_type": "unexpected_status",
  "level": "error",
  "message": "endpoint error",
  "type": "couper_access"
}
```

Let's add an `error_handler` to handle the error:

```hcl
...
      request {
        ...
        expected_status = [200]
      }
      error_handler "unexpected_status" {
        response {
          status = 500
          json_body = {
            error = "upstream error"
            error_description = "an upstream service responded with an unexpected status code"
          }
        }
      }
# ...
```

```sh
$ curl -si -H "Content-Type: application/json" -d '[12, "foo"]' localhost:8080/connect
HTTP/1.1 500 Internal Server Error
Content-Type: application/json
...

{"error":"upstream error","error_description":"an upstream service responded with an unexpected status code"}
```

And we can log some additionaly information about the requests in the case of an error:

```hcl
# ...
      error_handler "unexpected_status" {
        response {
          ...
        }
        custom_log_fields = {
          add = backend_responses.add.body
          default = backend_responses.default.body
        }
      }
# ...
```

This adds a new field to the log message:

```json
{
  "custom": {
    "add": "{\n  \"error\": {\n    \"id\":      \"c7bvae8plt7t9hpdkaqg\",\n    \"message\": \"expression evaluation error\",\n    \"path\":    \"/add\",\n    \"status\":  500\n  }\n}\n"
  },
  "error_type": "unexpected_status"
}
```

showing that the proxy `"add"` responded with a status code `500` and the error message `"expression evaluation error"`.

If we change the `request` to

```hcl
# ...
      request {
        url = "http://math:8081/multiply"
        json_body = [ backend_responses.add.json_body.result, "bar" ]  # ← "bar" instead of 4
      }
# ...
```
and send a "proper" array, the `custom` field in the log message now shows that proxy `"add"` produced a "proper" result, while request `"default"` has an error:

```json
{
  "custom": {
    "add": "{\"result\":46}",
    "default": "{\n  \"error\": {\n    \"id\":      \"c7bvbgoplt7t9hpdkarg\",\n    \"message\": \"expression evaluation error\",\n    \"path\":    \"/multiply\",\n    \"status\":  500\n  }\n}\n"
  },
  "error_type": "unexpected_status"
}
```

---

Another use case for a sequence is the provisioning of an access token prior to a request that must be authorized.

See `couper_2.hcl` for an example:

```hcl
server "client" {
  hosts = ["*:8080"]
  api {
    endpoint "/" {
      request "token" {
        url = "http://math:8081/token"
        form_body = {
          sub = "myself"
        }
        expected_status = [200]
      }
      # The reference to backend_responses.token makes Couper wait for request "token"'s response.
      request "pr" {
        url = "http://localhost:8082/protected-res"
        headers = {
          authorization = "Bearer ${backend_responses.token.json_body.access_token}"
        }
        json_body = { a = true, b = 2 }
      }
      response {
        json_body = {
          pr = backend_responses.pr.json_body
        }
      }
    }
  }
}
# ...
```

Couper creates a sequence consisting of both requests.

If we added another request without any reference to one of the requests in the sequence, this request would be started in parallel with the sequence.
