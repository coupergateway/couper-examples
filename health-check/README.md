# Health Checks

Suppose we have a simple Couper proxy configuration – requests to `/` are forwarded to a backend service:

```hcl
server {
  api {
    endpoint "/" {
      proxy {
        backend = "fragile_backend"
      }
    }
  }
}

definitions {
  backend "fragile_backend" {
    origin = "http://backend:8080"
  }
}
```

To demonstrate Couper's health monitoring facilities, we create an unreliable
backend service that is sometimes failing. To be exact, it actually fails half of the time:

```hcl
server {
  api {
    endpoint "/" {
      response {
        # fail every 15 seconds for a period of 15 seconds
        status = (unixtime() % 30) < 15 ? 200 : 500
      }
    }
  }
}
```

Let's start the services to see them in action:

```sh
$ docker-compose pull && docker-compose up

```

Then, in another shell we send a request…

```sh
$ curl -i localhost:8080/
HTTP/1.1 200 OK
Date: Mon, 13 Jun 2022 09:21:35 GMT
…
```

… and Couper responds with `200 OK`. A few seconds later the backend is failing and
accordingly Couper forwards the `500 Internal Server Error`:

```sh
$ curl -i localhost:8080/
HTTP/1.1 500 Internal Server Error
Date: Mon, 13 Jun 2022 09:21:47 GMT
…
```

Now let's monitor the healthiness of the backend with the `beta_health` block:

```hcl
definitions {
  backend "fragile_backend" {
    origin = "http://backend:8080"
    beta_health {}
  }
}
```

Couper will now send `GET` requests to http://backend:8080/ every second and check
the response status. By default, status codes of 200, 204 or 301 will be considered as healthy.
If you want to accept other than the these codes, you can set the `expected_status` attribute accordingly.
To change the check frequency, set the `interval` attribute, for example

```hcl
    beta_health {
      expected_status = [200, 418]
      interval = "3s"
    }
```

Let's filter the logs to better see what's going on:

```sh
$ docker-compose logs | grep 'new health state'
… "level":"info","message":"new health state: healthy","timestamp":"2022-06-13T09:37:32Z",…
… "level":"warning","message":"new health state: failing","timestamp":"2022-06-13T09:37:47Z",…
… "level":"error","message":"unexpected status code: 500: new health state: unhealthy","timestamp":"2022-06-13T09:37:50Z",…
… "level":"info","message":"new health state: healthy","timestamp":"2022-06-13T09:38:02Z",…
```

We observe that Couper is repeatedly requesting the backend to determine its health.
After being intially `healthy`, Couper considers the backend `failing`
after its first "500" response. Three seconds later (`interval = "3s"`) when the status is
still 500, the health state downgrades to `unhealthy`.

The number of failing requests it takes until a backend is considered `unhealthy`
can be configured with the `failure_threshold` attribute (defaults to 1).
If you want the response body to contain a certain text, you can define that with
the `expected_text` attribute. See the [reference](https://github.com/avenga/couper/blob/master/docs/REFERENCE.md#health-block)
for details on these and other attributes.

The health state of a backend is accessible via the `backends.<label>.health` variable, that is
`backends.fragile_backend.health` in our case. We can put that into Couper's response:

```hcl
    endpoint "/" {
      proxy {
        backend = "fragile_backend"
      }
      response {
        headers = {
          Health = backends.fragile_backend.health.state
        }
        json_body = backends.fragile_backend.health
      }
    }
```

As long as the backend is in `healthy` or `failing` state, we now get

```sh
$ curl -i localhost:8080/
HTTP/1.1 200 OK
Health: healthy
…

{"error":"","healthy":true,"state":"healthy"}
```

or

```sh
$ curl -i localhost:8080/
HTTP/1.1 200 OK
Health: failing
…
{"error":"unexpected status code: 500","healthy":true,"state":"failing"}
```

However, if the backend is considered `unhealthy`, Couper stops forwarding requests to it by means of
the `proxy` or `request` blocks and instead responds with `502 Bad Gateway`. In a real
scenario that might help a failing backend service to recover due to the reduced amount
of requests it receives. (You can permit these requests by setting `use_when_unhealthy = true` within the `backend` block).

As with other errors, we can catch that one with an `error_handler` for errors of
type `backend_unhealthy` and then override Couper's default error response. Let's
respond with a `503` error instead:

```hcl
    endpoint "/" {
      proxy { … }
      response { … }

      error_handler "backend_unhealthy" {
        response {
          status = 503
          headers = {
            Retry-After = 15
          }
        }
      }
    }
```

```sh
$ curl -i localhost:8080/
HTTP/1.1 503 Service Unavailable
Retry-After: 15
…
```

**Note:** This is currently a [_beta_ feature](https://github.com/avenga/couper/blob/master/docs/BETA.md).
