[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$projectRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$buildRoot = Join-Path $projectRoot 'build\heartbeat_monitor'
$workLibrary = Join-Path $buildRoot 'work'

function Find-QuestaTool {
    param([Parameter(Mandatory)][string]$Name)

    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    $searchRoots = @('C:\altera_lite', 'C:\intelFPGA_lite', 'C:\intelFPGA')
    foreach ($root in $searchRoots) {
        if (Test-Path -LiteralPath $root) {
            $candidate = Get-ChildItem -LiteralPath $root -Filter "$Name.exe" -File -Recurse -ErrorAction SilentlyContinue |
                Where-Object { $_.FullName -match 'questa.*\\win64\\' } |
                Select-Object -First 1
            if ($candidate) {
                return $candidate.FullName
            }
        }
    }

    throw "Unable to find $Name.exe. Install Questa Altera FPGA Starter Edition or add its win64 directory to PATH."
}

$vlib = Find-QuestaTool -Name 'vlib'
$vmap = Find-QuestaTool -Name 'vmap'
$vlog = Find-QuestaTool -Name 'vlog'
$vsim = Find-QuestaTool -Name 'vsim'

New-Item -ItemType Directory -Path $buildRoot -Force | Out-Null
Push-Location $buildRoot
try {
    if (-not (Test-Path -LiteralPath $workLibrary)) {
        & $vlib $workLibrary
        if ($LASTEXITCODE -ne 0) { throw "vlib failed with exit code $LASTEXITCODE" }
    }

    & $vmap work $workLibrary
    if ($LASTEXITCODE -ne 0) { throw "vmap failed with exit code $LASTEXITCODE" }

    & $vlog -vlog01compat -lint=full -work work `
        (Join-Path $projectRoot 'rtl\heartbeat_monitor.v') `
        (Join-Path $projectRoot 'tb\tb_heartbeat_monitor.v')
    if ($LASTEXITCODE -ne 0) { throw "Verilog compilation failed with exit code $LASTEXITCODE" }

    $simulationLog = Join-Path $buildRoot 'simulation.log'
    & $vsim -c -onfinish exit -do 'run -all; quit -f' work.tb_heartbeat_monitor 2>&1 |
        Tee-Object -FilePath $simulationLog
    if ($LASTEXITCODE -ne 0) { throw "Simulation failed with exit code $LASTEXITCODE" }
    if (-not (Select-String -LiteralPath $simulationLog -SimpleMatch 'TEST PASSED' -Quiet)) {
        throw "Simulation completed without the testbench PASS marker. See $simulationLog"
    }
}
finally {
    Pop-Location
}
