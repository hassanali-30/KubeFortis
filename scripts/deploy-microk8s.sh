#!/usr/bin/env bash
set -Eeuo pipefail

cd "$(dirname "$0")/.."
KUBECTL=(sudo microk8s kubectl)

if ! sudo microk8s status --wait-ready >/dev/null; then
  echo "MicroK8s is not ready." >&2
  exit 1
fi

available_kib="$(df --output=avail / | tail -1 | tr -d ' ')"
if [[ "$available_kib" -lt 1048576 ]]; then
  echo "At least 1 GiB free disk space is required to pull the application images." >&2
  df -h /
  exit 1
fi
if [[ "$available_kib" -lt 2097152 ]]; then
  echo "Warning: less than the recommended 2 GiB is free; watch disk usage during deployment." >&2
fi

sudo microk8s enable dns hostpath-storage
"${KUBECTL[@]}" apply -f manifests/00-namespace.yaml

if ! "${KUBECTL[@]}" get secret db-secret -n fullstack >/dev/null 2>&1; then
  read -r -s -p "Database password (12-64 letters and numbers): " DB_PASSWORD
  echo
  if [[ ! "$DB_PASSWORD" =~ ^[A-Za-z0-9]{12,64}$ ]]; then
    echo "Password must contain 12-64 letters and numbers." >&2
    exit 1
  fi
  "${KUBECTL[@]}" create secret generic db-secret \
    --namespace fullstack \
    --from-literal=POSTGRES_USER=appuser \
    --from-literal=POSTGRES_PASSWORD="$DB_PASSWORD"
fi

"${KUBECTL[@]}" apply -k overlays/microk8s-single-node
"${KUBECTL[@]}" rollout status statefulset/postgres -n fullstack --timeout=10m
"${KUBECTL[@]}" rollout status deployment/backend -n fullstack --timeout=5m
"${KUBECTL[@]}" rollout status deployment/frontend -n fullstack --timeout=5m

echo "Deployment complete. Open http://$(hostname -I | awk '{print $1}'):30080"

