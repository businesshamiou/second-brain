#Requires -Version 5.1
<#
.SYNOPSIS
    Simulated network-failure test (Mission 168, ticket 05, criterion 5;
    spec, Testing Decisions -- "echec reseau simule, verdict d'arret, puis
    reprise").

.DESCRIPTION
    Rerun with one command, from the repository root:

        powershell -NoProfile -ExecutionPolicy Bypass -File tests\test-questionnaire-network-failure.ps1

    The installer's one real network dependency is tools/prerequisites.ps1
    downloading Git/uv when neither is already on PATH (ticket 04). This
    test simulates that going dark entirely INSIDE this process, never by
    touching any real network configuration (Mission constraint): it trims
    $env:Path for its own process (same technique
    tests/test-prerequisites-e2e.ps1 already uses to force the "absent"
    branch) and sets $env:SB_TEST_FORCE_NETWORK_FAILURE=1, the test-only
    hook prerequisites.ps1's own Get-CachedOrDownloadedFile checks right
    before its one Invoke-WebRequest call.

    Proves, in a fresh, blank temporary workspace:
      1. The run stops (exit 1) with a verdict naming the step
         ("prerequisites"), the cause (network-shaped), and a remedy.
      2. No install notebook is left behind, corrupted or otherwise -- the
         failure happens before the workspace (and therefore the notebook)
         is ever created, so "the notebook stays intact" holds trivially
         and correctly: there is nothing to corrupt, and nothing is
         falsely created either.
      3. Once the simulated outage is lifted (the env var cleared) and
         Git/uv are back on PATH, a relaunch with the exact same arguments
         succeeds, resuming at the failed step rather than doing anything
         differently.

    Exit code 0 means every assertion passed. Exit code 1 means at least one
    did not; details are printed to stdout as each check runs.
#>

[CmdletBinding()]
param([switch] $KeepTemp)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path $PSScriptRoot -Parent
$failures = New-Object System.Collections.Generic.List[string]

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if ($Condition) { Write-Output "  PASS - $Message" }
    else { Write-Output "  FAIL - $Message"; $failures.Add($Message) | Out-Null }
}

$TestRoot = Join-Path $env:TEMP ("sb-netfail-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $TestRoot | Out-Null
Write-Output "TestRoot: $TestRoot"

$installScript = Join-Path $RepoRoot 'install.ps1'
$workspacePath = Join-Path $TestRoot 'workspace'
$carnetPath = Join-Path (Join-Path $workspacePath 'second-brain') '.install\state.json'
$answersPath = Join-Path $TestRoot 'answers.json'
$sampleAnswers = Get-Content -Raw -Path (Join-Path $PSScriptRoot 'fixtures\install-answers.sample.json') | ConvertFrom-Json
$sampleAnswers.workspacePath = $workspacePath
$sampleAnswers | ConvertTo-Json -Depth 10 | Set-Content -Path $answersPath -Encoding UTF8

$originalPath = $env:Path

try {
    Write-Output ""
    Write-Output "=== 1. Simulate Git/uv absent from PATH, and the network going dark ==="
    # Same technique as tests/test-prerequisites-e2e.ps1: trims THIS
    # process's own $env:Path only, never the real user PATH
    # (HKCU\Environment) -- forces Assure-Prerequisites into its
    # "not found, must download" branch so the network hook actually gets
    # exercised, rather than short-circuiting on an already-resolvable git.
    $systemDirs = @("$env:WINDIR\System32", "$env:WINDIR", "$env:WINDIR\System32\WindowsPowerShell\v1.0")
    $env:Path = ($systemDirs -join ';')
    $env:SB_TEST_FORCE_NETWORK_FAILURE = '1'

    Write-Output ""
    Write-Output "=== 2. First run: stopped at 'prerequisites', naming cause and remedy ==="
    $run1Output = & $installScript -Source $RepoRoot -AnswersFile $answersPath -TestMode -TestRoot $TestRoot | Out-String
    $run1Exit = $LASTEXITCODE
    Write-Output $run1Output
    Assert-True ($run1Exit -eq 1) "first run stops (exit 1) under the simulated outage"
    Assert-True ($run1Output -match 'Stopped at step prerequisites') "verdict names the step (prerequisites)"
    Assert-True ($run1Output -match 'Network unreachable') "verdict names the cause (network)"
    Assert-True ($run1Output -match 'Check your internet connection') "verdict names a remedy"

    Write-Output ""
    Write-Output "=== 3. Notebook is not corrupted (none exists yet: failure precedes the workspace) ==="
    # T06/T22's "carnet intact" guarantee is about never losing or
    # corrupting a notebook that already exists -- the prerequisites step
    # runs before the workspace (and therefore the notebook, which is born
    # inside the clone) is ever created, so the correct, intact state here
    # is "no notebook at all", not a notebook with a false step recorded.
    Assert-True (-not (Test-Path $carnetPath)) "no notebook was falsely created by the failed run"
    Assert-True (-not (Test-Path $workspacePath)) "no workspace directory was left behind either"

    Write-Output ""
    Write-Output "=== 4. Lift the simulated outage, relaunch with the same arguments ==="
    Remove-Item Env:\SB_TEST_FORCE_NETWORK_FAILURE
    $env:Path = $originalPath
    $run2Output = & $installScript -Source $RepoRoot -AnswersFile $answersPath -TestMode -TestRoot $TestRoot | Out-String
    $run2Exit = $LASTEXITCODE
    Write-Output $run2Output
    Assert-True ($run2Exit -eq 0) "relaunch succeeds once the network is back (exit 0)"
    Assert-True ($run2Output -match 'Installation complete') "relaunch reaches the success verdict"
    Assert-True (Test-Path $carnetPath) "notebook now exists, born by the successful relaunch"
}
catch {
    Write-Output "  FAIL - unhandled error: $($_.Exception.Message)"
    $failures.Add("unhandled error: $($_.Exception.Message)") | Out-Null
}
finally {
    # Always restored, pass or fail -- this process's own PATH and the
    # test-only env var must never leak into any later command in this
    # session.
    $env:Path = $originalPath
    if (Test-Path Env:\SB_TEST_FORCE_NETWORK_FAILURE) { Remove-Item Env:\SB_TEST_FORCE_NETWORK_FAILURE }
}

if (-not $KeepTemp) {
    try {
        . (Join-Path $RepoRoot 'tools\resolve-bash-exe.ps1')
        $cleanupBash = Resolve-BashExe
        & $cleanupBash -c "rm -rf -- '$($TestRoot -replace '\\','/')'"
    }
    catch { }
    Write-Output ""
    Write-Output "TestRoot removed: $TestRoot"
}
else {
    Write-Output ""
    Write-Output "TestRoot kept (-KeepTemp): $TestRoot"
}

Write-Output ""
if ($failures.Count -eq 0) {
    Write-Output "=== RESULT: PASS (all checks green) ==="
    exit 0
}
else {
    Write-Output "=== RESULT: FAIL ($($failures.Count) check(s) failed) ==="
    $failures | ForEach-Object { Write-Output "  - $_" }
    exit 1
}
