# Environment

Usually, a Couper configuration is supposed to run in different environments with
oftentimes some slight changes. For example, we might have a
protected "prod" setup which requires a valid JWT token for access,
a "test" setup which is secured by Basic Authentication and
a "devel" setup which is open to use.

To neatly implement the above setup, we could wrap the parts of the configuration intended for a specific
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
  jwt "token" { … }               # for production
  basic_auth "credentials" { … }  # for test
}

settings {
  environment "prod" {
    # enable metrics on production only
    beta_metrics = true
  }

  # set "devel" as default environment
  environment = "devel"
}
```

When we start Couper with that configuration…

```sh
$ docker-compose pull && docker-compose up

```

… only the blocks and attributes within the default
environment (`devel`) will become active.
Therefore, all `access_control` attributes will be disabled so
that we are allowed to access `http://localhost:8080/` directly
without authentication.

What happens if we change the default environment to `"test"`?

```hcl
settings {
  # …
  # set "test" as default environment
  environment = "test"
}
```

This activates the `access_control = ["credentials"]` attribute
of the `server` block. When we now request `http://localhost:8080/` again, we get in the log…

```json
{… "error_type":"basic_auth_credentials_missing",… "message":"access control error: credentials: credentials required", …}
```

… which means that we have to provide a username and password to gain access.

Finally, if we set the `environment` to `prod`…

```hcl
settings {
  # …
  # set "prod" as default environment
  environment = "prod"
}
```

… the `access_control = ["token"]` attribute becomes active.
When we now reissue the request, Couper wants us to authenticate with a token:

```json
{… "error_type":"jwt_token_missing",… "message":"access control error: token: token required", …}
```

Nice!

Setting the environment by changing the default `environment` from `devel` to `test` and then to `prod` was just for demonstration.
Like all other Couper settings, `environment` comes with a corresponding environment variable
named `COUPER_ENVIRONMENT`. So generally the way to go is to use that variable to set the environment, for example in the `docker-compose.yaml`…

```yaml
services:
  gateway:
    # …
    environment:
      COUPER_WATCH: "true"
      COUPER_ENVIRONMENT: "prod" # "devel", "test" or "prod"
```

… or on the command line:

```sh
$ COUPER_ENVIRONMENT=test couper run
INFO[0000] couper uses "test" environment …
…
```

There's also a command line option `-e` for that:

```sh
$ couper run -e test
INFO[0000] couper uses "test" environment …
…
```

## `couper.environment`

It is pretty convenient to have a specific `/info` endpoint providing information about the current setup. So let's create one!

The environment Couper currently runs in can be read from the `couper.environment` variable:

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

Requesting that endpoint in den `devel` environment provides:

```sh
$ curl localhost:8080/info
{"environment":"devel","version":"1.10.0"}
```

## Multiple Configuration Files

To break down things better, let's finally split up the configuration into multiple files.
We move all parts of the configuration needed for production to `prod.hcl` in the `conf.new` directory:

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

Next, we put all the parts specific for testing into `conf.new/test.hcl`:

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

The remainder of the configuration finally goes into `conf.new/couper.hcl`:

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

At startup, we provide Couper with all those files and, of course, the environment.

On the command line we therefore add a `-d` option to specify the configuration directory.
Setting the log level to `debug` makes us see which files are loaded:

```sh
$ couper run -d conf.new -log-level=debug -e test
DEBU[0000] loaded files … files="[…/conf.new/couper.hcl …/conf.new/prod.hcl …/conf.new/test.hcl]" …
```

> 💡 The files in the configuration directory are loaded in lexicographical order.
> Blocks defined in files loaded later are merged into blocks loaded earlier.
> and might also override some settings.

Instead of `-d` we could also use multiple `-f` options to specify the configuration files one by one:

```sh
$ couper run -f conf.new/couper.hcl -f conf.new/prod.hcl -f conf.new/test.hcl -log-level=debug -e test
DEBU[0000] loaded files … files="[…/conf.new/couper.hcl …/conf.new/prod.hcl …/conf.new/test.hcl]" …
```

In the Docker setup the configuration is read from the *container's* `/conf`
directory, so we could simply change the volume mapping in the `docker-compose.yaml` and restart the service:

```yaml
services:
  gateway:
    # …
    volumes:
      - ./conf.new:/conf # map ./conf.new → /conf for multi file configuration
    environment:
      …
```

```sh
$ docker-compose up
…
gateway    | {… "couper uses \"prod\" environment",…}
…
gateway    | {… "files":["/conf/couper.hcl","/conf/prod.hcl","/conf/test.hcl"],… "loaded files"}
```

## Conclusion

In this example we've learned how to make use of Couper's `environment` features to
prepare a configuration to run in different environments and how to
read the configuration from multiple files or directories.
