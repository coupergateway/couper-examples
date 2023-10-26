# Linking Docker Containers

Developers might want to run the backend and Couper both in
containers on their computer. Be aware that `localhost` in a Docker
container is not the same thing as `localhost` on your host computer.

Use `docker run --link` parameter to allow Couper to reach the
backend in your other container. In this case you can simply make up
a hostname. But as the containers are then
talking directly to each other, you have to use the internal service
ports.

Let's start a local instance of `httpbin` in a container. It needs a
name to be linkable:

```sh
docker run --rm --name httpbin kennethreitz/httpbin
```

Note, that we don't need to exported a port (`-p`) here.

Now this command starts Couper linked to our local `httpbin` container:

```sh
docker run --rm \
-p 8080:8080 \
-v "$(pwd)":/conf \
--link httpbin:httpbin \
-e BACKEND_ORIGIN=http://httpbin:80 \
coupergateway/couper
```

Docker automatically sets some environment variables for linked
containers. With that in mind we could omit defining our own
environment variable (`BACKEND_ORIGIN`) and rely on Docker's instead:

```hcl
…
  endpoint "/example/**" {
    proxy {
      backend {
        origin = "http://${env.HTTPBIN_PORT_80_TCP_ADDR}:80"
      }
    }
  }
…
```

This is also an example for the handy variable substitutions in
strings. We can use variables enclosed in curly brackets to insert
dynamic data into a string.

## Linking containers with `docker-compose`

Please have a look at the [docker-compose example](../docker-compose) to see how you can link containers with `docker-compose`.
