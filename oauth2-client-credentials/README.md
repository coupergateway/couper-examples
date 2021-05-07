# Adding Access Tokens using the OAuth2 Client Credentials Flow

In this example we learn how to configure Couper to automatically request an access token for a third-party API using the OAuth2 client credentials grant.

OAuth2 defines (at least) three parties:
* the resource server providing resources (e.g. an API) protected by access tokens,
* the client requesting the resources,
* and the authorization server providing the access tokens.

Usually, Couper acts as the OAuth2 client.

However, in this example, we use Couper for all three parties.

First, we define two `server` blocks in `couper.hcl`, one for the client:

```hcl
server "client" {
  hosts = ["localhost:8080"]
  api {
    endpoint "/foo" {
      proxy {
        backend {
          origin = "http://localhost:8081"
          path = "/resource"
        }
      }
    }
  }
}
```

and another for the resource server:

```hcl
server "resource-server" {
  hosts = ["localhost:8081"]
  api {
    endpoint "/resource" {
      response {
        json_body = {"foo" = 1}
      }
    }
  }
}
```

We start couper and send a request to the client endpoint:

```sh
$ curl -is localhost:8080/foo
HTTP/1.1 200 OK
Connection: close
Content-Type: application/json
Server: couper.io
Vary: Accept-Encoding
Content-Length: 9
...

{"foo":1}
```

And watch the log:

```json
{"build":"0f62fad","bytes":9,"client_ip":"127.0.0.1","endpoint":"/resource","handler":"api","level":"info","message":"","method":"GET","proto":"HTTP/1.1","realtime":"0.340","request":{"addr":"localhost:8081","headers":{"accept":"*/*","user-agent":"curl/7.67.0"},"host":"localhost","path":"/resource","port":"8081","tls":false},"response":{"bytes":9,"headers":{"content-type":"application/json"}},"scheme":"http","server":"resource-server","status":200,"timestamp":"2021-05-07T14:28:18Z","type":"couper_access","uid":"c2akt0lgt4htpcc2rf10","url":"http://localhost:8081/resource","version":"master"}
{"backend":"default","build":"0f62fad","level":"info","message":"","realtime":"1.803","request":{"addr":"localhost:8081","headers":{"accept":"*/*","user-agent":"curl/7.67.0"},"host":"localhost","method":"GET","name":"default","path":"/foo","port":"8081","proto":"HTTP/1.1","scheme":"http"},"response":{"headers":{"content-type":"application/json"},"proto":"HTTP/1.1","tls":false},"status":200,"timestamp":"2021-05-07T14:28:18Z","timings":{"connect":"0.136","dns":"0.358","ttfb":"0.753"},"type":"couper_backend","uid":"c2akt0lgt4htpcc2rf0g","url":"http://localhost:8081/resource","version":"master"}
{"build":"0f62fad","bytes":9,"client_ip":"172.17.0.1","endpoint":"/foo","handler":"api","level":"info","message":"","method":"GET","proto":"HTTP/1.1","realtime":"2.273","request":{"addr":"localhost:8080","headers":{"accept":"*/*","user-agent":"curl/7.67.0"},"host":"localhost","path":"/foo","port":"8080","tls":false},"response":{"bytes":9,"headers":{"content-type":"application/json"}},"scheme":"http","server":"client","status":200,"timestamp":"2021-05-07T14:28:18Z","type":"couper_access","uid":"c2akt0lgt4htpcc2rf0g","url":"http://localhost:8080/foo","version":"master"}
```

We see three new log entries: the first is the request to the resource server in its access log; the second is the same request in the client's backend log; and the third is the request to the client in its access log.

Now we protect the resource at the resource server API with a `jwt` access control:

```hcl
...
server "resource-server" {
  hosts = ["localhost:8081"]
  api {
    access_control = ["token"]   # protect the resource server's api
    endpoint "/resource" {
      response {
        json_body = {"foo" = 1}
      }
    }
  }
}
definitions {
  jwt "token" {
    signature_algorithm = "HS256"
    key = "$eCr3T"
    header = "Authorization"
  }
}
```

We restart couper and try again the previous request:

```sh
$ curl -is localhost:8080/foo
HTTP/1.1 401 Unauthorized
Content-Type: application/json
Couper-Error: 5000 - "Authorization required"
Server: couper.io
Vary: Accept-Encoding
Content-Length: 164
...

{
  "error": {
    "code":    5000,
    "id":      "c2aktcs3nepbnmh48u9g",
    "message": "Authorization required",
    "path":    "/foo",
    "status":  401
  }
}
```

And watch the log:

