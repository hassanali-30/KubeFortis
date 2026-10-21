#!/usr/bin/env bash
set -Eeuo pipefail

command -v kubectl >/dev/null || { echo "kubectl is required." >&2; exit 1; }
kubectl apply -f manifests/00-namespace.yaml >/dev/null

read -r -p "Database user [appuser]: " DB_USER
DB_USER="${DB_USER:-appuser}"
read -r -s -p "Database password (letters and numbers only): " DB_PASSWORD
echo

if [[ ! "$DB_USER" =~ ^[a-z_][a-z0-9_]{2,30}$ ]]; then
  echo "Use a lowercase PostgreSQL-style username." >&2
  exit 1
fi
if [[ ! "$DB_PASSWORD" =~ ^[A-Za-z0-9]{12,64}$ ]]; then
  echo "Password must contain 12-64 letters and numbers." >&2
  exit 1
fi

kubectl create secret generic db-secret \
  --namespace fullstack \
  --from-literal=POSTGRES_USER="$DB_USER" \
  --from-literal=POSTGRES_PASSWORD="$DB_PASSWORD" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Secret db-secret created without writing the password to disk."

