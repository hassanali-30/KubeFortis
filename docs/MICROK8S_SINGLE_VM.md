# Run on One Existing MicroK8s VM

This profile is for a demonstration on one Ubuntu VM. It keeps the original
three-node kubeadm and Longhorn files unchanged, but substitutes:

- `microk8s-hostpath` for the two-replica Longhorn StorageClass;
- NodePort `30080` for MetalLB LAN address allocation.

These substitutions make the demo runnable without claiming storage or node
high availability that a single VM cannot provide.

```bash
cd ~/KubeFortis
chmod +x scripts/deploy-microk8s.sh
./scripts/deploy-microk8s.sh
```

The script requires MicroK8s to be ready and at least 1 GiB of free disk space.
At least 2 GiB is recommended. It also checks the resolver file configured by
the MicroK8s kubelet. If the file is missing on a systemd-resolved host, the
script resets and restarts that service, verifies the resolver file, and waits
for Calico, CoreDNS, and the hostpath provisioner before deploying the app.
After deployment, open `http://VM_IP:30080`.

