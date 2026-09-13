#Requires -Version 5.1
<#
.SYNOPSIS
    Skill/assistant link-conflict message test (Mission 172, audit defect 4).

.DESCRIPTION
    Rerun with one command, from the repository root:

        powershell -NoProfile -ExecutionPolicy Bypass -File tests\test-skill-conflict-message.ps1

    Measured at acceptance: "Note: 52 skill link path(s) already occupied
    by something else, left untouched: <52 comma-separated absolute
    paths>" -- one line, no agent breakdown, no skill names distinct from
    raw paths, no remedy. Mission 172 step 9 rewrites both conflict
    messages (skills deployment and assistant deployment) to name, per
    agent, how many and which skill names conflict, and to propose a
    remedy the participant can actually act on.

    Forces a real conflict by pre-creating a plain folder at one Claude
    Code skill link path and one Codex skill link path (both inside a
    -TestMode profile, never the real one) before running the installer,
    then greps the real console output (both streams, via Start-Process,
    same technique test-install-log-line-count.ps1 uses) for the new
    message's required elements. Also proves the "issue... fonctionne"
    half of the spec: the pre-existing folder is never replaced by a link.

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

$TestRoot = Join-Path $env:TEMP ("sb-skillconflict-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $TestRoot | Out-Null
Write-Output ""
Write-Output "TestRoot: $TestRoot"

try {
    Write-Output ""
    Write-Output "=== Force a real conflict, then run the installer as a real child process ==="

    # Pre-occupy one Claude Code skill path and one Codex skill path with a
    # plain, pre-existing folder holding a marker file -- proof, after the
    # run, that it was genuinely left untouched (not replaced by a link).
    $claudeConflictPath = Join-Path $TestRoot 'profile\.claude\skills\recherche-interne'
    $codexConflictPath = Join-Path $TestRoot 'profile\.agents\skills\session-start'
    New-Item -ItemType Directory -Force -Path $claudeConflictPath | Out-Null
    New-Item -ItemType Directory -Force -Path $codexConflictPath | Out-Null
    Set-Content -Path (Join-Path $claudeConflictPath 'PRE-EXISTING.txt') -Value 'not from second-brain'
    Set-Content -Path (Join-Path $codexConflictPath 'PRE-EXISTING.txt') -Value 'not from second-brain'

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

    Assert-True ($proc.ExitCode -eq 0) "install.ps1 still exits 0 despite the conflict (a conflict is a Note, not a failure)"

    $allOutput = (Get-Content -Path $stdoutPath -Raw -ErrorAction SilentlyContinue) + "`n" + (Get-Content -Path $stderrPath -Raw -ErrorAction SilentlyContinue)

    Write-Output ""
    Write-Output "=== The message is readable without reading the code ==="
    Assert-True $allOutput.Contains('Claude Code') "message names the Claude Code agent"
    Assert-True $allOutput.Contains('Codex') "message names the Codex agent"
    Assert-True $allOutput.Contains('recherche-interne') "message names the conflicting skill by name (Claude Code side)"
    Assert-True $allOutput.Contains('session-start') "message names the conflicting skill by name (Codex side)"
    Assert-True $allOutput.Contains('already occupied') "message states what happened"
    Assert-True ($allOutput.Contains('never') -or $allOutput.Contains('always wins')) "message states the existing item is never touched"
    Assert-True ($allOutput.Contains('remove or rename')) "message proposes a remedy the participant can act on"

    Write-Output ""
    Write-Output "=== The issue actually works: pre-existing content is genuinely untouched ==="
    Assert-True (Test-Path (Join-Path $claudeConflictPath 'PRE-EXISTING.txt')) "the pre-existing Claude Code folder's own file still exists"
    Assert-True (-not ((Get-Item $claudeConflictPath).LinkType)) "the Claude Code path is still a plain folder, not replaced by a link"
    Assert-True (Test-Path (Join-Path $codexConflictPath 'PRE-EXISTING.txt')) "the pre-existing Codex folder's own file still exists"
    Assert-True (-not ((Get-Item $codexConflictPath).LinkType)) "the Codex path is still a plain folder, not replaced by a link"
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
