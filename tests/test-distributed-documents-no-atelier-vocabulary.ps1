#Requires -Version 5.1
<#
.SYNOPSIS
    Sweeps the CONTENT of tracked, distributed, participant-facing documents
    for atelier vocabulary (Mission 177, step 4b). PowerShell parity with
    tests/test-distributed-documents-no-atelier-vocabulary.sh.

.DESCRIPTION
    Complement to Mission 174: that one sweeps only the CONSOLE OUTPUT of a
    nominal flow, never the CONTENT of documents themselves -- that gap let
    the role charter's `vault/skills/session-start/reading-list.md` citation
    (RULES-2026-08-23-224706-role-charter-and-session-determination.md) ship
    unnoticed: invisible to a console sweep, read directly by any
    participant who opens that file.

    SCOPE: an include list, not an exclude list -- the folders and files a
    participant actually reads as documentation or guidance (rules/,
    knowledge/, templates/, skills/ except external/, assistant/, i18n/,
    AGENTS.md, CLAUDE.md, README.md, INSTALL.md). Measured beforehand
    (Mission 177, step 1): these folders carry zero occurrences today.
    Source code (tools/, tests/) legitimately cites these same words in its
    own fixtures, historical-rationale comments, or its own definition (same
    pattern as tools/check-private-patterns.sh's own definition/test pair)
    -- including it would have needed a file-by-file exclude list as long
    as it is arbitrary, for far less participant-facing risk than a
    document the participant opens directly.

    Rerun with one command, from the repository root:
        powershell -NoProfile -ExecutionPolicy Bypass -File tests\test-distributed-documents-no-atelier-vocabulary.ps1

    Exit code 0 means no occurrence in the included documents, and the
    negative case proves the sweep still detects a present pattern. Exit
    code 1 otherwise; the offending file(s) and line(s) are printed.
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

# Same four atelier words as tests/test-nominal-flow-no-atelier-vocabulary.ps1
# (Mission 174), plus any backtick-quoted path starting with `vault/` -- the
# one alias tools/check-asserted-paths.sh still resolves back to this repo
# itself (historical: this repo was called "vault" before it shipped as a
# product), so the one kind of path that guardian cannot tell apart from a
# real subfolder a participant would have -- this repo never had a real
# `vault/` subfolder.
$WordPatterns = @(
    'workshop-build',
    'workshop-production',
    '\bworkshops\b',
    '\bLegacy\b'
)
$PathPattern = '`vault/'

# Scope: the live folders a participant reads, plus the root files that
# address them directly. `skills/external/` is excluded from `skills/`:
# third-party material adopted verbatim, body guaranteed by a SHA-256
# fingerprint (DECISION-171209) -- never rewritten, even for a vocabulary
# reason (measured: its "Legacy" occurrences are a plugin script's own
# filename, unrelated to the atelier).
$IncludeDirs = @('rules', 'knowledge', 'templates', 'skills', 'assistant', 'i18n')
$IncludeFiles = @('AGENTS.md', 'CLAUDE.md', 'README.md', 'INSTALL.md')
$ExcludeDir = Join-Path $RepoRoot 'skills\external'

function Get-ScopedFiles {
    param([string] $RepoRoot)
    $files = New-Object System.Collections.Generic.List[string]
    foreach ($d in $IncludeDirs) {
        $full = Join-Path $RepoRoot $d
        if (-not (Test-Path -LiteralPath $full)) { continue }
        Get-ChildItem -LiteralPath $full -Recurse -File | ForEach-Object {
            if ($_.FullName.StartsWith($ExcludeDir, [StringComparison]::OrdinalIgnoreCase)) { return }
            $files.Add($_.FullName) | Out-Null
        }
    }
    foreach ($f in $IncludeFiles) {
        $full = Join-Path $RepoRoot $f
        if (Test-Path -LiteralPath $full) { $files.Add($full) | Out-Null }
    }
    return $files
}

function Find-PatternHits {
    param([string[]] $Patterns, [string] $PlainPattern, [string[]] $Files)
    $hitReports = @()
    foreach ($pattern in $Patterns) {
        $hits = @()
        foreach ($f in $Files) {
            $matches = Select-String -LiteralPath $f -Pattern $pattern
            if ($matches) { $hits += $matches }
        }
        if ($hits.Count -gt 0) {
            $hitReports += [PSCustomObject]@{ Pattern = $pattern; Hits = $hits }
        }
    }
    if ($PlainPattern) {
        $hits = @()
        foreach ($f in $Files) {
            $matches = Select-String -LiteralPath $f -SimpleMatch -Pattern $PlainPattern
            if ($matches) { $hits += $matches }
        }
        if ($hits.Count -gt 0) {
            $hitReports += [PSCustomObject]@{ Pattern = $PlainPattern; Hits = $hits }
        }
    }
    return [PSCustomObject]@{
        AnyMatch = ($hitReports.Count -gt 0)
        Hits     = $hitReports
    }
}

Write-Output ""
Write-Output "=== 1. Sweep of distributed documents facing the participant ==="
$scoped = Get-ScopedFiles -RepoRoot $RepoRoot
$sweepResult = Find-PatternHits -Patterns $WordPatterns -PlainPattern $PathPattern -Files $scoped
foreach ($r in $sweepResult.Hits) {
    Write-Output "  FAIL - atelier pattern '$($r.Pattern)' found:"
    foreach ($h in $r.Hits) { Write-Output "      $($h.Path):$($h.LineNumber):$($h.Line.Trim())" }
    $failures.Add("atelier pattern '$($r.Pattern)' found in a distributed document") | Out-Null
}
Assert-True (-not $sweepResult.AnyMatch) "no atelier word or path in the distributed documents facing the participant"

Write-Output ""
Write-Output "=== 2. Negative case: the sweep still detects a pattern when present ==="
# Disposable sandbox repo, never a file tracked by THIS repo -- same
# discipline as tools/check-private-patterns.sh and Mission 176.
$Sandbox = Join-Path $env:TEMP ("sb-atelier-doc-sweep-" + [Guid]::NewGuid().ToString('N'))
try {
    New-Item -ItemType Directory -Force -Path (Join-Path $Sandbox 'rules') | Out-Null
    $fixture = Join-Path $Sandbox 'rules\example.md'
    Set-Content -Path $fixture -Value 'Un document qui cite workshop-build par erreur, et un chemin `vault/skills/x.md`.' -Encoding UTF8
    $negativeResult = Find-PatternHits -Patterns @('workshop-build') -PlainPattern $PathPattern -Files @($fixture)
    foreach ($r in $negativeResult.Hits) {
        Write-Output "  detected (expected) - pattern '$($r.Pattern)' matched $($r.Hits.Count) line(s)"
    }
    Assert-True $negativeResult.AnyMatch "the same sweep detects a fabricated atelier word AND path, never written to this repo"
}
finally {
    Remove-Item -Recurse -Force -Path $Sandbox -ErrorAction SilentlyContinue
}

Write-Output ""
if ($failures.Count -gt 0) {
    Write-Output "=== FAILURES ($($failures.Count)) ==="
    $failures | ForEach-Object { Write-Output "  - $_" }
    exit 1
}
Write-Output "=== RESULT: PASS (all checks green) ==="
exit 0
