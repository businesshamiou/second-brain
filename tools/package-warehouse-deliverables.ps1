#Requires -Version 5.1
<#
.SYNOPSIS
    Package every Skill of the skills-warehouse into one chat-upload ZIP per
    Skill, grouped by collection release, with a per-collection index.md and
    a SHA256SUMS.txt (Mission 171-C01, step 5).

.DESCRIPTION
    For each collection under skills-warehouse/skill-collections/<slug>/skills/
    this script writes, at skills-warehouse/deliverables/<slug>/<DateLabel>/:

      chat-zips/<skill>.zip   one ZIP per Skill, single top-level directory
                              named after the Skill (same packaging rule as
                              skills-warehouse/PRODUCTION_STANDARD.md #5)
      index.md                one line per Skill: name, licence, usage
      SHA256SUMS.txt           sha256sum -c compatible, self-excluded

    Deliberately narrower than skills-warehouse/tools/package-collection-
    release.py: it does not produce the "<slug>-skills-full.zip" collection
    package, does not write manifest.md/validation-report.md, and does not
    gate on a SkillSpector scan. That canonical script already exists and is
    the warehouse's own standard, but it hard-requires a passing SkillSpector
    JSON report (--skillspector-report) produced by an external `skillspector`
    binary; this machine has neither `skillspector` on PATH nor network
    access to fetch it (verified: `uvx skillspector --version` fails to
    reach pypi.org). Duplicating that full production contract without the
    means to satisfy its security gate would be worse than not attempting
    it. This script instead reuses the same source of truth (each Skill's
    own SKILL.md front matter: `description` and `license`) to build exactly
    what Mission 171-C01 step 5 asks for: a Skill zip a user can upload to a
    chat interface, plus a human-readable index. See tools/README.md (none
    yet) or the Mission report for this arbitration.

    Idempotent by construction:
      - Every ZIP entry gets a fixed timestamp (1980-01-01, same convention
        as package-collection-release.py), so ZIP bytes are a pure function
        of the Skill's file contents and relative paths -- never of wall
        clock time or filesystem mtimes.
      - A release directory is immutable once written (matches
        skills-warehouse/deliverables/README.md: "Never overwrite a release
        directory or alter a published checksum."). Re-running with the same
        -DateLabel against unchanged sources recomputes every output in
        memory, finds it byte-identical to what is already on disk, and
        writes nothing. If a recomputed file would differ from what is on
        disk, the script refuses and asks for a new -DateLabel instead of
        silently overwriting a published release.

.PARAMETER Collections
    Collection slugs to package. Defaults to all three named in Mission
    171-C01 step 5.

.PARAMETER DateLabel
    Release folder name under deliverables/<slug>/. Defaults to today's date
    plus "-v1" (yyyy-MM-dd-v1). Existing releases are never reused across a
    different label; pick a new label for a genuinely new release.

.PARAMETER WarehouseRoot
    Path to skills-warehouse/. Defaults to ..\skills-warehouse relative to
    this script (i.e. second-brain\skills-warehouse).

.EXAMPLE
    pwsh tools/package-warehouse-deliverables.ps1
    Packages all three collections into today's release label.

.EXAMPLE
    pwsh tools/package-warehouse-deliverables.ps1 -Collections visual-content -DateLabel 2026-09-12-v1
    Packages a single collection into an explicit label; safe to re-run.
#>
[CmdletBinding()]
param(
    [string[]] $Collections = @('software-engineering', 'web-design', 'visual-content'),
    [string]   $DateLabel = (Get-Date -Format 'yyyy-MM-dd') + '-v1',
    [string]   $WarehouseRoot,
    # One-line usage cut length in index.md. Kept short on purpose: this
    # repository's own pre-commit guardian (tools/check_index_weight.py,
    # DECISION-2026-09-05-124647) refuses any file named index.md heavier
    # than $IndexWeightCapBytes -- a 90-Skill collection at the full
    # front-matter description length (up to 200 chars, PRODUCTION_STANDARD
    # #2) would blow that budget. The guardian's own remedy is "line as a
    # locator": a short usage cue is enough for index.md; the full
    # description stays in each Skill's own SKILL.md.
    [int]      $IndexUsageMaxChars = 45
)

$IndexWeightCapBytes = 8000  # DECISION-2026-09-05-124647 point 3, tools/check_index_weight.py

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.IO.Compression | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem | Out-Null

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $WarehouseRoot) {
    $WarehouseRoot = Join-Path $ScriptDir '..\skills-warehouse'
}
$WarehouseRoot = (Resolve-Path $WarehouseRoot).Path
$CollectionsRoot = Join-Path $WarehouseRoot 'skill-collections'
$DeliverablesRoot = Join-Path $WarehouseRoot 'deliverables'

# Same forbidden-path contract as package-collection-release.py's forbidden()
# (PRODUCTION_STANDARD.md #5): VCS metadata, caches, OS artefacts, nested
# ZIPs, and the "releases" directory name never enter an active package.
$ForbiddenParts = @('.git', 'node_modules', '__MACOSX', '__pycache__', '.pytest_cache', 'releases')
$ForbiddenNames = @('.DS_Store', 'Thumbs.db')

function Test-ForbiddenRelativePath {
    param([string] $RelativePosixPath)
    $parts = $RelativePosixPath -split '/'
    foreach ($p in $parts) { if ($ForbiddenParts -contains $p) { return $true } }
    $leaf = $parts[-1]
    if ($ForbiddenNames -contains $leaf) { return $true }
    if ($leaf.ToLowerInvariant().EndsWith('.zip')) { return $true }
    return $false
}

function ConvertFrom-YamlScalar {
    param([string] $Text)
    $t = $Text.Trim()
    if ($t.Length -ge 2 -and $t[0] -eq '"' -and $t[-1] -eq '"') {
        return $t.Substring(1, $t.Length - 2) -replace '\\"', '"'
    }
    if ($t.Length -ge 2 -and $t[0] -eq "'" -and $t[-1] -eq "'") {
        return ($t.Substring(1, $t.Length - 2) -replace "''", "'")
    }
    return $t
}

function Get-SkillFrontMatter {
    <# Reads only the top-level (non-indented) `key: value` lines between the
       two `---` fences of a SKILL.md -- enough to recover `description` and
       `license`, the same two fields PRODUCTION_STANDARD.md requires every
       Skill to carry and the same source LICENSES.md/manifest.md are built
       from. Nested `metadata:` mappings are skipped; this script needs
       neither upstream-repo nor upstream-license-evidence. #>
    param([string] $SkillMdPath)
    $raw = Get-Content -LiteralPath $SkillMdPath -Raw
    if ($raw -notmatch '(?s)\A---\r?\n(?<front>.*?)\r?\n---(\r?\n|\z)') {
        throw "Invalid or missing front matter: $SkillMdPath"
    }
    $fields = @{}
    foreach ($line in ($Matches['front'] -split "`r?`n")) {
        if ($line.Trim().Length -eq 0) { continue }
        if ($line -match '^\s') { continue }   # skip nested mapping lines (e.g. metadata:)
        if ($line -notmatch ':') { continue }
        $idx = $line.IndexOf(':')
        $key = $line.Substring(0, $idx).Trim()
        $value = $line.Substring($idx + 1)
        if ($value.Trim().Length -gt 0) {
            $fields[$key] = ConvertFrom-YamlScalar $value
        }
    }
    return $fields
}

function Get-SkillFiles {
    <# Returns a sorted list of (RelativePosixPath, FullPath) pairs for every
       non-forbidden file under a Skill directory. #>
    param([string] $SkillDir)
    $root = (Resolve-Path $SkillDir).Path
    $items = Get-ChildItem -LiteralPath $root -Recurse -File -Force
    $result = @()
    foreach ($item in $items) {
        $rel = $item.FullName.Substring($root.Length + 1) -replace '\\', '/'
        if (Test-ForbiddenRelativePath $rel) {
            throw "Forbidden active file: $((Split-Path -Leaf $root))/$rel"
        }
        $result += [pscustomobject]@{ Relative = $rel; FullPath = $item.FullName }
    }
    return $result | Sort-Object { $_.Relative.ToLowerInvariant() }
}

function New-DeterministicZipBytes {
    <# Builds a ZIP in memory: fixed per-entry timestamp (1980-01-01, the
       oldest date the ZIP format allows and the same convention
       package-collection-release.py uses) so the output bytes depend only
       on entry names and contents, never on when this script runs or on
       source-file mtimes. #>
    param(
        [Parameter(Mandatory)] [array] $Entries   # [pscustomobject]@{ Name; Bytes }
    )
    $ms = New-Object System.IO.MemoryStream
    $fixedStamp = [DateTimeOffset]::new(1980, 1, 1, 0, 0, 0, [TimeSpan]::Zero)
    $archive = New-Object System.IO.Compression.ZipArchive($ms, [System.IO.Compression.ZipArchiveMode]::Create, $true)
    try {
        foreach ($e in ($Entries | Sort-Object { $_.Name })) {
            $entry = $archive.CreateEntry($e.Name, [System.IO.Compression.CompressionLevel]::Optimal)
            $entry.LastWriteTime = $fixedStamp
            $stream = $entry.Open()
            try { $stream.Write($e.Bytes, 0, $e.Bytes.Length) } finally { $stream.Dispose() }
        }
    } finally {
        $archive.Dispose()
    }
    return $ms.ToArray()
}

