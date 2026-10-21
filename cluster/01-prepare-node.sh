#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ENV="${PROJECT_ENV:-./config.env}"
if [[ ! -f "$PROJECT_ENV" ]]; then
  echo "Missing $PROJECT_ENV. Copy config.example.env to config.env first." >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$PROJECT_ENV"

NODE_NAME="${1:-}"
if [[ -z "$NODE_NAME" ]]; then
  echo "Usage: $0 <${CONTROL_PLANE_NAME}|${WORKER1_NAME}|${WORKER2_NAME}>" >&2
  exit 1
fi

case "$NODE_NAME" in
  "$CONTROL_PLANE_NAME"|"$WORKER1_NAME"|"$WORKER2_NAME") ;;
  *) echo "Node name is not present in config.env: $NODE_NAME" >&2; exit 1 ;;
esac

echo "Preparing $(hostname) as $NODE_NAME"
sudo hostnamectl set-hostname "$NODE_NAME"

sudo sed -i \
  -e '/# BEGIN kubernetes-fullstack-lab/,/# END kubernetes-fullstack-lab/d' \
  -e '/# BEGIN kubefortis/,/# END kubefortis/d' \
  /etc/hosts
printf '\n# BEGIN kubefortis\n%s %s\n%s %s\n%s %s\n# END kubefortis\n' \
  "$CONTROL_PLANE_IP" "$CONTROL_PLANE_NAME" \
  "$WORKER1_IP" "$WORKER1_NAME" \
  "$WORKER2_IP" "$WORKER2_NAME" | sudo tee -a /etc/hosts >/dev/null

sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

printf 'overlay\nbr_netfilter\n' | sudo tee /etc/modules-load.d/k8s.conf >/dev/null
sudo modprobe overlay
sudo modprobe br_netfilter

printf '%s\n' \
  'net.bridge.bridge-nf-call-iptables = 1' \
  'net.bridge.bridge-nf-call-ip6tables = 1' \
  'net.ipv4.ip_forward = 1' | sudo tee /etc/sysctl.d/kubernetes.conf >/dev/null
sudo sysctl --system >/dev/null

sudo apt-get update
sudo apt-get install -y containerd open-iscsi nfs-common curl ca-certificates gpg apt-transport-https python3-yaml
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl enable --now containerd iscsid

echo "Node preparation complete. Reboot this VM before installing Kubernetes packages."
echo "After reboot, confirm: hostname; swapon --show; systemctl is-active containerd iscsid"

