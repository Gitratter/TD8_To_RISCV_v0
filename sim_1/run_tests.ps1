$ErrorActionPreference = 'Stop'

foreach ($command in @('iverilog', 'vvp')) {
    if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
        throw "$command was not found. Install Icarus Verilog and add it to PATH."
    }
}

$projectRoot = Split-Path -Parent $PSScriptRoot
$buildDirectory = Join-Path $projectRoot 'build'
New-Item -ItemType Directory -Force $buildDirectory | Out-Null

$tests = @(
    'tb_v1_io',
    'tb_v1_instruction_set',
    'tb_v1_faults',
    'tb_v1_board'
)

Push-Location $projectRoot
try {
    foreach ($test in $tests) {
        $output = Join-Path $buildDirectory "$test.vvp"
        & iverilog -g2012 -Wall -s $test -o $output -c sim_1/rtl.f "sim_1/new/$test.v"
        if ($LASTEXITCODE -ne 0) {
            throw "iverilog failed for $test"
        }

        & vvp $output
        if ($LASTEXITCODE -ne 0) {
            throw "vvp failed for $test"
        }
    }
}
finally {
    Pop-Location
}

Write-Host 'PASS: all v1 self-checking simulations'
