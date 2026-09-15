#Requires -Version 5.1
<#
.SYNOPSIS
    Assistant description language test (Mission 172, audit defect 1).

.DESCRIPTION
    Rerun with one command, from the repository root:

        powershell -NoProfile -ExecutionPolicy Bypass -File tests\test-assistant-description-language.ps1

    Mission 172 step 4 requires that the frontmatter `description` field of
    the generated Claude Code subagent and Codex skill be produced in the
    installation's chosen language, and be more decisive than a plain
    description (Claude Code reads this field to decide whether to delegate
    to the subagent instead of answering itself -- measured at acceptance:
    unnamed, the primary agent answered in the assistant's place).

    Mechanical, model-free: generates the two forms for FR, EN and ES and
    greps each `description:` line for a language-specific needle and its
    absence in the other languages' needles -- no model call.

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

$TestRoot = Join-Path $env:TEMP ("sb-assistant-lang-" + [Guid]::NewGuid().ToString('N'))
Write-Output ""
Write-Output "TestRoot: $TestRoot"

# One language-specific needle per language, present only in that
# language's template (checked both ways: present in its own language,
# absent from the other two, so a stuck default would fail loudly).
$needles = @{
    FR = 'A invoquer systematiquement'
    EN = 'MUST be invoked'
    ES = 'SIEMPRE debe invocarse'
}

# Minimal clone: assistant/ASSISTANT.md plus every source path named in
# $Script:WebPackageKnowledgeFiles's own SourcePaths lists -- New-AssistantForms
# also writes the web package, which needs these to exist (same pattern as
# tests/test-web-package-answers-test-questions.ps1).
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
    foreach ($lang in @('FR', 'EN', 'ES')) {
        Write-Output ""
        Write-Output "=== Language: $lang ==="
        $clone = Join-Path $TestRoot $lang
        New-MinimalClone -ClonePath $clone

        $slug = New-AssistantForms -ClonePath $clone -Name 'Testlang' -Language $lang

        $subagentText = Get-Content -Raw -Path (Join-Path $clone ".claude\agents\$slug.md") -Encoding UTF8
        $skillText = Get-Content -Raw -Path (Join-Path $clone ".agents\skills\$slug\SKILL.md") -Encoding UTF8

        foreach ($form in @{ Subagent = $subagentText; 'Codex skill' = $skillText }.GetEnumerator()) {
            $descriptionLine = ($form.Value -split "`n" | Where-Object { $_ -match '^description:' })
            Assert-True ($descriptionLine -match [regex]::Escape($needles[$lang])) "$($form.Key) ($lang) description contains its own language's needle ('$($needles[$lang])')"
            foreach ($other in ($needles.Keys | Where-Object { $_ -ne $lang })) {
                Assert-True (-not ($descriptionLine -match [regex]::Escape($needles[$other]))) "$($form.Key) ($lang) description does not contain $other's needle ('$($needles[$other])')"
            }
            Assert-True ($descriptionLine -match 'Testlang') "$($form.Key) ($lang) description names the assistant"
        }
    }

    Write-Output ""
    Write-Output "=== Default language (no -Language passed) falls back to FR ==="
    $cloneDefault = Join-Path $TestRoot 'default'
    New-MinimalClone -ClonePath $cloneDefault
    $slugDefault = New-AssistantForms -ClonePath $cloneDefault -Name 'Testlang'
    $subagentDefaultText = Get-Content -Raw -Path (Join-Path $cloneDefault ".claude\agents\$slugDefault.md") -Encoding UTF8
    Assert-True ($subagentDefaultText -match [regex]::Escape($needles['FR'])) "no -Language passed defaults to FR"
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
