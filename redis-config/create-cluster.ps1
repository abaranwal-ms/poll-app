# create-cluster.ps1
# Forms the Redis cluster from the 6 running nodes (3 masters + 3 replicas)

$redisCli = "c:\apps\redis\bin\redis-cli.exe"

Write-Host "Creating Redis cluster with 3 masters and 3 replicas..." -ForegroundColor Cyan
Write-Host ""

& $redisCli --cluster create `
    127.0.0.1:7001 `
    127.0.0.1:7002 `
    127.0.0.1:7003 `
    127.0.0.1:7004 `
    127.0.0.1:7005 `
    127.0.0.1:7006 `
    --cluster-replicas 1 --cluster-yes

Write-Host ""
Write-Host "Cluster created! Verifying..." -ForegroundColor Cyan
Write-Host ""

& $redisCli -p 7001 CLUSTER INFO
Write-Host ""
& $redisCli -p 7001 CLUSTER NODES
