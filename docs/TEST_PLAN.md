# Resilience and Acceptance Test Plan

Run tests from the control-plane VM. Keep one terminal watching resources and a
second terminal polling the application.

```bash
kubectl get pods -n fullstack -o wide --watch
```

```bash
FRONTEND_IP="$(kubectl get service frontend -n fullstack -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
while true; do curl -sS -o /dev/null -w '%{http_code}\n' --max-time 3 "http://${FRONTEND_IP}/api/items" || true; sleep 2; done
```

Before every failure test, run `./scripts/verify.sh`. Stop if the baseline does
not pass.

## Test matrix

| ID | Test | Expected result | Stop condition |
|---|---|---|---|
| T1 | Delete one frontend pod | Replacement appears; HTTP stays 200 | Both replicas unavailable |
| T2 | Delete one backend pod | Replacement appears; API stays available | Repeated crashes or non-200 responses |
| T3 | Scale backend 2 -> 3 -> 2 | Endpoints follow replica count | New pod cannot become ready |
| T4 | Restart `postgres-0` | Brief outage, then same rows return | PVC unbound or volume faulted |
| T5 | Delete one Longhorn replica | Volume degrades then rebuilds healthy | A second replica is unhealthy |
| T6 | Cordon database node and restart DB pod | Pod starts on other worker; rows remain | Other worker or volume is unhealthy |
| T7 | Power off database worker | Recovery after eviction; rows remain | Control plane or remaining worker is unhealthy |

T1-T4 are available through `scripts/failure-tests.sh`. T5-T7 remain manual
because they alter storage or node availability.

## T1-T4 commands

```bash
./scripts/failure-tests.sh frontend-pod
./scripts/failure-tests.sh backend-pod
./scripts/failure-tests.sh scale-backend
./scripts/failure-tests.sh database-pod
```

Run `./scripts/verify.sh` after each test.

## T5: rebuild one Longhorn replica

```bash
kubectl get volumes.longhorn.io -n longhorn-system
kubectl get replicas.longhorn.io -n longhorn-system -o wide
kubectl delete replicas.longhorn.io -n longhorn-system REPLICA_NAME
kubectl get volumes.longhorn.io -n longhorn-system --watch
```

Delete exactly one healthy replica only when the other replica and both workers
are healthy. Stop and investigate if the volume becomes `faulted` or does not
return to `healthy`.

## T6: controlled database movement

```bash
kubectl get pod postgres-0 -n fullstack -o wide
kubectl cordon CURRENT_DATABASE_NODE
kubectl delete pod postgres-0 -n fullstack
kubectl get pod postgres-0 -n fullstack -o wide --watch
kubectl uncordon CURRENT_DATABASE_NODE
./scripts/verify.sh
```

Do not leave the node cordoned after the test.

## T7: worker failure

Never power off the control-plane node during this test. Confirm the Longhorn
node-down pod deletion policy and understand the several-minute Kubernetes
eviction delay before starting. Power off only the worker currently hosting
`postgres-0`, observe recovery, verify the data, then power it back on.

After the node returns:

```bash
kubectl get nodes --watch
kubectl get volumes.longhorn.io -n longhorn-system --watch
./scripts/verify.sh
```

## Evidence

After each successful test:

```bash
./scripts/collect-evidence.sh
```

Record test ID, UTC time, command, before/after screenshots, outage duration,
result, and any deviation. Never describe a test as passed without live output.

