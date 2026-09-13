#Requires -Version 5.1
<#
.SYNOPSIS
    Nominal-install log line count test (Mission 172, audit defect 3).

.DESCRIPTION
    Rerun with one command, from the repository root:

        powershell -NoProfile -ExecutionPolicy Bypass -File tests\test-install-log-line-count.ps1

    Measured at the 2026-09-13 acceptance: the index list defiled three
    times during a nominal install (each of the three build-indexes.sh
    calls a full install makes -- two from Save-ClonePendingChanges, one
    from tools/project-bootstrap.sh -- used to print one line per
    regenerated index.md/archive, hundreds across the whole repository's
    index tree).

    A variable-capture test (`$out = & install.ps1 ...`) cannot measure this
    honestly: install.ps1 calls bash.exe as an external process, and that
    process's own stderr (where build_indexes.py used to write) flows
    straight to the console host, bypassing PowerShell's success-stream
    capture entirely -- test-install-e2e.ps1's own "$verdict1.Count -eq 1"
    assertion only ever proved install.ps1's OWN output stream was one line,
    never that the console a real person watches stayed quiet. This test
    instead launches install.ps1 as a real child process
    (Start-Process -RedirectStandardOutput/-RedirectStandardError) so both
    streams are captured exactly as a terminal would show them, merged, and
    counts every line -- proving Mission 172's own Validations criterion 6
    ("Journal d'installation nominale : sous 40 lignes") the way an actual
    installation looks, not the way a narrower unit test would.

    -TestMode throughout: nothing this test does can reach the real profile
    (PATH, ~/.claude, ~/.codex).

    Exit code 0 means every assertion passed. Exit code 1 means at least one
    did not; details are printed to stdout as each check runs.
#>

[CmdletBinding()]
param([switch] $KeepTemp)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path $PSScriptRoot -Parent
$failures = New-Object System.Collections.Generic.List[string]
$LineCap = 40

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if ($Condition) { Write-Output "  PASS - $Message" }
    else { Write-Output "  FAIL - $Message"; $failures.Add($Message) | Out-Null }
}

$TestRoot = Join-Path $env:TEMP ("sb-logcount-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $TestRoot | Out-Null
Write-Output ""
Write-Output "TestRoot: $TestRoot"

try {
    Write-Output ""
    Write-Output "=== Nominal install, real child process, both streams captured ==="

    $workspacePath = Join-Path $TestRoot 'workspace'
    $answersPath = Join-Path $TestRoot 'answers.json'
    $sampleAnswers = Get-Content -Raw -Path (Join-Path $PSScriptRoot 'fixtures\install-answers.sample.json') | ConvertFrom-Json
    $sampleAnswers.workspacePath = $workspacePath
    $sampleAnswers | ConvertTo-Json -Depth 10 | Set-Content -Path $answersPath -Encoding UTF8

    $installScript = Join-Path $RepoRoot 'install.ps1'
    $stdoutPath = Join-Path $TestRoot 'stdout.log'
    $stderrPath = Join-Path $TestRoot 'stderr.log'
    $psExe = (Get-Process -Id $PID).Path
    if (-not $psExe) { $psExe = 'powershell.exe' }
    $argList = @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $installScript,
        '-Source', $RepoRoot, '-AnswersFile', $answersPath, '-TestMode', '-TestRoot', $TestRoot
    )
    $proc = Start-Process -FilePath $psExe -ArgumentList $argList -NoNewWindow -Wait -PassThru `
        -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath

    Assert-True ($proc.ExitCode -eq 0) "install.ps1 exits 0 (silent, -TestMode)"

    $stdoutLines = @(Get-Content -Path $stdoutPath -ErrorAction SilentlyContinue)
    $stderrLines = @(Get-Content -Path $stderrPath -ErrorAction SilentlyContinue)
    $total = $stdoutLines.Count + $stderrLines.Count

    Write-Output "  stdout lines: $($stdoutLines.Count)"
    Write-Output "  stderr lines: $($stderrLines.Count)"
    Write-Output "  total lines : $total (cap: $LineCap)"

    Assert-True ($total -le $LineCap) "nominal install log is $LineCap lines or fewer (measured: $total)"
    Assert-True (-not ($stderrLines -match '\\index\.md$')) "no bare 'X\index.md' line (the old unconditional per-file dump) appears in stderr"
    Assert-True (-not ($stderrLines -match '\(vivant, N=')) "no '(vivant, N=...)' per-index line (the old unconditional dump) appears in stderr"
}
finally {
    if (-not $KeepTemp) {
        Remove-Item -Recurse -Force -Path $TestRoot -ErrorAction SilentlyContinue
    }
    else {
        Write-Output ""
        Write-Output "Kept: $TestRoot"
    }
}

Write-Output ""
if ($failures.Count -gt 0) {
    Write-Output "=== FAILURES ($($failures.Count)) ==="
    $failures | ForEach-Object { Write-Output "  - $_" }
    exit 1
}
Write-Output "All assertions passed."
exit 0
