# Poll App on Kubernetes

A simple poll application built to learn Kubernetes concepts — scaling, load balancing, and shared state with Redis.

## Architecture

3 Flask pods behind a K8s LoadBalancer Service, all reading/writing votes to an external Redis cluster on the host machine.

See [architecture.md](architecture.md) for the full diagram.

## Quick Start

```powershell
# 1. Start Redis cluster (on Windows host)
& C:\apps\redis\start-cluster.ps1

# 2. Deploy to Kubernetes
kubectl apply -f manifest.yaml

# 3. Run the load test
.\load-test.ps1
```

## Endpoints

| Method | URL | Description |
|--------|-----|-------------|
| GET | `/` | Health check — shows pod name |
| GET | `/poll` | Read current poll results |
| POST | `/poll?vote=Python` | Cast a vote (Python, JavaScript, Go, Rust) |
| GET | `/crash` | Simulate pod crash (K8s auto-restarts) |

## K8s Concepts Covered

- **Deployments** — 3 replicas of the same app
- **Services** — LoadBalancer distributing traffic across pods
- **ConfigMaps** — Injecting app code into containers
- **Self-healing** — `/crash` endpoint triggers pod restart
- **External services** — Pods connecting to host Redis via `host.docker.internal`
