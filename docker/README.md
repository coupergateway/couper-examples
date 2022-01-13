# Using Couper with Docker

- [Introduction](#introduction)
- [Usage](#usage)
- [Custom build](#build)

## Introduction
Couper is also available as docker image from [Docker Hub](https://hub.docker.com/r/avenga/couper/).

Running the Couper container requires a working [Docker](https://www.docker.com/) setup on your computer.
Please visit the [get started guide](https://docs.docker.com/get-started/) to get prepared.

### Usage

To download the latest Couper image run:

```sh
docker pull avenga/couper
```

Couper needs a configuration file to know what to do.
Create an empty `couper.hcl` file.

Copy/paste the following configuration to the file and save it:

```hcl
server {
	endpoint "/**" {
        response {
            body = "Hello World!"
        }
    }
}
```

Then start the Couper container:

```sh
docker run --rm -p 8080:8080 -v "$(pwd)":/conf avenga/couper
```

Now Couper is serving on your computer's port `8080`:

```json lines
{"level":"info","message":"couper is serving: 0.0.0.0:8080","timestamp":"2022-01-03T04:20:00+01:00","type":"couper_daemon"}
```

Point your browser to [http://localhost:8080/](http://localhost:8080/) or use `curl` to see what's going on.

You can press `CTRL + c` to stop the running Couper container.

#### Additional links

- [Documentation reference](https://github.com/avenga/couper/tree/master/docs/)
- [more Examples](../README.md)

### Build

To be able to add custom resources which could be served from Couper like files or a SPA you can create
your own `Dockerfile` which inherits from the official Couper Image.

First we can create some content and place this into a new folder called `htdocs`.
We have used a simple [`html`-file](./build/www/index.html) here.

Next to our `htdocs` folder we will create a simple `couper.hcl` and insert a reference to `htodcs`.

```hcl
server {
  files {
    # we will copy this folder to this location in the next step
    document_root = "/htdocs"
  }
}
```

Create a file named `Dockerfile` and insert the following content:

```Dockerfile
FROM avenga/couper

COPY htdocs/ /htdocs/
COPY couper.hcl /conf/

```

Now we can build and run our custom Couper image:

```sh
docker build --pull --load -t my-couper .
```

Start our image named `my-couper`:

```sh
docker run --rm -p 8080:8080 my-couper
```

and visit [http://localhost:8080/](http://localhost:8080/).

The complete Setup can be found [here](./build).
