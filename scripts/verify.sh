#!/usr/bin/env bash
set -Eeuo pipefail

NAMESPACE=fullstack
failures=0

check() {
  local description="$1"
  shift
  printf '%-55s' "$description"
  if "$@" >/dev/null 2>&1; then
    echo "PASS"
  else
    echo "FAIL"
    failures=$((failures + 1))
  fi
}

check "Three Kubernetes nodes are Ready" bash -c \
  '[[ $(kubectl get nodes --no-headers | awk '\''$2 == "Ready" {c++} END {print c+0}'\'') -eq 3 ]]'
check "PostgreSQL rollout is complete" kubectl rollout status statefulset/postgres -n "$NAMESPACE" --timeout=5s
check "Backend rollout is complete" kubectl rollout status deployment/backend -n "$NAMESPACE" --timeout=5s
check "Frontend rollout is complete" kubectl rollout status deployment/frontend -n "$NAMESPACE" --timeout=5s
check "PostgreSQL PVC is Bound" bash -c \
  '[[ $(kubectl get pvc postgres-pvc -n fullstack -o jsonpath="{.status.phase}") == Bound ]]'
check "Frontend has two Ready replicas" bash -c \
  '[[ $(kubectl get deployment frontend -n fullstack -o jsonpath="{.status.readyReplicas}") == 2 ]]'
check "Backend has two Ready replicas" bash -c \
  '[[ $(kubectl get deployment backend -n fullstack -o jsonpath="{.status.readyReplicas}") == 2 ]]'

echo
echo "Live resources:"
kubectl get nodes -o wide
kubectl get pods,service,pvc -n "$NAMESPACE" -o wide

echo
echo "End-to-end API response:"
if kubectl exec -n "$NAMESPACE" deployment/frontend -- \
  wget -qO- 'http://127.0.0.1:8080/api/items?select=id,name&order=id.asc'; then
  echo
else
  echo "End-to-end request failed." >&2
  failures=$((failures + 1))
fi

if [[ "$failures" -gt 0 ]]; then
  echo "$failures verification check(s) failed." >&2
  exit 1
fi
echo "All automated checks passed."

