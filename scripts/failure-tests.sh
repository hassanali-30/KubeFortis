#!/usr/bin/env bash
set -Eeuo pipefail

NAMESPACE=fullstack
TEST="${1:-help}"

case "$TEST" in
  frontend-pod)
    pod="$(kubectl get pod -n "$NAMESPACE" -l app.kubernetes.io/name=frontend -o jsonpath='{.items[0].metadata.name}')"
    kubectl delete pod -n "$NAMESPACE" "$pod"
    kubectl rollout status deployment/frontend -n "$NAMESPACE" --timeout=3m
    ;;
  backend-pod)
    pod="$(kubectl get pod -n "$NAMESPACE" -l app.kubernetes.io/name=backend -o jsonpath='{.items[0].metadata.name}')"
    kubectl delete pod -n "$NAMESPACE" "$pod"
    kubectl rollout status deployment/backend -n "$NAMESPACE" --timeout=3m
    ;;
  database-pod)
    echo "This restarts PostgreSQL and may cause a brief application outage."
    kubectl delete pod postgres-0 -n "$NAMESPACE"
    kubectl rollout status statefulset/postgres -n "$NAMESPACE" --timeout=10m
    kubectl exec -n "$NAMESPACE" postgres-0 -- sh -c \
      'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "TABLE api.items;"'
    ;;
  scale-backend)
    kubectl scale deployment/backend -n "$NAMESPACE" --replicas=3
    kubectl rollout status deployment/backend -n "$NAMESPACE" --timeout=3m
    kubectl get pod -n "$NAMESPACE" -l app.kubernetes.io/name=backend -o wide
    kubectl scale deployment/backend -n "$NAMESPACE" --replicas=2
    kubectl rollout status deployment/backend -n "$NAMESPACE" --timeout=3m
    ;;
  help|*)
    cat <<'EOF'
Usage: ./scripts/failure-tests.sh TEST

Safe, bounded tests:
  frontend-pod   Delete one frontend pod and wait for replacement
  backend-pod    Delete one backend pod and wait for replacement
  database-pod   Restart PostgreSQL and confirm persisted rows
  scale-backend  Scale backend 2 -> 3 -> 2

Longhorn replica deletion and whole-node shutdown are intentionally manual.
Use docs/TEST_PLAN.md for their stop conditions and recovery steps.
EOF
    ;;
esac

