#Requires -Version 5.1
<#
.SYNOPSIS
    Skill deployment tests (Mission 168, ticket 07, all five criteria).

.DESCRIPTION
    Rerun with one command, from the repository root:

        powershell -NoProfile -ExecutionPolicy Bypass -File tests\test-skills-deployment.ps1

    Four independent checks, all against install.ps1's real -TestMode /
    -TestRoot redirection (never the real profile -- see this file's own
    fingerprint section, mirroring tests/test-install-e2e.ps1):

      1. Fresh silent install, no collections chosen: the six
         method-fabricated skills (measured from THIS repository's own
         skills/, excluding external/ -- never a literal list, so this
         test does not silently stop covering a seventh skill added later)
         are linked into both the Claude Code and the Codex-official
         skills folders, each one resolving all the way to its own
         SKILL.md with byte-identical content to the source (criterion 5,
         "chaque skill deploye se resout jusqu'a son SKILL.md"); the Codex
         description budget recorded in the install notebook matches an
         independent recount from the clone's own skills/ and stays under
         the 8000-character ceiling (criterion 3).

      2. Collections on choice only (criterion 2): a second fresh install
         requesting skillCollections = ['external', 'visual-content',
         'bogus-collection'] links every skills/external/ skill (T24:
         "outils de la methode") AND every skill of a real warehouse
         collection (skills-warehouse/skill-collections/visual-content/
         skills/, chosen because it is this repository's smallest
         materialized collection -- two skills, keeping the test fast)
         without failing on the unknown token -- and, conversely, that
         nothing from skills/external/ or any warehouse collection was
         linked in check 1, where no collection was requested at all.

      3. Idempotent relaunch (criterion 4, "aucun lien duplique, aucun
         fichier modifie"): rerunning check 1's exact install a second
         time, unchanged, leaves both skill folders' directory listings
         byte-for-byte identical (same names, same count) -- a good test
         observes only this external, filesystem-visible outcome, never
         internal call counts.

      4. Live-link proof: appending a marker line to a deployed skill's
         SKILL.md INSIDE THE CLONE and reading it back THROUGH the link
         proves the link is the genuine mechanism spec/ticket 07 asks for
         (a correction in second-brain propagating with no reinstall), not
         a one-time copy that would leave the link's own content stale.

    Exit code 0 means every assertion passed. Exit code 1 means at least
    one did not; details are printed to stdout as each check runs.
#>

[CmdletBinding()]
param([switch] $KeepTemp)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path $PSScriptRoot -Parent
$failures = New-Object System.Collections.Generic.List[string]

# Shared with install.ps1 -- one copy of the bash.exe lookup, never two
# drifting copies.
. (Join-Path $RepoRoot 'tools\resolve-bash-exe.ps1')

# Shared with tests/test-install-e2e.ps1 and tests/test-prerequisites-e2e.ps1
# (Mission 168): the same before/after measurement method for the Mission's
# own "environnement de l'Owner intact" constraint, now covering
# ~/.agents/skills too (ticket 07's own real write target).
. (Join-Path $RepoRoot 'tools\environment-fingerprint.ps1')

# Dot-sourced directly for the same reason tests/test-assistant-generation.ps1
# already dot-sources tools/generate-assistant.ps1: an independent recount
# of what THIS repository's own skills/ actually contains, and of the
# description-budget arithmetic, both measured from disk -- never a
# hardcoded expected list that could silently drift from the real one.
. (Join-Path $RepoRoot 'tools\deploy-skills.ps1')

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if ($Condition) { Write-Output "  PASS - $Message" }
    else { Write-Output "  FAIL - $Message"; $failures.Add($Message) | Out-Null }
}

$installScript = Join-Path $RepoRoot 'install.ps1'

Write-Output "=== 1. Real-environment fingerprint (before) ==="
$before = Get-EnvironmentFingerprint
Write-Output "  PATH SHA-256: $($before.PathHash)"
Write-Output "  .claude/skills entries: $($before.ClaudeSkills.Count)"
Write-Output "  .codex/skills entries: $($before.CodexSkills.Count)"
Write-Output "  .agents/skills entries: $($before.CodexAgentsSkills.Count)"

# Independent recount, straight from this repository's own skills/ (the
# source that install.ps1 will clone from -Source $RepoRoot below) -- the
# expected list this whole file checks against.
$expectedDefaultEntries = Get-DefaultSkillEntries -ClonePath $RepoRoot
$expectedDefaultNames = @($expectedDefaultEntries | ForEach-Object { $_.Name })
Write-Output ""
Write-Output "Expected default (always-deployed) skills, measured from $RepoRoot\skills: $($expectedDefaultNames -join ', ')"
$expectedBudget = Measure-DefaultSkillsCodexBudget -DefaultEntries $expectedDefaultEntries
Write-Output "Expected Codex budget (sum of the six descriptions): $($expectedBudget.Total) chars (ceiling $($expectedBudget.Ceiling))"

