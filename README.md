# Couper Example Collection

[Couper](https://github.com/coupergateway/couper) is designed to support developers
building and operating API-driven Web projects by offering security
and observability functionality in a frontend gateway
component.

This collection of examples highlights Couper's features with small, ready-to-use examples.
If you have any questions or feedback you are welcome to start a [discussion](https://github.com/coupergateway/couper/discussions).

## Getting started

To run the examples you need Couper. It is available as _docker
image_ from [Docker Hub](https://hub.docker.com/r/coupergateway/couper)

This requires a working [Docker](https://www.docker.com/) setup on your
computer. Please visit the [get started guide](https://docs.docker.com/get-started/) to get prepared.

To run the examples, clone the repository:

```sh
$ git clone https://github.com/coupergateway/couper-examples.git
Cloning into 'couper-examples'...
```

change into the `couper-examples` directory:

```sh
cd couper-examples
```

Choose an example, change to its directory:

```sh
cd simple-fileserving
```

and run

```sh
docker-compose pull && docker-compose up
```

Press `CTRL+C` to exit.

## Examples

### File & Web Serving

* [Simple File-Serving](simple-fileserving/README.md)
* [SPA Serving](spa-serving/README.md)
  * [Apply `bootstrap_data`](https://docs.couper.io/configuration/block/spa#bootstrap-data) to your SPA

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
* [Redirects](static-responses/README.md#example-1-redirects)
* [Request Sequences](sequences/README.md)

### Authorization & Authentication

* [JWT Access Control](jwt-access-control/README.md)
* [Sending JWT Claims Upstream](sending-jwt-upstream/README.md)
* [Permissions](permissions/README.md)
* [Permissions (Role-based Access Control)](permissions-rbac/README.md)
* [Permissions (Map)](permissions-map/README.md)
* [Creating JWT](creating-jwt/README.md)
* [Backend Authorization using OAuth2](backend-authorization-oauth2/README.md)
* [Single-Sign-On with SAML](saml/README.md)
* [Error Handling for Access Controls](error-handling-ba/README.md)
* [Userinfo Endpoint](static-responses/README.md#example-2-userinfo-endpoint)
* [OpenID Connect](oidc/README.md)

### Running Couper

* [Environment based configuration](environment)
* [Handling configuration files](configuration-files)
* [Environment Variables](env-var/README.md)
* [Emitting Environment Variables](static-responses/README.md#example-3-environment-variables)
* [Using docker](docker/README.md)
* [Using docker-compose](docker-compose/README.md)
* [Kubernetes](kubernetes-configuration/README.md)
* [Linking Docker Containers](linking-docker-containers/README.md)
* [Custom Logging](custom-logging/README.md)
