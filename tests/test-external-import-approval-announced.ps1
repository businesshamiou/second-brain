#Requires -Version 5.1
<#
.SYNOPSIS
    External-import approval announcement test (Mission 173 step 6, Q17).

.DESCRIPTION
    Rerun with one command, from the repository root:

        powershell -NoProfile -ExecutionPolicy Bypass -File tests\test-external-import-approval-announced.ps1

    Claude Code's own documentation (read 2026-09-13, Mesures prealables):
    a symbolic link/junction whose target is outside the current working
    directory is treated as an EXTERNAL IMPORT and triggers a one-time
    approval prompt per project. Mission 173 steps 4-5 create exactly that
    (the assistant/skills links, and the project's own @import of
    second-brain's CLAUDE.md) -- this step makes sure nobody is surprised
    by it: the announcement (what will happen, what to answer, why it is
    safe) must appear in three places (Validations criterion 4): README.md,
    INSTALL.md, and project-bootstrap.sh's own console output when it
    creates a project.

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

Write-Output ""
Write-Output "=== README.md announces it ==="
$readmeText = Get-Content -Raw -Path (Join-Path $RepoRoot 'README.md') -Encoding UTF8
Assert-True ($readmeText -match 'import externe') "README.md names the mechanism (import externe)"
Assert-True ($readmeText -match 'approbation') "README.md says an approval will be asked"
Assert-True ($readmeText -match '(?i)r.ponds?\s*\*{0,2}oui') "README.md says what to answer"

Write-Output ""
Write-Output "=== INSTALL.md announces it ==="
$installMdText = Get-Content -Raw -Path (Join-Path $RepoRoot 'INSTALL.md') -Encoding UTF8
Assert-True ($installMdText -match 'import externe') "INSTALL.md names the mechanism (import externe)"
Assert-True ($installMdText -match 'approbation') "INSTALL.md says an approval will be asked"

Write-Output ""
Write-Output "=== project-bootstrap.sh's own console output announces it, for a real created project ==="
$TestRoot = Join-Path $env:TEMP ("sb-importapproval-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $TestRoot | Out-Null
Write-Output "  TestRoot: $TestRoot"

try {
    $clonePath = Join-Path $TestRoot 'clone'
    New-Item -ItemType Directory -Force -Path $clonePath | Out-Null
    Copy-Item -Path (Join-Path $RepoRoot '*') -Destination $clonePath -Recurse -Force -Exclude @('.git')

    . (Join-Path $RepoRoot 'tools\resolve-bash-exe.ps1')
    $bashExe = Resolve-BashExe
    # A real marker, written by the repo's own tool -- a hand-written
    # placeholder file is not enough: project-bootstrap.sh's own Vault-root
    # lookup requires the template's real shape, not just the file's
    # presence (measured directly: "chemin du Vault illisible" otherwise).
    & $bashExe (Join-Path $clonePath 'tools\write-marker.sh') ($TestRoot -replace '\\', '/') 'Testbot' | Out-Null

    $projectPath = Join-Path $TestRoot 'demo-project'
    $posixProjectPath = ($projectPath -replace '\\', '/')
    # Never 2>&1: under this script's own $ErrorActionPreference = 'Stop',
    # merging a native command's stderr into the pipeline wraps it as a
    # terminating NativeCommandError (same trap install.ps1's own
    # Invoke-QuietGit/Invoke-BashTool comments already document) -- the
    # announcement this test checks for is on stdout anyway.
    $output = & $bashExe (Join-Path $clonePath 'tools\project-bootstrap.sh') $posixProjectPath 'Demo Project'
    $joinedOutput = $output -join "`n"
    Assert-True ($joinedOutput -match 'external import') "project-bootstrap.sh's own output names the mechanism (external import)"
    Assert-True ($joinedOutput -match '(?i)approval') "project-bootstrap.sh's own output says an approval will be asked"
    Assert-True ($joinedOutput -match '(?i)answer yes') "project-bootstrap.sh's own output says what to answer"
    Assert-True (Test-Path $projectPath) "the project was actually created (sanity)"
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
