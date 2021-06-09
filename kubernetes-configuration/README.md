# Kubernetes configuration for Couper

## Table of Contents

* [Kubernetes configuration for Couper](#kubernetes-configuration-for-couper)
    * [Table of Contents](#table-of-contents)
    * [Introduction](#introduction)
    * [Setup](#setup)
        * [Requirements](#requirements)
        * [Basics](#basics)
        * [Configuration](#configuration)
            * [Deployment](#deployment)
            * [Service](#service)
            * [Apply your configuration](#apply-your-configuration)
                * [List pods and services](#list-pods-and-services)
                * [Apply deployment and service](#apply-deployment-and-service)
            * [Accessing couper service](#accessing-couper-service)
            * [Adding a custom Couper configuration file](#adding-a-custom-couper-configuration-file)
                * [Replace the deployment](#replace-the-deployment)
    * [See Also](#see-also)

## Introduction

[Kubernetes](https://kubernetes.io/docs/home/), also known as *K8s*, is an established open-source container orchestration.
We will describe a Couper integration as gateway service to attach multiple internal services.

> **Note:** Currently Couper is not an [Ingress-Controller](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/). This is still required for e.g. TLS offloading.

## Setup

### Requirements

A running Kubernetes Cluster where you can apply the following configuration manifests.
Running a local cluster can be achieved with e.g. [MiniKube](https://minikube.sigs.k8s.io/docs/).

`kubectl` is required to apply the manifest files to your cluster: https://kubernetes.io/docs/tasks/tools/

### Basics

We will use a [deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) and a [service](https://kubernetes.io/docs/concepts/services-networking/service/) configuration to describe our basic setup.
Depending on the project you may want to connect the upstream services via additional kubernetes-services.
For those cases just use the related [service dns-record](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/) as backend [origin](https://github.com/avenga/couper/tree/master/docs#backend-block) within your Couper configuration.
To keep things simple, we will configure a [Pod](https://kubernetes.io/docs/concepts/workloads/pods/) containing a Couper and a service instance. The [backend]((https://github.com/avenga/couper/tree/master/docs#backend-block)) connects via `localhost` to the origin (service).

### Configuration

#### Deployment

The following configuration shows a setup with just one container, Couper. We have changed the listening port to `8099` (default: `8080`) via environment variable. This change will affect the `service` configuration since we will map the service to the container port.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: couper-example
spec:
  replicas: 1
  selector:
    matchLabels:
      app: couper
  minReadySeconds: 2
  template:
    metadata:
      labels:
        app: couper
    spec:
      containers:
        - name: couper
          # With 'latest' tag, K8s pull policy is implicitly 'always'
          image: avenga/couper:latest
          ports:
            - containerPort: 8099
          livenessProbe:
            httpGet:
              path: /healthz
              port: 8099
            initialDelaySeconds: 2
            periodSeconds: 5
          env:
            - name: COUPER_DEFAULT_PORT
              value: '8099'
```

#### Service

The service makes Couper available within your cluster namespace. To do so, we will link the service name to the couper container via
label selector with the key `app` and value `couper`. We have configured this selector in the deployment configuration above too.
Additionally, all packets gets sent from service port `7070` to the container port `8099`.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: couper-example
spec:
  ports:
  - port: 7070
    targetPort: 8099
    protocol: TCP
  selector:
    app: couper
```

#### Apply your configuration

Since we have a basic setup which will show up the Couper welcome page at the end, we need to apply those manifest (yaml) files.

I am using minikube here, but the following commands should work for all local or remote clusters. Just ensure your `kubectl` *context* and *namespace* is set accordingly.

##### List pods and services

Let's see what is already running:

```shell
kubectl get pods,services -o wide

NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE   SELECTOR
service/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   21h   <none>
```

Just the minikube service, we will ignore this for now.

##### Apply deployment and service

Execute the following apply command which will create all resources related to our configurations:
```shell
kubectl apply -f deployment.yaml -f service.yaml

deployment.apps/couper-example created
service/couper-example created
```

Check the results:
```shell
kubectl get pods,services -o wide

NAME                                  READY   STATUS    RESTARTS   AGE   IP           NODE       NOMINATED NODE   READINESS GATES
pod/couper-example-579d556dfc-4cpmv   1/1     Running   0          51s   172.17.0.5   minikube   <none>           <none>

NAME                     TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE   SELECTOR
service/couper-example   ClusterIP   10.96.203.227   <none>        7070/TCP   51s   app=couper
service/kubernetes       ClusterIP   10.96.0.1       <none>        443/TCP    22h   <none>
```

We can see the newly created `pod/couper-example-*` and the service named `couper-example` with port `7070`.

#### Accessing couper service

To be able to access the newly created `couper-example` service and keeping things simple we will just use the `kubectl port-forward` command.

> *Note*: For production setups this may be solved by a properly configured ingress-controller which will forward the traffic for e.g. a specific hostname to your Couper service.

We will pick a free port on our local machine for example `9090` and forwarding to the service port `7070` with:

```shell
kubectl port-forward service/couper-example 9090:7070

Forwarding from 127.0.0.1:9090 -> 8099
Forwarding from [::1]:9090 -> 8099
```

Running `curl -v http://127.0.0.1:9090/` results in:

```shell
...
< HTTP/1.1 200 OK
< Content-Type: text/html; charset=utf-8
< Server: couper.io
< Vary: Accept-Encoding
...
```

or you can visit the welcome page with your browser: [http://localhost:9090/](http://localhost:9090/) 

#### Adding a custom Couper configuration file

To customize the Couper configuration you can build a container inherits from `avenga/couper` and add the related file and make this image available to your K8s cluster.
For now, we will mount the configuration file into the pod with help from the [configmap](https://kubernetes.io/docs/concepts/configuration/configmap/).

Let's run the following:
```shell
kubectl create configmap couper-example --from-file=couper.hcl=couper.hcl

configmap/couper-example created
```

This will make the content from our `couper.hcl` available as key `couper.hcl` within the configmap `couper-example`.

##### Replace the deployment

The following updates can be found as complete configuration in `deployment_part_two.yaml`.
We will add a configmap volume with our `couper.hcl` and another environment variable to response the current pod name.

The environment variable `MY_POD_NAME` gets referred via Couper configuration.

```yaml
spec:
  template:
    spec:
      containers:
        - name: couper
          # ... complete spec see file
          env:
            - name: MY_POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
          volumeMounts:
            - name: couper-conf
              mountPath: /my-conf/couper.hcl
              subPath: couper.hcl
      volumes:
        - name: couper-conf
          configMap:
            name: couper-example
```

```shell
kubectl replace --force -f deployment_part_two.yaml

deployment.apps "couper-example" deleted
deployment.apps/couper-example replaced
```

> *Note:* The `--force` argument triggers a recreation even if nothing has changed.

You may want to re-run the `port-forward` command since the previous container got removed.

```shell
kubectl port-forward service/couper-example 9090:7070
```

Finally, we call `curl -v http://localhost:9090/hello` and see the result from our custom endpoint response:

```shell
< HTTP/1.1 200 OK
< Content-Type: text/plain
< Server: couper.io
< Content-Length: 43
<

Hello! I am couper-example-7fdf98f4c8-mrbx5
```

## See Also

K8s: [Expose a service](https://kubernetes.io/docs/tutorials/kubernetes-basics/expose/expose-intro/)
