# Run on One Existing MicroK8s VM

This profile is for a demonstration on one Ubuntu VM. It keeps the original
three-node kubeadm and Longhorn files unchanged, but substitutes:

- `microk8s-hostpath` for the two-replica Longhorn StorageClass;
- NodePort `30080` for MetalLB LAN address allocation.

These substitutions make the demo runnable without claiming storage or node
high availability that a single VM cannot provide.

```bash
cd ~/kubernetes-fullstack-internship
chmod +x scripts/deploy-microk8s.sh
./scripts/deploy-microk8s.sh
```

The script requires MicroK8s to be ready and at least 1 GiB of free disk space. At least 2 GiB is recommended.
After deployment, open `http://VM_IP:30080`.

