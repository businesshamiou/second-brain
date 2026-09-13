#Requires -Version 5.1
<#
.SYNOPSIS
    Assistant generation tests (Mission 168, ticket 06, criteria 1-2-3-4-5-6).

.DESCRIPTION
    Rerun with one command, from the repository root:

        powershell -NoProfile -ExecutionPolicy Bypass -File tests\test-assistant-generation.ps1

    Three independent checks, ASCII-only throughout this file (any accented
    test string is built from character codes at runtime, never typed
    literally -- the same reason tools/generate-assistant.ps1 itself stays
    ASCII, see that file's own header comment: an accented literal in a
    .ps1 file's own source needs a byte-order mark to parse correctly under
    Windows PowerShell 5.1, and this file carries none):

      1. Unit-level: ConvertTo-AssistantSlug (dot-sourced directly, no
         install.ps1 run needed) -- lowercase, no spaces, and accents
         stripped from a name built from character codes (not a literal
         accented byte in this file).

      2. End-to-end, silent mode (-AnswersFile, ticket 06 criterion 6): a
         fresh install under the name "Ibrahim" generates all three forms
         (.claude/agents/ibrahim.md with tools restricted to exactly Read,
         Glob, Grep; .agents/skills/ibrahim/SKILL.md; web-package/ibrahim/
         under the 8000-character / 25-file ceilings) -- none of them
         contain the literal string "Brian" anywhere, and each carries a
         fixed sentence from assistant/ASSISTANT.md verbatim (proof they
         are derived from the one source, not independently authored).

      3. End-to-end, interactive mode (-ScriptedAnswers, ticket 06
         criterion 5): a fresh install under the default name "Brian",
         then a relaunch in update mode renaming it to "Nova" -- the old
         brian-named forms are gone from their original path, recoverable
         under _trash/assistant-rename-brian-<timestamp>/ with their
         original "Brian" content intact (moved, never deleted), and the
         new nova-named forms exist and are conformant to the source.

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

function Get-FilesContaining {
    # Recursively scans every file under $Root for a literal (non-regex)
    # needle, returning the relative paths that contain it. Used both to
    # prove absence ("Brian" after generating under another name) and
    # presence (the old content surviving under _trash/).
    param([Parameter(Mandatory = $true)][string] $Root, [Parameter(Mandatory = $true)][string] $Needle)
    if (-not (Test-Path $Root)) { return @() }
    $hits = @()
    Get-ChildItem -Path $Root -Recurse -File | ForEach-Object {
        $text = Get-Content -Raw -Path $_.FullName -Encoding UTF8
        if ($text.Contains($Needle)) { $hits += $_.FullName }
    }
    return $hits
}

$installScript = Join-Path $RepoRoot 'install.ps1'
# A fixed, un-substituted, ASCII-only substring from INSIDE the source's own
# <!-- corps-generateur:debut/fin --> markers (the "Trois questions de
# test" section) -- proof a generated form is conformant to the source
# (criterion 6). Deliberately not a substring of the source's own preamble
# (outside the markers, never copied): that would defeat the very bug this
# constant is meant to catch a regression of.
$sourceSentence = 'session-start'

Write-Output ""
Write-Output "=== 1. Unit: ConvertTo-AssistantSlug ==="
. (Join-Path $RepoRoot 'tools\generate-assistant.ps1')
Assert-True ((ConvertTo-AssistantSlug -Name 'Brian') -eq 'brian') "'Brian' -> 'brian'"
Assert-True ((ConvertTo-AssistantSlug -Name 'Ibrahim') -eq 'ibrahim') "'Ibrahim' -> 'ibrahim'"
$accentedName = [string]::Concat('Am', [char]0x00E9, 'lie')  # "Amelie" with an accented e, built from a character code
Assert-True ((ConvertTo-AssistantSlug -Name $accentedName) -eq 'amelie') "accented name '$accentedName' -> 'amelie' (accents stripped)"
Assert-True ((ConvertTo-AssistantSlug -Name 'Dr. No Name!') -eq 'dr-no-name') "punctuation/spaces collapse to single hyphens"

