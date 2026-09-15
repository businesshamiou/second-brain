#Requires -Version 5.1
<#
.SYNOPSIS
    Permission-window documentation test (Mission 172, audit defect 2).

.DESCRIPTION
    Rerun with one command, from the repository root:

        powershell -NoProfile -ExecutionPolicy Bypass -File tests\test-permission-window-documented.ps1

    Measured at the 2026-09-13 acceptance: the first read of the assistant
    subagent from a neighbour project (a sibling of the second-brain clone)
    opens an English Claude Code permission window, unexplained. Research
    (Claude Code settings documentation) confirmed a
    `permissions.additionalDirectories` setting exists, but it grants read
    AND write access to the extra directory -- installing it for
    second-brain would let a neighbour project write into second-brain,
    contradicting this repository's own project/second-brain boundary rule
    (rules/RULES-2026-09-11-190000-project-second-brain-boundary.md). Mission
    172 step 6 therefore took the spec's "sinon" branch: no settings.json is
    written by the installer; README.md documents the window and what to
    answer instead.

    Updated for Mission 173 step 6 (Q17, corrected at step 9's own Contrôle):
    Mission 173 replaced the scenario this test originally measured (a
    NEIGHBOUR project reading a PROFILE-level link) with project-level
    links from each project straight to its own second-brain clone --
    `additionalDirectories` is no longer even a candidate setting to avoid,
    since nothing lives in the profile any more for a neighbour project to
    need cross-directory read access to (Mission 173 step 3). The window
    itself still appears (now for a different reason: Claude Code's own
    "external import" treatment of a project-local link whose target
    resolves outside the project folder, tested in full by
    tests/test-external-import-approval-announced.ps1) and README.md's FAQ
    entry was rewritten in French to document THAT window. This test keeps
    its own distinct angle -- confirming no settings.json permissions block
    is ever written for the created project, and that the boundary rule is
    linked as part of the reasoning -- rather than duplicate the other
    test's own assertions about the announcement's wording.

    Mechanical, model-free: greps README.md and tools/project-bootstrap.sh --
    no model call.

    Exit code 0 means every assertion passed. Exit code 1 means at least one
    did not; details are printed to stdout as each check runs.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path $PSScriptRoot -Parent
$failures = New-Object System.Collections.Generic.List[string]

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if ($Condition) { Write-Output "  PASS - $Message" }
    else { Write-Output "  FAIL - $Message"; $failures.Add($Message) | Out-Null }
}

$readmeText = Get-Content -Raw -Path (Join-Path $RepoRoot 'README.md') -Encoding UTF8

Write-Output ""
Write-Output "=== README.md documents the first-access permission window (Mission 173 wording) ==="
Assert-True ($readmeText -match 'approbation') "README.md mentions the approval window (approbation)"
Assert-True ($readmeText -match '(?i)r.ponds?\s*\*{0,2}oui') "README.md tells what to answer (repond oui)"
Assert-True ($readmeText -match 'import externe') "README.md names the mechanism now in play (import externe, not additionalDirectories)"
Assert-True $readmeText.Contains('RULES-2026-09-11-190000-project-second-brain-boundary.md') "README.md links the boundary rule as part of why answering yes is safe"

Write-Output ""
Write-Output "=== The installer never writes a settings.json permissions block for the created project ==="
$bootstrapText = Get-Content -Raw -Path (Join-Path $RepoRoot 'tools\project-bootstrap.sh') -Encoding UTF8
Assert-True (-not $bootstrapText.Contains('additionalDirectories')) "tools/project-bootstrap.sh does not write additionalDirectories (would grant write access into second-brain)"

Write-Output ""
if ($failures.Count -gt 0) {
    Write-Output "=== FAILURES ($($failures.Count)) ==="
    $failures | ForEach-Object { Write-Output "  - $_" }
    exit 1
}
Write-Output "All assertions passed."
exit 0
