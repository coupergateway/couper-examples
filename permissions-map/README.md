# Permissions (Map)

**Note:** This is currently a [_beta_ feature](https://github.com/avenga/couper/blob/master/docs/BETA.md).

Please, see the [Permissions example](../permissions/README.md) before reading this.

Suppose you have a calendar API (like Google's) with (among others) three endpoints:
* `/calendars/`
* `/calendars/{calendarId}`
* `/calendars/{calendarId}/events`

The API should be protected by a `jwt` access control (see example [JWT Access Control](../jwt-access-control/README.md))

Additionally, you want to define certain permissions for the endpoints, depending on the used HTTP method:

* calendar
* calendar.readonly
* calendar.events
* calendar.events.readonly

```hcl
server {
  api {
    base_path = "/calendars"
    access_control = ["Token"]

    endpoint "/" {
      required_permission = {
        POST = "calendar"
        GET = "calendar.readonly"
      }
      proxy = "p"
    }

    endpoint "/{calendarId}" {
      required_permission = {
        GET = "calendar.readonly"
        PATCH = "calendar"
        PUT = "calendar"
        DELETE = "calendar"
      }
      proxy = "p"
    }

    endpoint "/{calendarId}/events" {
      required_permission = {
        GET = "calendar.events.readonly"
        POST = "calendar.events"
      }
      proxy = "p"
    }
  }
}

definitions {
  jwt "Token" {
    signature_algorithm = "RS256"
    key_file = "pub-key.pem"
  }

  proxy "p" {
    backend = "api"
  }

  backend "api" {
    origin = "http://api:8080"
  }
}
```

If seen as granted permissions (also called privileges), these permissions are in a hierarchical relationship to one another:

The granted permission _calendar.events_ also "contains" _calendar.events.readonly_, the granted permission _calendar.readonly_ also "contains" _calendar.events.readonly_, and the granted permission _calendar_ also "contains" both _calendar.readonly_ and _calendar.events_.

This can be shown in a graph like this:
```
               calendar
                  |
        +---------+--------+
        |                  |
calendar.readonly  calendar.events
        |                  |
        +---------+--------+
                  |
      calendar.events.readonly
```

So, e.g. a client granted the calendar.events permission may also request a route with the required permission calendar.events.readonly, and a client granted the calendar permission may request every route.

In Couper, these relationships are configured using the `jwt` block's `permissions_map` attribute:

```hcl
  jwt "Token" {
    signature_algorithm = "RS256"
    key_file = "pub-key.pem"
    permissions_map = {    # ←
      "calendar" = ["calendar.readonly", "calendar.events"] # no need to list calendar.events.readonly here, as the map is called recursively
      "calendar.events" = ["calendar.events.readonly"]
      "calendar.readonly" = ["calendar.events.readonly"]
    }
  }
```

Then we have to specify the source of the granted permissions via the `jwt` block's `permissions_claim`. In this example we expect them to be in the `scope` claim:

```hcl
  jwt "Token" {
    signature_algorithm = "RS256"
    key_file = "pub-key.pem"
    permissions_claim = "scope"    # ←
    permissions_map = {
      # ...
```

**Note:** If our permissions map is quite big, or we would like to create one in some build process, we could reference it using `permissions_map_file = "permissions.json"` instead of `permissions_map`. The format of the JSON file is very similar to the `permissions_map` value, here:
```json
{
  "calendar": ["calendar.readonly", "calendar.events"],
  "calendar.events": ["calendar.events.readonly"],
  "calendar.readonly": ["calendar.events.readonly"]
}
```

To see the scope, which permission (singular!) was required and which permissions (plural!) were granted, we can add these response headers:
```hcl
  api {
    base_path = "/calendars"
    access_control = ["Token"]
    add_response_headers = {    # ←
      required-permission = request.context.required_permission
      scope = request.context.Token.scope
      granted-permissions = join(" ", request.context.granted_permissions)
    }
```

Now we can try this by using one of the tokens below (replace `<token>` with one of the tokens):

```
$ curl -si http://localhost:8080/calendars/ -H "Authorization: Bearer <token>"
```

* calendar scope:
  ```
  eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwic2NvcGUiOiJjYWxlbmRhciJ9.J6X4M5dk-ivyi9qpVu5HjGS9CC0J7e_7vReh6xLg_04aff5mE55Pk9B0WliT5cA4uDUybq9LgxgKEEKzOTQHFp3RW6TBDQQWxBCzaE0WyNj1nGO2ZNdvVIDk5QPHaj0-88bv-1fIdops3gzy0YFdA587kKDOnfjqCGT5tH07o2ZbzPp2ogLo-IkUNV_hYLp7zZvinJj3ve6Q3y-C08H1xJ_sPa3_141AO8lX-B3lTursZ4XXz-VxRDY9bNC0rizKEzPY0e2BJ2P8c1Q15EEdaWzSRzilPovLFGstTYmKjm4Wmf-6H9_Zlsj9Ax0wvu4sn2vlUhZK2qk-yPs4DllsUw
  ```
* calendar.readonly scope:
  ```
  eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwic2NvcGUiOiJjYWxlbmRhci5yZWFkb25seSJ9.uaQiszCaN4z4U07QKkjhUZNdr7R0gv94zHFcdyFO7KcNdjzDfFr7ZdoOpL3OUKWrYR-zrLVkMHMlleP7Jh6p5BzrN-Ez0OBuutwan2RmE1bIwrvJiv6oolWbjJKLCb0iWdjrC7bSZdy2GcybFV6BlPsIZhmVC0ByvKkCv0H2j_KjNNvtTR8ocCr8DRLDX7ODndd7vriX8_rQ6rUnQ2nov3w_bLN8nL3Xz3fdDpJyUPMm8OTvqFNffDpqNTVueJ8T7TEszqZsKdYRTgGADToZnPY_EVJMFHDe36DTmCgb84OXsJEC6uYUNggCjLSQw2Lj4xV6IYzuYvGMOus-5UowJw
  ```
* calendar.events scope:
  ```
  eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwic2NvcGUiOiJjYWxlbmRhci5ldmVudHMifQ.K5qnp3srLfBs3LYqi_80ZsxG__6LikhFTEROBk6ZiyP8pyUMOa_QBa6Ax5Pz4Eh_de3HRtgRlWMzRBNWYdlhJ6AOtGYl8f4_y9kW3fbhxwusNTfeY3LCDHxI6qOVWz7Hhi0IZcOyWHFylkwJuq9P8tSVjDCefpdUr0eOnaCv-c2PY_qCwzn3ZxC_NaEqI2HtO6Jbo1vw5s3IrrlxCkKcjZC4n8tfc46bz8AjRJkhGyTo-A6ZlTx5FH9GQIgBhy2L2Vha2h2awN48pxQnPrJop5u8ntpWUTNhM6Oc0xZuobhiujRRxez72QwOSvrtYt5sE9YWJDK6SbENIxZ0ADy-Xg
  ```
* calendar.events.readonly scope:
  ```
  eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwic2NvcGUiOiJjYWxlbmRhci5ldmVudHMucmVhZG9ubHkifQ.brqEUIIxYNWqBaNTLBx_2uzRCfuf_wzukoWnNqv3aefudl7AWKMQe9svGKca6ytELT3Dlv0-RH8hWvpvOKTUwsWDBLbVagzGP6zQSTSFV2TC55wvFLdJ9GwrohlmGTbqAtyxK7jjEnKCTt7Lmo-GucO1luTG30Bg9s6jL_VBqC9oAMrpP1yUZOosfvDLXqpzhX3QxSzZkzT26uDh2Iyv4xfsLszxMrcr1wGVZcLEBBZsJ8FB1ZbxTf6r0SW7WVroNzk0EZlN6nt3QpYujSDTDkJcAm0wlpTD1jTyuuxRPDvLl9whTST9r6ncBhEioO6ka9VHlHwuPtwP5jAANaqaNA
  ```

E.g. (using the calendar.events.readonly scoped token)
```
$ curl -si -X GET localhost:8080/calendars/ -H "Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwic2NvcGUiOiJjYWxlbmRhci5ldmVudHMucmVhZG9ubHkifQ.brqEUIIxYNWqBaNTLBx_2uzRCfuf_wzukoWnNqv3aefudl7AWKMQe9svGKca6ytELT3Dlv0-RH8hWvpvOKTUwsWDBLbVagzGP6zQSTSFV2TC55wvFLdJ9GwrohlmGTbqAtyxK7jjEnKCTt7Lmo-GucO1luTG30Bg9s6jL_VBqC9oAMrpP1yUZOosfvDLXqpzhX3QxSzZkzT26uDh2Iyv4xfsLszxMrcr1wGVZcLEBBZsJ8FB1ZbxTf6r0SW7WVroNzk0EZlN6nt3QpYujSDTDkJcAm0wlpTD1jTyuuxRPDvLl9whTST9r6ncBhEioO6ka9VHlHwuPtwP5jAANaqaNA"
HTTP/1.1 403 Forbidden
Cache-Control: private
Content-Type: application/json
Couper-Error: access control error

{
  "error": {
    "id":      "ca3s9qf56p5nbq9b5bog",
    "message": "access control error",
    "path":    "/calendars/",
    "status":  403
  }
}
```
with the following log entry
```
access-control | {...,"error_type":"insufficient_permissions","handler":"api","level":"error","message":"access control error: required permission \"calendar.readonly\" not granted","method":"GET",...
```

Or a successful request using the calendar scoped token:
```
$ curl -si -X GET localhost:8080/calendars/ -H "Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwic2NvcGUiOiJjYWxlbmRhciJ9.J6X4M5dk-ivyi9qpVu5HjGS9CC0J7e_7vReh6xLg_04aff5mE55Pk9B0WliT5cA4uDUybq9LgxgKEEKzOTQHFp3RW6TBDQQWxBCzaE0WyNj1nGO2ZNdvVIDk5QPHaj0-88bv-1fIdops3gzy0YFdA587kKDOnfjqCGT5tH07o2ZbzPp2ogLo-IkUNV_hYLp7zZvinJj3ve6Q3y-C08H1xJ_sPa3_141AO8lX-B3lTursZ4XXz-VxRDY9bNC0rizKEzPY0e2BJ2P8c1Q15EEdaWzSRzilPovLFGstTYmKjm4Wmf-6H9_Zlsj9Ax0wvu4sn2vlUhZK2qk-yPs4DllsUw"
HTTP/1.1 200 OK
Cache-Control: private
Content-Type: application/json
Granted-Permissions: calendar calendar.readonly calendar.events calendar.events.readonly
Required-Permission: calendar.readonly
Scope: calendar

{"method":"GET","path":"/calendars/"}
```

If we try the `PATCH` method instead with the same token, we get:
```
$ curl -si -X PATCH localhost:8080/calendars/ -H "Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwic2NvcGUiOiJjYWxlbmRhciJ9.J6X4M5dk-ivyi9qpVu5HjGS9CC0J7e_7vReh6xLg_04aff5mE55Pk9B0WliT5cA4uDUybq9LgxgKEEKzOTQHFp3RW6TBDQQWxBCzaE0WyNj1nGO2ZNdvVIDk5QPHaj0-88bv-1fIdops3gzy0YFdA587kKDOnfjqCGT5tH07o2ZbzPp2ogLo-IkUNV_hYLp7zZvinJj3ve6Q3y-C08H1xJ_sPa3_141AO8lX-B3lTursZ4XXz-VxRDY9bNC0rizKEzPY0e2BJ2P8c1Q15EEdaWzSRzilPovLFGstTYmKjm4Wmf-6H9_Zlsj9Ax0wvu4sn2vlUhZK2qk-yPs4DllsUw"
HTTP/1.1 405 Method Not Allowed
Cache-Control: private
Content-Type: application/json
Couper-Error: method not allowed error

{
  "error": {
    "id":      "ca3sbfn56p5nbq9b5bpg",
    "message": "method not allowed error",
    "path":    "/calendars/",
    "status":  405
  }
}
```
and the following log entry:
```
access-control | {...,"handler":"api","level":"error","message":"method not allowed error: method PATCH not allowed by required_permission","method":"PATCH",...
```
This happens because the `PATCH` method is not mentioned in the `required_permission` attribute value (neither explicitly, nor implicitly via `"*"`).

**Note:** The log message gives the indication that this `405` error results from `required_permission` (and not from `allowed_methods`).
