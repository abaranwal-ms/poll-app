# start-cluster.ps1
# Starts all 6 Redis cluster nodes as background processes

$redisServer = "c:\apps\redis\bin\redis-server.exe"
$baseDir = "c:\apps\redis"
$ports = 7001..7006

Write-Host "Starting Redis cluster nodes..." -ForegroundColor Cyan

foreach ($port in $ports) {
    $nodeDir = Join-Path $baseDir "node-$port"
    $confFile = Join-Path $nodeDir "redis.conf"

    $process = Start-Process -FilePath $redisServer `
        -ArgumentList $confFile `
        -WorkingDirectory $nodeDir `
        -PassThru `
        -WindowStyle Hidden

    Write-Host "  Node $port started (PID: $($process.Id))" -ForegroundColor Green
}

Write-Host ""
Write-Host "All 6 nodes started. Waiting 2 seconds for them to initialize..." -ForegroundColor Cyan
Start-Sleep -Seconds 2

# Verify nodes are running
foreach ($port in $ports) {
    try {
        $result = & "c:\apps\redis\bin\redis-cli.exe" -p $port PING 2>$null
        if ($result -eq "PONG") {
            Write-Host "  Node $port - OK" -ForegroundColor Green
        } else {
            Write-Host "  Node $port - FAILED" -ForegroundColor Red
        }
    } catch {
        Write-Host "  Node $port - FAILED" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Next step: Run 'create-cluster.ps1' to form the cluster." -ForegroundColor Yellow