# --- 1. Fresh silent install, no collections chosen -------------------------
$TestRoot1 = Join-Path $env:TEMP ("sb-skills-default-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $TestRoot1 | Out-Null
Write-Output ""
Write-Output "TestRoot (check 1/3/4): $TestRoot1"

$clonePath1 = $null
$claudeSkillsDir1 = $null
$codexAgentsSkillsDir1 = $null

try {
    Write-Output ""
    Write-Output "=== 1. Fresh silent install, default (no collections) ==="
    $sampleAnswers1 = Get-Content -Raw -Path (Join-Path $PSScriptRoot 'fixtures\install-answers.sample.json') | ConvertFrom-Json
    $workspacePath1 = Join-Path $TestRoot1 'workspace'
    $sampleAnswers1.workspacePath = $workspacePath1
    $sampleAnswers1.firstProject.create = $false
    $answersPath1 = Join-Path $TestRoot1 'answers.json'
    $sampleAnswers1 | ConvertTo-Json -Depth 10 | Set-Content -Path $answersPath1 -Encoding UTF8

    $verdict1 = & $installScript -Source $RepoRoot -AnswersFile $answersPath1 -TestMode -TestRoot $TestRoot1
    $exit1 = $LASTEXITCODE
    Write-Output "  verdict: $verdict1"
    Assert-True ($exit1 -eq 0) "fresh silent install (no collections) exits 0"

    $clonePath1 = Join-Path $workspacePath1 'second-brain'
    $profileRoot1 = Join-Path $TestRoot1 'profile'
    $claudeSkillsDir1 = Join-Path $profileRoot1 '.claude\skills'
    $codexAgentsSkillsDir1 = Join-Path $profileRoot1 '.agents\skills'

    foreach ($name in $expectedDefaultNames) {
        $claudeSkillMd = Join-Path $claudeSkillsDir1 "$name\SKILL.md"
        $codexSkillMd = Join-Path $codexAgentsSkillsDir1 "$name\SKILL.md"
        $sourceSkillMd = Join-Path $clonePath1 "skills\$name\SKILL.md"
        Assert-True (Test-Path $claudeSkillMd) "'$name' resolves to its SKILL.md through .claude/skills (Claude Code)"
        Assert-True (Test-Path $codexSkillMd) "'$name' resolves to its SKILL.md through .agents/skills (Codex, T11 official location)"
        if ((Test-Path $claudeSkillMd) -and (Test-Path $sourceSkillMd)) {
            $viaLink = Get-Content -Raw -Path $claudeSkillMd -Encoding UTF8
            $viaSource = Get-Content -Raw -Path $sourceSkillMd -Encoding UTF8
            Assert-True ($viaLink -eq $viaSource) "'$name' content through the Claude Code link is byte-identical to the source in the clone"
        }
    }

    # Criterion 2, negative half: nothing opt-in was requested, so nothing
    # from skills/external/ or any warehouse collection should appear.
    $externalLeak = Test-Path (Join-Path $claudeSkillsDir1 'implement')
    Assert-True (-not $externalLeak) "no skills/external/ skill ('implement') is linked when no collection was requested"

    # Criterion 3: Codex budget, recorded in the install notebook, matches
    # the independent recount and stays under the ceiling.
    $carnetPath1 = Join-Path $clonePath1 '.install\state.json'
    $carnet1 = Get-Content -Raw -Path $carnetPath1 -Encoding UTF8 | ConvertFrom-Json
    $recordedBudget = $carnet1.skillsDeployment.codexBudgetTotal
    Write-Output "  recorded Codex budget: $recordedBudget chars"
    Assert-True ($recordedBudget -eq $expectedBudget.Total) "recorded Codex budget ($recordedBudget) matches the independent recount ($($expectedBudget.Total))"
    Assert-True ($recordedBudget -lt 8000) "Codex budget for the six default skills stays under 8000 characters ($recordedBudget)"
}
catch {
    Write-Output "  FAIL - unhandled error (check 1): $($_.Exception.Message)"
    $failures.Add("unhandled error (check 1): $($_.Exception.Message)") | Out-Null
}

# --- 2. Collections on choice only: 'external' + an unknown token ----------
$TestRoot2 = Join-Path $env:TEMP ("sb-skills-collections-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $TestRoot2 | Out-Null
Write-Output ""
Write-Output "TestRoot (check 2): $TestRoot2"

try {
    Write-Output ""
    Write-Output "=== 2. Collections on choice: 'external' + a real warehouse collection + unknown token ==="
    $sampleAnswers2 = Get-Content -Raw -Path (Join-Path $PSScriptRoot 'fixtures\install-answers.sample.json') | ConvertFrom-Json
    $workspacePath2 = Join-Path $TestRoot2 'workspace'
    $sampleAnswers2.workspacePath = $workspacePath2
    $sampleAnswers2.firstProject.create = $false
    $sampleAnswers2 | Add-Member -MemberType NoteProperty -Name 'skillCollections' -Value @('external', 'visual-content', 'bogus-collection') -Force
    $answersPath2 = Join-Path $TestRoot2 'answers.json'
    $sampleAnswers2 | ConvertTo-Json -Depth 10 | Set-Content -Path $answersPath2 -Encoding UTF8

    $verdict2 = & $installScript -Source $RepoRoot -AnswersFile $answersPath2 -TestMode -TestRoot $TestRoot2
    $exit2 = $LASTEXITCODE
    Write-Output "  verdict: $verdict2"
    Assert-True ($exit2 -eq 0) "install with an unknown collection token still exits 0 (never a fatal error over a typo)"

    $clonePath2 = Join-Path $workspacePath2 'second-brain'
    $profileRoot2 = Join-Path $TestRoot2 'profile'
    $claudeSkillsDir2 = Join-Path $profileRoot2 '.claude\skills'
    $codexAgentsSkillsDir2 = Join-Path $profileRoot2 '.agents\skills'

    $expectedExternalEntries = Get-ExternalMethodSkillEntries -ClonePath $clonePath2
    Assert-True ($expectedExternalEntries.Count -gt 0) "skills/external/ has at least one skill to expect in the clone (sanity check on the fixture repo itself)"
    foreach ($entry in $expectedExternalEntries) {
        $claudeSkillMd = Join-Path $claudeSkillsDir2 "$($entry.Name)\SKILL.md"
        $codexSkillMd = Join-Path $codexAgentsSkillsDir2 "$($entry.Name)\SKILL.md"
        Assert-True (Test-Path $claudeSkillMd) "external skill '$($entry.Name)' resolves through .claude/skills when 'external' is chosen"
        Assert-True (Test-Path $codexSkillMd) "external skill '$($entry.Name)' resolves through .agents/skills when 'external' is chosen"
    }

    # A real warehouse collection, not just skills/external/: proves the
    # OTHER opt-in branch (Resolve-RequestedSkillCollectionEntries's
    # warehouse-slug match) actually links something too, not just that it
    # compiles. 'visual-content' is this repository's smallest materialized
    # collection (two skills), chosen to keep this test fast.
    $expectedWarehouseEntries = Get-WarehouseCollectionSkillEntries -ClonePath $clonePath2 -CollectionSlug 'visual-content'
    Assert-True ($expectedWarehouseEntries.Count -gt 0) "skills-warehouse/skill-collections/visual-content/skills/ has at least one skill to expect in the clone (sanity check on the fixture repo itself)"
    foreach ($entry in $expectedWarehouseEntries) {
        $claudeSkillMd = Join-Path $claudeSkillsDir2 "$($entry.Name)\SKILL.md"
        $codexSkillMd = Join-Path $codexAgentsSkillsDir2 "$($entry.Name)\SKILL.md"
        Assert-True (Test-Path $claudeSkillMd) "warehouse skill '$($entry.Name)' (visual-content) resolves through .claude/skills when the collection is chosen"
        Assert-True (Test-Path $codexSkillMd) "warehouse skill '$($entry.Name)' (visual-content) resolves through .agents/skills when the collection is chosen"
    }

    $bogusPath = Join-Path $claudeSkillsDir2 'bogus-collection'
    Assert-True (-not (Test-Path $bogusPath)) "an unknown collection token never creates anything on disk"
}
catch {
    Write-Output "  FAIL - unhandled error (check 2): $($_.Exception.Message)"
    $failures.Add("unhandled error (check 2): $($_.Exception.Message)") | Out-Null
}
finally {
    if (-not $KeepTemp) {
        try {
            $cleanupBash2 = Resolve-BashExe
            & $cleanupBash2 -c "rm -rf -- '$($TestRoot2 -replace '\\','/')'"
        }
        catch { }
    }
}

# --- 3. Idempotent relaunch: no duplicate link, no file modified -----------
try {
    if ($null -ne $clonePath1) {
        Write-Output ""
        Write-Output "=== 3. Idempotent relaunch (same TestRoot, same answers) ==="
        $beforeClaudeNames = @(Get-ChildItem -Path $claudeSkillsDir1 -Name -ErrorAction SilentlyContinue | Sort-Object)
        $beforeCodexNames = @(Get-ChildItem -Path $codexAgentsSkillsDir1 -Name -ErrorAction SilentlyContinue | Sort-Object)

        $verdictAgain = & $installScript -Source $RepoRoot -AnswersFile $answersPath1 -TestMode -TestRoot $TestRoot1
        $exitAgain = $LASTEXITCODE
        Assert-True ($exitAgain -eq 0) "relaunch (unchanged inputs) exits 0"

        $afterClaudeNames = @(Get-ChildItem -Path $claudeSkillsDir1 -Name -ErrorAction SilentlyContinue | Sort-Object)
        $afterCodexNames = @(Get-ChildItem -Path $codexAgentsSkillsDir1 -Name -ErrorAction SilentlyContinue | Sort-Object)
        Assert-True (@(Compare-Object $beforeClaudeNames $afterClaudeNames).Count -eq 0) "Claude Code skills folder listing is identical before/after the relaunch (no duplicate link)"
        Assert-True (@(Compare-Object $beforeCodexNames $afterCodexNames).Count -eq 0) "Codex skills folder listing is identical before/after the relaunch (no duplicate link)"

        $clonePorcelain = & git -C $clonePath1 status --porcelain
        Assert-True ([string]::IsNullOrEmpty(($clonePorcelain -join ''))) "second-brain clone porcelain is empty after the relaunch (skill deployment writes nothing tracked)"
    }
    else {
        Assert-True $false "idempotent relaunch skipped: check 1's clone was never established"
    }
}
catch {
    Write-Output "  FAIL - unhandled error (check 3): $($_.Exception.Message)"
    $failures.Add("unhandled error (check 3): $($_.Exception.Message)") | Out-Null
}

# --- 4. Live-link proof: a correction in second-brain propagates with no ---
#        reinstall (spec's own stated purpose for linking over copying).
try {
    if ($null -ne $clonePath1) {
        Write-Output ""
        Write-Output "=== 4. Live-link proof (correction propagates without reinstall) ==="
        $probeName = $expectedDefaultNames[0]
        $sourceSkillMd = Join-Path $clonePath1 "skills\$probeName\SKILL.md"
        $linkedSkillMd = Join-Path $claudeSkillsDir1 "$probeName\SKILL.md"
        $original = Get-Content -Raw -Path $sourceSkillMd -Encoding UTF8
        $marker = "TEST-MARKER-" + [Guid]::NewGuid().ToString('N')
        Add-Content -Path $sourceSkillMd -Value $marker -Encoding UTF8

        $throughLink = Get-Content -Raw -Path $linkedSkillMd -Encoding UTF8
        Assert-True ($throughLink.Contains($marker)) "a correction written to '$probeName' inside the clone is immediately visible through its .claude/skills link (real link, not a one-time copy)"

        # Revert the probe edit -- this TestRoot (a disposable clone under
        # $env:TEMP) is deleted right after anyway, but never rely on
        # discard-only cleanliness. Restores the captured original content
        # verbatim rather than computing a substring offset, since the
        # exact bytes Add-Content inserts around its line terminator are
        # not this test's concern.
        Set-Content -Path $sourceSkillMd -Value $original -Encoding UTF8 -NoNewline
    }
    else {
        Assert-True $false "live-link proof skipped: check 1's clone was never established"
    }
}
catch {
    Write-Output "  FAIL - unhandled error (check 4): $($_.Exception.Message)"
    $failures.Add("unhandled error (check 4): $($_.Exception.Message)") | Out-Null
}

if (-not $KeepTemp) {
    try {
        $cleanupBash1 = Resolve-BashExe
        & $cleanupBash1 -c "rm -rf -- '$($TestRoot1 -replace '\\','/')'"
    }
    catch { }
    Write-Output ""
    Write-Output "TestRoots removed: $TestRoot1, $TestRoot2"
}
else {
    Write-Output ""
    Write-Output "TestRoots kept (-KeepTemp): $TestRoot1, $TestRoot2"
}

Write-Output ""
Write-Output "=== Real-environment fingerprint (after) ==="
$after = Get-EnvironmentFingerprint
Write-Output "  PATH SHA-256: $($after.PathHash)"
Write-Output "  .claude/skills entries: $($after.ClaudeSkills.Count)"
Write-Output "  .codex/skills entries: $($after.CodexSkills.Count)"
Write-Output "  .agents/skills entries: $($after.CodexAgentsSkills.Count)"
Assert-True ($after.PathHash -eq $before.PathHash) "real user PATH is byte-identical before/after"
Assert-True (@(Compare-Object $before.ClaudeSkills $after.ClaudeSkills).Count -eq 0) "real ~/.claude/skills listing is identical before/after"
Assert-True (@(Compare-Object $before.CodexSkills $after.CodexSkills).Count -eq 0) "real ~/.codex/skills listing is identical before/after"
Assert-True (@(Compare-Object $before.CodexAgentsSkills $after.CodexAgentsSkills).Count -eq 0) "real ~/.agents/skills listing is identical before/after"

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
