# Backend Validation

This type of validation is meant to work with upstream API endpoints. The basic use-case is to prevent invalid requests
and responses between Couper and its backend origin respectively. This could be a requirement of the origin API or yourself.
Couper uses the [OpenAPI 3 standard](https://www.openapis.org/) to load the definitions from a given document.

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

Here is the full Couper configuration:

```hcl
server "my-api" {
  api {
    endpoint "/validate" {
      backend {
        origin = "https://httpbin.org"
        path = "/anything"
        openapi {
          file = "openapi.yaml"
        }
      }
    }
  }
}
```

That's basically all, and a call to [localhost:8080/validate](http://localhost:8080/validate) will give you a response with status `200` (OK).
We could refine the configuration to trigger a validation error. Let's add a requirement for
a specific `string` query parameter named `show_env` (`openapi_refined.yaml`): 

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

The result should have status code `400` if you are accessing [localhost:8080/validate](http://localhost:8080/validate) and the related log
entry should look like this:

```
request validation: Parameter 'show_env' in query has an error: must have a value
```

Providing the required query parameter will fix the request: [http://localhost:8080/validate?show_env=true](http://localhost:8080/validate?show_env=true).

You should see a json object from the previous response which we will validate partially with the following addition to the openapi file:

```yaml
responses:
  200:
    description: OK
    content:
      application/json:
        schema:
          type: object
          properties:
            url:
              type: string
              description: 'upstream url'
          required:
            - url
```

Now the upstream payload must contain a json object with a `url` property. To try out just add some properties and/or edit the `required` list.
