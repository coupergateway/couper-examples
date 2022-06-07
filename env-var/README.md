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
server {
  api {
    endpoint "/example/**" {
      proxy {
        backend {
          origin = "https://httpbin.org"
          path = "/**"
        }
      }
    }
  }
}
```

To configure the actual origin of our service, we decide to use the following environment variable:

```sh
BACKEND_ORIGIN=https://httpbin.org
```

Now we change the Couper configuration to read the origin host from that variable:

```hcl
server {
  api {
    endpoint "/example/**" {
      proxy {
        backend {
          origin = env.BACKEND_ORIGIN
          path = "/**"
        }
      }
    }
  }
}
```

There are numerous ways to inject environment variables into docker. We can set them in our `docker-compose.yaml`, define them in our Kubernetes `Deployment`, read them from a `ConfigMap` or pass them as command line arguments when starting the container.

[`docker-compose.yml`](docker-compose.yml):

```yml
    environment:
      - BACKEND_ORIGIN=https://httpbin.org
```

Docker command:

```sh
docker run --rm \
-p 8080:8080 \
-v "$(pwd)":/conf \
-e BACKEND_ORIGIN=https://httpbin.org \
avenga/couper
```

The [`environment_variables` map](https://github.com/avenga/couper/blob/master/docs/REFERENCE.md#defaults-block) in the `defaults` block allows us to define default values as fallback for missing environment variables:

```hcl
//...

defaults {
  environment_variables = {
    //use local backend as fallback
    BACKEND_ORIGIN = "http://backend:9000"
  }
}
```
