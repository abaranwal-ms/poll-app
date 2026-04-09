# Redis Cluster Setup (reference config for the poll app)
#
# The poll app connects to this Redis cluster from inside K8s pods
# via host.docker.internal:7001
#
# This is a 6-node cluster: 3 masters + 3 replicas
# Ports: 7001-7006, all on the Windows host
#
# Setup:
#   1. Install Redis binaries to C:\apps\redis\bin\
#   2. Copy redis.conf template to each node-700x folder (update port)
#   3. Run: start-cluster.ps1
#   4. Run: create-cluster.ps1  (one-time, forms the cluster)
#
# Management:
#   start-cluster.ps1  — Start all 6 nodes
#   stop-cluster.ps1   — Graceful shutdown
#   reset-cluster.ps1  — Wipe data and start fresh
