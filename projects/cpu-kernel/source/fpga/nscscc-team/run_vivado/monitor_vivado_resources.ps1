param(
    [Parameter(Mandatory = $true)]
    [int]$VivadoPid
)

$output = Join-Path $PSScriptRoot 'vivado_resource_monitor.csv'
'timestamp,free_physical_gb,free_virtual_gb,vivado_working_gb,cpu_seconds,status' | Set-Content -LiteralPath $output
$lowMemorySamples = 0

while ($true) {
    $process = Get-Process -Id $VivadoPid -ErrorAction SilentlyContinue
    if (-not $process) {
        $now = Get-Date -Format o
        $orphans = Get-Process -ErrorAction SilentlyContinue | Where-Object {
            $_.ProcessName -match '^(vivado|xsimk|xelab|xvlog|runsme)$'
        }
        if ($orphans) {
            $orphans | Stop-Process -Force -ErrorAction SilentlyContinue
            "$now,0,0,0,0,parent_missing_children_stopped" | Add-Content -LiteralPath $output
        } else {
            "$now,0,0,0,0,finished" | Add-Content -LiteralPath $output
        }
        exit 0
    }

    $os = Get-CimInstance Win32_OperatingSystem
    $toolProcesses = Get-Process -ErrorAction SilentlyContinue | Where-Object {
        $_.ProcessName -match '^(vivado|xsimk|xelab|xvlog|runsme)$'
    }
    $freePhysical = [math]::Round($os.FreePhysicalMemory * 1KB / 1GB, 2)
    $freeVirtual = [math]::Round($os.FreeVirtualMemory * 1KB / 1GB, 2)
    $working = [math]::Round(($toolProcesses | Measure-Object WorkingSet64 -Sum).Sum / 1GB, 2)
    $cpu = [math]::Round(($toolProcesses | Measure-Object CPU -Sum).Sum, 2)
    $now = Get-Date -Format o
    "$now,$freePhysical,$freeVirtual,$working,$cpu,running" | Add-Content -LiteralPath $output

    if ($freePhysical -lt 1.5) {
        $lowMemorySamples++
    } else {
        $lowMemorySamples = 0
    }

    # The placed-DCP write phase is stable around 1.6-1.8 GB free on this host.
    # Stop at the hard floor or after a full minute below 1.5 GB.
    if ($freePhysical -lt 1.0 -or $lowMemorySamples -ge 4 -or
        $freeVirtual -lt 10.0 -or $working -gt 10.0) {
        "$now,$freePhysical,$freeVirtual,$working,$cpu,resource_limit" | Add-Content -LiteralPath $output
        $toolProcesses | Stop-Process -Force -ErrorAction SilentlyContinue
        exit 2
    }
    Start-Sleep -Seconds 15
}
