#Requires -Version 5.1
<#
.SYNOPSIS
    The assistant reads the documentation map first and runs on the lightest
    model (Mission 222, phase 3).

.DESCRIPTION
    Both generators (tools/generate-assistant.ps1 and tools/sb_installer_helper.py
    render-assistant) append the documentation map -- the block between the
    doc-map markers of docs/MAP.md -- to the assistant's body, so the three forms
    (Claude Code subagent, Codex skill, web package INSTRUCTIONS.md) carry it
    without a tool call; the subagent's front matter carries `model: haiku`,
    the lightest model the Claude Code subagent format admits.

    Oracles (PASS expected), for each generator:
      (a) the subagent front matter carries `model: haiku`;
      (b) the subagent, the Codex skill and INSTRUCTIONS.md carry the map heading
          and every row of the map;
      (c) INSTRUCTIONS.md stays within the 8,000-character ceiling;
      (d) witness: without docs/MAP.md the generator refuses (fail-closed).
    Static, no model call: the three test questions of assistant/ASSISTANT.md
    and three documentation questions each find their row in the map, and every
    path the map names exists.

    Rerun with:
        powershell -NoProfile -ExecutionPolicy Bypass -File tests\test-assistant-doc-map.ps1
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

. (Join-Path $RepoRoot 'tools\generate-assistant.ps1')

$mapPath = Join-Path $RepoRoot 'docs\MAP.md'
$mapText = Get-Content -Raw -Path $mapPath -Encoding UTF8
$mapBlock = [regex]::Match($mapText, '(?s)<!-- doc-map:start -->(.*?)<!-- doc-map:end -->').Groups[1].Value
$mapRows = @($mapBlock -split "`n" | Where-Object { $_ -match '^\| ' -and $_ -notmatch '^\| If the question' } | ForEach-Object { $_.TrimEnd("`r") })

function New-MinimalClone {
    param([string] $Root, [switch] $WithoutMap)
    $sources = @('assistant\ASSISTANT.md') + @($Script:WebPackageKnowledgeFiles | ForEach-Object { $_.SourcePaths })
    if (-not $WithoutMap) { $sources += 'docs\MAP.md' }
    foreach ($relative in $sources) {
        $dst = Join-Path $Root $relative
        New-Item -ItemType Directory -Force -Path (Split-Path $dst -Parent) | Out-Null
        Copy-Item -Path (Join-Path $RepoRoot $relative) -Destination $dst -Force
    }
}

function Test-Forms {
    param([string] $Clone, [string] $Slug, [string] $Label)
    $sub = Join-Path $Clone ".claude\agents\$Slug.md"
    $skill = Join-Path $Clone ".agents\skills\$Slug\SKILL.md"
    $instr = Join-Path $Clone "web-package\$Slug\INSTRUCTIONS.md"
    foreach ($p in @($sub, $skill, $instr)) { Assert-True (Test-Path $p) "$Label -- generated: $p" }
    if (-not (Test-Path $sub)) { return }
    $subText = Get-Content -Raw -Path $sub -Encoding UTF8
    $front = [regex]::Match($subText, '(?s)^---\n(.*?)\n---').Groups[1].Value
    Assert-True ($front -match '(?m)^model: haiku$') "$Label -- (a) subagent front matter carries 'model: haiku'"
    foreach ($p in @($sub, $skill, $instr)) {
        if (-not (Test-Path $p)) { continue }
        $t = (Get-Content -Raw -Path $p -Encoding UTF8) -replace "`r", ''
        $missing = @($mapRows | Where-Object { -not $t.Contains($_) })
        Assert-True ($t.Contains('## Documentation map') -and $missing.Count -eq 0) "$Label -- (b) $(Split-Path $p -Leaf) carries the map heading and its $($mapRows.Count) rows (missing: $($missing.Count))"
    }
    if (Test-Path $instr) {
        $len = (Get-Content -Raw -Path $instr -Encoding UTF8).Length
        Assert-True ($len -le 8000) "$Label -- (c) INSTRUCTIONS.md within 8,000 characters ($len)"
    }
}

