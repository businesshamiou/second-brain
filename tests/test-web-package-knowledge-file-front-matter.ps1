#Requires -Version 5.1
<#
.SYNOPSIS
    Web package knowledge-file front-matter regression test (Mission 172,
    found at this Mission's own final control).

.DESCRIPTION
    Rerun with one command, from the repository root:

        powershell -NoProfile -ExecutionPolicy Bypass -File tests\test-web-package-knowledge-file-front-matter.ps1

    Mission 172 step 3 introduced HOW-TO.md, condensing multiple sources
    (some carrying their own YAML front matter, e.g.
    skills/session-start/SKILL.md) into one file, separated by a '---'
    divider placed before EACH section including the first. That made the
    generated file's own first line a bare '---', which
    tools/check-obsolescence-guardrail.py's front-matter reader
    (parse_front_matter) treats as an opening fence regardless of what
    follows -- the divider's own heading line (not a `key: value` pair)
    broke its flat parser, refusing the installer's own internal commit
    with "front-matter illisible". Found only at this Mission's own final
    control (test-install-e2e.sh end to end, a real installer run, real
    guardian), not by any of the unit-style web-package tests, none of
    which happened to assert on the file's own first line.

    Runs BOTH generators (PowerShell and the Python mirror) against a
    minimal clone carrying every real source HOW-TO.md needs, and checks
    the produced file's first line directly, plus a full re-run of the
    real guardian against it as the actual authority on whether it
    parses (never a hand-rolled reimplementation of its parser here).

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

. (Join-Path $RepoRoot 'tools\generate-assistant.ps1')

$TestRoot = Join-Path $env:TEMP ("sb-webpkg-fm-" + [Guid]::NewGuid().ToString('N'))
Write-Output ""
Write-Output "TestRoot: $TestRoot"

# Every source path any multi-source $Script:WebPackageKnowledgeFiles entry
# needs, read from that list itself (never hand-typed) so this test never
# drifts out of sync with which sources HOW-TO.md actually condenses.
$sourceFiles = @('assistant\ASSISTANT.md') + @($Script:WebPackageKnowledgeFiles | ForEach-Object { $_.SourcePaths })
function New-MinimalClone {
    param([Parameter(Mandatory = $true)][string] $ClonePath)
    foreach ($relative in $sourceFiles) {
        $src = Join-Path $RepoRoot $relative
        $dst = Join-Path $ClonePath $relative
        New-Item -ItemType Directory -Force -Path (Split-Path $dst -Parent) | Out-Null
        Copy-Item -Path $src -Destination $dst -Force
    }
}

try {
    Write-Output ""
    Write-Output "=== PowerShell generator ==="
    $clonePs1 = Join-Path $TestRoot 'ps1'
    New-MinimalClone -ClonePath $clonePs1
    $slugPs1 = New-AssistantForms -ClonePath $clonePs1 -Name 'Testfm'
    $howToPs1 = Join-Path $clonePs1 "web-package\$slugPs1\HOW-TO.md"
    $firstLinePs1 = (Get-Content -Path $howToPs1 -TotalCount 1 -Encoding UTF8)
    Assert-True (Test-Path $howToPs1) "HOW-TO.md is generated (PowerShell)"
    Assert-True ($firstLinePs1.Trim() -ne '---') "HOW-TO.md's first line is not a bare '---' (PowerShell): '$firstLinePs1'"

    Write-Output ""
    Write-Output "=== Python mirror ==="
    $clonePy = Join-Path $TestRoot 'py'
    New-MinimalClone -ClonePath $clonePy
    $helperScript = Join-Path $RepoRoot 'tools\sb_installer_helper.py'
    & uv run --no-project $helperScript render-assistant $clonePy 'Testfm' --language FR *> $null
    $howToPy = Join-Path $clonePy 'web-package\testfm\HOW-TO.md'
    $firstLinePy = (Get-Content -Path $howToPy -TotalCount 1 -Encoding UTF8)
    Assert-True (Test-Path $howToPy) "HOW-TO.md is generated (Python)"
    Assert-True ($firstLinePy.Trim() -ne '---') "HOW-TO.md's first line is not a bare '---' (Python): '$firstLinePy'"

    Write-Output ""
    Write-Output "=== The real guardian raises no front-matter violation on HOW-TO.md ==="
    # Not a full clean-guardian-pass assertion: this minimal clone is
    # missing files sources like CONTEXT.md link to (an unrelated R3
    # broken-link violation this test's own minimal fixture would cause,
    # not a real defect), so only the exact 'FM ... HOW-TO.md' violation
    # this Mission's regression produced is checked for, not the guardian's
    # overall exit code. Redirected to a FILE, never merged via 2>&1: under
    # this script's own $ErrorActionPreference = 'Stop', merging a native
    # command's stderr into the pipeline wraps it as a terminating
    # NativeCommandError (same trap install.ps1's own Invoke-QuietGit
    # documents and works around).
    $guardianScript = Join-Path $RepoRoot 'tools\check-obsolescence-guardrail.py'
    foreach ($pair in @(@{ Label = 'PowerShell'; Clone = $clonePs1 }, @{ Label = 'Python'; Clone = $clonePy })) {
        Push-Location $pair.Clone
        $guardianLogFile = Join-Path $TestRoot "guardian-$($pair.Label).log"
        $previousEap = $ErrorActionPreference
        try {
            & git init -q .
            & git add -A
            $ErrorActionPreference = 'Continue'
            & uv run --no-project $guardianScript *> $guardianLogFile
        }
        finally {
            $ErrorActionPreference = $previousEap
            Pop-Location
        }
        $guardianOutput = Get-Content -Raw -Path $guardianLogFile -ErrorAction SilentlyContinue
        Assert-True (-not ($guardianOutput -match 'HOW-TO\.md[^\n]*front-matter illisible')) "$($pair.Label) clone's HOW-TO.md triggers no 'front-matter illisible' violation"
    }
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
