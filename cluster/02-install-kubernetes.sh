#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ENV="${PROJECT_ENV:-./config.env}"
if [[ ! -f "$PROJECT_ENV" ]]; then
  echo "Missing $PROJECT_ENV. Copy config.example.env to config.env first." >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$PROJECT_ENV"

sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL "https://pkgs.k8s.io/core:/stable:/${KUBERNETES_MINOR}/deb/Release.key" \
  | sudo gpg --dearmor --yes -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${KUBERNETES_MINOR}/deb/ /" \
  | sudo tee /etc/apt/sources.list.d/kubernetes.list >/dev/null

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable --now kubelet

kubeadm version
echo "Kubernetes packages installed. kubelet restart loops are normal until the node joins a cluster."

