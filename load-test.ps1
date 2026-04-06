# ──────────────────────────────────────────────────
# Load Test Script for Poll App (PowerShell)
# Sends 50 requests to /poll and shows which pod
# handled each request (demonstrates K8s load balancing)
# ──────────────────────────────────────────────────

param(
    [string]$ServiceUrl = "http://localhost:80"
)

$TotalRequests = 50
$VoteOptions = @("Python", "JavaScript", "Go", "Rust")
$PodCount = @{}

Write-Host "============================================="
Write-Host "  Poll App Load Test"
Write-Host "  Target: $ServiceUrl/poll"
Write-Host "  Requests: $TotalRequests"
Write-Host "============================================="
Write-Host ""

# --- Phase 1: GET /poll (read traffic) ---
$half = [math]::Floor($TotalRequests / 2)
Write-Host ">>> Phase 1: Sending $half GET requests..."
Write-Host "---------------------------------------------"
for ($i = 1; $i -le $half; $i++) {
    try {
        $response = Invoke-RestMethod -Uri "$ServiceUrl/poll" -Method Get -ErrorAction Stop
        $pod = $response.pod
        Write-Host "  [$i] Pod: $pod"
        if ($PodCount.ContainsKey($pod)) { $PodCount[$pod]++ } else { $PodCount[$pod] = 1 }
    } catch {
        Write-Host "  [$i] ERROR: $_" -ForegroundColor Red
    }
    Start-Sleep -Milliseconds 100
}

Write-Host ""

# --- Phase 2: POST /poll?vote=<random> (write traffic) ---
Write-Host ">>> Phase 2: Sending $half POST votes..."
Write-Host "---------------------------------------------"
for ($i = 1; $i -le $half; $i++) {
    $vote = $VoteOptions | Get-Random
    try {
        $response = Invoke-RestMethod -Uri "$ServiceUrl/poll?vote=$vote" -Method Post -ErrorAction Stop
        $pod = $response.pod
        Write-Host "  [$i] Pod: $pod  |  Voted: $vote"
        if ($PodCount.ContainsKey($pod)) { $PodCount[$pod]++ } else { $PodCount[$pod] = 1 }
    } catch {
        Write-Host "  [$i] ERROR: $_" -ForegroundColor Red
    }
    Start-Sleep -Milliseconds 100
}

Write-Host ""
Write-Host "============================================="
Write-Host "  Load Distribution Summary"
Write-Host "============================================="
foreach ($pod in $PodCount.Keys) {
    $count = $PodCount[$pod]
    Write-Host "  $pod  ->  $count requests"
}
Write-Host "============================================="
Write-Host ""

# --- Final poll state from each pod ---
Write-Host ">>> Final poll results (one request to show):"
try {
    $final = Invoke-RestMethod -Uri "$ServiceUrl/poll" -Method Get
    $final | ConvertTo-Json -Depth 5
} catch {
    Write-Host "  Could not fetch final results: $_" -ForegroundColor Red
}
Write-Host ""
