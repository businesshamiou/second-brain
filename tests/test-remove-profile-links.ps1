#Requires -Version 5.1
<#
.SYNOPSIS
    Dry-run test for tools/remove-profile-links.ps1 (Mission 173 step 8, Q17).

.DESCRIPTION
    Rerun with one command, from the repository root:

        powershell -NoProfile -ExecutionPolicy Bypass -File tests\test-remove-profile-links.ps1

    Builds a disposable, fabricated fake profile (never the real ~/.claude,
    ~/.agents) with fake links laid out exactly as Mission 171-C01's retired
    Publish-SkillLink/Publish-FileLink used to write them:
      - a junction under .claude\skills\<name>  -> a fake clone's skill dir
      - a hard link  under .claude\agents\<slug>.md -> a fake clone's assistant file
      - a junction under .agents\skills\<slug>  -> a fake clone's Codex skill dir
    plus one FOREIGN junction under .claude\skills, pointing at an unrelated
    folder outside any second-brain clone -- proving the script never touches
    a link some other tool or a hand-made skill installed there.

    Runs the script twice against this fake profile:
      1. no -Remove (list-only, the safe default): asserts every real link is
         named with its true target, the foreign link is not even listed,
         and nothing under the fake profile changed.
      2. -Remove -Confirm:$false: asserts every real link is gone, the
         foreign link is untouched, and -- the one rule this script must
         never break -- every TARGET (the clone's own skill dir, assistant
         file, Codex skill dir) still exists with its content intact.

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

