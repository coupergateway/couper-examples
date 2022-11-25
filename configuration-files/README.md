* [Configuration files](#configuration-files)
  * [Split by topic](#split-by-topic)
    * [The base](#the-base)
    * [API](#api)
    * [Result](#result)
  * [Different Access-Control](#different-access-control)
    * [Base](#base)
    * [Dockerfile](#dockerfile)
    * [Stage environment file](#stage-environment-file)
    * [Production environment file](#production-environment-file)

# Configuration files

Couper gets configured by a [configuration file](https://github.com/avenga/couper/tree/master/docs#configuration-file) and
as of the [1.9 release](https://github.com/avenga/couper/releases/tag/v1.9.0) Couper has an option to handle multiple
configuration files and configuration directories. Both can be passed as arguments and will be processed in order.

This enables you to split up a Couper configuration by content or even by environment. This is solved by [merging](https://github.com/avenga/couper/blob/master/docs/MERGE.md) the top-level
declarations and replacing nested ones. Details are explained in our [merge documentation](https://github.com/avenga/couper/blob/master/docs/MERGE.md).

## Split by topic

Let's say we have some API endpoints which could be extracted out of a base configuration which just describes basics
like files, SPA serving or default environment variables.

### The base

We start with a simple SPA configuration and some file serving:

```hcl
server {
  files {
    document_root = "/htdocs"
  }

  spa {
    bootstrap_file = "/htdocs/index.html"
    paths = ["/", "/app"]
  }

  set_response_headers = {
    x-service = env.SERVICE_NAME
  }
}

defaults {
  environment_variables = {
    SERVICE_NAME = "example"
  }
}
```

### API

The API part describes a service and the related environment default values for e.g. local development:

```hcl
server {
    api "serviceA" {
        base_path = "/api/v1/service-a"
        endpoint "/**" {
            proxy {
                url = "http://${env.SERVICE_A_ORIGIN}/"
            }
        }
    }
}

defaults {
    environment_variables = {
        SERVICE_A_ORIGIN = "http://localhost:8080"
        SERVICE_NAME = "service-a"
    }
}
```

#### Environment Variables

The `environment_variables` map within the `defaults` block is handled differently during the merge process: Its values
are merged by their key instead of replacing the whole map. This allows to override or add specific environment defaults.

### Result

The following configuration would be the one Couper will finally load if we provide the directory with these two files.

The Couper container basically runs already with the argument `-d /conf` inside the container which enables us to just mount
our `./conf-a` directory to `/conf`. Also, the Couper welcome page already exists within `/htdocs`.

```shell
docker run --pull -v ${PWD}/conf-a:/conf -p 8080:8080 avenga/couper
```

```hcl
server {
  files {
    document_root = "/htdocs"
  }

  spa {
    bootstrap_file = "/htdocs/index.html"
  }

  set_response_headers = {
    x-service = env.SERVICE_NAME
  }

  api "serviceA" {
    base_path = "/api/v1/service-a"
    endpoint "/**" {
      proxy {
        url = "http://${env.SERVICE_A_ORIGIN}/"
      }
    }
  }
}

defaults {
  environment_variables = {
    SERVICE_A_ORIGIN = "localhost:8080"
    SERVICE_NAME = "service-a"
  }
}
```

We can verify the running configuration with calls to `/`, `/app` or `/api/v1/service-a` endpoints:

```shell
curl -i http://localhost:8080/api/v1/service-a

# output
# HTTP/1.1 200 OK
# Couper-Request-Id: c9haiurm8vfs73bi7ku0
# Server: couper.io
# X-Service: service-a
```

The `SERVICE_NAME` environment value `example` got also replaced with `service-a`.

## Different Access-Control

Another possible case would be an access-control which may differ between a stage and production environment due to their complexity.
Let's use this case to tailor a possible configuration setup.

Basically we will have some base configuration again. This can be a single file or a directory. To keep things simple, we will add all environment related configuration files during the container build process. If you want to ship a specific environment-based configuration file this conditional must be solved by your continuous-integration setup. If you have any questions, feel free
to open a [discussion](https://github.com/avenga/couper/discussions).

### Base

We simply want to protect our file server. It's recommended to protect even your base with an unrealizable
`access_control` since the related CI job could not work properly which may result in an unprotected production environment.
This is the reason why we will reference an undefined access-control. Couper won't start up in this case, and you may get
instant feedback from your deployment jobs.

For development purposes you could add a configuration file with an empty `access_control` list to negate the `undefined` reference.

```hcl
server {
  access_control = ["undefined"]
  files {
    document_root = "/htdocs"
  }
}
```

### Dockerfile

```Dockerfile
FROM avenga/couper:latest

# copy base configuration
COPY *.hcl /conf/

# Switch to -f argument instead of -d
CMD [ "run", "-f", "/conf/couper.hcl" ]
```

So building the container with:

```shell
docker build -t couper-env-example -f Dockerfile .
```

and run:

```shell
docker run -p 8080:8080 couper-env-example

# output:
# {"level":"error","message":"accessControl is not defined: undefined"}
```

results in our expected error.

### Stage environment file

So let's build the image again and this time add the `stage.hcl` to the build process:

```hcl
server {
  access_control = ["stage-ba"]
}

definitions {
  basic_auth "stage-ba" {
    password = env.STAGE_BA_PASSWD
  }
}

defaults {
  environment_variables = {
    STAGE_BA_PASSWD = "test"
  }
}
```

```shell
docker build -t couper-env-example -f Dockerfile .
```

Now we will run our image again and just combine the base (`couper.hcl`) with our `stage.hcl` file:

```shell
docker run -p 8080:8080 couper-env-example run -f /conf/couper.hcl -f /conf/stage.hcl
```

Just visit [http://localhost:8080/](http://localhost:8080/) in your browser, so you will see a basic-auth prompt.
Your Stage environment is protected now. Enter `test` as value into the password field, and you will see the Couper welcome page.

### Production environment file

The advantage to switch to a complete other `access_control` mechanism could be very handy if you have to use a specific SSO or other provider
to handle the permissions.

In this example, we keep it simpler and just switch from a very simple `basic_auth` to a slightly more sophisticated one using `htpasswd_file` instead of just a `password`.

```hcl
server {
  access_control = ["production-ba"]
}

definitions {
  basic_auth "production-ba" {
    htpasswd_file = ".htpasswd"
  }
}
```

Currently, there are two valid users with their passwords:
* alice with password ecila
* bob with password B06

We will build the docker image again to copy the newest files.

```shell
docker build -t couper-env-example -f Dockerfile .
```

Now run our image again:

```shell
docker run -p 8080:8080 couper-env-example run -f /conf/couper.hcl -f /conf/production.hcl
```

If we visit our endpoint again and enter one of the two valid user credentials, then we will get the already known welcome page again.

In a more real-world scenario, we would rather switch to a `jwt` access control e.g. using `jwks_url` to reference an identity provider's JWKS resource.
