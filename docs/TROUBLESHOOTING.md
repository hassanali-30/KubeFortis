# Troubleshooting Runbook

Start with the smallest useful view:

```bash
kubectl get nodes -o wide
kubectl get pods -A -o wide
kubectl get events -n fullstack --sort-by=.lastTimestamp | tail -30
```

## Node remains NotReady

```bash
kubectl get tigerastatus
kubectl get pods -n calico-system -o wide
sudo systemctl status kubelet --no-pager
sudo journalctl -u kubelet --since '30 minutes ago' --no-pager | tail -100
```

Check that swap is off, `net.ipv4.ip_forward=1`, containerd is active, node
addresses are unique, and the pod CIDR does not overlap the LAN.

## Longhorn is not ready

On each worker:

```bash
df -h /
systemctl is-active iscsid
sudo journalctl -u iscsid --since '30 minutes ago' --no-pager | tail -50
```

On the control plane:

```bash
kubectl get nodes.longhorn.io -n longhorn-system
kubectl get pods -n longhorn-system -o wide
kubectl get events -n longhorn-system --sort-by=.lastTimestamp | tail -30
```

Full worker disks commonly cause evictions and failed Longhorn readiness.

## PostgreSQL claim remains Pending

```bash
kubectl describe pvc postgres-pvc -n fullstack
kubectl get storageclass
kubectl get pods -n longhorn-system
```

The `longhorn-2replica` class must exist and Longhorn must have two usable
storage nodes.

## PostgreSQL crashes

```bash
kubectl logs postgres-0 -n fullstack --previous
kubectl describe pod postgres-0 -n fullstack
```

If authentication fails after changing the Secret, remember that PostgreSQL
uses the password from its first database initialization. Restoring consistency
requires either changing the role password inside PostgreSQL or deliberately
recreating the lab data volume. Do not delete the PVC casually.

## Backend is not ready

```bash
kubectl logs deployment/backend -n fullstack --tail=100
kubectl describe deployment backend -n fullstack
kubectl get endpoints backend postgres -n fullstack
```

Typical causes are an absent Secret, an invalid password, PostgreSQL not ready,
or the database initialization script not running because an older PVC already
contains a database.

## Pods remain in ContainerCreating and deployment times out

Check recent events:

```bash
sudo microk8s kubectl get events -A --sort-by=.lastTimestamp
```

If events report that `/run/systemd/resolve/resolv.conf` does not exist, the
host resolver service has failed and MicroK8s cannot create pod sandboxes. The
single-VM deployment script detects and repairs this condition. To repair it
manually, run:

```bash
sudo systemctl reset-failed systemd-resolved
sudo systemctl restart systemd-resolved
systemctl is-active systemd-resolved
ls -l /run/systemd/resolve/resolv.conf
```

Wait for the `kube-system` pods to become ready before rerunning deployment:

```bash
sudo microk8s kubectl get pods -n kube-system --watch
```

## Frontend has no external address

```bash
kubectl get pods -n metallb-system
kubectl get ipaddresspool,l2advertisement -n metallb-system
kubectl describe service frontend -n fullstack
```

Confirm that the MetalLB range belongs to the node LAN, does not overlap DHCP,
and is not used by another host. As a temporary diagnostic fallback:

```bash
kubectl port-forward service/frontend -n fullstack 8080:80
```

Then open `http://127.0.0.1:8080` on the control-plane VM.

## NetworkPolicy blocks traffic

```bash
kubectl get networkpolicy -n fullstack
kubectl run netcheck -n fullstack --rm -it --restart=Never --image=curlimages/curl:8.12.1 -- sh
```

Inside the diagnostic pod, test DNS and Services. A general diagnostic pod is
subject to default deny; temporarily label it to match a workload only during a
controlled test, then remove it. Avoid deleting all policies as a first step.

