
# Poll App — Kubernetes + Redis Architecture
---

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  YOUR WINDOWS MACHINE                                                       │
│                                                                             │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │  KUBERNETES CLUSTER  (Docker Desktop)                                │   │
│  │                                                                      │   │
│  │  ┌────────────────────────────────────────┐                          │   │
│  │  │  Service: voter-service                │                          │   │
│  │  │  Type: LoadBalancer                    │                          │   │
│  │  │  Port: 80 → targetPort: 5000           │                          │   │
│  │  │  Exposed on: localhost:80               │                          │   │
│  │  └──────┬─────────────┬───────────────┬───┘                          │   │
│  │         │ round-robin │               │                              │   │
│  │         ▼             ▼               ▼                              │   │
│  │  ┌────────────┐ ┌────────────┐ ┌────────────┐                       │   │
│  │  │  Pod 1     │ │  Pod 2     │ │  Pod 3     │   Deployment          │   │
│  │  │  Flask     │ │  Flask     │ │  Flask     │   replicas: 3         │   │
│  │  │  :5000     │ │  :5000     │ │  :5000     │                       │   │
│  │  │            │ │            │ │            │   ConfigMap:           │   │
│  │  │ GET /poll  │ │ GET /poll  │ │ GET /poll  │    voter-code         │   │
│  │  │ POST /poll │ │ POST /poll │ │ POST /poll │    (app source)       │   │
│  │  └─────┬──────┘ └─────┬──────┘ └──────┬─────┘                       │   │
│  │        │              │               │                              │   │
│  │        └──────────────┼───────────────┘                              │   │
│  │                       │  host.docker.internal                        │   │
│  └───────────────────────┼──────────────────────────────────────────────┘   │
│                          │  (resolves to 192.168.65.254)                     │
│                          ▼                                                   │
│  ┌───────────────────────────────────────────────────────────────────────┐   │
│  │  REDIS CLUSTER  (Windows host, C:\apps\redis)                         │   │
│  │                                                                       │   │
│  │  Masters (read/write)              Replicas (failover)                │   │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐                              │   │
│  │  │ node     │ │ node     │ │ node     │                              │   │
│  │  │ :7001    │ │ :7002    │ │ :7003    │                              │   │
│  │  │ slots    │ │ slots    │ │ slots    │                              │   │
│  │  │ 0-5460   │ │ 5461-    │ │ 10923-   │                              │   │
│  │  │          │ │ 10922    │ │ 16383    │                              │   │
│  │  └────┬─────┘ └────┬─────┘ └────┬─────┘                              │   │
│  │       │             │            │                                    │   │
│  │       ▼             ▼            ▼                                    │   │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐                              │   │
│  │  │ node     │ │ node     │ │ node     │                              │   │
│  │  │ :7005    │ │ :7006    │ │ :7004    │                              │   │
│  │  │ replica  │ │ replica  │ │ replica  │                              │   │
│  │  │ of 7001  │ │ of 7002  │ │ of 7003  │                              │   │
│  │  └──────────┘ └──────────┘ └──────────┘                              │   │
│  │                                                                       │   │
│  │  Key: "poll_votes" → hash {Python:0, JavaScript:0, Go:0, Rust:0}     │   │
│  └───────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌───────────────────────────────┐                                          │
│  │  load-test.ps1                │                                          │
│  │  Sends 50 requests to        │──────── GET/POST http://localhost:80/poll  │
│  │  localhost:80/poll            │                                          │
│  └───────────────────────────────┘                                          │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Data Flow

1. **Load test** sends HTTP requests → `localhost:80`
2. **K8s Service** (LoadBalancer) round-robins traffic across **3 Flask pods**
3. Each pod connects to **Redis** via `host.docker.internal:7001`
4. If Redis returns a `MOVED` redirect (key hashes to a different slot),
   the app reconnects to the correct master node (`:7002` or `:7003`)
5. All 3 pods **read/write the same Redis hash** (`poll_votes`),
   so votes are **shared state** — totals are consistent regardless of which pod handles the request

## K8s Resources (manifest.yaml)

| Resource       | Name              | Purpose                                    |
|----------------|-------------------|--------------------------------------------|
| **ConfigMap**  | `voter-code`      | Holds the Python app source code           |
| **Deployment** | `voter-deployment`| Runs 3 replicas of the Flask app           |
| **Service**    | `voter-service`   | LoadBalancer exposing port 80 → pods:5000  |

## Endpoints

| Method | URL                          | Description                        |
|--------|------------------------------|------------------------------------|
| GET    | `http://localhost:80/`       | Health check — shows pod name      |
| GET    | `http://localhost:80/poll`   | Read current poll results          |
| POST   | `http://localhost:80/poll?vote=Python` | Cast a vote              |
| GET    | `http://localhost:80/crash`  | Simulate pod crash (K8s restarts)  |
