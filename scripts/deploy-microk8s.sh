#!/usr/bin/env bash
set -Eeuo pipefail

cd "$(dirname "$0")/.."
KUBECTL=(sudo microk8s kubectl)

if ! sudo microk8s status --wait-ready >/dev/null; then
  echo "MicroK8s is not ready." >&2
  exit 1
fi

kubelet_args=/var/snap/microk8s/current/args/kubelet
resolver_conf="$(sudo awk -F= '$1 == "--resolv-conf" { print $2 }' "$kubelet_args" 2>/dev/null | tail -1)"
resolver_conf="${resolver_conf:-/run/systemd/resolve/resolv.conf}"

if [[ ! -s "$resolver_conf" ]]; then
  echo "MicroK8s resolver file is missing: $resolver_conf"
  if systemctl cat systemd-resolved.service >/dev/null 2>&1; then
    echo "Repairing the systemd-resolved service..."
    sudo systemctl reset-failed systemd-resolved
    sudo systemctl restart systemd-resolved
    for _ in {1..10}; do
      [[ -s "$resolver_conf" ]] && break
      sleep 1
    done
  fi
fi

if [[ ! -s "$resolver_conf" ]]; then
  echo "MicroK8s cannot start pods because its resolver file is unavailable: $resolver_conf" >&2
  echo "Check: sudo systemctl status systemd-resolved --no-pager -l" >&2
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

sudo microk8s enable dns
sudo microk8s enable hostpath-storage

for workload in \
  daemonset/calico-node \
  deployment/calico-kube-controllers \
  deployment/coredns \
  deployment/hostpath-provisioner; do
  if "${KUBECTL[@]}" get "$workload" -n kube-system >/dev/null 2>&1; then
    "${KUBECTL[@]}" rollout status "$workload" -n kube-system --timeout=5m
  fi
done

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

