#Requires -Version 5.1
<#
.SYNOPSIS
    Main end-to-end test of install.ps1 (Mission 168, ticket 03; spec,
    Testing Decisions -- "point de controle principal").

.DESCRIPTION
    Rerun this exact test with one command, from the repository root:

        powershell -NoProfile -ExecutionPolicy Bypass -File tests\test-install-e2e.ps1

    What it proves, in a single fresh, blank temporary workspace:
      1. install.ps1 accepts a local source and an answers file and reports
         a success verdict.
      2. The workspace conformity tool -- tools/session-preflight.sh, chosen
         because the spec's own Testing Decisions describe this exact check
         as "une session ouverte dans second-brain rend READY", the literal
         vocabulary this tool (and only this tool, among the two 168/03
         candidates) actually prints -- is green (READY) in the freshly
         cloned second-brain.
      3. A trial commit in the first project passes all of its guardians
         (repo: local, pinned on the clone -- tools/project-bootstrap.sh).
      4. Running the installer a second time, unchanged inputs, is a true
         no-op: identical verdict, empty porcelain in both the second-brain
         clone and the first project.
      5. Throughout, the Owner's real environment is untouched: the user
         PATH (HKCU\Environment\Path) and the skill folders
         (~/.claude/skills, ~/.codex/skills, ~/.agents/skills -- the last
         added by ticket 07, the first real write target
         tools/deploy-skills.ps1 could ever leak into) are fingerprinted
         before and after and asserted identical -- install.ps1 is always
         invoked with -TestMode so nothing it does can reach the real
         profile. (Its PATH-redirection helper, Add-InstallerPathEntry, is
         not called by this ticket's own steps at all -- measured directly:
         only tools/prerequisites.ps1 (ticket 04) ever calls it, neither
         ticket 06's assistant generation nor ticket 07's skill deployment
         needs a PATH entry -- so there is nothing of it to exercise here
         beyond this fingerprint proof.)

    Exit code 0 means every assertion above passed. Exit code 1 means at
    least one did not; details are printed to stdout as each check runs.
#>

[CmdletBinding()]
param(
    [switch] $KeepTemp
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path $PSScriptRoot -Parent
$failures = New-Object System.Collections.Generic.List[string]

# Shared with install.ps1 -- one copy of the bash.exe lookup, never two
# drifting copies.
. (Join-Path $RepoRoot 'tools\resolve-bash-exe.ps1')

# Shared with tests/test-prerequisites-e2e.ps1 (Mission 168, ticket 04) --
# mirrors the Mission's own before/after measurement method exactly (user
# PATH via the registry, both skill folder listings) so this test's proof
# is directly comparable to the Executor's own report, and both tests stay
# byte-for-byte comparable to each other.
. (Join-Path $RepoRoot 'tools\environment-fingerprint.ps1')

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if ($Condition) {
        Write-Output "  PASS - $Message"
    }
    else {
        Write-Output "  FAIL - $Message"
        $failures.Add($Message) | Out-Null
    }
}

Write-Output "=== 1. Real-environment fingerprint (before) ==="
$before = Get-EnvironmentFingerprint
Write-Output "  PATH SHA-256: $($before.PathHash)"
Write-Output "  .claude/skills entries: $($before.ClaudeSkills.Count)"
Write-Output "  .claude/agents entries: $($before.ClaudeAgents.Count)"
Write-Output "  .codex/skills entries: $($before.CodexSkills.Count)"
Write-Output "  .agents/skills entries: $($before.CodexAgentsSkills.Count)"