```json
{"build":"8d356b3","bytes":169,"client_ip":"127.0.0.1","code":5000,"endpoint":"","level":"error","message":"access control: token: empty token","method":"GET","proto":"HTTP/1.1","realtime":"0.091","request":{"addr":"localhost:8081","headers":{"accept":"*/*","user-agent":"curl/7.67.0"},"host":"localhost","path":"/resource","port":"8081","tls":false},"response":{"bytes":169,"headers":{"content-type":"application/json"}},"scheme":"http","server":"resource-server","status":401,"timestamp":"2021-05-07T14:30:08Z","type":"couper_access","uid":"c2akts1o6onekdf5gdl0","url":"http://localhost:8081/resource","version":"1.1.1"}
{"backend":"default","build":"8d356b3","code":5000,"level":"error","message":"Authorization required","realtime":"3.145","request":{"addr":"localhost:8081","headers":{"accept":"*/*","user-agent":"curl/7.67.0"},"host":"localhost","method":"GET","name":"default","path":"/foo","port":"8081","proto":"HTTP/1.1","scheme":"http"},"response":{"headers":{"content-type":"application/json"},"proto":"HTTP/1.1","tls":false},"status":401,"timestamp":"2021-05-07T14:30:08Z","timings":{"connect":"0.161","dns":"0.931","ttfb":"0.720"},"type":"couper_backend","uid":"c2akts1o6onekdf5gdkg","url":"http://localhost:8081/resource","version":"1.1.1"}
{"build":"8d356b3","bytes":164,"client_ip":"172.17.0.1","code":5000,"endpoint":"/foo","handler":"api","level":"error","message":"Authorization required","method":"GET","proto":"HTTP/1.1","realtime":"4.360","request":{"addr":"localhost:8080","headers":{"accept":"*/*","user-agent":"curl/7.67.0"},"host":"localhost","path":"/foo","port":"8080","tls":false},"response":{"bytes":164,"headers":{"content-type":"application/json"}},"scheme":"http","server":"client","status":401,"timestamp":"2021-05-07T14:30:08Z","type":"couper_access","uid":"c2akts1o6onekdf5gdkg","url":"http://localhost:8080/foo","version":"1.1.1"}
```

In the log we see the problem: There was no token in the request.

We add a third `server` block (the authorization server) using a `jwt_signing_profile` block to `couper.hcl`:

```hcl
server "authorization-server" {
  hosts = ["localhost:8082"]
  endpoint "/token" {
    response {
      json_body = {
        "access_token" = jwt_sign("token", {  })
        "expires_in" = 10
      }
    }
  }
}
...
definitions {
  jwt_signing_profile "token" {
    signature_algorithm = "HS256"
    key = "$eCr3T"
    ttl = "10s"
  }
  ...
```

This creates a simple OAuth2 authorization server with a token endpoint creating a token response with a JWT expiring after 10 seconds. A real authorization server will of course do a lot of checks before creating the response, but we skip that here for simplicity.

Now we reference this token endpoint in an `oauth2` block that we add to the `backend` in the "client" `server` block:

```hcl
...
        backend {
          origin = "http://localhost:8081"
          path = "/resource"
          oauth2 {
            grant_type = "client_credentials"
            token_endpoint = "http://localhost:8082/token"
            client_id = "my-client"
            client_secret = "my-client-secret"
          }
        }
...
```

We restart couper and try again the previous request:

```sh
$ curl -is localhost:8080/foo
HTTP/1.1 200 OK
Connection: close
Content-Type: application/json
Server: couper.io
Vary: Accept-Encoding
Content-Length: 9
...

{"foo":1}
```

If we now look at the logs, we see five new entries:

