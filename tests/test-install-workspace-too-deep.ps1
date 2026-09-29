#Requires -Version 5.1
<#
.SYNOPSIS
    Deep workspace root refused at once by install.ps1 (Mission 221, batch D,
    A-219-1) -- PowerShell twin of tests/test-install-workspace-too-deep.sh.

.DESCRIPTION
    An installation in a workspace folder so deep that its deepest file
    passes the Windows path limit (259 characters) used to fail half-way,
    at the marker step (report 219). install.ps1 now refuses such a root
    before writing anything in it, with the catalogue message that gives
    the measured length and the maximum: 259 - 1 - (second-brain\ + the
    longest tracked Markdown file outside skills-warehouse), 118 on the
    tree measured by Mission 221 (118 installs, 119 stops at the marker step).

    Drives install.ps1's interactive questionnaire through -ScriptedAnswers,
    stopped right after the 'workspace' step (-StopAfterStep), as
    tests/test-install-workspace-path-validation.ps1 does.

    Oracles (PASS expected):
      (a) a root longer than the maximum is refused: exit 1, the message
          names the length and the maximum, the workspace folder is not
          created, no forced stop reached;
      (b) witness: a short root passes the workspace step, folder created.

    Rerun with:
        powershell -NoProfile -ExecutionPolicy Bypass -File tests\test-install-workspace-too-deep.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path $PSScriptRoot -Parent
$installScript = Join-Path $RepoRoot 'install.ps1'
$failures = New-Object System.Collections.Generic.List[string]

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if ($Condition) { Write-Output "  PASS - $Message" }
    else { Write-Output "  FAIL - $Message"; $failures.Add($Message) | Out-Null }
}

function Invoke-WorkspaceCase {
    param([string] $TestRoot, [string[]] $ScriptedAnswers)
    $output = & $installScript -Source $RepoRoot -TestMode -TestRoot $TestRoot `
        -ScriptedAnswers $ScriptedAnswers -StopAfterStep 'workspace' 6>&1 | Out-String
    return [PSCustomObject]@{ Output = $output; ExitCode = $LASTEXITCODE }
}

# Expected maximum, computed as the installer must, on the same source.
$longest = 0
foreach ($tracked in @(& git -C $RepoRoot -c core.quotepath=off ls-files -- '*.md' ':(exclude)skills-warehouse')) {
    if ($tracked.Length -gt $longest) { $longest = $tracked.Length }
}
$expectedMax = 259 - 1 - 13 - $longest

$testRootDeep = Join-Path $env:TEMP ("m221-deep-" + [Guid]::NewGuid().ToString('N').Substring(0, 8))
$testRootShort = Join-Path $env:TEMP ("m221-short-" + [Guid]::NewGuid().ToString('N').Substring(0, 8))

try {
    Write-Output ""
    Write-Output "=== (a) deep root: refused before any write (maximum $expectedMax) ==="
    New-Item -ItemType Directory -Force -Path $testRootDeep | Out-Null
    $pad = 'dossier-tres-profond-pour-mesurer-la-limite-de-chemin-de-windows'
    $deepWorkspace = Join-Path $testRootDeep "$pad\$pad\workspace"
    $resultA = Invoke-WorkspaceCase -TestRoot $testRootDeep -ScriptedAnswers @('EN', 'TestBrian', $deepWorkspace)
    Write-Output $resultA.Output
    Assert-True ($resultA.ExitCode -eq 1) "exit 1"
    $expectedText = "is $($deepWorkspace.Length) characters long; on Windows it can be at most $expectedMax"
    Assert-True ($resultA.Output -match [regex]::Escape($expectedText)) "the message names the length ($($deepWorkspace.Length)) and the maximum ($expectedMax)"
    Assert-True (-not ($resultA.Output -match 'Forced stop for testing, after step: workspace')) "the workspace step was never reached"
    Assert-True (-not (Test-Path $deepWorkspace)) "nothing written: the workspace folder does not exist"

    Write-Output ""
    Write-Output "=== (b) witness: short root passes the workspace step ==="
    New-Item -ItemType Directory -Force -Path $testRootShort | Out-Null
    $shortWorkspace = Join-Path $testRootShort 'workspace'
    $resultB = Invoke-WorkspaceCase -TestRoot $testRootShort -ScriptedAnswers @('EN', 'TestBrian', $shortWorkspace)
    Assert-True ($resultB.Output -match 'Forced stop for testing, after step: workspace') "the workspace step was reached ($($shortWorkspace.Length) characters)"
    Assert-True (-not ($resultB.Output -match 'characters long; on Windows')) "no depth refusal for a short root"
    Assert-True (Test-Path $shortWorkspace) "the workspace folder was created"
}
catch {
    Write-Output "  FAIL - unhandled error: $($_.Exception.Message)"
    $failures.Add("unhandled error: $($_.Exception.Message)") | Out-Null
}
finally {
    foreach ($root in @($testRootDeep, $testRootShort)) {
        if ($root -and (Test-Path $root)) {
            try { Remove-Item -Recurse -Force -Path $root -ErrorAction SilentlyContinue } catch { }
        }
    }
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
