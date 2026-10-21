#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ENV="${PROJECT_ENV:-./config.env}"
if [[ ! -f "$PROJECT_ENV" ]]; then
  echo "Missing $PROJECT_ENV. Copy config.example.env to config.env first." >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$PROJECT_ENV"

if [[ "$(hostname)" != "$CONTROL_PLANE_NAME" ]]; then
  echo "Run this only on $CONTROL_PLANE_NAME; current hostname is $(hostname)." >&2
  exit 1
fi

if [[ ! -f /etc/kubernetes/admin.conf ]]; then
  sudo kubeadm init \
    --apiserver-advertise-address="$CONTROL_PLANE_IP" \
    --pod-network-cidr="$POD_CIDR"
else
  echo "Existing control-plane configuration detected; kubeadm init was skipped."
fi

mkdir -p "$HOME/.kube"
sudo cp /etc/kubernetes/admin.conf "$HOME/.kube/config"
sudo chown "$(id -u):$(id -g)" "$HOME/.kube/config"

if kubectl get installation.operator.tigera.io default >/dev/null 2>&1; then
  echo "Existing Calico installation detected; install manifests were skipped."
else
  kubectl create -f "https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/v3_projectcalico_org.yaml"
  kubectl create -f "https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/tigera-operator.yaml"
  curl -fsSL "https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/custom-resources.yaml" \
    | sed "s#192.168.0.0/16#${POD_CIDR}#g" \
    | kubectl create -f -
fi

echo
echo "Calico submitted. Watch readiness with: watch kubectl get tigerastatus"
echo "Run the following command on each worker:"
kubeadm token create --print-join-command

