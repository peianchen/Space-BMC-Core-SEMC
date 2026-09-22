[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$projectRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$buildRoot = Join-Path $projectRoot 'build\heartbeat_monitor'
$workLibrary = Join-Path $buildRoot 'work'
$doFile = Join-Path $PSScriptRoot 'open_heartbeat_wave.do'

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

    throw "Unable to find $Name.exe."
}

# Compile and run the automated regression first. Do not open a waveform for a
# design that has not passed its self-checking testbench.
& (Join-Path $PSScriptRoot 'run_heartbeat_sim.ps1')
if ($LASTEXITCODE -ne 0) {
    throw "Automated heartbeat simulation failed; the GUI was not opened."
}

$vsim = Find-QuestaTool -Name 'vsim'
$arguments = @(
    '-gui',
    '-onfinish',
    'stop',
    '-voptargs=+acc',
    '-do',
    "do {$doFile}",
    'work.tb_heartbeat_monitor'
)

Start-Process -FilePath $vsim -ArgumentList $arguments -WorkingDirectory $buildRoot
