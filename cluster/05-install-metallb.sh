#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ENV="${PROJECT_ENV:-./config.env}"
if [[ ! -f "$PROJECT_ENV" ]]; then
  echo "Missing $PROJECT_ENV. Copy config.example.env to config.env first." >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$PROJECT_ENV"

if [[ ! "$METALLB_RANGE" =~ ^[0-9.]+-[0-9.]+$ ]]; then
  echo "METALLB_RANGE must look like 192.0.2.240-192.0.2.245" >&2
  exit 1
fi

kubectl apply -f "https://raw.githubusercontent.com/metallb/metallb/${METALLB_VERSION}/config/manifests/metallb-native.yaml"
kubectl wait --for=condition=Available deployment/controller -n metallb-system --timeout=5m
kubectl rollout status daemonset/speaker -n metallb-system --timeout=5m

cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: lab-pool
  namespace: metallb-system
spec:
  addresses:
    - ${METALLB_RANGE}
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: lab-l2
  namespace: metallb-system
spec:
  ipAddressPools:
    - lab-pool
EOF

kubectl get ipaddresspool,l2advertisement -n metallb-system
kubectl get service frontend -n fullstack

