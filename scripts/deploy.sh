#!/usr/bin/env bash
set -Eeuo pipefail

command -v kubectl >/dev/null || { echo "kubectl is required." >&2; exit 1; }
kubectl cluster-info >/dev/null

kubectl apply -f manifests/00-namespace.yaml
if ! kubectl get secret db-secret -n fullstack >/dev/null 2>&1; then
  echo "Missing db-secret. Run ./scripts/create-secret.sh first." >&2
  exit 1
fi
if ! kubectl get crd volumes.longhorn.io >/dev/null 2>&1; then
  echo "Longhorn does not appear to be installed. Run cluster/04-install-longhorn.sh first." >&2
  exit 1
fi

kubectl apply -k manifests
kubectl rollout status statefulset/postgres -n fullstack --timeout=10m
kubectl rollout status deployment/backend -n fullstack --timeout=5m
kubectl rollout status deployment/frontend -n fullstack --timeout=5m

echo "Application rollout completed. Run ./scripts/verify.sh for end-to-end checks."

