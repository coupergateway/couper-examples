# Proxy API Requests

Most modern Web applications use APIs to get information for display, to
trigger actions or to check if a user is authorized to see or do
stuff. Those APIs may be part of your application (i.e. you have
written it) or a third-party service running elsewhere. Wherever they
run – our favorite spot for them is behind Couper :)

Let's create a Couper configuration that exposes two backend services
in a consolidated API for the client.

## Configuration

A basic gateway configuration defines upstream backend services and
"mounts" them on local API endpoints:

[`couper.hcl`](couper.hcl):

```hcl
server "my-api" {

  api {
    endpoint "/example/**" {
      path = "/**"
      backend {
        origin = "https://httpbin.org"
      }
    }
  }
  
}
```

## Routing

So what happens when you request `localhost:8080/example`?

The `api` block is implicitly mounted on `/` on the exposed server
(if no `base_path` is given). Therefore `/example` is matched against
the defined `endpoint` configurations. We only have one here, that
uses the "catch-all" operator `/**`. This means that our `endpoint`
handles `/example` (yes, without the trailing `/`), `/example/` and
every possible sub-path of it, such as `/example/user/login`.

The endpoint defines a `backend` to proxy requests to. The only
mandatory information is the `origin` attribute: Where should Couper
connect to? This could be a local application (e.g. running in the same
Kubernetes namespace), or some remote service. We can define a lot of
HTTP related settings here.

## Path Mapping

We have decided to mount `httpbin.org` onto the `/example` path. But
the origin doesn't know about that path. Its endpoints live under
`/` (e.g. `/headers`). We need to remove our local path prefix and adapt it to
the backend base prefix.

The `path` property does just that. Everything that was matched by
the `/**` operator of our endpoint is added to the new path where we
use the operator again. `/example/anything` becomes
`https://httpbin.org/anything` in the backend request.

## Try it out

[Start a Couper container](/README.md#getting-started) and play with the [httpbin endpoints](https://httpbin.org/):

```
$ curl 'localhost:8080/example/anything?a=b'
{
  "args": {
    "a": "b"
  }, 
  "data": "", 
  "files": {}, 
  "form": {}, 
  "headers": {
    "Accept": "*/*", 
    "Accept-Encoding": "gzip", 
    "Host": "httpbin.org", 
    "User-Agent": "curl/7.64.1", 
    "X-Amzn-Trace-Id": "Root=1-5f4b851f-23dfa24d1f3fd4cf142a7fe3"
  }, 
  "json": null, 
  "method": "GET", 
  "url": "https://httpbin.org/anything?a=b"
}
```

Notice how host and path in the `curl` command differ from the `url` in the response JSON.


## Environment Variables

Oftentimes the address of the upstream service to use depends on the
environment/stage of the setup. For example, in a testing environment
the backend may run locally, e.g. at `http://backend:9000`. Whereas in a
production environment the same service runs at
`https://httpbin.org`. Of course, we don't want to have different
Couper configurations for every environment – that would be error
prone.

A widely used approach is making the settings that actually differ
configurable with environment variables.

To configure the actual origin of our service, we decide to use the following environment variable:

```
BACKEND_ORIGIN=https://httpbin.org
```

Now we can change the Couper configuration to read the origin host from that variable:

```hcl
…
  endpoint "/example/**" {
    backend {
      origin = env.BACKEND_ORIGIN
    }
  }
…
```

There are numerous ways to inject environment variables into docker.
You can set them in your `docker-compose.yaml`, define them in your
Kubernetes `Deployment` or read them from a `ConfigMap`.
Or you simply pass them as command line arguments when starting the container:

```sh
$ docker run --rm \
-p 8080:8080 \
-v "$(pwd)":/conf \
-e BACKEND_ORIGIN=https://httpbin.org \
avenga/couper
```

## Linking Docker Containers

Be aware that `localhost` in a Docker container is not the same thing
as `localhost` on your host computer. If both Couper and httpbin are
running in containers, you should `--link` one to the other. In that
case you can simply make up a hostname. But as the containers are then
talking directly to each other, you have to use the internal service
ports.

Let's start a local instance of `httpbin` running at
`http://localhost:3000`. It needs a name to be linkable.

```
$ docker run --rm --name httpbin kennethreitz/httpbin
```

Note, that we don't need to exported a port (`-p`) here.

Now this command starts Couper linked to our local `httpbin` container:

```sh
$ docker run --rm \
-p 8080:8080 \
-v "$(pwd)":/conf \
--link httpbin:httpbin \
-e BACKEND_ORIGIN=http://httpbin:80 \
avenga/couper
```

Docker automatically sets some environment variables for linked
containers. With that in mind we could omit defining our own
environment variable (`BACKEND_ORIGIN`) and rely on Docker's instead:

```hcl
…
  endpoint "/example/**" {
    backend {
      origin = "http://${env.HTTPBIN_PORT_80_TCP_ADDR}:80"
    }
  }
…
```

This is also an example for the handy variable substitutions in
strings. We can use variables enclosed in curly brackets to insert
dynamic data into a string.
