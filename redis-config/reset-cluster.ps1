# reset-cluster.ps1
# Stops all nodes and cleans up all data files to start fresh

$redisCli = "c:\apps\redis\bin\redis-cli.exe"
$baseDir = "c:\apps\redis"
$ports = 7001..7006

Write-Host "Stopping all nodes..." -ForegroundColor Cyan
foreach ($port in $ports) {
    & $redisCli -p $port SHUTDOWN NOSAVE 2>$null | Out-Null
}
Start-Sleep -Seconds 1

Write-Host "Cleaning up data files..." -ForegroundColor Cyan
foreach ($port in $ports) {
    $nodeDir = Join-Path $baseDir "node-$port"
    Remove-Item -Path (Join-Path $nodeDir "nodes-*.conf") -Force -ErrorAction SilentlyContinue
    Remove-Item -Path (Join-Path $nodeDir "dump-*.rdb") -Force -ErrorAction SilentlyContinue
    Remove-Item -Path (Join-Path $nodeDir "appendonly-*.aof") -Force -ErrorAction SilentlyContinue
    Write-Host "  Cleaned node-$port" -ForegroundColor Green
}

Write-Host ""
Write-Host "Cluster reset complete. Run 'start-cluster.ps1' to start fresh." -ForegroundColor Yellow
