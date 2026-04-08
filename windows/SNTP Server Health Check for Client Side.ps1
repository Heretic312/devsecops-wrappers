# Advanced SNTP Health + Auto-Optimization (AD-aware)
# Author: Victor Bishop
# Date: 4/8/2026

$servers = @("0.pool.ntp.org", "1.pool.ntp.org", "time.windows.com")
$samples = 5
$maxOffsetMs = 50
$timeoutSeconds = 5
$jitterThresholdMs = 20

Write-Host "SNTP Intelligent Health Check (AD-Aware)"

# Detect if this machine is PDC Emulator
function Get-IsPDC {
    try {
        $domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
        $pdc = $domain.PdcRoleOwner.Name
        return ($env:COMPUTERNAME -ieq $pdc)
    } catch {
        return $false
    }
}

$isPDC = Get-IsPDC

if ($isPDC) {
    Write-Host "This server is the PDC Emulator (will allow NTP changes)" -ForegroundColor Green
} else {
    Write-Host "Not PDC Emulator (will NOT modify time config)" -ForegroundColor Yellow
}

function Invoke-StripchartWithTimeout {
    param ($Server, $TimeoutSec)

    $job = Start-Job -ScriptBlock {
        param($s)
        w32tm /stripchart /computer:$s /samples:1 /dataonly 2>&1
    } -ArgumentList $Server

    if (Wait-Job $job -Timeout $TimeoutSec) {
        $out = Receive-Job $job
        Remove-Job $job
        return $out
    } else {
        Stop-Job $job | Out-Null
        Remove-Job $job
        return $null
    }
}

$results = @()

foreach ($server in $servers) {

    Write-Host "Testing $server"
    $offsets = @()
    $failures = 0

    # Stratum check
    $status = w32tm /query /status /computer:$server 2>&1
    $stratum = $null

    if ($status -match "Stratum:\s+(\d+)") {
        $stratum = [int]$matches[1]
        Write-Host "Stratum: $stratum"
    }

    if ($stratum -eq 16) {
        Write-Host "UNSYNCHRONIZED (Stratum 16)" -ForegroundColor Red
    }

    # Collect samples
    for ($i=1; $i -le $samples; $i++) {

        $result = Invoke-StripchartWithTimeout $server $timeoutSeconds

        if (-not $result) {
            Write-Host "Sample $i timeout" -ForegroundColor Yellow
            $failures++
            continue
        }

        $line = $result | Where-Object { $_ -match "^[\+\-]?\d+\.\d+s" }

        if ($line -match "([\+\-]?\d+\.\d+)s") {
            $val = [double]$matches[1]
            $offsets += $val
            Write-Host ("Sample {0}: {1} ms" -f $i, [math]::Round($val*1000,2))
        } else {
            Write-Host "Sample $i invalid" -ForegroundColor Yellow
            $failures++
        }
    }

    if ($offsets.Count -gt 0) {
        $avg = [math]::Abs(($offsets | Measure-Object -Average).Average * 1000)
        $min = ($offsets | Measure-Object -Minimum).Minimum * 1000
        $max = ($offsets | Measure-Object -Maximum).Maximum * 1000
        $jitter = [math]::Abs($max - $min)
    } else {
        $avg = $null; $min = $null; $max = $null; $jitter = $null
    }

    # Score calculation
    $score = 100

    if ($stratum -eq 16) { $score -= 50 }
    if ($avg -gt $maxOffsetMs) { $score -= 20 }
    if ($jitter -gt $jitterThresholdMs) { $score -= 15 }
    if ($failures -gt 0) { $score -= ($failures * 5) }

    # Detect asymmetric spikes
    $spikeDetected = $false
    if ($offsets.Count -ge 3) {
        for ($i=1; $i -lt $offsets.Count; $i++) {
            $delta = [math]::Abs(($offsets[$i] - $offsets[$i-1]) * 1000)
            if ($delta -gt $jitterThresholdMs) {
                $spikeDetected = $true
                break
            }
        }
        if ($spikeDetected) {
            Write-Host "Jitter spike detected!" -ForegroundColor Yellow
            $score -= 10
        }
    }

    $results += [PSCustomObject]@{
        Server  = $server
        Stratum = $stratum
        AvgMs   = $avg
        Jitter  = $jitter
        Fail    = $failures
        Score   = $score
    }
}

# Rank servers
Write-Host "Ranking Servers"
$ranked = $results | Sort-Object Score -Descending

$ranked | ForEach-Object {
    Write-Host ("{0} | Score:{1} | Avg:{2}ms | Jitter:{3}ms | Fail:{4}" -f `
        $_.Server,
        $_.Score,
        [math]::Round($_.AvgMs,2),
        [math]::Round($_.Jitter,2),
        $_.Fail)
}

$best = $ranked | Select-Object -First 1

Write-Host "Best server: $($best.Server)" -ForegroundColor Green

# Auto-configure ONLY if PDC
if ($isPDC -and $best.Server) {

    Write-Host "Updating Windows Time configuration..." -ForegroundColor Cyan

    w32tm /config /manualpeerlist:$($best.Server) /syncfromflags:manual /reliable:yes /update
    Restart-Service w32time

    w32tm /resync | Out-Null

    Write-Host "Time service updated to use $($best.Server)" -ForegroundColor Green
} else {
    Write-Host "Skipping config update (not PDC)" -ForegroundColor Yellow
}

# Final status
if ($best.Score -ge 70) {
    Write-Host "Overall Status: HEALTHY" -ForegroundColor Green
    exit 0
} elseif ($best.Score -ge 40) {
    Write-Host "Overall Status: WARNING" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "Overall Status: CRITICAL" -ForegroundColor Red
    exit 2
}