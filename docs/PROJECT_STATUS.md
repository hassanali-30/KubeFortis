# KubeNova Project Status

Status date: 2026-10-21

## Completed in the repository

- Three-node kubeadm setup scripts for Ubuntu 24.04.
- Versioned Calico, Longhorn, and MetalLB installation stages.
- Namespace, ConfigMaps, two-replica StorageClass, PVC, Secret workflow,
  PostgreSQL StatefulSet, redundant API and frontend Deployments, Services,
  PodDisruptionBudgets, and NetworkPolicies.
- Automatic database schema and sample-data initialization on a fresh volume.
- Deployment, verification, controlled failure-test, and evidence scripts.
- A single-node MicroK8s overlay with hostpath storage, NodePort access,
  resolver preflight and system-workload readiness checks.
- Architecture, troubleshooting, test-plan, report, and viva documentation.
- A GitHub Actions workflow with immutable official action revisions,
  checksum-verified tooling, ShellCheck, and strict schema validation.

## Validation completed locally and in GitHub Actions

- Offline project validator: **PASS**.
- Base Kubernetes resources parsed: **19 resources in 9 deployable files**.
- Base Kubeconform strict Kubernetes 1.36 validation: **19 valid, 0 invalid,
  0 errors, 0 skipped**.
- Rendered MicroK8s overlay validation: **18 valid, 0 invalid, 0 errors,
  0 skipped**.
- Bash syntax validation: **PASS** for all cluster and application scripts.
- ShellCheck validation: **PASS** for all cluster and application scripts.
- Placeholder Secret and MetalLB examples are excluded from Kustomize: **PASS**.
- Repository privacy and credential-signature scans: **PASS**.

## Pending on the target lab

- Provision and address the three Ubuntu VMs.
- Run cluster bootstrap and join both workers.
- Confirm Calico and Longhorn health.
- Create the real Secret and deploy the application.
- Confirm the MetalLB address from another LAN machine.
- Execute T1-T7 and attach timestamped evidence.

The project is repository-complete and schema-valid. It must not be described as
live-deployed or resilience-tested until the target-lab items above are complete.

