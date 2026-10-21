#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ENV="${PROJECT_ENV:-./config.env}"
if [[ ! -f "$PROJECT_ENV" ]]; then
  echo "Missing $PROJECT_ENV. Copy config.example.env to config.env first." >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$PROJECT_ENV"

ready_nodes="$(kubectl get nodes --no-headers 2>/dev/null | awk '$2 == "Ready" {count++} END {print count+0}')"
if [[ "$ready_nodes" -lt 3 ]]; then
  echo "Expected 3 Ready nodes, found $ready_nodes. Longhorn installation stopped." >&2
  kubectl get nodes -o wide || true
  exit 1
fi

kubectl apply -f "https://raw.githubusercontent.com/longhorn/longhorn/${LONGHORN_VERSION}/deploy/longhorn.yaml"
kubectl wait --for=condition=Ready pod --all -n longhorn-system --timeout=15m
kubectl get nodes.longhorn.io -n longhorn-system

for worker in "$WORKER1_NAME" "$WORKER2_NAME"; do
  worker_ready="$(kubectl get nodes.longhorn.io "$worker" -n longhorn-system \
    -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || true)"
  if [[ "$worker_ready" != "True" ]]; then
    echo "Longhorn worker $worker is not ready. Do not deploy PostgreSQL yet." >&2
    exit 1
  fi
done

echo "Longhorn is ready. The application StorageClass will request two replicas."