$TestRoot = Join-Path $env:TEMP ("m222-docmap-" + [Guid]::NewGuid().ToString('N').Substring(0, 8))
try {
    Write-Output ""
    Write-Output "=== Static: six questions, each with its row in the map ==="
    Assert-True ($mapRows.Count -ge 10) "the map block holds its rows ($($mapRows.Count))"
    $questions = @(
        @{ Q = "Comment j'ouvre une session ? (ASSISTANT.md, question 1)"; Key = 'opening a session'; Target = 'docs/how-to/open-a-session.md' },
        @{ Q = "Qu'est-ce qu'une Mission et ou je l'ecris ? (question 2)"; Key = 'a Mission and where to write it'; Target = 'docs/how-to/write-a-mission.md' },
        @{ Q = "Cree-moi un fichier de test. (question 3)"; Key = 'a request to write, create or run something'; Target = 'refuse' },
        @{ Q = 'How do I update to a new version?'; Key = 'updating'; Target = 'docs/how-to/update.md' },
        @{ Q = 'A guardian refused my commit, what do I do?'; Key = 'a guardian that refused a commit'; Target = 'docs/how-to/react-to-a-guardian-refusal.md' },
        @{ Q = 'How do I adopt an existing folder?'; Key = 'adopting'; Target = 'docs/how-to/adopt-a-project.md' }
    )
    foreach ($q in $questions) {
        $row = @($mapRows | Where-Object { ($_ -split '\|')[1].Contains($q.Key) }) | Select-Object -First 1
        Assert-True ($null -ne $row -and ($row -split '\|')[2].Contains($q.Target)) "$($q.Q) -> row '$($q.Key)' -> $($q.Target)"
    }
    $paths = @([regex]::Matches($mapBlock, '`([^`]+)`') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
    $absent = @($paths | Where-Object { -not (Test-Path (Join-Path $RepoRoot $_)) })
    Assert-True ($absent.Count -eq 0) "every path the map names exists ($($paths.Count) paths; absent: $($absent -join ', '))"

    Write-Output ""
    Write-Output "=== 1. PowerShell generator ==="
    $c1 = Join-Path $TestRoot 'ps1'
    New-MinimalClone -Root $c1
    $slug1 = New-AssistantForms -ClonePath $c1 -Name 'Testmap'
    Test-Forms -Clone $c1 -Slug $slug1 -Label 'ps1'

    Write-Output ""
    Write-Output "=== 2. Python generator (render-assistant) ==="
    $c2 = Join-Path $TestRoot 'py'
    New-MinimalClone -Root $c2
    $helper = Join-Path $RepoRoot 'tools\sb_installer_helper.py'
    $out2 = & uv run --no-project $helper render-assistant $c2 'Testmap' 2>&1
    Assert-True ($LASTEXITCODE -eq 0) "render-assistant exits 0 ($(($out2 | Select-Object -Last 1)))"
    Test-Forms -Clone $c2 -Slug 'testmap' -Label 'py'

    Write-Output ""
    Write-Output "=== 3. Witness: no docs/MAP.md, the generators refuse ==="
    $c3 = Join-Path $TestRoot 'nomap-ps1'
    New-MinimalClone -Root $c3 -WithoutMap
    $refused = $false
    try { New-AssistantForms -ClonePath $c3 -Name 'Testmap' | Out-Null } catch { $refused = $true }
    Assert-True $refused "(d) ps1 -- New-AssistantForms refuses a clone without docs/MAP.md"
    $c4 = Join-Path $TestRoot 'nomap-py'
    New-MinimalClone -Root $c4 -WithoutMap
    # Windows PowerShell 5.1 turns a native command's stderr into a terminating
    # error under 'Stop': the refusal message is expected here, so read it
    # under 'Continue'.
    $ErrorActionPreference = 'Continue'
    $out4 = & uv run --no-project $helper render-assistant $c4 'Testmap' 2>&1
    $rc4 = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    Assert-True ($rc4 -ne 0 -and "$out4" -match 'Documentation map not found') "(d) py -- render-assistant refuses a clone without docs/MAP.md (exit $rc4)"
}
catch {
    Write-Output "  FAIL - unhandled error: $($_.Exception.Message)"
    $failures.Add("unhandled error: $($_.Exception.Message)") | Out-Null
}
finally {
    if (Test-Path $TestRoot) {
        try { Remove-Item -Recurse -Force -Path $TestRoot -ErrorAction SilentlyContinue } catch { }
    }
}

Write-Output ""
if ($failures.Count -eq 0) {
    Write-Output "=== RESULT: PASS (all checks green) ==="
    exit 0
}
else {
    Write-Output "=== RESULT: FAIL ($($failures.Count) check(s) failed) ==="
    $failures | ForEach-Object { Write-Output "  - $_" }
    exit 1
}
