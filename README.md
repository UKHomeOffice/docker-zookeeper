# Zookeeper on Kubernetes
[![Docker Repository on Quay](https://quay.io/repository/ukhomeofficedigital/zookeeper/status "Docker Repository on Quay")](https://quay.io/repository/ukhomeofficedigital/zookeeper)

Bits you need to run Zookeeper cluster on Kubernetes. It is based on Zookeeper
version 3.5.x which is currently in alpha, but it's been pretty stable.


### Deployment
By default, if you don't specify any parameters, zookeeper will start in
standalone mode.

Deploying onto a Kubernetes cluster is fairly easy. There are example
kubernetes controller and service files in [kube/](kube/) directory.

In the service yaml files, you will notice that we asked for static
`ClusterIP`, in this example case, we're using `10.200.0.0/16` service IP
range. It is very likely that your estate is configured to use different
service IP range, so be sure you set the right IPs.

Zookeeper itself relies on the following DNS names for find its peers:
- `zookeeper-1`
- `zookeeper-2`
- `zookeeper-3`


#### Deploy Services
There is no strict ordering how you deploy the resources, let's start with
services first:

```bash
$ kubectl create -f kube/zookeeper-service.yaml
$ kubectl create -f kube/zookeeper-1-service.yaml
$ kubectl create -f kube/zookeeper-2-service.yaml
$ kubectl create -f kube/zookeeper-3-service.yaml
```

Let's list the services. There are four services, `zookeeper` service is
pointing to all zookeeper instances - for clients to use. The rest are pointing
to each relevant zookeeper pod.

```bash
$ kubectl get services
NAME          CLUSTER_IP       EXTERNAL_IP   PORT(S)                      SELECTOR                          AGE
zookeeper     10.200.143.219   <none>        2181/TCP                     service=zookeeper                 4h
zookeeper-1   10.200.10.31     <none>        2181/TCP,2888/TCP,3888/TCP   name=zookeeper-1,zookeeper_id=1   23h
zookeeper-2   10.200.10.32     <none>        2181/TCP,2888/TCP,3888/TCP   name=zookeeper-2,zookeeper_id=2   23h
zookeeper-3   10.200.10.33     <none>        2181/TCP,2888/TCP,3888/TCP   name=zookeeper-3,zookeeper_id=3   23h
```


#### Deploy Replication Controllers

```
$ kubectl create -f kube/zookeeper-1-controller.yaml
$ kubectl create -f kube/zookeeper-2-controller.yaml
$ kubectl create -f kube/zookeeper-3-controller.yaml
```

Get the pods:
```
$ kubectl get pods
NAME                READY     STATUS    RESTARTS   AGE
zookeeper-1-w3u4g   1/1       Running   0          9m
zookeeper-2-kpwaj   1/1       Running   0          9m
zookeeper-3-vcl94   1/1       Running   0          9m
```

#### Test the Cluster

Now, let's see if our zookeeper cluster is healthy. First, we will set `/foo`
key to `bar`, then kill the Pod and try to get `/foo` from another zookeeper
instance:

```bash
$ kubectl exec -ti zookeeper-1-w3u4g bash

[root@zookeeper-1-w3u4g zookeeper]# bin/zkCli.sh
[zk: localhost:2181(CONNECTED) 1] create /foo bar
Created /foo
[zk: localhost:2181(CONNECTED) 2] get /foo
bar
```

Delete the pod we just used to set the `/foo` value:
```
$ kubectl delete zookeeper-1-w3u4g
$ kubectl exec -ti zookeeper-3-vcl94 bash

[root@zookeeper-3-vcl94 zookeeper]# bin/zkCli.sh
[zk: localhost:2181(CONNECTED) 0] get /foo
bar
```

This just shows that if one node dies, the cluster is still functioning and the
deleted pod will be re-created by the replication controller.

### Known Caveats

By default there is no data persistence. So be aware that if you delete more
than one replication controller or more than one pod, you will lose the quorum.

