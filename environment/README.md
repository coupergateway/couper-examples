# Environment

Usually a Couper configuration is supposed to run in different environments with
oftentimes some slight changes. For example, we might have a
protected "prod" setup which requires a valid JWT token to be accessed, a "test"
setup which is secured by Basic Authentication and
a "devel" setup which is open to use.

To achieve this, we could wrap parts of the configuration intended for a specific
environment in corresponding `environment` blocks:

```hcl
server {
  environment "prod" {
    # production only
    access_control = ["token"]
  }
  environment "test" {
    # test only
    access_control = ["credentials"]
  }

  api {
    endpoint "/" {
      proxy {
        backend = "backend"
      }
    }
  }
}

definitions {
  backend "backend" { … }
  jwt "token" { … }
  basic_auth "credentials" { … }
}

settings {
  environment "prod" {
    # enable metrics on production only
    beta_metrics = true
  }

  # the default environment is "devel"
  environment = "devel"
}
```

With that configuration only the blocks and attributes within the enabled
environment will become active. When we new start Couper…

```sh
$ docker-compose pull && docker-compose up

```

… we can access `http://localhost:8080/` directly without error as the
environment is set to `devel` in the `settings` block
and all `access_control` attributes therefore have been disabled.

Let's now change that setting to `"test"`

```hcl
settings {
  …
  # the default environment is "test"
  environment = "test"
}
```

which activated the `access_control = ["credentials"]` attribute as we are
now in the `test` environment. We request `http://localhost:8080/` again and
in the log we get

```json
{… "error_type":"basic_auth_credentials_missing",… "message":"access control error: credentials: credentials required", …}
```

Finally, if we set the `environment` to `prod`…

```hcl
settings {
  …
  # the default environment is "prod"
  environment = "prod"
}
```

… and reissue the request, Couper now wants us to authenticate with a token:

```json
{… "error_type":"jwt_token_missing",… "message":"access control error: token: token required", …}
```

Nice!

Changing the default `environment` from `devel` to `test` and then `prod` was just for demonstration.
Like all other settings, `environment` has a corresponding environment variable
named `COUPER_ENVIRONMENT`. So generally the way to go is to set environment
variable, for example in the `docker-compose.yaml`:

```yaml
services:
  gateway:
    …
    environment:
      COUPER_WATCH: "true"
      COUPER_ENVIRONMENT: "prod" # "devel", "test" or "prod"
```

or on the command line:

```sh
$ COUPER_ENVIRONMENT="test" couper run
INFO[0000] couper uses "test" environment …
…
```

We could also use the `-e` option instead:

```sh
$ couper run -e prod
INFO[0000] couper uses "prod" environment …
…
```

It is pretty convenient to have a specific `/info` endpoint providing information about the system.
We can get the environment Couper currently runs in with the `couper.environment` variable:

```hcl
    endpoint "/info" {
      response {
        json_body = {
          version = couper.version
          environment = couper.environment
        }
      }
    }
```

```sh
$ curl localhost:8080/info
{"environment":"devel","version":"edge"}
```

To break down things better, let's finally split the configuration into multiple files:
Let's move all parts needed for production to `couper.prod.hcl`:

```hcl
environment "prod" {
  server {
    access_control = ["token"]
  }

  definitions {
    jwt "token" { … }
  }

  settings {
    beta_metrics = true
  }
}
```

All the parts specific for testing go into `couper.test.hcl`:

```hcl
environment "test" {
  server {
    access_control = ["credentials"]
  }

  definitions {
    basic_auth "credentials" { … }
  }
}
```

The remainder of the configuration stays in `couper.hcl`:

```hcl
server {
  api {
    endpoint "/" {
      proxy {
        backend = "backend"
      }
    }
  }
}

definitions {
  backend "backend" { … }
}

settings {
  environment = "devel"
}
```
