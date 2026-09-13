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
    172 step 6 therefore takes the spec's "sinon" branch: no settings.json
    is written by the installer; README.md documents the window and what to
    answer instead.

    Mechanical, model-free: greps README.md for the FAQ entry and its two
    required elements (what to answer, and why it is safe not to grant
    write access) -- no model call.

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
Write-Output "=== README.md documents the first-access permission window ==="
Assert-True $readmeText.Contains('permission') "README.md mentions a permission window"
Assert-True $readmeText.Contains('Yes') "README.md tells what to answer (the actual button text)"
Assert-True $readmeText.Contains('additionalDirectories') "README.md names the setting it deliberately does not use"
Assert-True $readmeText.Contains('RULES-2026-09-11-190000-project-second-brain-boundary.md') "README.md links the boundary rule as the reason additionalDirectories is not set"

Write-Output ""
Write-Output "=== The installer does not write a settings.json permissions block for the created project ==="
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
