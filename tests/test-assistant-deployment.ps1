#Requires -Version 5.1
<#
.SYNOPSIS
    Assistant deployment tests (Mission 171-C01 step 6; audit Defect 3).

.DESCRIPTION
    Rerun with one command, from the repository root:

        powershell -NoProfile -ExecutionPolicy Bypass -File tests\test-assistant-deployment.ps1

    Before this step, the assistant's own generated forms (a Claude Code
    subagent, a Codex skill) only ever existed INSIDE the second-brain
    clone (.claude\agents\<slug>.md, .agents\skills\<slug>\) -- nothing
    made them reachable from a neighbouring project the way every method
    skill already was (tools/deploy-skills.ps1, ticket 07). This file
    proves the fix: Publish-DeployedAssistant links both forms into the
    profile ($Context.ClaudeAgentsDir, $Context.CodexAgentsSkillsDir),
    scoped to exactly the one assistant just (re)generated.

    Five independent checks, all against install.ps1's real -TestMode /
    -TestRoot redirection (never the real profile -- see this file's own
    fingerprint section, mirroring tests/test-skills-deployment.ps1):

      1. Fresh silent install: the CURRENT assistant's Claude Code subagent
         and Codex skill both resolve, from the profile, all the way to
         their own generated file, byte-identical to the source inside the
         clone -- and the subagent's `tools:` frontmatter line, at the
         DEPLOYED path, still reads exactly "Read, Glob, Grep" (the
         Mission's own explicit "outils toujours limites a la lecture"
         test requirement) -- deployment must never widen what the
         mechanically-restricted subagent format already refuses.

      2. Neighbour-project resolution (the Mission's own explicit
         "joignable depuis un projet voisin" test requirement): the SAME
         deployed paths resolve identically whether the current directory
         is inside the second-brain clone or inside an unrelated sibling
         project folder.

      3. Idempotent relaunch: rerunning check 1's exact install a second
         time, unchanged, leaves both profile folders' listings
         byte-for-byte identical (no duplicate link, same rule as every
         other link-based step in this repository).

      4. Live-link proof: appending a marker line to the deployed subagent
         INSIDE THE CLONE and reading it back THROUGH the profile-level
         link proves the link is the genuine mechanism (a correction
         propagating with no reinstall), not a one-time copy.

      5. Rename cleanup (spec criterion 3 -- deployment must be for THE
         right assistant, never every assistant a machine has ever
         generated): a fresh interactive install as "Brian", then an
         update-mode relaunch renaming to "Nova" -- the OLD 'brian'
         profile-level links are gone (Remove-DeployedAssistantLinks), the
         NEW 'nova' links exist and resolve, and the clone's own _trash/
         copy of the old forms (ticket 06's own rename handling, untouched
         by this step) still carries the original content.

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

# Shared with tests/test-install-e2e.ps1, tests/test-prerequisites-e2e.ps1
# and tests/test-skills-deployment.ps1 (Mission's own "environnement de
# l'Owner intact" constraint), now covering ~/.claude/agents too (this
# step's own real write target).
. (Join-Path $RepoRoot 'tools\environment-fingerprint.ps1')

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if ($Condition) { Write-Output "  PASS - $Message" }
    else { Write-Output "  FAIL - $Message"; $failures.Add($Message) | Out-Null }
}

$installScript = Join-Path $RepoRoot 'install.ps1'

Write-Output "=== 1. Real-environment fingerprint (before) ==="
$before = Get-EnvironmentFingerprint
Write-Output "  PATH SHA-256: $($before.PathHash)"
Write-Output "  .claude/agents entries: $($before.ClaudeAgents.Count)"
Write-Output "  .agents/skills entries: $($before.CodexAgentsSkills.Count)"

