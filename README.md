# Couper Example Collection

[Couper](https://github.com/avenga/couper) is designed to support developers
building and operating API-driven Web projects by offering security
and observability functionality in a frontend gateway
component.

This collection of examples highlights Couper's features with small, ready-to-use examples.
If you have any questions or feedback you are welcome to start a [discussion](https://github.com/avenga/couper/discussions).

## Getting started

To run the examples you need Couper. It is available as _docker
image_ from [Docker Hub](https://hub.docker.com/r/avenga/couper)

This requires a working [Docker](https://www.docker.com/) setup on your
computer. Please visit the [get started guide](https://docs.docker.com/get-started/) to get prepared.

To download/install Couper, open a terminal and execute:

```sh
$ docker pull avenga/couper
```

To run the examples, clone the repository:
```sh
$ git clone https://github.com/avenga/couper-examples.git

Cloning into 'couper-examples'...
```
`cd` into the directory:
```sh
$ cd couper-examples
```
Choose an example and `cd` into the directory:
```sh
$ cd /simple-fileserving
````

Then start Couper in a docker
container: 

```sh
$ docker run --rm -p 8080:8080 -v "$(pwd)":/conf avenga/couper

{"addr":"0.0.0.0:8080","level":"info","message":"couper gateway is serving","timestamp":"2020-08-27T16:39:18Z","type":"couper"}
```
In the examples with a `docker-compose.yml` you can also run: 
```sh
$ docker-compose up
```
as an alternative.

Now Couper is serving on your computer's port *8080*. Point your
browser or `curl` to [`localhost:8080`](http://localhost:8080/) to see what's going on.

Press `CTRL+c` to stop the container.

> Git Bash users on Windows may encounter the error message `Failed to load configuration: open couper.hcl: no such file or directory`. Try if disabling Windows path conversion helps:
> ```sh
> $ export MSYS_NO_PATHCONV=1
> ```

## Examples

### File & Web Serving

* [Simple File-Serving](simple-fileserving/README.md)
* [SPA Serving](spa-serving/README.md)

### Requests & Responses

* [Proxy API Requests](api-proxy/README.md)
* [Custom Requests](custom-requests/README.md)
* [Multiple Requests](multiple-requests/README.md)
* [Static Responses](static-responses/README.md)
* [Backend Validation](backend-validation/README.md)
* [Path Parameter](path-params/README.md)
* [Query Parameter Manipulation](query/README.md)
* [Sending JSON Content](sending-json/README.md)
* [Sending Form Content](sending-form/README.md)

### Authorization & Authentication

* [JWT Access Control](jwt-access-control/README.md)
* [Sending JWT Claims Upstream](sending-jwt-upstream/README.md)
* [Creating JWT](creating-jwt/README.md)
* [OAuth2 Client Credentials Flow](oauth2-client-credentials/README.md)
* [Single-Sign-On with SAML](saml/README.md)
* [Error Handling for Access Controls](error-handling-ba/README.md)

### Running Couper
* [Environment Variables](env-vars/README.md)
* [Using docker-compose](docker-compose/README.md)
* [Linking Docker Containers](linking-docker-containers/README.md)
