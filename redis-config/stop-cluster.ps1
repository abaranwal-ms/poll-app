# stop-cluster.ps1
# Stops all running Redis cluster node processes

$redisCli = "c:\apps\redis\bin\redis-cli.exe"
$ports = 7001..7006

Write-Host "Stopping Redis cluster nodes..." -ForegroundColor Cyan

foreach ($port in $ports) {
    try {
        & $redisCli -p $port SHUTDOWN NOSAVE 2>$null | Out-Null
        Write-Host "  Node $port - stopped" -ForegroundColor Green
    } catch {
        Write-Host "  Node $port - already stopped or not reachable" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "All nodes stopped." -ForegroundColor Green
