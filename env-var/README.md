# Environment Variables

Oftentimes the address of the upstream service to use depends on the
environment/stage of the setup. For example, in a testing environment
the backend may run locally, e.g. at `http://backend:9000`. Whereas in a
production environment the same service runs at
`https://httpbin.org`. Of course, we don't want to have different
Couper configurations for every environment – that would be error
prone.

A widely used approach is making the settings that actually differ
configurable with environment variables.

We have a basic Couper configuration that defines an upstream backend service and "mounts" it on local API endpoints.

[`couper.hcl`](couper.hcl):

```hcl
server "my-api" {
  api {
    endpoint "/example/**" {
      path = "/**"
      proxy {
        backend {
          origin = "https://httpbin.org"
        }
      }
    }
  }
}
```

To configure the actual origin of our service, we decide to use the following environment variable:

```sh
HTTPBIN_ORIGIN=https://httpbin.org
```

Now we change the Couper configuration to read the origin host from that variable:

```hcl
…
  endpoint "/example/**" {
    proxy {
      backend {
        origin = env.HTTPBIN_ORIGIN
      }
    }
  }
…
```

There are numerous ways to inject environment variables into docker. We can set them in our `docker-compose.yaml`, define them in our Kubernetes `Deployment`, read them from a `ConfigMap` or pass them as command line arguments when starting the container.

[`docker-compose.yml`](docker-compose.yml):

```yml
    environment:
      - HTTPBIN_ORIGIN=https://httpbin.org
```

Docker command:

```sh
docker run --rm \
-p 8080:8080 \
-v "$(pwd)":/conf \
-e HTTPBIN_ORIGIN=https://httpbin.org \
avenga/couper
```