function Get-Sha256Hex {
    param([byte[]] $Bytes)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { return [System.BitConverter]::ToString($sha.ComputeHash($Bytes)).Replace('-', '').ToLowerInvariant() }
    finally { $sha.Dispose() }
}

function Write-BytesIfDifferent {
    <# Writes $Bytes to $Path only if the file is absent or its content
       already matches. Returns 'created', 'unchanged', or throws on a
       genuine mismatch (protects an immutable release from silent
       overwrite). #>
    param([string] $Path, [byte[]] $Bytes)
    if (Test-Path -LiteralPath $Path) {
        $existing = [System.IO.File]::ReadAllBytes($Path)
        if ([System.Linq.Enumerable]::SequenceEqual($existing, $Bytes)) {
            return 'unchanged'
        }
        throw "Refusing to overwrite an existing release file with different content: $Path (pick a new -DateLabel for a genuinely new release)"
    }
    $dir = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllBytes($Path, $Bytes)
    return 'created'
}

function Get-CollectionTitle {
    param([string] $Slug)
    $catalogPath = Join-Path $CollectionsRoot 'catalog.json'
    $catalog = Get-Content -LiteralPath $catalogPath -Raw | ConvertFrom-Json
    $entry = $catalog.categories | Where-Object { $_.slug -eq $Slug }
    if (-not $entry) { throw "Unknown collection slug: $Slug" }
    return $entry.title
}

