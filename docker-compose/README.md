# Using docker-compose

A typical setup for local development is running Couper with [`docker-compose`](https://docs.docker.com/compose/). Couper's Docker image [`avenga/couper`](https://hub.docker.com/r/avenga/couper) is ready to use. All you need is a `docker-compose.yaml`: 

```yaml
version: "3"
services:
  couper:
    image: avenga/couper
    ports:
      - 8080:8080
    volumes:
      - ./:/conf
```

In this example, we are using the current working directory (`.`) as Couper's `/conf` directory. 

Start your setup:

```shell
$ docker-compose up
```

Now point your browser to [`http://localhost:8080`](http://localhost:8080).

We have provided a [`couper.hcl`](couper.hcl) and some [files](htdocs/) for this example. Have a look at the configuration and the HTML document to understand what is going on. Couper serves the `htdocs/index.html` document to your browser. The Javascript code fetches our "API" which in turns fetches data from `https://httpbin.org/ip`.

## Environment Variables

We should make our Couper setup configurable for the different environments it will run in. Environment variables are the way to go. This is easy to do with the `environment` section in our `docker-compose.yml`:

```yaml
version: "3"
services:
  couper:
    image: avenga/couper
    ports:
      - 8080:8080
    volumes:
      - ./:/conf
    environment:
      # hot reload config
      - COUPER_WATCH=true
      # make important parameters configurable
      - GREET_NAME=Couper
      - SERVICE_ORIGIN=https://httpbin.org
```

In this example we have set three variables.

Variables starting with `COUPER_` usually refer to Couper settings.
(`COUPER_WATCH` is an equivalent for the `-watch` command line switch
– it tells Couper to reload the configuration when the file changes).
You can find a complete list
[here](https://github.com/avenga/couper/blob/master/DOCKER.md).

The other two variables `GREET_NAME` and `SERVICE_ORIGIN` are
application variables. They are available in the configuration file
in the `env.<VAR>` variable. It is a good idea to make the origin of
backends configurable:

```hcl
definitions {
  backend "aService" {
    origin = env.SERVICE_ORIGIN
  }
}
```

`docker-compose` also allows you to read environment variables from a
file with:

 ```yaml
     env_file:
      - ./.env
```

This can be helpful if you have variables that should not be pushed
into you source code repository: You could list the
`.env` file in your project's `.gitignore` to avoid accidental
exposure of local secrets, such as usernames and passwords.

## Linking other services

Now that everything is configurable, let's make things more complicated:

We want to run a local version of the upstream service, to develop
against. (This could even be a mocked version of it). We add it as
a second `service` in our `docker-compose.yml`. Docker automatically
links those services with their name as network address.

```yaml
version: "3"
services:
  couper:
    image: avenga/couper
    ports:
      - 8080:8080
    volumes:
      - ./:/conf
    environment:
      # hot reload config
      - COUPER_WATCH=true
      # make important parameters configurable
      - GREET_NAME=Couper
      # use local service
      - SERVICE_ORIGIN=http://httpbin
  httpbin:
    image: kennethreitz/httpbin
```

Run

```shell
$ docker-compose up
```

and this time, two services come up. http://localhost:8080 should
greet you with a local IP address.