$TestRoot = Join-Path $env:TEMP ("sb-e2e-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $TestRoot | Out-Null
Write-Output ""
Write-Output "=== 2. Fresh, blank temporary workspace ==="
Write-Output "  TestRoot: $TestRoot"

$workspacePath = Join-Path $TestRoot 'workspace'
$answersPath = Join-Path $TestRoot 'answers.json'
$sampleAnswers = Get-Content -Raw -Path (Join-Path $PSScriptRoot 'fixtures\install-answers.sample.json') | ConvertFrom-Json
$sampleAnswers.workspacePath = $workspacePath
$sampleAnswers | ConvertTo-Json -Depth 10 | Set-Content -Path $answersPath -Encoding UTF8

$installScript = Join-Path $RepoRoot 'install.ps1'
$clonePath = Join-Path $workspacePath 'second-brain'
$firstProjectPath = Join-Path $workspacePath $sampleAnswers.firstProject.name

try {
    Write-Output ""
    Write-Output "=== 3. First run (installer) ==="
    $verdict1 = & $installScript -Source $RepoRoot -AnswersFile $answersPath -TestMode -TestRoot $TestRoot
    $exit1 = $LASTEXITCODE
    Write-Output "  verdict: $verdict1"
    Assert-True ($exit1 -eq 0) "first run exits 0"
    Assert-True ($verdict1 -match 'Installation complete') "first run verdict reports success"
    # Ticket 05 criterion 7: -AnswersFile mode never prints a single
    # question, even though this same run answers all eight of them (from
    # the file) plus the first-project confirmation -- the verdict is the
    # ONLY line silent mode ever produces.
    Assert-True (@($verdict1).Count -eq 1) "silent mode (-AnswersFile) prints exactly one line, never a question"
    Assert-True ($verdict1 -notmatch 'first name|assistant|workspace live|Question') "silent mode output contains no question-prompt text"

    Write-Output ""
    Write-Output "=== 4. Workspace conformity tool: tools/session-preflight.sh -> READY ==="
    $bashExe = Resolve-BashExe
    Push-Location $clonePath
    try {
        # No `2>$null` here: in Windows PowerShell 5.1, redirecting a native
        # command's stderr while also capturing its output turns every
        # stderr line into a terminating ErrorRecord under
        # $ErrorActionPreference = 'Stop' -- measured directly (a harmless
        # "sibling repo not found" warning from session-preflight.sh, always
        # expected in a standalone workspace, was aborting this whole
        # script). Leaving stderr unredirected prints it straight to the
        # console instead, which is exactly what a diagnostic warning
        # should do, and stdout capture is unaffected either way.
        $preflightOutput = & $bashExe 'tools/session-preflight.sh'
        $preflightExit = $LASTEXITCODE
    }
    finally { Pop-Location }
    Write-Output "  output: $preflightOutput"
    Assert-True ($preflightExit -eq 0) "session-preflight.sh exits 0"
    Assert-True ($preflightOutput -contains 'READY') "session-preflight.sh reports READY"

    Write-Output ""
    Write-Output "=== 5. Trial commit in the first project passes all guardians ==="
    Push-Location $firstProjectPath
    try {
        $journalScript = Join-Path $clonePath 'tools\append-journal.sh'
        & $bashExe $journalScript '.' 'STATE: trial commit for Mission 168 ticket 03 main test' | Out-Null
        & git add -- state/journal.md
        # No stderr redirection here (never `2>&1` on a native command in
        # PowerShell 5.1 -- it wraps stderr lines as NativeCommandError and
        # can flip $? even on exit 0); the hook's own PASS/FAIL table
        # prints straight to the console either way, and $LASTEXITCODE
        # alone is what this assertion needs.
        & git commit -q -m "Trial commit: ticket 03 main test"
        $commitExit = $LASTEXITCODE
    }
    finally { Pop-Location }
    Assert-True ($commitExit -eq 0) "trial commit passes guardians (git commit exits 0)"

    Write-Output ""
    Write-Output "=== 6. Second run (installer) is a true no-op ==="
    $verdict2 = & $installScript -Source $RepoRoot -AnswersFile $answersPath -TestMode -TestRoot $TestRoot
    $exit2 = $LASTEXITCODE
    Write-Output "  verdict: $verdict2"
    Assert-True ($exit2 -eq 0) "second run exits 0"
    Assert-True ($verdict2 -eq $verdict1) "second run verdict is identical to the first"

    $clonePorcelain = & git -C $clonePath status --porcelain
    $projectPorcelain = & git -C $firstProjectPath status --porcelain
    Assert-True ([string]::IsNullOrEmpty(($clonePorcelain -join ''))) "second-brain clone porcelain is empty after the second run"
    Assert-True ([string]::IsNullOrEmpty(($projectPorcelain -join ''))) "first project porcelain is empty after the second run"
}
catch {
    Write-Output "  FAIL - unhandled error: $($_.Exception.Message)"
    $failures.Add("unhandled error: $($_.Exception.Message)") | Out-Null
}

# --- 7. Real-environment fingerprint, after -------------------------------
# The two real runs above (-TestMode throughout) are the actual proof the
# Mission's constraint asks for; install.ps1's PATH-redirection helper
# (Add-InstallerPathEntry) is not called by this ticket's own steps, so
# there is nothing else to exercise here beyond reconfirming the fingerprint.
Write-Output ""
Write-Output "=== 7. Real-environment fingerprint (after) ==="
$after = Get-EnvironmentFingerprint
Write-Output "  PATH SHA-256: $($after.PathHash)"
Write-Output "  .claude/skills entries: $($after.ClaudeSkills.Count)"
Write-Output "  .claude/agents entries: $($after.ClaudeAgents.Count)"
Write-Output "  .codex/skills entries: $($after.CodexSkills.Count)"
Write-Output "  .agents/skills entries: $($after.CodexAgentsSkills.Count)"
Assert-True ($after.PathHash -eq $before.PathHash) "real user PATH is byte-identical before/after"
Assert-True (@(Compare-Object $before.ClaudeSkills $after.ClaudeSkills).Count -eq 0) "real ~/.claude/skills listing is identical before/after"
Assert-True (@(Compare-Object $before.ClaudeAgents $after.ClaudeAgents).Count -eq 0) "real ~/.claude/agents listing is identical before/after"
Assert-True (@(Compare-Object $before.CodexSkills $after.CodexSkills).Count -eq 0) "real ~/.codex/skills listing is identical before/after"
Assert-True (@(Compare-Object $before.CodexAgentsSkills $after.CodexAgentsSkills).Count -eq 0) "real ~/.agents/skills listing is identical before/after"

if (-not $KeepTemp) {
    # Not Remove-Item: it silently leaves debris behind under the same
    # long-path file that needed `core.longpaths` for git (measured -- a
    # "successful", exit-0 run still left
    # skills-warehouse/.../shadow clone.md on disk under $env:TEMP,
    # -ErrorAction SilentlyContinue swallowing the failure). bash's `rm -rf`
    # handles the same path without issue.
    $cleanupBash = Resolve-BashExe
    & $cleanupBash -c "rm -rf -- '$($TestRoot -replace '\\','/')'"
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
