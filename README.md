# Couper Example Collection

[Couper](https://couper.io) is designed to support developers
building and operating API-driven Web projects by offering security
and observability functionality in a lightweight API gateway
component.

This collection of examples highlights Couper's features with small, ready-to-use examples.

## Getting started

To run the examples you need Couper 2. It is available as _docker
image_ from [Docker Hub](https://hub.docker.com/r/avenga/couper)

Of course you need a working [Docker](https://www.docker.com/) setup on your
computer.

To download/install Couper, open a terminal and execute:

```sh
$ docker pull avenga/couper
```

To run the examples, clone the repository and start Couper in a docker
container with the example's directory shared into the container:

```sh
$ git clone https://github.com/avenga/couper-examples.git
$ cd couper-examples
$ cd simple-fileserving
$ docker run --rm -p 8080:8080 -v "$(pwd)":/conf avenga/couper

{"addr":"0.0.0.0:8080","level":"info","message":"couper gateway is serving","timestamp":"2020-08-27T16:39:18Z","type":"couper"}
…
```

Now Couper is serving on your computer's port 8080. Point your
browser or `curl` to [`localhost:8080`](http://localhost:8080/) to see what's going on.

Press `CTRL+c` to stop the container.

## [Simple File-Serving](simple-fileserving/README.md)