```json
{"auth_user":"my-client","build":"8d356b3","bytes":140,"client_ip":"127.0.0.1","endpoint":"/token","handler":"endpoint","level":"info","message":"","method":"POST","proto":"HTTP/1.1","realtime":"0.343","request":{"addr":"localhost:8082","headers":{},"host":"localhost","path":"/token","port":"8082","tls":false},"response":{"bytes":140,"headers":{"content-type":"application/json"}},"scheme":"http","server":"authorization-server","status":200,"timestamp":"2021-05-07T14:31:25Z","type":"couper_access","uid":"c2akuffq7cemq8oe2blg","url":"http://localhost:8082/token","version":"1.1.1"}
{"auth_user":"my-client","backend":"default","build":"8d356b3","level":"info","message":"","realtime":"1.782","request":{"addr":"localhost:8082","headers":{},"host":"localhost","method":"POST","name":"default","path":"","port":"8082","proto":"HTTP/1.1","scheme":"http"},"response":{"headers":{"content-type":"application/json"},"proto":"HTTP/1.1","tls":false},"status":200,"timestamp":"2021-05-07T14:31:25Z","timings":{"connect":"0.148","dns":"0.369","ttfb":"0.791"},"token_request":"oauth2","type":"couper_backend","uid":"c2akuffq7cemq8oe2bl0","url":"http://localhost:8082/token","version":"1.1.1"}
{"build":"8d356b3","bytes":9,"client_ip":"127.0.0.1","endpoint":"/resource","handler":"api","level":"info","message":"","method":"GET","proto":"HTTP/1.1","realtime":"0.321","request":{"addr":"localhost:8081","headers":{"accept":"*/*","user-agent":"curl/7.67.0"},"host":"localhost","path":"/resource","port":"8081","tls":false},"response":{"bytes":9,"headers":{"content-type":"application/json"}},"scheme":"http","server":"resource-server","status":200,"timestamp":"2021-05-07T14:31:25Z","type":"couper_access","uid":"c2akuffq7cemq8oe2bm0","url":"http://localhost:8081/resource","version":"1.1.1"}
{"backend":"default","build":"8d356b3","level":"info","message":"","realtime":"1.939","request":{"addr":"localhost:8081","headers":{"accept":"*/*","user-agent":"curl/7.67.0"},"host":"localhost","method":"GET","name":"default","path":"/foo","port":"8081","proto":"HTTP/1.1","scheme":"http"},"response":{"headers":{"content-type":"application/json"},"proto":"HTTP/1.1","tls":false},"status":200,"timestamp":"2021-05-07T14:31:25Z","timings":{"connect":"0.275","dns":"0.510","ttfb":"0.685"},"type":"couper_backend","uid":"c2akuffq7cemq8oe2bl0","url":"http://localhost:8081/resource","version":"1.1.1"}
{"build":"8d356b3","bytes":9,"client_ip":"172.17.0.1","endpoint":"/foo","handler":"api","level":"info","message":"","method":"GET","proto":"HTTP/1.1","realtime":"4.460","request":{"addr":"localhost:8080","headers":{"accept":"*/*","user-agent":"curl/7.67.0"},"host":"localhost","path":"/foo","port":"8080","tls":false},"response":{"bytes":9,"headers":{"content-type":"application/json"}},"scheme":"http","server":"client","status":200,"timestamp":"2021-05-07T14:31:25Z","type":"couper_access","uid":"c2akuffq7cemq8oe2bl0","url":"http://localhost:8080/foo","version":"1.1.1"}
```

The second is in the client's backend log and represents the token request sent by Couper because it had no (valid) token, the first is the token request in the authorization server's access log.

If we retry the request within 10 seconds,

```sh
$ curl -is localhost:8080/foo
HTTP/1.1 200 OK
Content-Type: application/json
Server: couper.io
Vary: Accept-Encoding
Content-Length: 9
...

{"foo":1}
```

we don't see any entries for a token request in the log, because now Couper has a valid token:

```json
{"build":"8d356b3","bytes":9,"client_ip":"127.0.0.1","endpoint":"/resource","handler":"api","level":"info","message":"","method":"GET","proto":"HTTP/1.1","realtime":"0.248","request":{"addr":"localhost:8081","headers":{"accept":"*/*","user-agent":"curl/7.67.0"},"host":"localhost","path":"/resource","port":"8081","tls":false},"response":{"bytes":9,"headers":{"content-type":"application/json"}},"scheme":"http","server":"resource-server","status":200,"timestamp":"2021-05-07T14:31:58Z","type":"couper_access","uid":"c2akunnq7cemq8oe2bog","url":"http://localhost:8081/resource","version":"1.1.1"}
{"backend":"default","build":"8d356b3","level":"info","message":"","realtime":"1.645","request":{"addr":"localhost:8081","headers":{"accept":"*/*","user-agent":"curl/7.67.0"},"host":"localhost","method":"GET","name":"default","path":"/foo","port":"8081","proto":"HTTP/1.1","scheme":"http"},"response":{"headers":{"content-type":"application/json"},"proto":"HTTP/1.1","tls":false},"status":200,"timestamp":"2021-05-07T14:31:58Z","timings":{"connect":"0.363","dns":"0.499","ttfb":"0.467"},"type":"couper_backend","uid":"c2akunnq7cemq8oe2bo0","url":"http://localhost:8081/resource","version":"1.1.1"}
{"build":"8d356b3","bytes":9,"client_ip":"172.17.0.1","endpoint":"/foo","handler":"api","level":"info","message":"","method":"GET","proto":"HTTP/1.1","realtime":"2.043","request":{"addr":"localhost:8080","headers":{"accept":"*/*","user-agent":"curl/7.67.0"},"host":"localhost","path":"/foo","port":"8080","tls":false},"response":{"bytes":9,"headers":{"content-type":"application/json"}},"scheme":"http","server":"client","status":200,"timestamp":"2021-05-07T14:31:58Z","type":"couper_access","uid":"c2akunnq7cemq8oe2bo0","url":"http://localhost:8080/foo","version":"1.1.1"}
```

