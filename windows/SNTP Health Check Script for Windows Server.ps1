# SNTP Health Check Script for Windows Server
# Author: Victor Bishop - https://github.com/Heretic312
# Date: 4/8/2026

Write-Host "SNTP Server Health Check"

# Check Windows Time service
$service = Get-Service -Name w32time -ErrorAction SilentlyContinue

if (-not $service) {
    Write-Host "Windows Time service not found!" -ForegroundColor Red
    return
}

Write-Host "Windows Time Service Status: $($service.Status)"

if ($service.Status -ne 'Running') {
    Write-Host "Windows Time service is NOT running!" -ForegroundColor Red
} else {
    Write-Host "Windows Time service is running." -ForegroundColor Green
}

# Get status of time sync
Write-Host "Time Sync Status"
$status = w32tm /query /status 2>&1
$status | ForEach-Object { Write-Host $_ }

# Parse Stratum safely
$stratumLine = $status | Where-Object { $_ -match "Stratum" }

if ($stratumLine) {
    if ($stratumLine -match "Stratum:\s+(\d+)") {
        $stratum = [int]$matches[1]

        if ($stratum -ge 1 -and $stratum -le 4) {
            Write-Host "Stratum level is $stratum (healthy)" -ForegroundColor Green
        } else {
            Write-Host "Stratum level is $stratum (unhealthy or unsynchronized)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Could not parse stratum value" -ForegroundColor Yellow
    }
} else {
    Write-Host "Stratum line not found" -ForegroundColor Red
}

# Check last successful sync
$lastSync = $status | Where-Object { $_ -match "Last Successful Sync Time" }

Write-Host "Last Successful Sync"
if ($lastSync) {
    Write-Host $lastSync
} else {
    Write-Host "No sync time found" -ForegroundColor Yellow
}

# Check configured NTP peers
Write-Host "Configured NTP Peers"
$peers = w32tm /query /peers 2>&1
$peers | ForEach-Object { Write-Host $_ }

# Attempt immediate resync (check exit code instead of try/catch)
Write-Host "Resync Attempt"
w32tm /resync 2>&1 | ForEach-Object { Write-Host $_ }

if ($LASTEXITCODE -eq 0) {
    Write-Host "Resync completed successfully" -ForegroundColor Green
} else {
    Write-Host "Resync failed (Exit Code: $LASTEXITCODE)" -ForegroundColor Red
}

Write-Host "SNTP Health Check Complete"