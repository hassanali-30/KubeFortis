# KubeFortis Internship Project Report

## Title

KubeFortis: Design and Implementation of a Resilient Stateful Full-Stack
Application on a Three-Node Kubernetes Cluster

## Abstract

KubeFortis designs and implements an on-premises Kubernetes environment on
three Ubuntu virtual machines. The platform uses kubeadm and containerd for
cluster bootstrapping, Calico for container networking and policy enforcement,
Longhorn for two-replica persistent storage, and MetalLB for local-network
service exposure. A full-stack application demonstrates the platform through
an nginx frontend, a two-replica PostgREST API, and a PostgreSQL StatefulSet.
Health probes, resource controls, rolling updates, topology spreading,
disruption budgets, Secrets, and default-deny NetworkPolicies improve
reliability and security. Controlled pod, storage-replica, and worker-failure
tests evaluate service recovery and data persistence. Final results must be
completed from live evidence generated on the three-node cluster.

## Problem statement

Stateful applications are more difficult to operate than stateless workloads
because compute instances may be replaced while data must remain consistent and
available. The project explores how Kubernetes and replicated software-defined
storage can provide repeatable deployment and bounded failure recovery in a
small on-premises lab.

## Objectives

1. Build a three-node Kubernetes cluster from clean Ubuntu Server VMs.
2. provide cross-node pod networking and namespace-level network isolation.
3. Deploy a stateful database with replicated persistent storage.
4. Deploy redundant frontend and backend services with health checks.
5. Expose the application to the LAN without a cloud load balancer.
6. Test pod replacement, scaling, data persistence, replica rebuild, and node
   recovery.
7. Produce repeatable commands and timestamped technical evidence.

## Methodology

The implementation follows an incremental method. Node prerequisites and the
container runtime are configured first. kubeadm creates the control plane and
joins two workers. Calico is installed before workloads, followed by Longhorn
and its two-replica StorageClass. Application resources are deployed through
Kustomize after a database Secret is created out of band. MetalLB assigns a LAN
address only after internal health checks pass. Each resilience test begins
from a verified baseline and has an explicit stop condition.

## Implementation summary

| Layer | Implementation |
|---|---|
| Cluster | kubeadm, kubelet, kubectl, containerd |
| Network | Calico CNI and NetworkPolicy |
| Storage | Longhorn, two replicas, 5 GiB PVC |
| Database | PostgreSQL 16 StatefulSet |
| API | Two PostgREST replicas, read-only anonymous role |
| Web | Two nginx replicas and reverse proxy |
| Exposure | MetalLB layer-2 LoadBalancer |
| Validation | Offline manifest checks plus live rollout and API tests |

## Results

Complete this section only after live testing.

| Test | Measured outage | Data intact | Result | Evidence ID |
|---|---:|---|---|---|
| Delete one frontend pod | TBD | N/A | TBD | TBD |
| Delete one backend pod | TBD | N/A | TBD | TBD |
| Restart PostgreSQL pod | TBD | TBD | TBD | TBD |
| Delete one Longhorn replica | TBD | TBD | TBD | TBD |
| Move database to other worker | TBD | TBD | TBD | TBD |
| Power off database worker | TBD | TBD | TBD | TBD |

## Limitations

The lab has a single control-plane node, one active PostgreSQL instance, plain
HTTP, no external identity provider, and no off-cluster backup. Longhorn
replication improves local availability but does not replace backup or disaster
recovery. Results are valid only for the tested VM resources and network.

## Conclusion

Write the final conclusion after completing the result table. It should compare
observed recovery behavior with expected behavior, identify the largest outage,
and propose the next improvement, such as control-plane redundancy, TLS,
external Secret management, monitoring, or scheduled backups.