$TestRoot = Join-Path $env:TEMP ("sb-removeprofilelinks-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $TestRoot | Out-Null
Write-Output ""
Write-Output "TestRoot: $TestRoot"

try {
    Write-Output ""
    Write-Output "=== Fabricated fake workspace, fake clone, fake profile ==="
    $workspacePath = Join-Path $TestRoot 'workspace'
    $clonePath = Join-Path $workspacePath 'second-brain'
    $skillSource = Join-Path $clonePath 'skills\fake-skill'
    New-Item -ItemType Directory -Force -Path $skillSource | Out-Null
    Set-Content -Path (Join-Path $skillSource 'SKILL.md') -Value "# fake skill`n" -Encoding UTF8

    $assistantSource = Join-Path $clonePath '.claude\agents\fake-assistant.md'
    New-Item -ItemType Directory -Force -Path (Split-Path $assistantSource -Parent) | Out-Null
    Set-Content -Path $assistantSource -Value "# fake assistant`n" -Encoding UTF8

    $codexSkillSource = Join-Path $clonePath '.agents\skills\fake-assistant'
    New-Item -ItemType Directory -Force -Path $codexSkillSource | Out-Null
    Set-Content -Path (Join-Path $codexSkillSource 'SKILL.md') -Value "# fake assistant codex skill`n" -Encoding UTF8

    $foreignSource = Join-Path $TestRoot 'unrelated-hand-made-skill'
    New-Item -ItemType Directory -Force -Path $foreignSource | Out-Null
    Set-Content -Path (Join-Path $foreignSource 'SKILL.md') -Value "# not from second-brain`n" -Encoding UTF8

    # A DEAD junction (Mission 175, step 8): its own old clone ("old-workspace")
    # is deleted below, so its target text is the only thing left naming it --
    # built under a SEPARATE workspace from $workspacePath (the one this test
    # passes as -WorkspacePath) specifically so Test-PointsInsideClone can
    # never match it: only the new dead-link path should catch this one.
    $deadCloneWorkspace = Join-Path $TestRoot 'old-workspace'
    $deadSkillSource = Join-Path $deadCloneWorkspace 'second-brain\skills\dead-skill'
    New-Item -ItemType Directory -Force -Path $deadSkillSource | Out-Null
    Set-Content -Path (Join-Path $deadSkillSource 'SKILL.md') -Value "# dead skill`n" -Encoding UTF8

    $fakeProfile = Join-Path $TestRoot 'fake-profile'
    $claudeSkillsDir = Join-Path $fakeProfile '.claude\skills'
    $claudeAgentsDir = Join-Path $fakeProfile '.claude\agents'
    $codexSkillsDir = Join-Path $fakeProfile '.agents\skills'
    New-Item -ItemType Directory -Force -Path $claudeSkillsDir, $claudeAgentsDir, $codexSkillsDir | Out-Null

    $skillLinkPath = Join-Path $claudeSkillsDir 'fake-skill'
    $assistantLinkPath = Join-Path $claudeAgentsDir 'fake-assistant.md'
    $codexSkillLinkPath = Join-Path $codexSkillsDir 'fake-assistant'
    $foreignLinkPath = Join-Path $claudeSkillsDir 'unrelated-hand-made-skill'
    $deadLinkPath = Join-Path $claudeSkillsDir 'dead-skill'

    New-Item -ItemType Junction -Path $skillLinkPath -Target (Resolve-Path $skillSource) | Out-Null
    New-Item -ItemType HardLink -Path $assistantLinkPath -Target (Resolve-Path $assistantSource) | Out-Null
    New-Item -ItemType Junction -Path $codexSkillLinkPath -Target (Resolve-Path $codexSkillSource) | Out-Null
    New-Item -ItemType Junction -Path $foreignLinkPath -Target (Resolve-Path $foreignSource) | Out-Null
    New-Item -ItemType Junction -Path $deadLinkPath -Target (Resolve-Path $deadSkillSource) | Out-Null

    # Kill it now: the junction $deadLinkPath survives (a separate filesystem
    # object, in the profile), only what it points at is gone.
    Remove-Item -Recurse -Force -Path $deadCloneWorkspace

    $scriptPath = Join-Path $RepoRoot 'tools\remove-profile-links.ps1'

    Write-Output ""
    Write-Output "=== 1. List-only (no -Remove): nothing touched ==="
    $listOutput = & $scriptPath -WorkspacePath $workspacePath -ProfileRoot $fakeProfile
    Assert-True ($LASTEXITCODE -eq 0) "list-only run exits 0"
    Assert-True (($listOutput -join "`n") -match [regex]::Escape($skillLinkPath)) "lists the fake skill junction"
    Assert-True (($listOutput -join "`n") -match [regex]::Escape($assistantLinkPath)) "lists the fake assistant hard link"
    Assert-True (($listOutput -join "`n") -match [regex]::Escape($codexSkillLinkPath)) "lists the fake Codex skill junction"
    Assert-True (-not (($listOutput -join "`n") -match [regex]::Escape($foreignLinkPath))) "does NOT list the foreign junction (points outside the clone)"
    Assert-True (($listOutput -join "`n") -match [regex]::Escape($deadLinkPath)) "lists the dead junction (target deleted, names a second-brain segment)"
    Assert-True (($listOutput -join "`n") -match 'DeadJunction') "labels the dead junction distinctly (Kind = DeadJunction)"
    Assert-True (($listOutput -join "`n") -match 'Listing only') "says it only listed, nothing removed"
    Assert-True (Test-Path $skillLinkPath) "fake skill link still exists after list-only run"
    Assert-True (Test-Path $assistantLinkPath) "fake assistant link still exists after list-only run"
    Assert-True (Test-Path $codexSkillLinkPath) "fake Codex skill link still exists after list-only run"
    Assert-True (Test-Path $foreignLinkPath) "foreign link still exists after list-only run (never touched)"
    Assert-True ((Get-Item -LiteralPath $deadLinkPath -Force -ErrorAction SilentlyContinue) -ne $null) "dead junction itself still exists after list-only run (only its target is gone)"

    Write-Output ""
    Write-Output "=== 2. -Remove -Confirm:`$false: real links gone, foreign link and every target intact ==="
    $removeOutput = & $scriptPath -WorkspacePath $workspacePath -ProfileRoot $fakeProfile -Remove -Confirm:$false
    Assert-True ($LASTEXITCODE -eq 0) "remove run exits 0"
    Assert-True (-not (Test-Path $skillLinkPath)) "fake skill link removed"
    Assert-True (-not (Test-Path $assistantLinkPath)) "fake assistant link removed"
    Assert-True (-not (Test-Path $codexSkillLinkPath)) "fake Codex skill link removed"
    Assert-True (Test-Path $foreignLinkPath) "foreign junction left untouched"
    Assert-True ((Get-Item -LiteralPath $deadLinkPath -Force -ErrorAction SilentlyContinue) -eq $null) "dead junction removed"

    Write-Output ""
    Write-Output "=== 3. Targets untouched -- the one rule this script must never break ==="
    # -match, not -eq: Set-Content -Encoding UTF8 always writes a BOM, so
    # Get-Content -Raw's exact string would carry a leading BOM character
    # an -eq literal comparison never matches (the same PowerShell UTF-8
    # BOM quirk already documented against sb_installer_helper.py's own
    # read_json -- here it just needs a tolerant comparison, not a fix).
    Assert-True (Test-Path (Join-Path $skillSource 'SKILL.md')) "the clone's own skill source still exists, with its content"
    Assert-True ((Get-Content -Raw (Join-Path $skillSource 'SKILL.md')) -match '# fake skill') "the clone's own skill source content is unchanged"
    Assert-True (Test-Path $assistantSource) "the clone's own assistant source file still exists"
    Assert-True ((Get-Content -Raw $assistantSource) -match '# fake assistant') "the clone's own assistant source content is unchanged"
    Assert-True (Test-Path (Join-Path $codexSkillSource 'SKILL.md')) "the clone's own Codex skill source still exists, with its content"
    Assert-True (Test-Path $foreignSource) "the unrelated foreign source directory still exists, untouched"

    Write-Output ""
    Write-Output "=== 4. Rerun after removal: nothing left to report ==="
    $rerunOutput = & $scriptPath -WorkspacePath $workspacePath -ProfileRoot $fakeProfile
    Assert-True ($LASTEXITCODE -eq 0) "rerun after removal exits 0"
    Assert-True (($rerunOutput -join "`n") -match 'Nothing to do') "rerun after removal reports nothing left to do"
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