# A name containing a literal double quote must never break the generated
# YAML frontmatter's own quoted 'description' value (code-review finding).
$quoteName = 'Robo' + [char]0x22 + 'bot' + [char]0x22  # Robo"bot" -- built from a character code, same ASCII-only rule
$quoteBody = "placeholder body`n"
$subagentWithQuote = New-ClaudeCodeSubagentContent -Name $quoteName -Slug 'robobot' -Body $quoteBody
$descriptionLine = ($subagentWithQuote -split "`n" | Where-Object { $_ -match '^description:' })
Assert-True ($descriptionLine -match '\\"bot\\"') "a name containing a literal double quote is escaped inside the frontmatter description ($descriptionLine)"
Assert-True ($subagentWithQuote -match '(?m)^tools:\s*Read,\s*Glob,\s*Grep\s*$') "frontmatter after the quoted name still parses as a normal 'tools:' line (YAML not corrupted)"

# --- 2. End-to-end, silent mode: fresh install as "Ibrahim" -----------------
$TestRoot2 = Join-Path $env:TEMP ("sb-assistant-ibrahim-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $TestRoot2 | Out-Null
Write-Output ""
Write-Output "TestRoot (scenario 2): $TestRoot2"

try {
    Write-Output ""
    Write-Output "=== 2. Fresh silent install as 'Ibrahim' -- no form keeps 'Brian' ==="
    $sampleAnswers = Get-Content -Raw -Path (Join-Path $PSScriptRoot 'fixtures\install-answers.sample.json') | ConvertFrom-Json
    $sampleAnswers.vaultName = 'Ibrahim'
    $sampleAnswers.workspacePath = Join-Path $TestRoot2 'workspace'
    $sampleAnswers.firstProject.create = $false
    $answersPath2 = Join-Path $TestRoot2 'answers.json'
    $sampleAnswers | ConvertTo-Json -Depth 10 | Set-Content -Path $answersPath2 -Encoding UTF8

    $verdict = & $installScript -Source $RepoRoot -AnswersFile $answersPath2 -TestMode -TestRoot $TestRoot2
    $exit = $LASTEXITCODE
    Write-Output "  verdict: $verdict"
    Assert-True ($exit -eq 0) "fresh silent install as 'Ibrahim' exits 0"

    $clonePath2 = Join-Path (Join-Path $TestRoot2 'workspace') 'second-brain'
    $subagentPath = Join-Path $clonePath2 '.claude\agents\ibrahim.md'
    $skillPath = Join-Path $clonePath2 '.agents\skills\ibrahim\SKILL.md'
    $webInstructionsPath = Join-Path $clonePath2 'web-package\ibrahim\INSTRUCTIONS.md'
    $webReadmePath = Join-Path $clonePath2 'web-package\ibrahim\README.md'

    Assert-True (Test-Path $subagentPath) "Claude Code subagent generated at .claude/agents/ibrahim.md"
    Assert-True (Test-Path $skillPath) "Codex skill generated at .agents/skills/ibrahim/SKILL.md (T11 official location)"
    Assert-True (Test-Path $webInstructionsPath) "web package INSTRUCTIONS.md generated"
    Assert-True (Test-Path $webReadmePath) "web package README.md generated"

    if (Test-Path $subagentPath) {
        $subagentText = Get-Content -Raw -Path $subagentPath -Encoding UTF8
        Assert-True ($subagentText -match '(?m)^tools:\s*Read,\s*Glob,\s*Grep\s*$') "subagent frontmatter restricts tools to exactly Read, Glob, Grep"
        # Checked against the 'tools:' line alone, never the whole file: the
        # body's own refusal sentence legitimately contains the English
        # word "writes" ("Never writes or runs anything", the generated
        # description) -- a whole-file substring scan for "Write" would
        # false-positive on exactly the sentence that DISCLAIMS writing.
        $toolsLine = ($subagentText -split "`n" | Where-Object { $_ -match '^tools:' })
        Assert-True (($toolsLine -join '') -notmatch 'Bash|Write|Edit') "subagent's 'tools:' line never grants Bash, Write or Edit"
        Assert-True ($subagentText.Contains('Ibrahim')) "subagent body carries the chosen name 'Ibrahim'"
        Assert-True ($subagentText.Contains($sourceSentence)) "subagent body carries the source's own fixed sentence verbatim (criterion 6: conformant to the source)"
    }
    if (Test-Path $skillPath) {
        $skillText = Get-Content -Raw -Path $skillPath -Encoding UTF8
        Assert-True ($skillText.Contains('Ibrahim')) "Codex skill body carries the chosen name 'Ibrahim'"
        Assert-True ($skillText.Contains($sourceSentence)) "Codex skill body carries the source's own fixed sentence verbatim"
    }
    if (Test-Path $webInstructionsPath) {
        $webText = Get-Content -Raw -Path $webInstructionsPath -Encoding UTF8
        Assert-True ($webText.Length -lt 8000) "web package instructions are under 8000 characters ($($webText.Length) chars)"
        Assert-True ($webText.Contains('Ibrahim')) "web package instructions carry the chosen name 'Ibrahim'"
        Assert-True ($webText.Contains($sourceSentence)) "web package instructions carry the source's own fixed sentence verbatim (criterion 6)"
    }
    $webPackageDir = Join-Path $clonePath2 'web-package\ibrahim'
    if (Test-Path $webPackageDir) {
        $fileCount = @(Get-ChildItem -Path $webPackageDir -File).Count
        Assert-True ($fileCount -le 25) "web package has at most 25 files (has $fileCount)"
    }

    # Scoped to the personalized identity files only (subagent, Codex
    # skill, INSTRUCTIONS.md) -- never the whole web-package tree (Mission
    # 171-C01 step 8): that tree now also holds knowledge files copied
    # verbatim from this repository (CONTEXT.md, the project/Second-Brain
    # boundary rule, README.md), two of which legitimately mention "Brian"
    # as Second Brain's own documented default value, exactly the way
    # assistant/ASSISTANT.md's own excluded preamble does -- see
    # generate-assistant.ps1's $Script:WebPackageKnowledgeFiles comment.
    # Scanning those copied reference documents for "Brian" would fail on
    # correct, unmodified repository content, not on a real regression.
    $brianHits = Get-FilesContaining -Root (Join-Path $clonePath2 '.claude\agents') -Needle 'Brian'
    $brianHits += Get-FilesContaining -Root (Join-Path $clonePath2 '.agents\skills') -Needle 'Brian'
    if (Test-Path $webInstructionsPath) {
        if ((Get-Content -Raw -Path $webInstructionsPath -Encoding UTF8).Contains('Brian')) {
            $brianHits += $webInstructionsPath
        }
    }
    Assert-True ($brianHits.Count -eq 0) "no personalized identity file (subagent, Codex skill, INSTRUCTIONS.md) contains 'Brian' when installed as 'Ibrahim' (criterion 6): $($brianHits -join ', ')"

    # The web package's copied knowledge files (defect 8) are present and
    # not corrupted: proof New-AssistantForms actually writes them, not
    # just INSTRUCTIONS.md and README.md as before this step.
    $knowledgeFileNames = @('GLOSSARY.md', 'PROJECT-BOUNDARY.md', 'HOW-TO.md')
    foreach ($knowledgeFileName in $knowledgeFileNames) {
        $knowledgeFilePath = Join-Path $webPackageDir $knowledgeFileName
        Assert-True (Test-Path $knowledgeFilePath) "web package knowledge file generated: $knowledgeFileName (defect 8)"
    }
}
catch {
    Write-Output "  FAIL - unhandled error (scenario 2): $($_.Exception.Message)"
    $failures.Add("unhandled error (scenario 2): $($_.Exception.Message)") | Out-Null
}

# --- 3. End-to-end, interactive mode: fresh install as "Brian", then rename to "Nova" ---
$TestRoot3 = Join-Path $env:TEMP ("sb-assistant-rename-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $TestRoot3 | Out-Null
Write-Output ""
Write-Output "TestRoot (scenario 3): $TestRoot3"

try {
    Write-Output ""
    Write-Output "=== 3a. Fresh interactive install, default name 'Brian' ==="
    # Order: language, assistant name (blank -> default 'Brian'), workspace
    # (blank -> default), firstName, activity, aiToolsRaw (blank),
    # whatMatters, firstProject confirm (n). The eighth question
    # (skillCollectionsRaw) is retired (Mission 171-C01 step 4): skill
    # deployment is unconditional now, nothing about it is asked.
    $run1Answers = @('EN', '', '', 'Ana', 'Building a personal AI system', '', 'Simplicity', 'n')
    $run1Output = & $installScript -Source $RepoRoot -TestMode -TestRoot $TestRoot3 -ScriptedAnswers $run1Answers 6>&1 | Out-String
    $run1Exit = $LASTEXITCODE
    Assert-True ($run1Exit -eq 0) "fresh interactive install (default name) exits 0"

    $clonePath3 = Join-Path (Join-Path $TestRoot3 'workspace') 'second-brain'
    $brianSubagentPath = Join-Path $clonePath3 '.claude\agents\brian.md'
    Assert-True (Test-Path $brianSubagentPath) "'brian' subagent generated on the fresh install"

    Write-Output ""
    Write-Output "=== 3b. Update-mode relaunch, renamed to 'Nova' ==="
    # Order after 'y' (something changed): language (blank -> keep EN),
    # assistant name ('Nova' -- the rename), firstName (must be non-blank,
    # Required), activity (blank -> keep), aiToolsRaw (blank -> keep),
    # whatMatters (blank -> keep), firstProject confirm (n). The eighth
    # question is retired (Mission 171-C01 step 4).
    $run2Answers = @('y', '', 'Nova', 'Ana', '', '', '', 'n')
    $run2Output = & $installScript -Source $RepoRoot -TestMode -TestRoot $TestRoot3 -ScriptedAnswers $run2Answers 6>&1 | Out-String
    $run2Exit = $LASTEXITCODE
    Write-Output $run2Output
    Assert-True ($run2Exit -eq 0) "update-mode rename to 'Nova' exits 0"

    $novaSubagentPath = Join-Path $clonePath3 '.claude\agents\nova.md'
    $novaSkillPath = Join-Path $clonePath3 '.agents\skills\nova\SKILL.md'
    $novaWebDir = Join-Path $clonePath3 'web-package\nova'
    Assert-True (Test-Path $novaSubagentPath) "'nova' subagent exists after the rename"
    Assert-True (Test-Path $novaSkillPath) "'nova' Codex skill exists after the rename"
    Assert-True (Test-Path $novaWebDir) "'nova' web package exists after the rename"
    if (Test-Path $novaSubagentPath) {
        $novaText = Get-Content -Raw -Path $novaSubagentPath -Encoding UTF8
        Assert-True ($novaText.Contains('Nova')) "'nova' subagent body carries the new name"
        Assert-True ($novaText.Contains($sourceSentence)) "'nova' subagent body still conformant to the source"
    }

    Assert-True (-not (Test-Path $brianSubagentPath)) "old 'brian' subagent no longer at its original path (moved, not left behind)"
    $oldSkillDir = Join-Path $clonePath3 '.agents\skills\brian'
    $oldWebDir = Join-Path $clonePath3 'web-package\brian'
    Assert-True (-not (Test-Path $oldSkillDir)) "old 'brian' Codex skill folder no longer at its original path"
    Assert-True (-not (Test-Path $oldWebDir)) "old 'brian' web package folder no longer at its original path"

    $trashRoot = Join-Path $clonePath3 '_trash'
    $renameTrashDirs = @()
    if (Test-Path $trashRoot) {
        $renameTrashDirs = @(Get-ChildItem -Path $trashRoot -Directory | Where-Object { $_.Name -like 'assistant-rename-brian-*' })
    }
    Assert-True ($renameTrashDirs.Count -eq 1) "exactly one _trash/assistant-rename-brian-<timestamp>/ directory exists (found $($renameTrashDirs.Count))"
    if ($renameTrashDirs.Count -ge 1) {
        $trashedSubagent = Join-Path $renameTrashDirs[0].FullName '.claude\agents\brian.md'
        $trashedSkill = Join-Path $renameTrashDirs[0].FullName '.agents\skills\brian\SKILL.md'
        $trashedWebDir = Join-Path $renameTrashDirs[0].FullName 'web-package\brian'
        Assert-True (Test-Path $trashedSubagent) "old 'brian' subagent recovered under _trash/ (moved, never deleted -- Decision 110852)"
        Assert-True (Test-Path $trashedSkill) "old 'brian' Codex skill recovered under _trash/"
        Assert-True (Test-Path $trashedWebDir) "old 'brian' web package recovered under _trash/"
        if (Test-Path $trashedSubagent) {
            $trashedText = Get-Content -Raw -Path $trashedSubagent -Encoding UTF8
            Assert-True ($trashedText.Contains('Brian')) "the recovered _trash/ copy still names 'Brian' (untouched content, just relocated)"
        }
    }
}
catch {
    Write-Output "  FAIL - unhandled error (scenario 3): $($_.Exception.Message)"
    $failures.Add("unhandled error (scenario 3): $($_.Exception.Message)") | Out-Null
}

if (-not $KeepTemp) {
    try {
        . (Join-Path $RepoRoot 'tools\resolve-bash-exe.ps1')
        $cleanupBash = Resolve-BashExe
        & $cleanupBash -c "rm -rf -- '$($TestRoot2 -replace '\\','/')' '$($TestRoot3 -replace '\\','/')'"
    }
    catch { }
    Write-Output ""
    Write-Output "TestRoots removed: $TestRoot2, $TestRoot3"
}
else {
    Write-Output ""
    Write-Output "TestRoots kept (-KeepTemp): $TestRoot2, $TestRoot3"
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
