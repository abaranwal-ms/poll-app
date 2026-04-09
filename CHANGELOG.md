# Changelog

## [1.0] - 2026-04-10
### Added
- **Dockerfile** — custom image (`poll-app:1.0`) with Flask + Redis baked in
- **.dockerignore** — excludes docs, tests, and cache from the image build
- **Redis integration** — all pods now share poll state via external Redis cluster
  - Connects to host Redis via `host.docker.internal`
  - Handles Redis Cluster `MOVED` redirects transparently
- **`/poll` endpoint** — GET to read results, POST to cast a vote (Python, JavaScript, Go, Rust)
- **`/crash` endpoint** — simulates pod failure to demonstrate K8s self-healing

### Changed
- **manifest.yaml** — replaced ConfigMap + `pip install` hack with the custom Docker image
  - Removed `voter-code` ConfigMap (code now lives in the image)
  - Removed runtime `command` that installed packages on every pod start
  - Image pull policy set to `IfNotPresent` (uses local image)
  - Pods now start in ~1s instead of ~30s

## [0.1] - 2026-03-29
### Added
- **voter-app.py** — Flask app with `/` health check and `/poll` endpoint
- **manifest.yaml** — K8s Deployment (3 replicas), LoadBalancer Service, ConfigMap with app code
- **load-test.ps1** — PowerShell script sending 50 requests to show K8s load distribution
- **load-test.sh** — Bash version (for non-Windows)
- **architecture.md** — ASCII diagram of the full system
- **README.md** — Quick start, endpoints, and K8s concepts covered
