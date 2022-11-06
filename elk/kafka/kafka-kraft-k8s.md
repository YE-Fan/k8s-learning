



https://developer.ibm.com/tutorials/kafka-in-kubernetes/



[Apache Kafka](https://kafka.apache.org/) is a distributed streaming platform that is the foundation for many event-driven systems. It allows for applications to produce and consume events on various topics with built-in fault tolerance.

Prior to v2.8 of Kafka, all Kafka instances required Zookeeper to function. [Zookeeper](https://zookeeper.apache.org/) has been used as the metadata storage for Kafka, providing a way to manage brokers, partitions, and tasks such as providing consensus when electing the controller across brokers.

You can read the early access release docs for KRaft mode [here](https://github.com/apache/kafka/blob/2.8.0/config/kraft/README.md).

You can read more about Zookeeper-less Kafka in [Gunnar Morling's blog](https://www.morling.dev/blog/exploring-zookeeper-less-kafka/).

You can read more about the performance benefits of KRaft mode in this [Confluent blog post](https://www.confluent.io/blog/kafka-without-zookeeper-a-sneak-peek/#scaling-up).

[Apache Kafka v2.8](https://kafka.apache.org/) now has experimental support for running without Zookeeper: Kafka Raft Metadata mode (KRaft mode). KRaft mode was proposed in Kafka Improvement Proposal (KIP) [KIP-500](https://cwiki.apache.org/confluence/display/KAFKA/KIP-500%3A+Replace+ZooKeeper+with+a+Self-Managed+Metadata+Quorum). KRaft mode Kafka now runs as a single process and a single distributed system, making it simpler to deploy, operate, and manage Kafka, especially when running Kafka on Kubernetes. KRaft mode also allows Kafka to more easily run with less resources, making it more suitable for [edge computing solutions](https://developer.ibm.com/depmodels/edge-computing/).

In this tutorial, I will walk through what these tools are, why you would want to run Kafka on Kubernetes without Zookeeper, some warnings around using these experimental features in KRaft mode, and the steps for getting up and running with a working environment. The resulting environment will consist of three KRaft mode Kafka v2.8.0 brokers in a single-node Kubernetes cluster on Minikube.

**Important:** It's still early days for this new KRaft mode Kafka. Kafka v2.8.0 is only the initial implementation, and there are many features that don't yet work in KRaft mode, such as the use of ACLs and other security features, transactions, partition reassignment, and JBOD to name a few (see [this KRaft doc](https://github.com/apache/kafka/blob/6d1d68617ecd023b787f54aafc24a4232663428d/config/kraft/README.md#missing-features) for more details). KRaft mode is currently best-suited for testing out this new technology in a development environment. **You should not use this version for any production application.**

## Why run Kafka on Kubernetes?

[Kubernetes](https://kubernetes.io/) handles deployment, scaling, and management of containerized applications. Kafka's built-in features around fault tolerance can work well with the scaling and other management features provided by Kubernetes. Cluster scaling and management also becomes easier for a Kafka instance now that KRaft mode removes the need to also manage Zookeeper pods in your cluster.

Read more about [why you should run Kafka on Kubernetes](https://www.redhat.com/en/topics/integration/why-run-apache-kafka-on-kubernetes) in this Red Hat article.

This means that DevOps teams will be able to scale up Kafka clusters using Kubernetes commands and configuration, and without the need to make similar changes to the Kafka configuration. Any change in Kafka broker, replica, or partition settings would be minor, and could automatically occur when cluster configuration changes are being applied during pod restarts.

[Strimzi](https://strimzi.io/) provides a simplified path to running Kafka on Kubernetes by making use of [Kubernetes operator features](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/). Strimzi handles both Kubernetes and Kafka configuration, including security, scaling, creating users, broker management, and other features. However, Strimzi does not yet support Kafka v2.8 (in KRaft mode or otherwise). Strimzi v.0.24.0 supports Kafka v2.7.1. It is still too early to know when the future Strimzi version with support for KRaft mode Kafka will be released (see [roadmap](https://github.com/orgs/strimzi/projects/1)).

## Prerequisites

- An understanding of Apache Kafka. Read this [fundamentals of Apache Kafka](https://developer.ibm.com/articles/event-streams-kafka-fundamentals/) article.
- An understanding of Kubernetes. Watch this video to learn the history and [fundamentals of Kubernetes](https://developer.ibm.com/videos/learn-the-history-and-fundamentals-of-kubernetes/).
- An understanding of Minikube. You can read the [docs](https://minikube.sigs.k8s.io/docs/), or try your hand at [setting up Minikube on an Ubuntu server](https://developer.ibm.com/tutorials/set-up-minikube-on-ubuntu-server-within-minutes/).

The following steps were initially taken on a MacBook Pro with 32GB memory running MacOS Big Sur v11.4.

Make sure to have the following applications installed:

- [docker](https://www.docker.com/) v20.10.7
- [minikube](https://minikube.sigs.k8s.io/docs/) v1.21.0 (running [kubernetes](https://kubernetes.io/docs/home/) v1.20.7 internally)

It's possible the steps below will work with different versions of the above tools, but if you run into unexpected issues, you'll want to ensure you have identical versions.

Minikube was chosen for this exercise due to its focus on local development, and the experimental nature of KRaft mode Kafka in version 2.8.0 makes it best suited for testing locally.

## Cluster components

The cluster we will create will have the following components:

- Namespace `kafka-kraft` ([source](https://github.com/IBM/kraft-mode-kafka-on-kubernetes/blob/main/kubernetes/kafka.yml#L1-L4))
  This is the namespace within which all components (except for the PersistentVolume) will be scoped.
- PersistentVolume `kafka-pv-volume` ([source](https://github.com/IBM/kraft-mode-kafka-on-kubernetes/blob/main/kubernetes/kafka.yml#L6-L19))
  This will be the single storage shared between all three Kafka pods. The PersistentVolume can be seen as the cluster administrator's view of the storage resource.
- PersistentVolumeClaim `kafka-pv-claim` ([source](https://github.com/IBM/kraft-mode-kafka-on-kubernetes/blob/main/kubernetes/kafka.yml#L21-L32))
  In Kubernetes, every PersistentVolume needs an associated claim in order to function as storage. The PersistentVolumeClaim can be seen as the application developer's view into (or request for) the shared storage.
- Service `kafka-svc` ([source](https://github.com/IBM/kraft-mode-kafka-on-kubernetes/blob/main/kubernetes/kafka.yml#L34-L49))
  `kafka-svc` is a headless service that allows direct access to endpoints on the pod from within the cluster (rather than providing a single endpoint for multiple pods). This allows Kafka to control which pod is responsible for handling requests based on which broker is the leader for a requested topic. See the [docs](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services) for more details on how this works.
- StatefulSet `kafka` [source](https://github.com/IBM/kraft-mode-kafka-on-kubernetes/blob/main/kubernetes/kafka.yml#L51-L90)
  This is the configuration for managing the three Kafka pods. It associates each pod to the PersistentVolumeClaim and Service, defines the docker image, ensures the pods get started in sequential order, and names each pod accordingly (`<StatefulSet name>-0` etc.)

## Steps

1. [Create the cluster](https://developer.ibm.com/tutorials/kafka-in-kubernetes/#create-the-cluster)
2. [Verify communication across brokers](https://developer.ibm.com/tutorials/kafka-in-kubernetes/#verify-communication-across-brokers)
3. [Create a topic and recovery](https://developer.ibm.com/tutorials/kafka-in-kubernetes/#create-a-topic-and-recovery)

### Create the cluster

Clone the repo and change into the new directory:

```
git clone https://github.com/IBM/kraft-mode-kafka-on-kubernetes && cd kraft-mode-kafka-on-kubernetes
```

Show more

Start Minikube with additional memory to ensure there aren't issues running three Kafka instances. This will also automatically switch to the `minikube` context.

```
minikube start --memory=4096
```

Show more

Create a shared storage folder `/mnt/data` on the single Minikube node.

```
minikube ssh
sudo mkdir /mnt/data
exit
```

Show more

This folder will be mounted as `/mnt/kafka` in each of the three Kafka pods. Each pod will have its own sub-folder for storing logs (`kafka-0` will use `/mnt/kafka/0`). The initial broker `kafka-0` will also be responsible for creating a file `/mnt/data/cluster_id` containing a cluster ID that is used by all subsequent brokers. This cluster ID is then re-used on subsequent restarts by all brokers. The relevant code that controls this process is in [entrypoint.sh](https://github.com/IBM/kraft-mode-kafka-on-kubernetes/blob/main/docker/entrypoint.sh#L18-L23).

Create a new `DOCKER_USERNAME` environment variable that will be used in the next three commands below, including as the prefix to the docker image that is pushed to [Docker Hub](https://hub.docker.com/). This value should match your existing Docker username.

```
export DOCKER_USERNAME=<username>
```

Show more

Build the Kafka docker image according to [this Dockerfile](https://github.com/IBM/kraft-mode-kafka-on-kubernetes/blob/main/docker/Dockerfile).

```
docker build -t $DOCKER_USERNAME/kafka-kraft docker/
```

Show more

This image will install Kafka v2.8 and copy over the [entrypoint.sh](https://github.com/IBM/kraft-mode-kafka-on-kubernetes/blob/main/docker/entrypoint.sh) file.

In addition to the cluster ID handling discussed above, this file is also responsible for defining some environment variables, updating the Kafka `server.properties` file, and starting Kafka.

Push the Kafka docker image to Docker Hub. This makes the image available for use within Kubernetes. Make sure you are logged in to the docker registry (with `docker login`) before pushing the image using the command below:

```
docker push $DOCKER_USERNAME/kafka-kraft
```

Show more

Now we can use the previous image in Kubernetes.

First we need to make sure the provided script uses the correct image name, so the script is sent through `sed` and then piped to `kubectl apply`. All Kubernetes components (except the persistent volume `kafka-pv-volume`) are under the namespace `kafka-kraft`. See [kafka.yml](https://github.com/IBM/kraft-mode-kafka-on-kubernetes/blob/main/kubernetes/kafka.yml) for more details.

```
sed -e "s|docker_username|$DOCKER_USERNAME|g" kubernetes/kafka.yml | kubectl apply -f -
```

Show more

Switch to the `kafka-kraft` namespace so subsequent commands will work without specifying the namespace each time:

```
kubectl config set-context --current --namespace=kafka-kraft
```

Show more

### Verify communication across brokers

There should now be three Kafka brokers each running on separate pods within your cluster. Name resolution for the headless service and the three pods within the StatefulSet is automatically configured by Kubernetes as they are created, allowing for communication across brokers. See the related [documentation](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/) for more details on this feature.

You can check the first pod's logs with the following command:

```
kubectl logs kafka-0
```

Show more

The name resolution of the three pods can take more time to work than it takes the pods to start, so you may see `UnknownHostException` warnings in the pod logs initially:

```
[2021-06-21 11:46:08,039] WARN [RaftManager nodeId=2] Error connecting to node kafka-1.kafka-svc.kafka-kraft.svc.cluster.local:9093 (id: 1 rack: null) (org.apache.kafka.clients.NetworkClient)
java.net.UnknownHostException: kafka-1.kafka-svc.kafka-kraft.svc.cluster.local
        ...
```

Show more

But eventually each pod will successfully resolve pod hostnames and end with a message stating the broker has been unfenced:

```
[2021-06-21 11:46:13,950] INFO [Controller 0] Unfenced broker: UnfenceBrokerRecord(id=1, epoch=176) (org.apache.kafka.controller.ClusterControlManager)
```

Show more

## Create a topic and recovery

The Kafka StatefulSet should now be up and running successfully. You can read more about [StatefulSets](https://kubernetes.io/docs/tutorials/stateful-application/basic-stateful-set/) in the Kubernetes docs.

Now we can create a topic, verify the replication of this topic, and then see how the system recovers when a pod is deleted.

Open terminal on pod `kafka-0`:

```
kubectl exec -it kafka-0 -- /bin/sh
```

Show more

Create a topic named `test` with three partitions and a replication factor of 3. This means this topic will be spread across three partitions, and that each partition must be replicated three times. Since we have a StatefulSet that defines three replicas, this will result in each Kafka broker having three partitions for this topic.

```
kafka-topics.sh --create --topic test --partitions 3 --replication-factor 3 --bootstrap-server localhost:9092
```

Show more

Verify the topic partitions are replicated across all three brokers:

```
kafka-topics.sh --describe --topic test --bootstrap-server localhost:9092
```

Show more

The output of the above command will be similar to the following:

```
Topic: test     TopicId: IxUIITk6RFOwIquWi-_dAA PartitionCount: 3       ReplicationFactor: 3    Configs: segment.bytes=1073741824
  Topic: test     Partition: 0    Leader: 0       Replicas: 1,2,0 Isr: 0,1,2
  Topic: test     Partition: 1    Leader: 0       Replicas: 0,2,1 Isr: 0,2,1
  Topic: test     Partition: 2    Leader: 0       Replicas: 0,2,1 Isr: 0,1,2
```

Show more

The output above shows there are 3 in-sync replicas. Keep in mind that each of the three partitions will have a random leader from the three available brokers. In the output above, Broker 0 is the leader for all three partitions (your cluster will likely have different leaders).

Now we will simulate a loss of one of the brokers by deleting the associated pod. Open a new local terminal for the following command:

```
kubectl delete pod kafka-1
```

Show more

In the remote `kafka-0` terminal, quickly check topic replication to see that only 2 replicas exist:

```
kafka-topics.sh --describe --topic test --bootstrap-server localhost:9092
```

Show more

The output of the command above will be similar to the following:

```
Topic: test     TopicId: IxUIITk6RFOwIquWi-_dAA PartitionCount: 3    ReplicationFactor: 3    Configs: segment.bytes=1073741824
  Topic: test     Partition: 0    Leader: 0   Replicas: 1,2,0  Isr: 0,2
  Topic: test     Partition: 1    Leader: 0   Replicas: 0,2,1  Isr: 0,2
  Topic: test     Partition: 2    Leader: 0   Replicas: 0,2,1  Isr: 0,2
```

Show more

Notice that there are only two in-sync replicas for each partition. It's possible that the time it took for you to get results from the previous command was longer than it took for the deleted replica to be replaced. If you see there are three in-sync replicas, then delete the pod again to catch the in-sync replica count drop as expected.

In the local terminal, get the pod status and wait until all three are running:

```
kubectl get pod -w
```

Show more

In the remote `kafka-0` terminal, check topic replication to ensure we are back to three replicas again:

```
kafka-topics.sh --describe --topic test --bootstrap-server localhost:9092
```

Show more

## Cleanup

If you just want to stop the Kafka pods, scale down the replicas on the StatefulSet:

```
kubectl scale statefulsets kafka --replicas=0
```

Show more

Note that scaling down a StatefulSet can only occur when all associated replicas are running and ready. See [this section](https://kubernetes.io/docs/tasks/run-application/scale-stateful-set/#scaling-down-does-not-work-right) of the Kubernetes docs for more details.

Scale the StatefulSet back up once you are ready to start Kafka again:

```
kubectl scale statefulsets kafka --replicas=3
```

Show more

Here are the steps to delete all components in the cluster and in your local Docker install:

```
docker rmi $DOCKER_USERNAME/kafka-kraft
kubectl delete -f kubernetes/kafka.yml
```

Show more

*Keep in mind that you will still have the Docker image available in your remote Docker Hub repo.*

Use the following commands to delete the shared storage on the Minikube node:

```
minikube ssh
sudo rm -rf /mnt/data
```

Show more

## Summary and next steps

This tutorial showed you how to get Kafka v2.8 running in KRaft mode on a Kubernetes cluster. Both Kafka and Kubernetes are popular technologies, and this tutorial hopefully gives some insight into how it is becoming even easier to use these two tools together.

The most obvious next step in learning more about Kafka in KRaft mode on Kubernetes would be to connect it to an application! There are many options here, and one such option would be making use of the [`kafkajs` library](https://kafka.js.org/) to connect a web application to Kafka.

Of course, you'll need to add a proper `livenessProbe` and `readinessProbe` to the Kafka `StatefulSet` configuration before connecting any application to this system. This would ensure that consumers and producers could read and write when they expect to be able to and it would improve the cluster stability.

Event-driven architecture provides a blueprint for creating highly-scalable systems. There are a number of considerations when it comes to scaling your application, and a great resource for more information on this topic is this pattern which shows how to [autoscale your microservices in Red Hat OpenShift using KEDA](https://developer.ibm.com/patterns/scaling-an-event-driven-architecture-with-kafka-on-openshift/) (Kubernetes-based Event Driven Autoscaler).