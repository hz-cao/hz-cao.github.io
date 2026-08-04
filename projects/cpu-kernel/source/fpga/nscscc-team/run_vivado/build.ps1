param(
    [ValidateSet('func', 'perf')]
    [string]$Mode = 'perf',

    [ValidateSet('project', 'synth', 'bitstream')]
    [string]$Action = 'bitstream'
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
    -log (Join-Path $scriptDir "build_${Mode}_${Action}.log") `
    -source (Join-Path $scriptDir 'build.tcl') `
    -tclargs $Mode $Action
exit $LASTEXITCODE
