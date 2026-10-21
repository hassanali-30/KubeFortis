# Viva and Demonstration Notes

## Core questions

**Why is PostgreSQL a StatefulSet?**  It needs stable identity, ordered lifecycle
behavior, and persistent storage. The stateless web and API tiers do not.

**Why is PostgreSQL only one pod?**  A second ordinary pod cannot safely share a
single ReadWriteOnce data directory. Database high availability requires
database-aware replication, not merely increasing the replica count.

**What does Longhorn replicate?**  The block volume, with one replica on each
worker. It improves node/disk fault tolerance but is not an independent backup.

**What does MetalLB do?**  It assigns and advertises a LAN address for a
LoadBalancer Service in an environment without a cloud load balancer.

**Why use a headless database Service?**  It provides stable DNS directly to the
StatefulSet pod without load-balancing multiple database writers.

**ConfigMap versus Secret?**  A ConfigMap stores non-sensitive settings. A
Secret stores sensitive values, although Kubernetes Secrets require additional
cluster configuration to be encrypted at rest.

**Readiness versus liveness?**  Readiness controls whether a pod receives
Service traffic. Liveness decides when Kubernetes should restart a stuck
container.

**Why two frontend and backend pods?**  One can serve while the other is
replaced or updated. This does not make the single database continuously
available.

**What does the NetworkPolicy achieve?**  It defaults the namespace to deny and
opens only client-to-frontend, frontend-to-backend, backend-to-database, and DNS
paths.

**What proves persistence?**  Rows inserted before deleting `postgres-0` remain
after Kubernetes recreates the pod and reattaches the Longhorn volume.

## Honest project status wording

Before live deployment: "The repository and manifests passed offline structural
validation; cluster deployment remains to be demonstrated."

After live acceptance: "The three-node deployment passed the recorded rollout,
API, persistence, and recovery tests shown in the evidence folder."

Never call YAML parsing alone a successful Kubernetes deployment.

