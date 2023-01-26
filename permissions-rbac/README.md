# Permissions (Role-based Access Control)

**Note:** This is currently a [_beta_ feature](https://github.com/avenga/couper/blob/master/docs/BETA.md).

This example is an extension of the [Permissions example](../permissions/README.md).

In some cases the granted permissions (also called privileges) can be derived from user roles: access to a certain API endpoint is granted if the user represented by the requesting party has a certain role. This is called role-based access control (RBAC).

In Couper, RBAC is configured using two attributes of the `jwt` access control block: `roles_claim` specifying the claim containing the user's roles, and 
`roles_map` specifying a role-permissions map.

Similar to the `permissions_claim`, Couper expects the roles as a string containing a space-separated list, or an array of strings, like this:
```json
{
  # ...
  "roles": "role1 role2",
  # ...
}
```
or
```json
{
  # ...
  "roles": ["role1", "role2"],
  # ...
}
```

The `roles_map` attribute maps a role to a set of granted permissions. The `"*"` key means all other roles, or no role at all.

So instead of the `permissions_claim` attribute, we set the `roles_claim` and `roles_map` attributes:
```hcl
  jwt "Token" {
    signature_algorithm = "RS256"
    key_file = "pub-key.pem"
    roles_claim = "roles"    # ←
    roles_map = {            # ←
      admin = ["a", "b:send", "b:copy", "c", "c:del"]
      developer = ["a", "b:send", "b:copy", "c"]
      "*" = ["a"]
    }
  }
```

**Note:** If our roles map is quite big, or we would like to create one in some build process, we could reference it using `roles_map_file = "roles.json"` instead of `roles_map`. The format of the JSON file is very similar to the `roles_map` value, here:
```json
{
  "admin": ["a", "b:send", "b:copy", "c", "c:del"],
  "developer": ["a", "b:send", "b:copy", "c"],
  "*": ["a"]
}
```


Now we can try accessing the endpoints by using one of the tokens below (replace `<token>` with one of the tokens):
```
$ curl -si http://localhost:8080/a -H "Authorization: Bearer <token>"
```
* admin role:
  ```
  eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwicm9sZXMiOiJhZG1pbiJ9.QUss5qdBsh60pZOpMcMG5e92fJtAyhwGO78NiHw7sZkWKPF_9zyKO1o2b-EcoCmzIod8bFvqtalLGlS1kTIgXh3oKHdqx2Rxy6BxrK1UtZ0K4K3htKLt2kSAWVw3gT5Voas4bGclfJY-gDmcKgRGltU9rwET57ZA5e9QJVxl6NVrnm2yX2k4a6fOD0s5BDMe9S7jhDS-eCl2uz7IWOqd6MQJH_pDeknX--au6LbttdaGsckIara_o2XbEpeAnyMdzgV2SXejNUHhwRIiFGok2ZkvcLAUh4IeTRes6NvghZeh886BuiNWyeMB-3nyxqqNn8hFYvTzJ_1nRRcA0HCzLA
  ```
* developer role:
  ```
  eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwicm9sZXMiOiJkZXZlbG9wZXIifQ.b4BvZH9uUGIZrty8oHAiLOwzFS5j_c6V3_Tt16Y3tJ76Lu4pLZUeQmiiiSZD1fDE2N1mSNMBPY7BOjo69U0C56LXsTB7tfJ76_oZyIzdKs2T9k7a_Gn18nHysRHuuKdI7TloNL18cior0coiyN0k_CGjEpJ3cdWbrfTia-tfsSlMGXgDNQR5hQCqXUXUOC5ELs14d-4NZjyass-fjOckhr4qt-mo5zUryGX2tbv4nXEUtDbgT5ub0xjmc8RhfdSzV_niManiuhOQU_pOwsxkgvheyZiNMMr8H-yn_-DMxwxRdB_0UBRtE07Kzc2nMPyTAnEezZ35_A6MTo3cwDcP4w
  ```
* no role:
  ```
  eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dw1oz77jAV2AUdIv7MAiarGl1EmVM8HGJUPxCaC5GUyD6VLp3c8K58fbgOPnslpgDf8wmgiwr2KzgPPNXCX5ebxz3b_q-09fHirXn_8fhUV2GAbcvgW9aCL8LxmUH-zLbyBYWcdc-GGFucOVNCB7uP-nWHgjim7BLiyUn1XwRuJhZTaZtMGnAgZ8oTw83yznLFdjpZBD9NUGE_m_FlGT_7559ixUk1jQVPkDjRZldQWwjSSzHVwLpQXHgCoHhWhRykmTgyg8KERtwywvBJikQABOEYw592uP2cWl023g3reZu8xl-17ojSFUplz2J4zqMhqZptP3z7kpe0C_SQQlNw
  ```

Requesting the `/c` endpoint with the `POST` method with a token containing only the developer role, is successful:
```
$ curl -si -X POST localhost:8080/c -H "Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwicm9sZXMiOiJkZXZlbG9wZXIifQ.b4BvZH9uUGIZrty8oHAiLOwzFS5j_c6V3_Tt16Y3tJ76Lu4pLZUeQmiiiSZD1fDE2N1mSNMBPY7BOjo69U0C56LXsTB7tfJ76_oZyIzdKs2T9k7a_Gn18nHysRHuuKdI7TloNL18cior0coiyN0k_CGjEpJ3cdWbrfTia-tfsSlMGXgDNQR5hQCqXUXUOC5ELs14d-4NZjyass-fjOckhr4qt-mo5zUryGX2tbv4nXEUtDbgT5ub0xjmc8RhfdSzV_niManiuhOQU_pOwsxkgvheyZiNMMr8H-yn_-DMxwxRdB_0UBRtE07Kzc2nMPyTAnEezZ35_A6MTo3cwDcP4w"
HTTP/1.1 200 OK
Cache-Control: private
Content-Type: application/json
Granted-Permissions: a b:send b:copy c
Required-Permission: c

{"method":"POST","path":"/c"}
```

Using the `DELETE` method with the same token, however, results in an error:
```
$ curl -si -X DELETE localhost:8080/c -H "Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwicm9sZXMiOiJkZXZlbG9wZXIifQ.b4BvZH9uUGIZrty8oHAiLOwzFS5j_c6V3_Tt16Y3tJ76Lu4pLZUeQmiiiSZD1fDE2N1mSNMBPY7BOjo69U0C56LXsTB7tfJ76_oZyIzdKs2T9k7a_Gn18nHysRHuuKdI7TloNL18cior0coiyN0k_CGjEpJ3cdWbrfTia-tfsSlMGXgDNQR5hQCqXUXUOC5ELs14d-4NZjyass-fjOckhr4qt-mo5zUryGX2tbv4nXEUtDbgT5ub0xjmc8RhfdSzV_niManiuhOQU_pOwsxkgvheyZiNMMr8H-yn_-DMxwxRdB_0UBRtE07Kzc2nMPyTAnEezZ35_A6MTo3cwDcP4w"
HTTP/1.1 403 Forbidden
Cache-Control: private
Content-Type: application/json
Couper-Error: access control error

{
  "error": {
    "id":      "ca3qr3g318lam7ed86r0",
    "message": "access control error",
    "path":    "/c",
    "status":  403
  }
}
```
In the log we see an entry like this:
```
access-control | {...,"error_type":"insufficient_permissions","handler":"api","level":"error","message":"access control error: required permission \"c:del\" not granted","method":"DELETE",...
```
