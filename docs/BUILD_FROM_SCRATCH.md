# Build the Three-Node Cluster From Scratch

This runbook turns three clean Ubuntu Server 24.04 VMs into the cluster used by
the application. Run one stage at a time and do not continue when its checks
fail.

## 1. Plan the network

Reserve three fixed node addresses and a separate unused address range for
MetalLB. The pod CIDR must not overlap the LAN.

Copy the repository to each VM, then create the configuration file on every VM:

```bash
cd kubernetes-fullstack-internship
cp config.example.env config.env
nano config.env
chmod +x cluster/*.sh scripts/*.sh
```

Use identical `config.env` content on all three nodes.

## 2. Prepare every node

Run the matching command on each VM:

```bash
# Control plane
sudo -v
./cluster/01-prepare-node.sh k8s-control

# Worker 1
sudo -v
./cluster/01-prepare-node.sh k8s-worker1

# Worker 2
sudo -v
./cluster/01-prepare-node.sh k8s-worker2
```

Use the names from your `config.env`, not necessarily the sample names above.
Reboot each VM when the script finishes:

```bash
sudo reboot
```

After reconnecting, verify on each VM:

```bash
hostname
swapon --show
systemctl is-active containerd iscsid
df -h /
```

Stop if swap output is non-empty, either service is inactive, or a worker has
less than roughly 15 GiB free space.

## 3. Install Kubernetes packages on every node

```bash
cd kubernetes-fullstack-internship
./cluster/02-install-kubernetes.sh
```

The kubelet may restart until the node joins a cluster. That is expected.

## 4. Initialize the control plane

Run only on the control-plane VM:

```bash
./cluster/03-init-control-plane.sh
watch kubectl get tigerastatus
```

Wait until all Calico status rows are available, then check:

```bash
kubectl get nodes -o wide
kubectl get pods -A -o wide
```

The control-plane node must be `Ready` before continuing.

## 5. Join the workers

The control-plane script prints a `kubeadm join` command. Run it with `sudo` on
both workers. If it has expired, generate a new command on the control plane:

```bash
kubeadm token create --print-join-command
```

Then verify on the control plane:

```bash
kubectl get nodes -o wide
```

Stop until all three nodes are `Ready`.

## 6. Install Longhorn

The node-preparation script already installs `open-iscsi` and `nfs-common`.
On the control plane, run:

```bash
./cluster/04-install-longhorn.sh
```

Required result:

```bash
kubectl get nodes.longhorn.io -n longhorn-system
kubectl get pods -n longhorn-system
```

Both worker storage nodes must report ready and all required Longhorn pods must
be running. If not, inspect free disk space before retrying.

## 7. Deploy the application

```bash
python3 tools/validate_manifests.py
./scripts/create-secret.sh
./scripts/deploy.sh
./scripts/verify.sh
```

The deployment creates a two-replica Longhorn StorageClass, a 5 GiB claim, one
PostgreSQL StatefulSet pod, two PostgREST pods, and two nginx pods.

## 8. Install MetalLB

Confirm again that `METALLB_RANGE` contains unused addresses outside the DHCP
pool. A ping test is useful but does not prove an address is unassigned.

```bash
./cluster/05-install-metallb.sh
kubectl get service frontend -n fullstack --watch
```

When an external address appears, test it:

```bash
FRONTEND_IP="$(kubectl get service frontend -n fullstack -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
curl --fail "http://${FRONTEND_IP}/api/items?select=id,name&order=id.asc"
```

Open `http://FRONTEND_IP` in a browser on the same LAN.

## 9. Final acceptance gate

The project is live only when all of the following are true:

- Three nodes are `Ready`.
- Calico and Longhorn system pods are healthy.
- The PostgreSQL claim is `Bound`.
- PostgreSQL, backend, and frontend rollouts complete.
- Both frontend and both backend replicas are ready.
- The in-cluster API check returns the two seeded rows.
- The MetalLB address loads the page from another LAN machine.
- A database-pod restart preserves the rows.

Local YAML validation alone does not satisfy this gate.

