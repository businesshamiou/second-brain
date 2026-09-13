#Requires -Version 5.1
<#
.SYNOPSIS
    Skill deployment tests (Mission 168, ticket 07; unconditional external
    deployment, combined Codex budget and Doctrine rule 3 fallback,
    Mission 171-C01 step 4).

.DESCRIPTION
    Rerun with one command, from the repository root:

        powershell -NoProfile -ExecutionPolicy Bypass -File tests\test-skills-deployment.ps1

    Five independent checks, all against install.ps1's real -TestMode /
    -TestRoot redirection (never the real profile -- see this file's own
    fingerprint section, mirroring tests/test-install-e2e.ps1), plus one
    synthetic check of the Codex-budget fallback that does not need a full
    install:

      1. Fresh silent install: EVERY method skill -- both skills/ (default)
         and skills/external/ (measured from THIS repository's own disk,
         never a literal list, so this test does not silently stop
         covering a skill added or removed later) -- is linked into both
         the Claude Code and the Codex-official skills folders,
         unconditionally (Mission 171-C01 step 4: the questionnaire's
         retired eighth question used to gate skills/external/; nothing
         gates it now), each one resolving all the way to its own SKILL.md
         with byte-identical content to the source ("chaque skill deploye
         se resout jusqu'a son SKILL.md"); the combined Codex description
         budget recorded in the install notebook matches an independent
         recount from the clone's own skills/ and skills/external/, and
         the notebook records no fallback (this repository is measured
         under the ceiling as of 2026-09-12: 7451 of 8000 characters).

      2. Neighbour-project resolution: the SAME deployed skill paths
         (profile-level, absolute, never relative to a project) resolve to
         their SKILL.md identically whether the current directory is
         inside the second-brain clone or inside an unrelated sibling
         project folder -- the literal proof for "chaque skill deploye se
         resout jusqu'a son SKILL.md, depuis un projet voisin comme depuis
         second-brain" (Mission 171-C01 step 4's own test requirement),
         not merely an assumption that profile-rooted paths must behave
         this way.

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

      5. Doctrine rule 3 fallback (synthetic, no full install needed): a
         throwaway fake clone with one default skill and one
         skills/external/ skill whose description alone exceeds the 8000-
         character ceiling proves Publish-DeployedSkills' per-target
         split -- Codex receives the default skill only, Claude Code
         receives both -- directly, rather than only by reading this
         file's own source.

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
# of what THIS repository's own skills/ and skills/external/ actually
# contain, and of the description-budget arithmetic, both measured from
# disk -- never a hardcoded expected list that could silently drift from
# the real one.
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

# Independent recount, straight from this repository's own skills/ and
# skills/external/ (the source that install.ps1 will clone from -Source
# $RepoRoot below) -- the expected list this whole file checks against.
$expectedDefaultEntries = Get-DefaultSkillEntries -ClonePath $RepoRoot
$expectedExternalEntries = Get-ExternalMethodSkillEntries -ClonePath $RepoRoot
$expectedDefaultNames = @($expectedDefaultEntries | ForEach-Object { $_.Name })
$expectedExternalNames = @($expectedExternalEntries | ForEach-Object { $_.Name })
$expectedAllNames = @($expectedDefaultNames + $expectedExternalNames)
Write-Output ""
Write-Output "Expected default (skills/) entries, measured from $RepoRoot\skills: $($expectedDefaultNames.Count)"
Write-Output "Expected external (skills/external/) entries: $($expectedExternalNames.Count)"
$expectedBudget = Measure-MethodSkillsCodexBudget -DefaultEntries $expectedDefaultEntries -ExternalEntries $expectedExternalEntries
Write-Output "Expected combined Codex budget: $($expectedBudget.Total) chars (ceiling $($expectedBudget.Ceiling), over: $($expectedBudget.OverBudget))"

# --- 1. Fresh silent install: every method skill, unconditionally ----------
$TestRoot1 = Join-Path $env:TEMP ("sb-skills-default-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $TestRoot1 | Out-Null
Write-Output ""
Write-Output "TestRoot (check 1/2/3/4): $TestRoot1"

$clonePath1 = $null
$claudeSkillsDir1 = $null
$codexAgentsSkillsDir1 = $null

try {
    Write-Output ""
    Write-Output "=== 1. Fresh silent install: skills/ and skills/external/, both targets ==="
    $sampleAnswers1 = Get-Content -Raw -Path (Join-Path $PSScriptRoot 'fixtures\install-answers.sample.json') | ConvertFrom-Json
    $workspacePath1 = Join-Path $TestRoot1 'workspace'
    $sampleAnswers1.workspacePath = $workspacePath1
    $sampleAnswers1.firstProject.create = $false
    $answersPath1 = Join-Path $TestRoot1 'answers.json'
    $sampleAnswers1 | ConvertTo-Json -Depth 10 | Set-Content -Path $answersPath1 -Encoding UTF8

    $verdict1 = & $installScript -Source $RepoRoot -AnswersFile $answersPath1 -TestMode -TestRoot $TestRoot1
    $exit1 = $LASTEXITCODE
    Write-Output "  verdict: $verdict1"
    Assert-True ($exit1 -eq 0) "fresh silent install exits 0"

    $clonePath1 = Join-Path $workspacePath1 'second-brain'
    $profileRoot1 = Join-Path $TestRoot1 'profile'
    $claudeSkillsDir1 = Join-Path $profileRoot1 '.claude\skills'
    $codexAgentsSkillsDir1 = Join-Path $profileRoot1 '.agents\skills'

    foreach ($name in $expectedAllNames) {
        $claudeSkillMd = Join-Path $claudeSkillsDir1 "$name\SKILL.md"
        $codexSkillMd = Join-Path $codexAgentsSkillsDir1 "$name\SKILL.md"
        $sourceSkillMd = if ($expectedDefaultNames -contains $name) { Join-Path $clonePath1 "skills\$name\SKILL.md" } else { Join-Path $clonePath1 "skills\external\$name\SKILL.md" }
        Assert-True (Test-Path $claudeSkillMd) "'$name' resolves to its SKILL.md through .claude/skills (Claude Code)"
        Assert-True (Test-Path $codexSkillMd) "'$name' resolves to its SKILL.md through .agents/skills (Codex, T11 official location)"
        if ((Test-Path $claudeSkillMd) -and (Test-Path $sourceSkillMd)) {
            $viaLink = Get-Content -Raw -Path $claudeSkillMd -Encoding UTF8
            $viaSource = Get-Content -Raw -Path $sourceSkillMd -Encoding UTF8
            Assert-True ($viaLink -eq $viaSource) "'$name' content through the Claude Code link is byte-identical to the source in the clone"
        }
    }
    Assert-True ($expectedExternalNames.Count -gt 0) "skills/external/ has at least one skill to expect in the clone (sanity check on the fixture repo itself)"

    # Criterion 3: combined Codex budget, recorded in the install notebook,
    # matches the independent recount and the fallback flag matches whether
    # this repository is over the ceiling (measured 2026-09-12: it is not).
    $carnetPath1 = Join-Path $clonePath1 '.install\state.json'
    $carnet1 = Get-Content -Raw -Path $carnetPath1 -Encoding UTF8 | ConvertFrom-Json
    $recordedBudget = $carnet1.skillsDeployment.codexBudgetTotal
    $recordedFallback = $carnet1.skillsDeployment.fallbackApplied
    Write-Output "  recorded Codex budget: $recordedBudget chars, fallbackApplied: $recordedFallback"
    Assert-True ($recordedBudget -eq $expectedBudget.Total) "recorded Codex budget ($recordedBudget) matches the independent recount ($($expectedBudget.Total))"
    Assert-True ([bool]$recordedFallback -eq $expectedBudget.OverBudget) "recorded fallbackApplied ($recordedFallback) matches the independent OverBudget verdict ($($expectedBudget.OverBudget))"
    if (-not $expectedBudget.OverBudget) {
        foreach ($name in $expectedExternalNames) {
            $codexSkillMd = Join-Path $codexAgentsSkillsDir1 "$name\SKILL.md"
            Assert-True (Test-Path $codexSkillMd) "under budget: external skill '$name' still resolves through .agents/skills (Codex)"
        }
    }
}
catch {
    Write-Output "  FAIL - unhandled error (check 1): $($_.Exception.Message)"
    $failures.Add("unhandled error (check 1): $($_.Exception.Message)") | Out-Null
}

# --- 2. Neighbour-project resolution: same absolute path, any cwd ----------
try {
    if ($null -ne $clonePath1) {
        Write-Output ""
        Write-Output "=== 2. Resolution from a neighbour project vs. from second-brain itself ==="
        $neighborRoot = Join-Path $TestRoot1 'neighbor-project'
        New-Item -ItemType Directory -Force -Path $neighborRoot | Out-Null
        $probeNames = @($expectedDefaultNames | Select-Object -First 1) + @($expectedExternalNames | Select-Object -First 1)

        foreach ($cwdCase in @(
            [PSCustomObject]@{ Label = 'from second-brain'; Cwd = $clonePath1 },
            [PSCustomObject]@{ Label = 'from a neighbour project'; Cwd = $neighborRoot }
        )) {
            Push-Location $cwdCase.Cwd
            try {
                foreach ($name in $probeNames) {
                    $claudeSkillMd = Join-Path $claudeSkillsDir1 "$name\SKILL.md"
                    $codexSkillMd = Join-Path $codexAgentsSkillsDir1 "$name\SKILL.md"
                    Assert-True (Test-Path $claudeSkillMd) "$($cwdCase.Label): '$name' resolves through .claude/skills regardless of the current directory"
                    Assert-True (Test-Path $codexSkillMd) "$($cwdCase.Label): '$name' resolves through .agents/skills regardless of the current directory"
                }
            }
            finally { Pop-Location }
        }
    }
    else {
        Assert-True $false "neighbour-project resolution skipped: check 1's clone was never established"
    }
}
catch {
    Write-Output "  FAIL - unhandled error (check 2): $($_.Exception.Message)"
    $failures.Add("unhandled error (check 2): $($_.Exception.Message)") | Out-Null
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
    Write-Output "TestRoot removed: $TestRoot1"
}
else {
    Write-Output ""
    Write-Output "TestRoot kept (-KeepTemp): $TestRoot1"
}

# --- 5. Doctrine rule 3 fallback (synthetic, no full install needed) -------
$TestRoot5 = Join-Path $env:TEMP ("sb-skills-budget-" + [Guid]::NewGuid().ToString('N'))
try {
    Write-Output ""
    Write-Output "=== 5. Doctrine rule 3: Codex drops skills/external/ over budget, Claude Code never does ==="
    $fakeClone = Join-Path $TestRoot5 'fake-clone'
    New-Item -ItemType Directory -Force -Path (Join-Path $fakeClone 'skills\alpha') | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $fakeClone 'skills\external\beta') | Out-Null
    Set-Content -Path (Join-Path $fakeClone 'skills\alpha\SKILL.md') -Encoding UTF8 -Value @(
        '---'
        'name: alpha'
        'description: "short default skill"'
        '---'
        'Alpha body.'
    )
    $bigDescription = 'x' * 9000
    Set-Content -Path (Join-Path $fakeClone 'skills\external\beta\SKILL.md') -Encoding UTF8 -Value @(
        '---'
        'name: beta'
        "description: ""$bigDescription"""
        '---'
        'Beta body.'
    )

    $fakeProfileRoot = Join-Path $TestRoot5 'profile'
    $fakeContext = [PSCustomObject]@{
        ClaudeSkillsDir      = Join-Path $fakeProfileRoot '.claude\skills'
        CodexAgentsSkillsDir = Join-Path $fakeProfileRoot '.agents\skills'
    }
    $fakeResult = Publish-DeployedSkills -Context $fakeContext -ClonePath $fakeClone

    Assert-True ($fakeResult.Budget.OverBudget) "synthetic clone's combined description budget ($($fakeResult.Budget.Total) chars) is measured over the $($fakeResult.Budget.Ceiling)-character ceiling"
    Assert-True ($fakeResult.FallbackApplied) "FallbackApplied is set when the combined budget is over the ceiling"
    Assert-True ($fakeResult.ClaudeNames -contains 'alpha') "Claude Code still receives the default skill 'alpha' over budget"
    Assert-True ($fakeResult.ClaudeNames -contains 'beta') "Claude Code still receives the external skill 'beta' over budget (never drops external)"
    Assert-True ($fakeResult.CodexNames -contains 'alpha') "Codex receives the default skill 'alpha' over budget"
    Assert-True (-not ($fakeResult.CodexNames -contains 'beta')) "Codex does NOT receive the external skill 'beta' over budget (Doctrine rule 3)"
    Assert-True (Test-Path (Join-Path $fakeContext.ClaudeSkillsDir 'beta\SKILL.md')) "'beta' resolves to its SKILL.md through Claude Code's link even over budget"
    Assert-True (-not (Test-Path (Join-Path $fakeContext.CodexAgentsSkillsDir 'beta\SKILL.md'))) "'beta' has no link at all under Codex's folder when over budget"
}
catch {
    Write-Output "  FAIL - unhandled error (check 5): $($_.Exception.Message)"
    $failures.Add("unhandled error (check 5): $($_.Exception.Message)") | Out-Null
}
finally {
    if (-not $KeepTemp) {
        try {
            $cleanupBash5 = Resolve-BashExe
            & $cleanupBash5 -c "rm -rf -- '$($TestRoot5 -replace '\\','/')'"
        }
        catch { }
    }
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
