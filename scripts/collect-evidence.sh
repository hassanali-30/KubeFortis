#!/usr/bin/env bash
set -Eeuo pipefail

stamp="$(date -u +%Y%m%dT%H%M%SZ)"
destination="evidence/$stamp"
mkdir -p "$destination"

kubectl version -o yaml >"$destination/kubernetes-version.yaml"
kubectl get nodes -o wide >"$destination/nodes.txt"
kubectl get all,pvc,configmap,networkpolicy -n fullstack -o wide >"$destination/application.txt"
kubectl get events -n fullstack --sort-by=.lastTimestamp >"$destination/events.txt"
kubectl get storageclass,pv >"$destination/storage.txt"
kubectl get volumes.longhorn.io,replicas.longhorn.io -n longhorn-system -o wide >"$destination/longhorn.txt"
kubectl get service frontend -n fullstack -o yaml >"$destination/frontend-service.yaml"
kubectl logs statefulset/postgres -n fullstack --tail=100 >"$destination/postgres.log"
kubectl logs deployment/backend -n fullstack --tail=100 >"$destination/backend.log"

echo "Evidence saved to $destination"
echo "Secrets are not collected. Review every file before sharing it."

