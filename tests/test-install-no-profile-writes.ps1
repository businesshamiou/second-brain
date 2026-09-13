#Requires -Version 5.1
<#
.SYNOPSIS
    No-profile-writes test (Mission 173, Q17: "rien dans le profil").

.DESCRIPTION
    Rerun with one command, from the repository root:

        powershell -NoProfile -ExecutionPolicy Bypass -File tests\test-install-no-profile-writes.ps1

    Owner decision 2026-09-13 (Q17): Second Brain writes nothing into the
    user's profile. Mission 171-C01 (steps 4 and 6) and the code they
    added -- Publish-DeployedSkills, Publish-DeployedAssistant, the
    'assistantDeployed'/'skillsDeployed' installer steps -- are retired by
    this Mission's step 3.

    Runs a full, real, silent installation (-AnswersFile, -TestMode) and
    proves the -TestMode profile's .claude, .agents and .codex
    subdirectories -- the exact scope the Mission's own constraint names
    ("les tests mesurent que ~/.claude, ~/.agents et ~/.codex sont
    identiques avant et apres") -- are byte-for-byte identical before and
    after: since New-InstallerContext creates the profile root empty,
    "absent/empty before, absent/empty after" is the strongest form of
    that proof those three subdirectories can offer. Deliberately does NOT
    assert on the whole profile root: uv (invoked by the pre-commit
    guardians this install triggers) writes its own unrelated cache under
    the test profile root when %USERPROFILE%/$HOME happens to be
    redirected there -- a fact about uv's cache location, nothing to do
    with Q17's own scope. Also asserts the real profile (~/.claude,
    ~/.agents, ~/.codex) is untouched, same technique test-install-e2e.ps1
    already uses.

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

. (Join-Path $RepoRoot 'tools\environment-fingerprint.ps1')

Write-Output ""
Write-Output "=== Real-environment fingerprint (before) ==="
$before = Get-EnvironmentFingerprint
Write-Output "  PATH SHA-256: $($before.PathHash)"
Write-Output "  .claude/skills entries: $($before.ClaudeSkills.Count)"
Write-Output "  .claude/agents entries: $($before.ClaudeAgents.Count)"
Write-Output "  .codex/skills entries: $($before.CodexSkills.Count)"
Write-Output "  .agents/skills entries: $($before.CodexAgentsSkills.Count)"

$TestRoot = Join-Path $env:TEMP ("sb-noprofile-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $TestRoot | Out-Null
Write-Output ""
Write-Output "TestRoot: $TestRoot"

try {
    $workspacePath = Join-Path $TestRoot 'workspace'
    $answersPath = Join-Path $TestRoot 'answers.json'
    $sampleAnswers = Get-Content -Raw -Path (Join-Path $PSScriptRoot 'fixtures\install-answers.sample.json') | ConvertFrom-Json
    $sampleAnswers.workspacePath = $workspacePath
    $sampleAnswers | ConvertTo-Json -Depth 10 | Set-Content -Path $answersPath -Encoding UTF8

    $installScript = Join-Path $RepoRoot 'install.ps1'

    Write-Output ""
    Write-Output "=== Fresh install, -TestMode profile's .claude/.agents/.codex start absent ==="
    $profileRoot = Join-Path $TestRoot 'profile'
    New-Item -ItemType Directory -Force -Path $profileRoot | Out-Null
    function Get-ScopedProfileEntries {
        param([string] $Root)
        $entries = @()
        foreach ($sub in @('.claude', '.agents', '.codex')) {
            $subPath = Join-Path $Root $sub
            if (Test-Path $subPath) {
                $entries += @(Get-ChildItem -Path $subPath -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName })
            }
        }
        return $entries
    }
    $beforeEntries = @(Get-ScopedProfileEntries -Root $profileRoot)
    Assert-True ($beforeEntries.Count -eq 0) "test profile's .claude/.agents/.codex start absent/empty (0 entries)"

    $verdict = & $installScript -Source $RepoRoot -AnswersFile $answersPath -TestMode -TestRoot $TestRoot
    $exit = $LASTEXITCODE
    Write-Output "  verdict: $verdict"
    Assert-True ($exit -eq 0) "install exits 0"
    Assert-True ($verdict -match 'Installation complete') "verdict reports success"

    $afterEntries = @(Get-ScopedProfileEntries -Root $profileRoot)
    Assert-True ($afterEntries.Count -eq 0) "test profile's .claude/.agents/.codex are STILL absent/empty after a full install (0 entries, was 0) -- byte-for-byte identical, the strongest proof an empty scope can offer"
    if ($afterEntries.Count -gt 0) {
        Write-Output "  Unexpected entries written under the test profile's .claude/.agents/.codex:"
        $afterEntries | ForEach-Object { Write-Output "    $_" }
    }

    Write-Output ""
    Write-Output "=== The assistant and method skills exist, but only inside the clone/project, never the profile ==="
    $clonePath = Join-Path $workspacePath 'second-brain'
    Assert-True (Test-Path (Join-Path $clonePath '.claude\agents')) "assistant subagent form still generated INSIDE the clone"
    Assert-True (Test-Path (Join-Path $clonePath 'skills')) "method skills still exist INSIDE the clone"

    Write-Output ""
    Write-Output "=== Second run (installer) is still a true no-op, no profile writes either ==="
    $verdict2 = & $installScript -Source $RepoRoot -AnswersFile $answersPath -TestMode -TestRoot $TestRoot
    $exit2 = $LASTEXITCODE
    Assert-True ($exit2 -eq 0) "second run exits 0"
    Assert-True ($verdict -eq $verdict2) "second run verdict is identical to the first"
    $afterSecondEntries = @(Get-ScopedProfileEntries -Root $profileRoot)
    Assert-True ($afterSecondEntries.Count -eq 0) "test profile's .claude/.agents/.codex are still absent/empty after a second, no-op run"
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
Write-Output "=== Real-environment fingerprint (after) ==="
$after = Get-EnvironmentFingerprint
Write-Output "  PATH SHA-256: $($after.PathHash)"
Write-Output "  .claude/skills entries: $($after.ClaudeSkills.Count)"
Write-Output "  .claude/agents entries: $($after.ClaudeAgents.Count)"
Write-Output "  .codex/skills entries: $($after.CodexSkills.Count)"
Write-Output "  .agents/skills entries: $($after.CodexAgentsSkills.Count)"
Assert-True ($before.PathHash -eq $after.PathHash) "real user PATH is byte-identical before/after"
Assert-True ((Compare-Object $before.ClaudeSkills $after.ClaudeSkills) -eq $null) "real ~/.claude/skills listing is identical before/after"
Assert-True ((Compare-Object $before.ClaudeAgents $after.ClaudeAgents) -eq $null) "real ~/.claude/agents listing is identical before/after"
Assert-True ((Compare-Object $before.CodexSkills $after.CodexSkills) -eq $null) "real ~/.codex/skills listing is identical before/after"
Assert-True ((Compare-Object $before.CodexAgentsSkills $after.CodexAgentsSkills) -eq $null) "real ~/.agents/skills listing is identical before/after"

Write-Output ""
if ($failures.Count -gt 0) {
    Write-Output "=== FAILURES ($($failures.Count)) ==="
    $failures | ForEach-Object { Write-Output "  - $_" }
    exit 1
}
Write-Output "All assertions passed."
exit 0
