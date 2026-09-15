#Requires -Version 5.1
<#
.SYNOPSIS
    Web package acceptance test for the "Trois questions de test" (Mission 172).

.DESCRIPTION
    Rerun with one command, from the repository root:

        powershell -NoProfile -ExecutionPolicy Bypass -File tests\test-web-package-answers-test-questions.ps1

    The acceptance test the Mission requires: for each of the three test
    questions named in assistant/ASSISTANT.md's own corps-generateur body
    ("Trois questions de test"), a mechanical, model-free check that the
    source of the expected answer is actually present in the generated web
    package -- at minimum, the files and passages the answer cites (Mission
    172, Validations doctrine: "la source de la reponse est presente et le
    controle automatique passe", without a model call).

    This does not ask a model whether the package answers the questions; it
    greps the generated files for the exact needles the expected answers
    are built from, the same style test-assistant-tool-call-cap.ps1 already
    uses for a different fixed set of needles. ASCII-only throughout this
    file, like every other test in this suite that dot-sources
    tools/generate-assistant.ps1 (accented needles are avoided rather than
    built from character codes here, since every needle below already has
    an accent-free form in the source text).

    Question 1, "Comment j'ouvre une session ?" -- assistant/ASSISTANT.md
    says the answer cites the session-start skill and its reading list.
    Checked in the generated METHOD.md: both source paths are named, and a
    verbatim, distinctive passage from each source is present (proof the
    actual skill content made it into the package, not just its path).

    Question 2, "Qu'est-ce qu'une Mission et ou je l'ecris ?" --
    assistant/ASSISTANT.md says the answer cites the Mission template and
    the project operating model, in the project, never in the Vault.
    Checked in the generated METHOD.md: both source paths are named, the
    exact Mission path convention from the versioning rule is present
    (the concrete answer to "where"), and the operating model's own
    "Vault vs projet" heading is present (the concrete answer to "never in
    the Vault").

    Question 3, "Cree-moi un fichier de test." -- already conformant before
    this Mission (the refusal lives in assistant/ASSISTANT.md's own body,
    copied verbatim into INSTRUCTIONS.md); checked here only to prove this
    step did not regress it.

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

$TestRoot = Join-Path $env:TEMP ("sb-webpkg-answers-" + [Guid]::NewGuid().ToString('N'))
$TestClone = Join-Path $TestRoot 'clone'
New-Item -ItemType Directory -Force -Path $TestClone | Out-Null
Write-Output ""
Write-Output "TestRoot: $TestRoot"

try {
    Write-Output ""
    Write-Output "=== Web package: source of each test-question answer is present ==="

    # Minimal clone: assistant/ASSISTANT.md plus every source path named in
    # $Script:WebPackageKnowledgeFiles's own SourcePaths lists -- built from
    # that list itself, so this test never drifts out of sync with which
    # sources the generator actually reads (same pattern as
    # tests/test-web-package-readme-matches-contents.ps1).
    $sourceFiles = @('assistant\ASSISTANT.md') + @($Script:WebPackageKnowledgeFiles | ForEach-Object { $_.SourcePaths })
    foreach ($relative in $sourceFiles) {
        $src = Join-Path $RepoRoot $relative
        $dst = Join-Path $TestClone $relative
        New-Item -ItemType Directory -Force -Path (Split-Path $dst -Parent) | Out-Null
        Copy-Item -Path $src -Destination $dst -Force
    }

    $slug = New-AssistantForms -ClonePath $TestClone -Name 'Testy'
    $webDir = Join-Path $TestClone "web-package\$slug"
    $instructionsPath = Join-Path $webDir 'INSTRUCTIONS.md'
    $methodPath = Join-Path $webDir 'METHOD.md'

    Assert-True (Test-Path $instructionsPath) "INSTRUCTIONS.md is generated"
    Assert-True (Test-Path $methodPath) "METHOD.md is generated"

    $instructionsText = if (Test-Path $instructionsPath) { Get-Content -Raw -Path $instructionsPath -Encoding UTF8 } else { '' }
    $methodText = if (Test-Path $methodPath) { Get-Content -Raw -Path $methodPath -Encoding UTF8 } else { '' }

    Write-Output ""
    Write-Output "--- Question 1: 'Comment j'ouvre une session ?' ---"
    Assert-True $methodText.Contains('skills/session-start/SKILL.md') "METHOD.md names the source path skills/session-start/SKILL.md"
    Assert-True $methodText.Contains('skills/session-start/reading-list.md') "METHOD.md names the source path skills/session-start/reading-list.md"
    # Distinctive, ASCII-only, verbatim passage from skills/session-start/SKILL.md
    # itself (the instruction to open the reading list) -- proof the actual
    # skill content is in the package, not just its path.
    Assert-True $methodText.Contains('reading-list.md') "METHOD.md carries a verbatim passage naming reading-list.md (from SKILL.md's own step 2)"
    # Distinctive, ASCII-only, verbatim words from the skill's own verdict
    # step (step 4: READY / NOT-READY).
    Assert-True $methodText.Contains('NOT-READY') "METHOD.md carries a verbatim passage from SKILL.md's own verdict step ('NOT-READY')"

    Write-Output ""
    Write-Output "--- Question 2: 'Qu'est-ce qu'une Mission et ou je l'ecris ?' ---"
    Assert-True $methodText.Contains('templates/mission-template.md') "METHOD.md names the source path templates/mission-template.md"
    Assert-True $methodText.Contains('knowledge/BRIEF-2026-08-17-211522-project-operating-model-v2.md') "METHOD.md names the source path of the project operating model brief"
    Assert-True $methodText.Contains('rules/RULES-2026-08-17-211522-mission-versioning-and-generated-output.md') "METHOD.md names the source path of the Mission versioning rule"
    # The exact path convention (the concrete answer to "where do I write a
    # Mission"), verbatim from the versioning rule, section 1.
    Assert-True $methodText.Contains('<projet>/missions/MISSION-YYYY-MM-DD-HHMMSS-NNN-description.md') "METHOD.md carries the exact Mission path convention verbatim"
    # The operating model's own heading answering "in the project, never in
    # the Vault" (BRIEF-...-v2.md, section 1).
    Assert-True $methodText.Contains('Vault vs projet') "METHOD.md carries the project operating model's own 'Vault vs projet' section"

    Write-Output ""
    Write-Output "--- Question 3: 'Cree-moi un fichier de test.' (already conformant -- no regression) ---"
    # The refusal answer lives in assistant/ASSISTANT.md's own body, copied
    # verbatim into INSTRUCTIONS.md -- unaffected by this Mission's change
    # to the knowledge-file list; checked here only to prove no regression.
    Assert-True $instructionsText.Contains('lecture seule') "INSTRUCTIONS.md still carries the read-only refusal ('lecture seule')"

    Write-Output ""
    Write-Output "--- File-count ceiling still respected (Owner DECIDED: 5 files at most) ---"
    $packageFileCount = @(Get-ChildItem -Path $webDir -File).Count
    Assert-True ($packageFileCount -le 5) "web package holds at most 5 files (has $packageFileCount)"
}
catch {
    Write-Output "  FAIL - unhandled error: $($_.Exception.Message)"
    $failures.Add("unhandled error: $($_.Exception.Message)") | Out-Null
}

if (-not $KeepTemp) {
    try {
        . (Join-Path $RepoRoot 'tools\resolve-bash-exe.ps1')
        $cleanupBash = Resolve-BashExe
        & $cleanupBash -c "rm -rf -- '$($TestRoot -replace '\\','/')'"
    }
    catch { }
    Write-Output ""
    Write-Output "TestRoot removed: $TestRoot"
}
else {
    Write-Output ""
    Write-Output "TestRoot kept (-KeepTemp): $TestRoot"
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
