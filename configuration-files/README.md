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

Couper gets configured by a [configuration-file](https://github.com/avenga/couper/tree/master/docs#configuration-file) and
with the [latest 1.9 release](https://github.com/avenga/couper/releases/latest) Couper has an option to handle multiple
configuration-files: the configuration-directory. This directory can be passed as an argument along with a configuration-file
or as standalone argument.

This enables you to split up a Couper configuration by content or even by environment. This is solved by [merging](https://github.com/avenga/couper/blob/master/docs/MERGE.md) the top-level
declarations and replacing nested ones. Details are explained in our [merge documentation](https://github.com/avenga/couper/blob/master/docs/MERGE.md).

## Split by topic

Let's say we have some api endpoints which could be extracted out of a base configuration which just describes basics
like files, spa serving or default environment variables.

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

The API part describes two api services and their related environment default values for e.g. local development:

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

The `environment_variables` attribute within the `defaults` block has an exception during the merge process. The map-value
will be merged by key instead of the whole map. This allows to override or add specific environment defaults.

### Result

The following configuration would be the one Couper will finally load if we provide the directory with these two files.

The Couper container basically runs already with the argument `-d /conf` inside the container which enables us to just mount
our `./conf-a` directory to `/conf`. Also, the Couper welcome page already exists within `/htdocs`.

```shell
docker run --pull -v $(PWD)/conf-a:/conf -p 8080:8080 avenga/couper
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

You may have read how the files will be merged by file-name-order. A `couper.hcl` will be prioritized within this directory
which makes this file a good starting point for our base configuration.

## Different Access-Control

Another possible case would be an access-control which may differ between a stage and production environment due to their complexity.
Let's use this case to tailor a possible configuration setup.

Basically we will have some base configuration again. This can be a single file or a directory. The environment related
configuration will be added during the container build process. In this example we will call these build-arguments by hand but
this environment-based conditional must be solved by your continuous-integration setup. If you have any questions, feel free
to open a [discussion](https://github.com/avenga/couper/discussions).

### Base

To keep things simple we just want to protect our file server. It's recommended to protect even your base with an unrealizable
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

Docker provides build arguments which we will use to switch between our environment files while building the Couper container image.
The `HCL_FILE` argument will fall back to `couper.hcl` if we do not provide this argument at all.

```Dockerfile
FROM avenga/couper:edge

ARG HCL_FILE=couper.hcl

# copy base configuration
COPY couper.hcl /conf/couper.hcl
# copy environment base overlay configuration
COPY $HCL_FILE /conf/
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

So lets build the image again and let's add the `stage.hcl` to the build process.

```hcl
server {
  access_control = ["my-ba"]
}

definitions {
  basic_auth "my-ba" {
    password = "test"
  }
}
```

To do so we add the docker related build argument:

```shell
docker build -t couper-env-example --build-arg=HCL_FILE=stage.hcl -f Dockerfile .
```

Now we will run our image again:

```shell
docker run -p 8080:8080 couper-env-example
```

Just visit [http://localhost:8080/](http://localhost:8080/) in your browser, so you will see a basic-auth prompt.
Your Stage environment is protected now. Enter `test` as value into the password field, and you will see the Couper welcome page.

### Production environment file

The advantage to switch to a complete other `access_control` mechanism could be very handy if you have to use a specific SSO or other provider
to handle the permissions.

So let's switch from **basic-auth** to **jwt** with the `production.hcl` configuration file.

```hcl
server {
  access_control = ["my-jwt"]
}

definitions {
    jwt "my-jwt" {
      jwks_url = "https://demo-idp.couper.io/jwks.json"
      required_claims = ["role", "sub", "exp"]
      claims = {
        iss = "https://demo-idp.couper.io/"
      }
    }
  }
```

We will build the docker image again and change the build arguments value.

```shell
docker build -t couper-env-example --build-arg=HCL_FILE=production.hcl -f Dockerfile .
```

Now run our image again:

```shell
docker run -p 8080:8080 couper-env-example
```

If we visit our endpoint again:

```shell
curl -i http://localhost:8080/

HTTP/1.1 401 Unauthorized
Cache-Control: private
Couper-Error: access control error
Couper-Request-Id: c9h4mdp473ds73dnvsvg
Server: couper.io
```

We will get a 401 response without basic-auth related headers and no prompt. Additionally, the couper log output:

`"level":"error","message":"access control error: my-jwt: bearer required with authorization header"`

Let's retry the request with a valid jwt token. Just visit [https://demo-idp.couper.io/](https://demo-idp.couper.io/) and copy the generated token. Use this token with our next call:

```shell
curl -i -H "Authorization: Bearer <your-token>"  http://localhost:8080/
```

and we will get the already known welcome page again.
