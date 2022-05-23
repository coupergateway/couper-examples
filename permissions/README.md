# Permissions

**Note:** This is currently a [_beta_ feature](https://github.com/avenga/couper/blob/master/docs/BETA.md).

Suppose you have an API with four endpoints:
* `/a`
* `/b/send`
* `/b/copy`
* `/c`

and you want to use couper for access control. No problem, you can use the `jwt` access control (see example [JWT Access Control](../jwt-access-control/README.md))

```hcl
server {
  api {
    access_control = ["Token"]

    endpoint "/**" {
      proxy {
        backend = "api"
      }
    }
  }
}

definitions {
  jwt "Token" {
    signature_algorithm = "RS256"
    key_file = "pub-key.pem"
  }

  backend "api" {
    origin = "http://api:8080"
  }
}
```

But additionally, the API endpoints have certain permissions that have to be granted to the requester to access them:

* requests to `/a` need permission "a"
* requests to `/b/send` need permission "b:send"
* requests to `/b/copy` need permission "b:copy"
* `DELETE` requests to `/c` need permission "c:del"
* `GET` requests to `/c` need no permission
* other requests to `/c` need permission "c"

You can configure this using the `beta_required_permission` attribute in the endpoint block.

First, we replace the wildcard `endpoint` bock with three more specific `endpoint` blocks:


```hcl
server {
  api {
    access_control = ["Token"]

    endpoint "/a" {
      proxy {
        backend = "api"
      }
    }

    endpoint "/b/{action}" { # send, copy
      proxy {
        backend = "api"
      }
    }

    endpoint "/c" {
      proxy {
        backend = "api"
      }
    }
  }
}
```

Then we set the required permission for `/a`:

```hcl
    endpoint "/a" {
      beta_required_permission = "a"    # ←

      proxy {
        backend = "api"
      }
    }
```
That is simple. For the `/b/{action}` endpoint we can use a quoted template expression, because the permission consists of a prefix ("b:") and the value of the `action` path parameter ("send" or "copy").

```hcl
    endpoint "/b/{action}" { # send, copy
      beta_required_permission = "b:${request.path_params.action}"    # ←

      proxy {
        backend = "api"
      }
    }
```

Last, the value of `beta_required_permission` can also be an object with a method-permission mapping.

```hcl
    endpoint "/c" {
      beta_required_permission = {    # ←
        GET = ""         # no permission required for GET
        DELETE = "c:del" # permission for DELETE is c:del
        "*" = "c"        # permission for other methods is c
      }

      proxy {
        backend = "api"
      }
    }
```

But how do we know that certain permissions were granted to the requester? With JWT they should be specified in a claim. The claim containing the granted permissions (also called privileges) is configured in the `jwt` access control block with the `beta_permissions_claim`:

```hcl
  jwt "Token" {
    signature_algorithm = "RS256"
    key_file = "pub-key.pem"
    beta_permissions_claim = "permissions"    # ←
  }
```

**Note:** Couper expects the granted permissions as a string containing a space-separated list, or an array of strings, like this:
```json
{
  # ...
  "permissions": "a c c:del",
  # ...
}
```
or
```json
{
  # ...
  "permissions": ["a", "c", "c:del"],
  # ...
}
```

Now we can try this by using one of the tokens below (replace `<token>` with one of the tokens):
```
$ curl -si http://localhost:8080/a -H "Authorization: Bearer <token>"
```
* all permissions `"a b:send b:copy c c:del"`:
  ```
  eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwicGVybWlzc2lvbnMiOiJhIGI6c2VuZCBiOmNvcHkgYyBjOmRlbCJ9.UdwsXqLWsUHOMitzktVflBuA0ubXbuNE5F72xqzg1ZJOxZMU9aVWSMzE1QuxkD6-1ml0yPFg0rPe5ekrEr2DsGrUSPM3nCpTBnMOUb9xz5pdERF10CdBhYhwz0QALNI8nkPri1ewROrquD_aCgDaD1skEjn5KTUYykbD8eFCEOpvB24LG-Z83sfe929gnY066gUYNjgeqhaxOtdbFKhjaM0K2U2pl21e4dLx7lstlnb63yIq_0HJapOD-4xecZ0VkdzvQU3m4f0zwnxc0YwiXPGFVnsIn4r6oErUJnvC9zeFlfBnx3iXBj6qLKVZDBxy8kDAn3WCMDRyeDsDKIcWvg
  ```
* only permissions `"a b:send b:copy c"`:
  ```
  eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwicGVybWlzc2lvbnMiOiJhIGI6c2VuZCBiOmNvcHkgYyJ9.nKnNKPYWvUUV1tFraGejIu-j3REyn4Rii5OpceJJfUXtYv9xGpgZNgycaS0s15WQFyGu7nOJIH-Q7Mk7gsEkKyWObY_B6UuSGoexXtM02OU_P4EAvCI-nMV1-8tW3-veQnNG6TgqVN0L2jR06exP2imbybJlwm3nrJ3LZ2ayGiQhA3vHGZMm7ODPER-mzg9MI3sQmbZwDF8AnUH0Oh--tnc3Fig4I5fQ788ACz057iuOy6EOTNru3AZOJoaPqoWA6VEkMejG2vQ5EaF1VPnAhQjyrdNa1sx4s_-WfjoVFmAAXp_XJnT5jWnpaS234T4ir1hK4XquECP7bv-_m3A1lQ
  ```
* no permissions:
  ```
  eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dw1oz77jAV2AUdIv7MAiarGl1EmVM8HGJUPxCaC5GUyD6VLp3c8K58fbgOPnslpgDf8wmgiwr2KzgPPNXCX5ebxz3b_q-09fHirXn_8fhUV2GAbcvgW9aCL8LxmUH-zLbyBYWcdc-GGFucOVNCB7uP-nWHgjim7BLiyUn1XwRuJhZTaZtMGnAgZ8oTw83yznLFdjpZBD9NUGE_m_FlGT_7559ixUk1jQVPkDjRZldQWwjSSzHVwLpQXHgCoHhWhRykmTgyg8KERtwywvBJikQABOEYw592uP2cWl023g3reZu8xl-17ojSFUplz2J4zqMhqZptP3z7kpe0C_SQQlNw
  ```

To see which permission (singular!) was required and which permissions (plural!) were granted, we can add these response headers:
```hcl
  api {
    access_control = ["Token"]
    add_response_headers = {    # ←
      required-permission = request.context.beta_required_permission
      granted-permissions = join(" ", request.context.beta_granted_permissions)
    }
```
**Note:** One header or both are missing if its value is empty (e.g. no permission required or no permissions granted).

Requesting the `/c` endpoint with the `POST` method with a token providing the "b" permission, but lacking "c:del", is successful:
```
$ curl -si -X POST localhost:8080/c -H "Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwicGVybWlzc2lvbnMiOiJhIGI6c2VuZCBiOmNvcHkgYyJ9.nKnNKPYWvUUV1tFraGejIu-j3REyn4Rii5OpceJJfUXtYv9xGpgZNgycaS0s15WQFyGu7nOJIH-Q7Mk7gsEkKyWObY_B6UuSGoexXtM02OU_P4EAvCI-nMV1-8tW3-veQnNG6TgqVN0L2jR06exP2imbybJlwm3nrJ3LZ2ayGiQhA3vHGZMm7ODPER-mzg9MI3sQmbZwDF8AnUH0Oh--tnc3Fig4I5fQ788ACz057iuOy6EOTNru3AZOJoaPqoWA6VEkMejG2vQ5EaF1VPnAhQjyrdNa1sx4s_-WfjoVFmAAXp_XJnT5jWnpaS234T4ir1hK4XquECP7bv-_m3A1lQ"
HTTP/1.1 200 OK
Cache-Control: private
Content-Type: application/json
Granted-Permissions: a b:send b:copy c
Required-Permission: c

{"method":"POST","path":"/c"}
```

Using the `DELETE` method with the same token, however, results in an error:
```
$ curl -si -X DELETE localhost:8080/c -H "Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwicGVybWlzc2lvbnMiOiJhIGI6c2VuZCBiOmNvcHkgYyJ9.nKnNKPYWvUUV1tFraGejIu-j3REyn4Rii5OpceJJfUXtYv9xGpgZNgycaS0s15WQFyGu7nOJIH-Q7Mk7gsEkKyWObY_B6UuSGoexXtM02OU_P4EAvCI-nMV1-8tW3-veQnNG6TgqVN0L2jR06exP2imbybJlwm3nrJ3LZ2ayGiQhA3vHGZMm7ODPER-mzg9MI3sQmbZwDF8AnUH0Oh--tnc3Fig4I5fQ788ACz057iuOy6EOTNru3AZOJoaPqoWA6VEkMejG2vQ5EaF1VPnAhQjyrdNa1sx4s_-WfjoVFmAAXp_XJnT5jWnpaS234T4ir1hK4XquECP7bv-_m3A1lQ"
HTTP/1.1 403 Forbidden
Cache-Control: private
Content-Type: application/json
Couper-Error: access control error

{
  "error": {
    "id":      "ca3pp02g5k7ueknrtj60",
    "message": "access control error",
    "path":    "/b",
    "status":  403
  }
}
```
In the log we see an entry like this:
```
access-control | {...,"error_type":"beta_insufficient_permissions","handler":"api","level":"error","message":"access control error: required permission \"c:del\" not granted","method":"DELETE",...
```

This error can be handled with an error_handler like this:
```hcl
server {
  api {
    # ...

    error_handler "beta_insufficient_permissions" {    # ←
      response {
        status = 403
        json_body = {
          error = "request lacking granted permission '${request.context.beta_required_permission}'"
        }
      }
    }
```

See also the examples
* [Permissions (Role-based Access Control)](../permissions-rbac/README.md)
* [Permissions (Map)](../permissions-map/README.md)
