param(
    [ValidateSet('func', 'perf')]
    [string]$Mode = 'func',

    [string]$Benchmark = 'stream_copy'
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$vivado = Get-Command vivado.bat -ErrorAction SilentlyContinue
if (-not $vivado) {
    $defaultVivado = 'C:\Xilinx\Vivado\2023.2\bin\vivado.bat'
    if (-not (Test-Path -LiteralPath $defaultVivado)) {
        throw 'Vivado 2023.2 was not found. Add vivado.bat to PATH.'
    }
    $vivadoPath = $defaultVivado
} else {
    $vivadoPath = $vivado.Source
}

$env:PROCESSOR_ARCHITECTURE = 'AMD64'
& $vivadoPath -mode batch -notrace -nojournal `
    -log (Join-Path $scriptDir "simulate_${Mode}.log") `
    -source (Join-Path $scriptDir 'simulate.tcl') `
    -tclargs $Mode $Benchmark
exit $LASTEXITCODE