# --- 1. Fresh silent install: assistant forms deployed, tools restricted ---
$TestRoot1 = Join-Path $env:TEMP ("sb-assistant-deploy-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $TestRoot1 | Out-Null
Write-Output ""
Write-Output "TestRoot (check 1/2/3/4): $TestRoot1"

$clonePath1 = $null
$claudeAgentsDir1 = $null
$codexAgentsSkillsDir1 = $null
$slug1 = 'deploytestbot'

try {
    Write-Output ""
    Write-Output "=== 1. Fresh silent install: assistant forms resolve at the profile level ==="
    $sampleAnswers1 = Get-Content -Raw -Path (Join-Path $PSScriptRoot 'fixtures\install-answers.sample.json') | ConvertFrom-Json
    $sampleAnswers1.vaultName = 'DeployTestBot'
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
    $claudeAgentsDir1 = Join-Path $profileRoot1 '.claude\agents'
    $codexAgentsSkillsDir1 = Join-Path $profileRoot1 '.agents\skills'

    $sourceSubagent = Join-Path $clonePath1 ".claude\agents\$slug1.md"
    $deployedSubagent = Join-Path $claudeAgentsDir1 "$slug1.md"
    $sourceSkillMd = Join-Path $clonePath1 ".agents\skills\$slug1\SKILL.md"
    $deployedSkillMd = Join-Path $codexAgentsSkillsDir1 "$slug1\SKILL.md"

    Assert-True (Test-Path $sourceSubagent) "sanity: '$slug1' subagent generated inside the clone"
    Assert-True (Test-Path $deployedSubagent) "'$slug1' Claude Code subagent resolves through ~/.claude/agents (profile level)"
    Assert-True (Test-Path $deployedSkillMd) "'$slug1' Codex skill resolves through ~/.agents/skills (profile level)"

    if ((Test-Path $sourceSubagent) -and (Test-Path $deployedSubagent)) {
        $sourceText = Get-Content -Raw -Path $sourceSubagent -Encoding UTF8
        $deployedText = Get-Content -Raw -Path $deployedSubagent -Encoding UTF8
        Assert-True ($sourceText -eq $deployedText) "deployed subagent content is byte-identical to the source in the clone"

        # Mission's own explicit test requirement: "outils toujours limites
        # a la lecture" -- the deployed copy's own 'tools:' line, not the
        # whole file (its body legitimately contains the English word
        # "writes" in its own refusal sentence).
        $deployedToolsLine = ($deployedText -split "`n" | Where-Object { $_ -match '^tools:' })
        Assert-True ($deployedText -match '(?m)^tools:\s*Read,\s*Glob,\s*Grep\s*$') "deployed subagent frontmatter still restricts tools to exactly Read, Glob, Grep"
        Assert-True (($deployedToolsLine -join '') -notmatch 'Bash|Write|Edit') "deployed subagent's 'tools:' line never grants Bash, Write or Edit"

        $sourceToolsLine = ($sourceText -split "`n" | Where-Object { $_ -match '^tools:' })
        Assert-True ((($sourceToolsLine -join '')) -eq (($deployedToolsLine -join ''))) "deployment does not widen the tools line: source and deployed 'tools:' lines match exactly"
    }
    if ((Test-Path $sourceSkillMd) -and (Test-Path $deployedSkillMd)) {
        $viaLink = Get-Content -Raw -Path $deployedSkillMd -Encoding UTF8
        $viaSource = Get-Content -Raw -Path $sourceSkillMd -Encoding UTF8
        Assert-True ($viaLink -eq $viaSource) "deployed Codex skill content is byte-identical to the source in the clone"
    }

    $carnetPath1 = Join-Path $clonePath1 '.install\state.json'
    $carnet1 = Get-Content -Raw -Path $carnetPath1 -Encoding UTF8 | ConvertFrom-Json
    Assert-True ($carnet1.assistantDeployment.slug -eq $slug1) "install notebook records the deployed slug ('$slug1')"
    Assert-True ($carnet1.assistantDeployment.conflictCount -eq 0) "install notebook records zero deployment conflicts"
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

        foreach ($cwdCase in @(
            [PSCustomObject]@{ Label = 'from second-brain'; Cwd = $clonePath1 },
            [PSCustomObject]@{ Label = 'from a neighbour project'; Cwd = $neighborRoot }
        )) {
            Push-Location $cwdCase.Cwd
            try {
                $subagentMd = Join-Path $claudeAgentsDir1 "$slug1.md"
                $skillMd = Join-Path $codexAgentsSkillsDir1 "$slug1\SKILL.md"
                Assert-True (Test-Path $subagentMd) "$($cwdCase.Label): assistant subagent resolves through ~/.claude/agents regardless of the current directory"
                Assert-True (Test-Path $skillMd) "$($cwdCase.Label): assistant Codex skill resolves through ~/.agents/skills regardless of the current directory"
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
        $beforeAgentsNames = @(Get-ChildItem -Path $claudeAgentsDir1 -Name -ErrorAction SilentlyContinue | Sort-Object)
        $beforeSkillsNames = @(Get-ChildItem -Path $codexAgentsSkillsDir1 -Name -ErrorAction SilentlyContinue | Sort-Object)

        $verdictAgain = & $installScript -Source $RepoRoot -AnswersFile $answersPath1 -TestMode -TestRoot $TestRoot1
        $exitAgain = $LASTEXITCODE
        Assert-True ($exitAgain -eq 0) "relaunch (unchanged inputs) exits 0"

        $afterAgentsNames = @(Get-ChildItem -Path $claudeAgentsDir1 -Name -ErrorAction SilentlyContinue | Sort-Object)
        $afterSkillsNames = @(Get-ChildItem -Path $codexAgentsSkillsDir1 -Name -ErrorAction SilentlyContinue | Sort-Object)
        Assert-True (@(Compare-Object $beforeAgentsNames $afterAgentsNames).Count -eq 0) "~/.claude/agents listing is identical before/after the relaunch (no duplicate link)"
        Assert-True (@(Compare-Object $beforeSkillsNames $afterSkillsNames).Count -eq 0) "~/.agents/skills listing is identical before/after the relaunch (no duplicate link)"

        $clonePorcelain = & git -C $clonePath1 status --porcelain
        Assert-True ([string]::IsNullOrEmpty(($clonePorcelain -join ''))) "second-brain clone porcelain is empty after the relaunch (assistant deployment writes nothing tracked)"
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
#        reinstall.
try {
    if ($null -ne $clonePath1) {
        Write-Output ""
        Write-Output "=== 4. Live-link proof (correction propagates without reinstall) ==="
        $sourceSubagent = Join-Path $clonePath1 ".claude\agents\$slug1.md"
        $deployedSubagent = Join-Path $claudeAgentsDir1 "$slug1.md"
        $original = Get-Content -Raw -Path $sourceSubagent -Encoding UTF8
        $marker = "TEST-MARKER-" + [Guid]::NewGuid().ToString('N')
        Add-Content -Path $sourceSubagent -Value $marker -Encoding UTF8

        $throughLink = Get-Content -Raw -Path $deployedSubagent -Encoding UTF8
        Assert-True ($throughLink.Contains($marker)) "a correction written to the subagent inside the clone is immediately visible through its ~/.claude/agents link (hard link, not a one-time copy)"

        Set-Content -Path $sourceSubagent -Value $original -Encoding UTF8 -NoNewline
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

# --- 5. Rename cleanup: deployment follows the CURRENT slug only -----------
$TestRoot5 = Join-Path $env:TEMP ("sb-assistant-deploy-rename-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $TestRoot5 | Out-Null
Write-Output ""
Write-Output "TestRoot (check 5): $TestRoot5"

try {
    Write-Output ""
    Write-Output "=== 5a. Fresh interactive install, default name 'Brian' ==="
    $run1Answers = @('EN', '', '', 'Ana', 'Building a personal AI system', '', 'Simplicity', 'n')
    $run1Output = & $installScript -Source $RepoRoot -TestMode -TestRoot $TestRoot5 -ScriptedAnswers $run1Answers 6>&1 | Out-String
    $run1Exit = $LASTEXITCODE
    Assert-True ($run1Exit -eq 0) "fresh interactive install (default name) exits 0"

    $clonePath5 = Join-Path (Join-Path $TestRoot5 'workspace') 'second-brain'
    $profileRoot5 = Join-Path $TestRoot5 'profile'
    $claudeAgentsDir5 = Join-Path $profileRoot5 '.claude\agents'
    $codexAgentsSkillsDir5 = Join-Path $profileRoot5 '.agents\skills'

    $brianDeployedSubagent = Join-Path $claudeAgentsDir5 'brian.md'
    $brianDeployedSkill = Join-Path $codexAgentsSkillsDir5 'brian\SKILL.md'
    Assert-True (Test-Path $brianDeployedSubagent) "'brian' subagent deployed to the profile on the fresh install"
    Assert-True (Test-Path $brianDeployedSkill) "'brian' Codex skill deployed to the profile on the fresh install"

    Write-Output ""
    Write-Output "=== 5b. Update-mode relaunch, renamed to 'Nova' ==="
    $run2Answers = @('y', '', 'Nova', 'Ana', '', '', '', 'n')
    $run2Output = & $installScript -Source $RepoRoot -TestMode -TestRoot $TestRoot5 -ScriptedAnswers $run2Answers 6>&1 | Out-String
    $run2Exit = $LASTEXITCODE
    Write-Output $run2Output
    Assert-True ($run2Exit -eq 0) "update-mode rename to 'Nova' exits 0"

    $novaDeployedSubagent = Join-Path $claudeAgentsDir5 'nova.md'
    $novaDeployedSkill = Join-Path $codexAgentsSkillsDir5 'nova\SKILL.md'
    Assert-True (Test-Path $novaDeployedSubagent) "'nova' subagent deployed to the profile after the rename"
    Assert-True (Test-Path $novaDeployedSkill) "'nova' Codex skill deployed to the profile after the rename"

    Assert-True (-not (Test-Path $brianDeployedSubagent)) "old 'brian' profile-level subagent link removed after the rename (Remove-DeployedAssistantLinks)"
    Assert-True (-not (Test-Path (Join-Path $codexAgentsSkillsDir5 'brian'))) "old 'brian' profile-level Codex skill link removed after the rename"

    # The link/junction is gone from the profile, but the CONTENT is not
    # lost (Decision 110852): the clone's own _trash/ copy (ticket 06's own
    # rename handling, untouched by this step) still carries it.
    $trashRoot = Join-Path $clonePath5 '_trash'
    $renameTrashDirs = @()
    if (Test-Path $trashRoot) {
        $renameTrashDirs = @(Get-ChildItem -Path $trashRoot -Directory | Where-Object { $_.Name -like 'assistant-rename-brian-*' })
    }
    Assert-True ($renameTrashDirs.Count -eq 1) "exactly one _trash/assistant-rename-brian-<timestamp>/ directory exists (found $($renameTrashDirs.Count))"
    if ($renameTrashDirs.Count -ge 1) {
        $trashedSubagent = Join-Path $renameTrashDirs[0].FullName '.claude\agents\brian.md'
        Assert-True (Test-Path $trashedSubagent) "old 'brian' subagent content survives, recovered under _trash/ (moved, never deleted)"
    }
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
        Write-Output ""
        Write-Output "TestRoot removed: $TestRoot5"
    }
    else {
        Write-Output ""
        Write-Output "TestRoot kept (-KeepTemp): $TestRoot5"
    }
}

Write-Output ""
Write-Output "=== Real-environment fingerprint (after) ==="
$after = Get-EnvironmentFingerprint
Write-Output "  PATH SHA-256: $($after.PathHash)"
Write-Output "  .claude/agents entries: $($after.ClaudeAgents.Count)"
Write-Output "  .agents/skills entries: $($after.CodexAgentsSkills.Count)"
Assert-True ($after.PathHash -eq $before.PathHash) "real user PATH is byte-identical before/after"
Assert-True (@(Compare-Object $before.ClaudeAgents $after.ClaudeAgents).Count -eq 0) "real ~/.claude/agents listing is identical before/after"
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
