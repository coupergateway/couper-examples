# Backend Validation

This type of validation is meant to work with upstream api endpoints. The basic use-case is to prevent invalid requests
and responses between Couper and its backend origin respectively. This could be a requirement of the origin api or yourself.

## Configuration

To enable the validation we must provide an `openapi` block within a `backend` block which refers to the related OpenAPI yaml file.
There are additional options which are described further in our [documentation](https://github.com/avenga/couper/tree/master/docs#openapi_block).

A simple backend configuration with validation looks like this:

```hcl
backend "validated-origin" {
    origin = "https://httpbin.org"
    openapi {
      file = "openapi.yaml"
    }
}
```

Since that's only half the story, a valid OpenAPI schema file is required (`openapi.yaml`):

```yaml
openapi: 3.0.1
info:
  title: 'Couper example api'
  version: '0.3'
paths:
  /anything:
    get:
      responses:
        200:
          description: OK
```

Now we can define an api endpoint on `/validate` for example which validates the backend origin request with the path
`/anything`. That's the thing here, `/validate` is the client path while accessing Couper's endpoint where the backend
replaces to the configured `/anything` path and this resulting request gets validated before Couper sends out the
modified request. Here is the related configuration:

```hcl
server "my-api" {
  api {
    backend = "validated-origin"

    endpoint "/validate" {
      path = "/anything"
    }
  }
}

definitions {
  backend "validated-origin" {
    origin = "https://httpbin.org"
    openapi {
      file = "openapi.yaml"
    }
  }
}
```

That's basically all, but we could refine the configuration to trigger a validation error. Let's add a requirement for
a specific query parameter `show_env <string>` (`openapi_refined.yaml`): 

```yaml
openapi: 3.0.1
info:
  title: 'Couper example api'
  version: '0.3'
paths:
  /anything:
    get:
      parameters:
      - in: query
        name: show_env
        schema:
          type: string
        required: true
      responses:
        200:
          description: OK
```

The result should be a status-code 400 if you are accessing [localhost:8080/validate](http://localhost:8080/validate) and the related log
entry should look like this: `request validation: Parameter 'show_env' in query has an error: must have a value`.
Providing the required query param results in an OK response: [http://localhost:8080/validate?show_env=true](http://localhost:8080/validate?show_env=true).

If you have any questions or feedback you are welcome to start a [discussion](https://github.com/avenga/couper/discussions).