If we wait for more than 10 seconds, the token is expired and we again see two entries for a new token request:

```json
{"auth_user":"my-client","build":"8d356b3","bytes":140,"client_ip":"127.0.0.1","endpoint":"/token","handler":"endpoint","level":"info","message":"","method":"POST","proto":"HTTP/1.1","realtime":"1.031","request":{"addr":"localhost:8082","headers":{},"host":"localhost","path":"/token","port":"8082","tls":false},"response":{"bytes":140,"headers":{"content-type":"application/json"}},"scheme":"http","server":"authorization-server","status":200,"timestamp":"2021-05-07T14:32:19Z","type":"couper_access","uid":"c2akusvq7cemq8oe2bpg","url":"http://localhost:8082/token","version":"1.1.1"}
{"auth_user":"my-client","backend":"default","build":"8d356b3","level":"info","message":"","realtime":"2.574","request":{"addr":"localhost:8082","headers":{},"host":"localhost","method":"POST","name":"default","path":"","port":"8082","proto":"HTTP/1.1","scheme":"http"},"response":{"headers":{"content-type":"application/json"},"proto":"HTTP/1.1","tls":false},"status":200,"timestamp":"2021-05-07T14:32:19Z","timings":{"connect":"0.282","dns":"0.546","ttfb":"1.361"},"token_request":"oauth2","type":"couper_backend","uid":"c2akusvq7cemq8oe2bp0","url":"http://localhost:8082/token","version":"1.1.1"}
{"build":"8d356b3","bytes":9,"client_ip":"127.0.0.1","endpoint":"/resource","handler":"api","level":"info","message":"","method":"GET","proto":"HTTP/1.1","realtime":"0.552","request":{"addr":"localhost:8081","headers":{"accept":"*/*","user-agent":"curl/7.67.0"},"host":"localhost","path":"/resource","port":"8081","tls":false},"response":{"bytes":9,"headers":{"content-type":"application/json"}},"scheme":"http","server":"resource-server","status":200,"timestamp":"2021-05-07T14:32:19Z","type":"couper_access","uid":"c2akusvq7cemq8oe2bq0","url":"http://localhost:8081/resource","version":"1.1.1"}
{"backend":"default","build":"8d356b3","level":"info","message":"","realtime":"4.419","request":{"addr":"localhost:8081","headers":{"accept":"*/*","user-agent":"curl/7.67.0"},"host":"localhost","method":"GET","name":"default","path":"/foo","port":"8081","proto":"HTTP/1.1","scheme":"http"},"response":{"headers":{"content-type":"application/json"},"proto":"HTTP/1.1","tls":false},"status":200,"timestamp":"2021-05-07T14:32:19Z","timings":{"connect":"0.218","dns":"0.290","ttfb":"3.340"},"type":"couper_backend","uid":"c2akusvq7cemq8oe2bp0","url":"http://localhost:8081/resource","version":"1.1.1"}
{"build":"8d356b3","bytes":9,"client_ip":"172.17.0.1","endpoint":"/foo","handler":"api","level":"info","message":"","method":"GET","proto":"HTTP/1.1","realtime":"7.622","request":{"addr":"localhost:8080","headers":{"accept":"*/*","user-agent":"curl/7.67.0"},"host":"localhost","path":"/foo","port":"8080","tls":false},"response":{"bytes":9,"headers":{"content-type":"application/json"}},"scheme":"http","server":"client","status":200,"timestamp":"2021-05-07T14:32:19Z","type":"couper_access","uid":"c2akusvq7cemq8oe2bp0","url":"http://localhost:8080/foo","version":"1.1.1"}
```

In a real-world setting, just use the `oauth2` block specifying `grant_type = "client_credentials"`, `token_endpoint`, `client_id` and `client_secret` in a backend for a third-party API that needs a token available via the client credentials flow.

By default, Couper uses basic authentication to authenticate itself at the authorization server (`token_endpoint_auth_method = "client_secret_basic"`). In some settings authorization servers require the client credentials to be sent as form parameters in the POST request body. This can be achieved by configuring the `oauth2` block accordingly:

```hcl
token_endpoint_auth_method = "client_secret_post"
```

We can also specify the scope of the requested access token by setting the `scope` attribute in the `oauth2` block:

```hcl
scope = "foo bar"
```

See also:

* [OAuth2 Block](https://github.com/avenga/couper/tree/master/docs/README.md#oauth2-block) (reference)
* [JWT Block](https://github.com/avenga/couper/tree/master/docs/README.md#jwt-block) (reference)
* [JWT Signing Profile Block](https://github.com/avenga/couper/tree/master/docs/README.md#jwt-signing-profile-block) (reference)
* [jwt_sign() Function](https://github.com/avenga/couper/tree/master/docs/README.md#functions) (reference)
