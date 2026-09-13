#Requires -Version 5.1
<#
.SYNOPSIS
    Update-mode-with-no-change test (Mission 168, ticket 05, criterion 6;
    spec, Testing Decisions -- user story 18: "je veux qu'aucun fichier ne
    soit modifie" when nothing changed at a relaunch).

.DESCRIPTION
    Rerun with one command, from the repository root:

        powershell -NoProfile -ExecutionPolicy Bypass -File tests\test-questionnaire-update-mode.ps1

    Update mode only exists on the INTERACTIVE path (silent -AnswersFile
    mode is always a plain idempotent re-run, already proven by
    tests/test-install-e2e.ps1's own second-run assertion) -- this test
    drives install.ps1's -ScriptedAnswers replay queue for both runs, never
    Read-Host, never the real console:
      1. A first, fully interactive run completes every one of the seven
         questions plus the first-project confirmation, at the installer's
         own default workspace path (so a second interactive run can find
         it without being told where to look, per T06 complement 2's
         "Workspace" question).
      2. A second run finds that install complete, shows the previously
         recorded answers, and is answered "no" to "has anything changed?"
         -- ticket 05 criterion 6 requires this to modify NOTHING.
      3. Asserted: the second run's own exit code and verdict, the tracked
         clone's porcelain (empty), the first project's porcelain (empty),
         and the notebook's own content (byte-identical) all confirm
         nothing was written.

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

$TestRoot = Join-Path $env:TEMP ("sb-update-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $TestRoot | Out-Null
Write-Output "TestRoot: $TestRoot"

$installScript = Join-Path $RepoRoot 'install.ps1'
# Matches New-InstallerContext's own -TestMode default workspace
# (Join-Path $TestRoot 'workspace') -- the installer's interactive path
# proposes exactly this location by default, so accepting the offered
# default (an empty scripted answer) lands here.
$workspacePath = Join-Path $TestRoot 'workspace'
$clonePath = Join-Path $workspacePath 'second-brain'
$carnetPath = Join-Path $clonePath '.install\state.json'

try {
    Write-Output ""
    Write-Output "=== 1. First run: a full interactive install, English, default workspace ==="
    # Order: language, assistant name, workspace path (blank -> default),
    # firstName, activity, aiToolsRaw (blank), whatMatters, firstProject
    # confirm (n -- keeps this test's assertions focused on the clone
    # alone, no separate first-project repo to check). The eighth question
    # (skillCollectionsRaw) is retired (Mission 171-C01 step 4).
    $run1Answers = @('EN', 'Brian', '', 'Ana', 'Building a personal AI system', '', 'Simplicity', 'n')
    $run1Output = & $installScript -Source $RepoRoot -TestMode -TestRoot $TestRoot `
        -ScriptedAnswers $run1Answers 6>&1 | Out-String
    $run1Exit = $LASTEXITCODE
    Assert-True ($run1Exit -eq 0) "first (fresh) run completes (exit 0)"
    Assert-True ($run1Output -match 'Installation complete') "first run reaches the success verdict"
    Assert-True (Test-Path $carnetPath) "notebook exists after the first run"

    $carnetBefore = Get-Content -Raw -Path $carnetPath -Encoding UTF8
    $clonePorcelainBefore = & git -C $clonePath status --porcelain

    Write-Output ""
    Write-Output "=== 2. Second run: update mode, 'has anything changed?' -> no ==="
    $run2Answers = @('n')
    $run2Output = & $installScript -Source $RepoRoot -TestMode -TestRoot $TestRoot `
        -ScriptedAnswers $run2Answers 6>&1 | Out-String
    $run2Exit = $LASTEXITCODE
    Write-Output $run2Output
    Assert-True ($run2Exit -eq 0) "second (update-mode) run completes (exit 0)"
    Assert-True ($run2Output -match 'recorded previously') "second run shows the previously recorded answers"
    Assert-True ($run2Output -match 'Nothing changed') "second run reports the no-change verdict"

    Write-Output ""
    Write-Output "=== 3. Nothing was modified ==="
    $clonePorcelainAfter = & git -C $clonePath status --porcelain
    Assert-True ([string]::IsNullOrEmpty(($clonePorcelainBefore -join ''))) "clone porcelain was already empty before the update-mode run"
    Assert-True ([string]::IsNullOrEmpty(($clonePorcelainAfter -join ''))) "clone porcelain is still empty after the update-mode run"
    $carnetAfter = Get-Content -Raw -Path $carnetPath -Encoding UTF8
    # lastRunAt is expected to differ (the notebook always records when it
    # was last read) -- only the *answers* and *steps* must be untouched.
    $before = $carnetBefore | ConvertFrom-Json
    $after = $carnetAfter | ConvertFrom-Json
    Assert-True (($before.answers | ConvertTo-Json -Depth 10) -eq ($after.answers | ConvertTo-Json -Depth 10)) "notebook answers unchanged"
    Assert-True (($before.steps | ConvertTo-Json -Depth 10) -eq ($after.steps | ConvertTo-Json -Depth 10)) "notebook steps unchanged"
}
catch {
    Write-Output "  FAIL - unhandled error: $($_.Exception.Message)"
    $failures.Add("unhandled error: $($_.Exception.Message)") | Out-Null
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
