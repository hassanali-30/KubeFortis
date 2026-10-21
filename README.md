# KubeFortis

### Resilient Full-Stack Kubernetes Platform

KubeFortis is an internship-ready, on-premises Kubernetes platform built from
three Ubuntu 24.04 virtual machines. It demonstrates cluster bootstrapping, replicated
persistent storage, service discovery, load balancing, workload resilience,
network isolation, and recovery testing.

## What this project deploys

```text
LAN client
    |
    v
MetalLB LoadBalancer IP
    |
    v
nginx frontend (2 pods)
    |
    v
PostgREST API (2 pods)
    |
    v
PostgreSQL StatefulSet (1 pod)
    |
    v
Longhorn volume (2 replicas across 2 workers)
```

The cluster itself contains one control-plane node and two worker nodes. Calico
provides pod networking and enforces the included NetworkPolicies.

## Technology baseline

| Component | Version used by this repository |
|---|---|
| Ubuntu Server | 24.04 LTS |
| Kubernetes packages | 1.36 repository |
| Calico | 3.33.0 |
| Longhorn | 1.13.0 |
| MetalLB | 0.16.1 |
| PostgreSQL | 16.15 Alpine |
| PostgREST | 16.4 |
| nginx | stable Alpine |

The infrastructure versions were checked against official documentation on
2026-10-19. Re-check compatibility before using this outside the lab.

## Repository map

```text
.
|-- cluster/                  # Three-node kubeadm setup scripts
|-- manifests/                # Kubernetes application manifests
|-- scripts/                  # Deploy, verify, test, and evidence helpers
|-- docs/                     # Architecture, runbook, report, and viva notes
|-- evidence/                 # Generated test evidence (ignored by Git)
|-- config.example.env        # Environment-specific values to copy and edit
|-- Makefile                  # Short commands for common operations
`-- tools/validate_manifests.py
```

See [docs/PROJECT_STATUS.md](docs/PROJECT_STATUS.md) for the exact distinction
between completed repository work and tests that require the target VMs.

For a demonstration on one existing MicroK8s VM, use the separate
[single-VM profile](docs/MICROK8S_SINGLE_VM.md). It does not change or overstate
the original three-node Longhorn architecture.

## Minimum lab resources

- Three Ubuntu Server 24.04 VMs on the same LAN.
- At least 2 vCPU and 2 GiB RAM per VM; 4 GiB on workers is recommended.
- At least 25 GiB disk per VM.
- One fixed IP for each VM and a small unused LAN range for MetalLB.
- Internet access during installation and `sudo` access on each VM.

Do not reuse the sample IP addresses blindly. Confirm that the node and
MetalLB addresses are free and outside the DHCP pool.

## Quick start

### 1. Configure the project

Run on the control-plane VM after copying this repository to it:

```bash
cp config.example.env config.env
nano config.env
set -a
source config.env
set +a
```

### 2. Build the cluster

Follow [docs/BUILD_FROM_SCRATCH.md](docs/BUILD_FROM_SCRATCH.md). The scripts
are deliberately split by stage so that every important operation can be
observed and explained during an internship demonstration.

### 3. Validate the files before deployment

```bash
python3 tools/validate_manifests.py
```

If `kubectl` is connected to the cluster, also run:

```bash
kubectl apply --dry-run=client -k manifests
```

### 4. Create the database Secret

```bash
./scripts/create-secret.sh
```

The password is entered interactively and is never saved in this repository.
Use only letters and numbers in this lab because PostgREST receives a database
connection URI.

### 5. Deploy and verify

```bash
./scripts/deploy.sh
./scripts/verify.sh
```

Install and configure MetalLB when the application is healthy:

```bash
./cluster/05-install-metallb.sh
kubectl get service frontend -n fullstack --watch
```

Open the assigned `EXTERNAL-IP` using plain HTTP.

## Demonstration workflow

1. Show all three nodes as `Ready`.
2. Show two frontend and two backend pods on the workers.
3. Load the web page and refresh the PostgreSQL data.
4. Delete one frontend or backend pod and show uninterrupted responses.
5. Delete `postgres-0`, wait for recovery, and prove the rows remain.
6. Delete one Longhorn replica and show it rebuild to `healthy`.
7. Collect timestamped evidence with `./scripts/collect-evidence.sh`.

The exact procedure and stop conditions are in
[docs/TEST_PLAN.md](docs/TEST_PLAN.md). Do not run the node-power-off test on a
shared or production cluster.

## Important boundaries

- This is a learning and internship lab, not a production platform.
- The included API is intentionally read-only to unauthenticated clients.
- Kubernetes Secrets are base64-encoded, not encrypted at rest by default.
- A single control-plane node is not control-plane high availability.
- Longhorn data replication is not a backup. Export or snapshot important data.
- The repository can be validated locally, but successful live deployment must
  be proven on the three Ubuntu VMs with the checks in `scripts/verify.sh`.

## Official references

- [Install kubeadm](https://v1-36.docs.kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)
- [Calico on-premises installation](https://docs.tigera.io/calico/latest/getting-started/kubernetes/self-managed-onprem/onpremises)
- [Longhorn kubectl installation](https://longhorn.io/docs/1.13.0/deploy/install/install-with-kubectl/)
- [MetalLB installation](https://metallb.io/installation/)