function Format-MarkdownCell {
    param([string] $Text)
    if ($null -eq $Text) { return '' }
    return ($Text -replace '\|', '\|') -replace "`r?`n", ' '
}

function Get-UsageOneLiner {
    <# Shortens a Skill's front-matter `description` to a one-line usage cue
       for index.md, cut at a word boundary, ellipsis appended when
       shortened. Keeps index.md well under the repository's index-weight
       guardian even for a 90-Skill collection. #>
    param([string] $Text, [int] $MaxChars)
    $t = $Text.Trim()
    if ($t.Length -le $MaxChars) { return $t }
    $cut = $t.Substring(0, $MaxChars)
    $lastSpace = $cut.LastIndexOf(' ')
    if ($lastSpace -gt 0) { $cut = $cut.Substring(0, $lastSpace) }
    return ($cut.TrimEnd(',', ';', ':', '.', ' ') + '...')
}

$summaries = @()

foreach ($slug in $Collections) {
    Write-Host "== $slug =="
    $collectionDir = Join-Path $CollectionsRoot $slug
    $skillsRoot = Join-Path $collectionDir 'skills'
    if (-not (Test-Path -LiteralPath $skillsRoot)) {
        throw "Missing collection skills directory: $skillsRoot"
    }
    $title = Get-CollectionTitle $slug

    $skillDirs = Get-ChildItem -LiteralPath $skillsRoot -Directory |
        Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md') } |
        Sort-Object Name

    if ($skillDirs.Count -eq 0) {
        throw "No Skills with a SKILL.md found under: $skillsRoot"
    }

    $releaseDir = Join-Path (Join-Path $DeliverablesRoot $slug) $DateLabel
    $chatZipsDir = Join-Path $releaseDir 'chat-zips'

    $rows = @()
    $sumLines = @()
    $totalBytes = 0
    $created = 0
    $unchanged = 0

    foreach ($skillDir in $skillDirs) {
        $name = $skillDir.Name
        $skillMd = Join-Path $skillDir.FullName 'SKILL.md'
        $fields = Get-SkillFrontMatter $skillMd
        if ($fields['name'] -ne $name) {
            throw "Front-matter name does not match folder: $name"
        }
        $description = [string]$fields['description']
        $license = [string]$fields['license']
        if ([string]::IsNullOrWhiteSpace($description)) { throw "Missing description: $name" }
        if ([string]::IsNullOrWhiteSpace($license)) { throw "Missing licence: $name" }

        $files = Get-SkillFiles $skillDir.FullName
        $entries = foreach ($f in $files) {
            [pscustomobject]@{
                Name  = "$name/$($f.Relative)"
                Bytes = [System.IO.File]::ReadAllBytes($f.FullPath)
            }
        }
        $zipBytes = New-DeterministicZipBytes -Entries $entries
        $zipPath = Join-Path $chatZipsDir "$name.zip"
        $state = Write-BytesIfDifferent -Path $zipPath -Bytes $zipBytes
        if ($state -eq 'created') { $created++ } else { $unchanged++ }
        $totalBytes += $zipBytes.Length

        $rows += [pscustomobject]@{
            Name        = $name
            License     = $license
            Description = $description
            Usage       = Get-UsageOneLiner -Text $description -MaxChars $IndexUsageMaxChars
        }
    }

    $indexLines = New-Object System.Collections.Generic.List[string]
    [void]$indexLines.Add("# Index - $slug")
    [void]$indexLines.Add('')
    [void]$indexLines.Add("Collection: $title")
    [void]$indexLines.Add("Release: ``$DateLabel``")
    [void]$indexLines.Add("Skills: **$($rows.Count)**")
    [void]$indexLines.Add('')
    [void]$indexLines.Add('| Skill | Licence | Usage |')
    [void]$indexLines.Add('|---|---|---|')
    foreach ($r in ($rows | Sort-Object Name)) {
        [void]$indexLines.Add("| ``$($r.Name)`` | $(Format-MarkdownCell $r.License) | $(Format-MarkdownCell $r.Usage) |")
    }
    [void]$indexLines.Add('')
    $indexText = ($indexLines -join "`n")
    $indexBytes = [System.Text.Encoding]::UTF8.GetBytes($indexText)
    if ($indexBytes.Length -gt $IndexWeightCapBytes) {
        throw "index.md for '$slug' would be $($indexBytes.Length) bytes > $IndexWeightCapBytes (DECISION-2026-09-05-124647); lower -IndexUsageMaxChars (currently $IndexUsageMaxChars)"
    }
    $indexPath = Join-Path $releaseDir 'index.md'
    $indexState = Write-BytesIfDifferent -Path $indexPath -Bytes $indexBytes
    if ($indexState -eq 'created') { $created++ } else { $unchanged++ }
    $totalBytes += $indexBytes.Length

    # SHA256SUMS.txt covers every produced file except itself -- self-
    # inclusion cannot produce a stable checksum, same rule as
    # PRODUCTION_STANDARD.md #4. Paths are relative to the release
    # directory, sha256sum -c compatible (two spaces, forward slashes).
    $sumTargets = @(Get-ChildItem -LiteralPath $chatZipsDir -File | ForEach-Object { $_.FullName })
    $sumTargets += $indexPath
    $sumTargets = $sumTargets | Sort-Object { ($_ -replace [regex]::Escape($releaseDir + [IO.Path]::DirectorySeparatorChar), '') -replace '\\', '/' }
    foreach ($t in $sumTargets) {
        $rel = ($t.Substring($releaseDir.Length + 1)) -replace '\\', '/'
        $hex = Get-Sha256Hex ([System.IO.File]::ReadAllBytes($t))
        $sumLines += "$hex  $rel"
    }
    $sumsText = ($sumLines -join "`n") + "`n"
    $sumsBytes = [System.Text.Encoding]::ASCII.GetBytes($sumsText)
    $sumsPath = Join-Path $releaseDir 'SHA256SUMS.txt'
    $sumsState = Write-BytesIfDifferent -Path $sumsPath -Bytes $sumsBytes
    if ($sumsState -eq 'created') { $created++ } else { $unchanged++ }
    $totalBytes += $sumsBytes.Length

    $summaries += [pscustomobject]@{
        Collection   = $slug
        Skills       = $rows.Count
        Zips         = $skillDirs.Count
        ReleaseDir   = $releaseDir
        TotalBytes   = $totalBytes
        FilesCreated = $created
        FilesUnchanged = $unchanged
    }

    Write-Host "   skills=$($rows.Count) zips=$($skillDirs.Count) bytes=$totalBytes created=$created unchanged=$unchanged"
    Write-Host "   release: $releaseDir"
}

Write-Host ''
Write-Host '== Summary =='
$grandTotal = ($summaries | Measure-Object -Property TotalBytes -Sum).Sum
$summaries | Format-Table -AutoSize | Out-String | Write-Host
Write-Host "Grand total bytes across all packaged collections: $grandTotal"
