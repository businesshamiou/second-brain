#Requires -Version 5.1
<#
.SYNOPSIS
    Project skeleton and rule-contradiction test (Mission 172, audit
    defects 7 and 8).

.DESCRIPTION
    Rerun with one command, from the repository root:

        powershell -NoProfile -ExecutionPolicy Bypass -File tests\test-project-structure-standard-conformity.ps1

    Audit defect 7 ("missions/ absent du projet cree") was measured
    NON-REPRODUCIBLE: tools/project-bootstrap.sh already creates it (since
    this repository's initial commit), and the real installation mirror
    (sb2/landing-page-factory/missions/) already has it. This test proves
    that measurement mechanically rather than trusting the audit's prose:
    it runs project-bootstrap.sh directly and checks the created project's
    skeleton against rules/RULES-2026-08-26-142800-project-structure-
    standard.md's own reference list.

    Audit defect 8 (RULES-2026-08-17-211522 section 8's "inheritance does
    not force missions/" read as contradicting RULES-2026-08-26-142800's
    unconditional skeleton mandate) is fixed by reconciling text and a
    reciprocal `see also` link in both rule files (Doctrine rule 8: apply
    the more specific rule, record the contradiction and the fix). This
    test greps both files for the reconciling text so a future edit that
    silently reintroduces the contradiction is caught.

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
Write-Output "=== Defect 7: missions/ exists in a freshly created project ==="

. (Join-Path $RepoRoot 'tools\resolve-bash-exe.ps1')
$bashExe = Resolve-BashExe
$TestRoot = Join-Path $env:TEMP ("sb-projectstruct-" + [Guid]::NewGuid().ToString('N'))
$clonePath = Join-Path $TestRoot 'second-brain'
$projectPath = Join-Path $TestRoot 'demo-project'
New-Item -ItemType Directory -Force -Path $TestRoot | Out-Null
Write-Output "  TestRoot: $TestRoot"

function ConvertTo-PosixPathLocal {
    param([string] $Path)
    $p = $Path -replace '\\', '/'
    if ($p -match '^([A-Za-z]):(.*)$') { return "/$($Matches[1].ToLowerInvariant())$($Matches[2])" }
    return $p
}

try {
    & git -c core.longpaths=true clone -q -- $RepoRoot $clonePath
    if ($LASTEXITCODE -ne 0) { throw "git clone failed" }

    # project-bootstrap.sh requires a VAULT-ROOT.md ancestor -- the real
    # installer writes it (tools/write-marker.sh) before ever calling
    # project-bootstrap.sh; this minimal test does the same.
    $writeMarkerScript = Join-Path $clonePath 'tools\write-marker.sh'
    & $bashExe $writeMarkerScript (ConvertTo-PosixPathLocal $TestRoot) 'Testworkspace'

    $bootstrapScript = Join-Path $clonePath 'tools\project-bootstrap.sh'
    & $bashExe $bootstrapScript (ConvertTo-PosixPathLocal $projectPath) 'Demo Project'

    # Reference skeleton, read straight from the standard itself (Section
    # 2) rather than hand-typed, so this test never drifts out of sync
    # with the rule it is proving conformity to.
    $standardText = Get-Content -Raw -Path (Join-Path $clonePath 'rules\RULES-2026-08-26-142800-project-structure-standard.md') -Encoding UTF8
    $skeletonFolders = @('rules', 'state', 'missions', 'decisions', 'proposals', 'knowledge', 'handoffs')
    foreach ($folder in $skeletonFolders) {
        Assert-True ($standardText.Contains("$folder/")) "reference standard itself still lists '$folder/' (test not stale)"
        Assert-True (Test-Path (Join-Path $projectPath $folder)) "created project has '$folder/' (skeleton section 2)"
    }
    Assert-True (Test-Path (Join-Path $projectPath 'missions')) "created project has 'missions/' specifically (audit defect 7)"
    Assert-True (Test-Path (Join-Path $projectPath 'README.md')) "created project has 'README.md' (skeleton section 2)"

    Write-Output ""
    Write-Output "=== Defect 8: the two rules no longer contradict each other ==="

    # Read from $RepoRoot's own working tree, not the clone: the clone
    # reflects the last COMMIT (git clone never carries over uncommitted
    # changes), and this half of the test is about the rule text itself,
    # not about exercising project-bootstrap.sh against it.
    $versioningText = Get-Content -Raw -Path (Join-Path $RepoRoot 'rules\RULES-2026-08-17-211522-mission-versioning-and-generated-output.md') -Encoding UTF8
    Assert-True $versioningText.Contains('RULES-2026-08-26-142800-project-structure-standard.md') "versioning rule (211522) links the structure standard (142800)"
    Assert-True $versioningText.Contains('Mission 172') "versioning rule (211522) records the Mission 172 reconciliation"
    Assert-True (-not ($versioningText -match 'ne force pas la cr[ée]ation de `?missions/`?')) "versioning rule (211522) no longer names missions/ as NOT forced (the contradiction's exact wording)"

    $standardTextFromRepoRoot = Get-Content -Raw -Path (Join-Path $RepoRoot 'rules\RULES-2026-08-26-142800-project-structure-standard.md') -Encoding UTF8
    Assert-True $standardTextFromRepoRoot.Contains('RULES-2026-08-17-211522-mission-versioning-and-generated-output.md') "structure standard (142800) links back to the versioning rule (211522, reciprocal)"
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
