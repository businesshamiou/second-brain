#Requires -Version 5.1
<#
.SYNOPSIS
    Replays the seven mechanical scenarios of the acceptance playbook
    (Mission 170, step 3) and writes a one-line-per-scenario report.

.DESCRIPTION
    The acceptance playbook (tools/acceptance-wizard.sh, stages S1-S10 plus
    optional S11) splits into scenarios only a human can judge (S7, S8, S9 --
    out of scope here) and scenarios a script can replay end to end. This
    runner replays exactly the latter seven -- S1, S2, S3, S4, S5, S6, S10 --
    each in test mode, and never against the Owner's real environment.

    It does not duplicate what already exists: every scenario is delegated to
    an existing suite under tests/, chosen by actually reading what each
    suite proves (not by guessing from its file name), except S5 and S10,
    for which no existing suite exercises the behaviour the playbook
    describes (measured -- see each new file's own header comment):

      S1  Fresh install, Windows        -> test-install-e2e.ps1
      S2  Re-run without changes        -> test-questionnaire-update-mode.ps1
      S3  Resume after a forced stop    -> test-questionnaire-resume.ps1
      S4  First project                 -> test-install-e2e.ps1
      S5  A guardian refuses            -> test-guardian-secret-refusal.sh (new)
      S6  Cold session (session-start)  -> test-install-e2e.ps1
      S10 Offline commit                -> test-guardian-offline-commit.sh (new)

    Mission 174 step 5 (T21) adds an eighth, unnumbered check alongside
    these seven: tests/test-nominal-flow-no-atelier-vocabulary.ps1 replays
    the same three phases (install, session opening, trial commit) and
    refuses if their combined output shows a participant any name or word
    of the Owner's atelier. Not one of the acceptance playbook's own S1-S11
    scenarios -- a standing non-regression guard this Mission's own
    Objectif required, run every time this suite runs.

    test-install-e2e.ps1 backs three scenarios (S1, S4, S6) from a single
    run: it already asserts a fresh install's success verdict (S1), the
    first-project creation plus a trial commit accepted by its guardians
    (S4), and tools/session-preflight.sh reporting READY in the fresh clone
    -- the literal vocabulary the playbook's own S6 note asks for, and the
    same tool the Mission 168 spec names as the ticket 03 proof for this
    exact criterion. It only runs once; its single PASS/FAIL backs all three
    report lines, named as such in the Detail column.

    Every delegated suite already runs against a fresh temporary workspace
    with install.ps1 -TestMode (test-install-e2e.ps1,
    test-questionnaire-update-mode.ps1, test-questionnaire-resume.ps1) or
    against a disposable sandbox git repository it builds and destroys
    itself (test-guardian-secret-refusal.sh, test-guardian-offline-commit.sh,
    the latter via tests/standalone.sh). None of them can reach the Owner's
    real PATH or skill folders by construction; this runner additionally
    fingerprints both before and after the full replay (same
    tools/environment-fingerprint.ps1 helper used by tests/test-install-e2e.ps1
    and tests/test-prerequisites-e2e.ps1) and reports whether they matched,
    as an outer-loop confirmation rather than a repeat of each suite's own
    inner one.

    The report is a Markdown file written OUTSIDE this repository (default: a
    sibling of the second-brain checkout, timestamped -- same convention as
    tools/acceptance-wizard.sh's own resolve_report_path/write_report, and
    for the same reason: ticket 11's rule that a finished report must never
    enter a repository a later Owner push makes public). A custom -Out is
    honoured but refused if it resolves inside this repository.

    Usage (from the repository root):

        powershell -NoProfile -ExecutionPolicy Bypass -File tests\run-mechanical-acceptance.ps1
        powershell -NoProfile -ExecutionPolicy Bypass -File tests\run-mechanical-acceptance.ps1 -Out C:\path\outside\report.md

    Exit code 0 means all seven scenarios plus the step-5 check passed.
    Exit code 1 means at least one did not, or the report path was refused;
    the console output says
    which.
#>

[CmdletBinding()]
param(
    [string] $Out
)

$ErrorActionPreference = 'Continue'
$RepoRoot = Split-Path $PSScriptRoot -Parent

. (Join-Path $RepoRoot 'tools\resolve-bash-exe.ps1')
. (Join-Path $RepoRoot 'tools\environment-fingerprint.ps1')

# --- Report path: a sibling of this checkout, never inside it ---------------
function Resolve-ReportPath {
    param([string] $OutPath)

    if ($OutPath) {
        $path = $OutPath
        if (-not [System.IO.Path]::IsPathRooted($path)) {
            $path = Join-Path (Get-Location).Path $path
        }
    }
    else {
        $workspaceRoot = Split-Path $RepoRoot -Parent
        $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $path = Join-Path $workspaceRoot "second-brain-mechanical-acceptance-$stamp.md"
    }

    $repoRootNorm = $RepoRoot.TrimEnd('\') + '\'
    $pathNorm = $path
    if ($pathNorm -eq $RepoRoot.TrimEnd('\') -or $pathNorm.StartsWith($repoRootNorm, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Error: report path $pathNorm is inside $RepoRoot -- pick a path outside second-brain."
    }
    return $pathNorm
}

$reportPath = Resolve-ReportPath -OutPath $Out

# --- Scenario bookkeeping -----------------------------------------------------
$Results = New-Object System.Collections.Generic.List[PSCustomObject]

function Add-Result {
    param(
        [string] $Id,
        [string] $Title,
        [string] $Suite,
        [bool]   $Delegated,
        [bool]   $Pass,
        [string] $Detail
    )
    $Results.Add([PSCustomObject]@{
        Id        = $Id
        Title     = $Title
        Suite     = $Suite
        Delegated = $Delegated
        Verdict   = if ($Pass) { 'PASS' } else { 'FAIL' }
        Detail    = $Detail
    }) | Out-Null
}

function Invoke-PsSuite {
    param([string] $RelativePath)
    $full = Join-Path $RepoRoot $RelativePath
    $output = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $full
    $exit = $LASTEXITCODE
    return [PSCustomObject]@{ Output = ($output | Out-String); Exit = $exit }
}

function Invoke-BashSuite {
    param([string] $RelativePath)
    $bashExe = Resolve-BashExe
    Push-Location $RepoRoot
    try {
        $output = & $bashExe $RelativePath
        $exit = $LASTEXITCODE
    }
    finally { Pop-Location }
    return [PSCustomObject]@{ Output = ($output | Out-String); Exit = $exit }
}

Write-Output "=== Environment fingerprint (before) ==="
$before = Get-EnvironmentFingerprint
Write-Output "  PATH SHA-256: $($before.PathHash)"
Write-Output "  .claude/skills entries: $($before.ClaudeSkills.Count)"
Write-Output "  .codex/skills entries: $($before.CodexSkills.Count)"
Write-Output "  .agents/skills entries: $($before.CodexAgentsSkills.Count)"

# --- S1, S4, S6: one shared run of test-install-e2e.ps1 ----------------------
Write-Output ""
Write-Output "=== Running tests/test-install-e2e.ps1 (backs S1, S4, S6) ==="
$installRun = Invoke-PsSuite -RelativePath 'tests\test-install-e2e.ps1'
Write-Output $installRun.Output
$installPass = ($installRun.Exit -eq 0)
Add-Result -Id 'S1' -Title 'Fresh install, Windows' -Suite 'tests/test-install-e2e.ps1' -Delegated $true -Pass $installPass `
    -Detail 'shared run backing S1/S4/S6: first run success verdict'
Add-Result -Id 'S4' -Title 'First project' -Suite 'tests/test-install-e2e.ps1' -Delegated $true -Pass $installPass `
    -Detail 'shared run backing S1/S4/S6: first-project creation + trial commit passes guardians'
Add-Result -Id 'S6' -Title 'Cold session (session-start)' -Suite 'tests/test-install-e2e.ps1' -Delegated $true -Pass $installPass `
    -Detail 'shared run backing S1/S4/S6: tools/session-preflight.sh reports READY'

# --- S2: re-run without changes ----------------------------------------------
Write-Output ""
Write-Output "=== Running tests/test-questionnaire-update-mode.ps1 (backs S2) ==="
$updateRun = Invoke-PsSuite -RelativePath 'tests\test-questionnaire-update-mode.ps1'
Write-Output $updateRun.Output
Add-Result -Id 'S2' -Title 'Re-run without changes' -Suite 'tests/test-questionnaire-update-mode.ps1' -Delegated $true -Pass ($updateRun.Exit -eq 0) `
    -Detail 'update-mode re-run: "Nothing changed" verdict, empty porcelain'

# --- S3: resume after a forced stop ------------------------------------------
Write-Output ""
Write-Output "=== Running tests/test-questionnaire-resume.ps1 (backs S3) ==="
$resumeRun = Invoke-PsSuite -RelativePath 'tests\test-questionnaire-resume.ps1'
Write-Output $resumeRun.Output
Add-Result -Id 'S3' -Title 'Resume after a forced stop' -Suite 'tests/test-questionnaire-resume.ps1' -Delegated $true -Pass ($resumeRun.Exit -eq 0) `
    -Detail 'forced stop after "clone", resumed without re-asking answered questions'

# --- S5: a guardian refuses, then accepts ------------------------------------
Write-Output ""
Write-Output "=== Running tests/test-guardian-secret-refusal.sh (backs S5, new) ==="
$secretRun = Invoke-BashSuite -RelativePath 'tests/test-guardian-secret-refusal.sh'
Write-Output $secretRun.Output
Add-Result -Id 'S5' -Title 'A guardian refuses, then accepts' -Suite 'tests/test-guardian-secret-refusal.sh' -Delegated $false -Pass ($secretRun.Exit -eq 0) `
    -Detail 'check-secrets.sh: refuses a staged ghp_ token, accepts once removed'

# --- S10: offline commit ------------------------------------------------------
Write-Output ""
Write-Output "=== Running tests/test-guardian-offline-commit.sh (backs S10, new) ==="
$offlineRun = Invoke-BashSuite -RelativePath 'tests/test-guardian-offline-commit.sh'
Write-Output $offlineRun.Output
Add-Result -Id 'S10' -Title 'Offline commit' -Suite 'tests/test-guardian-offline-commit.sh' -Delegated $false -Pass ($offlineRun.Exit -eq 0) `
    -Detail 'no guardian calls the network; standalone.sh commit survives a poisoned proxy'

# --- Unnumbered: nominal flow shows no atelier vocabulary (Mission 174, step 5) ---
Write-Output ""
Write-Output "=== Running tests/test-nominal-flow-no-atelier-vocabulary.ps1 (T21, new) ==="
$noAtelierRun = Invoke-PsSuite -RelativePath 'tests\test-nominal-flow-no-atelier-vocabulary.ps1'
Write-Output $noAtelierRun.Output
Add-Result -Id 'T21' -Title 'No atelier vocabulary in the nominal flow' -Suite 'tests/test-nominal-flow-no-atelier-vocabulary.ps1' -Delegated $false -Pass ($noAtelierRun.Exit -eq 0) `
    -Detail 'fresh install + session opening + trial commit: combined output carries no atelier name/word'

Write-Output ""
Write-Output "=== Environment fingerprint (after) ==="
$after = Get-EnvironmentFingerprint
Write-Output "  PATH SHA-256: $($after.PathHash)"
Write-Output "  .claude/skills entries: $($after.ClaudeSkills.Count)"
Write-Output "  .codex/skills entries: $($after.CodexSkills.Count)"
Write-Output "  .agents/skills entries: $($after.CodexAgentsSkills.Count)"

$pathIdentical = ($after.PathHash -eq $before.PathHash)
$claudeIdentical = (@(Compare-Object $before.ClaudeSkills $after.ClaudeSkills).Count -eq 0)
$codexIdentical = (@(Compare-Object $before.CodexSkills $after.CodexSkills).Count -eq 0)
$agentsIdentical = (@(Compare-Object $before.CodexAgentsSkills $after.CodexAgentsSkills).Count -eq 0)
$envIdentical = $pathIdentical -and $claudeIdentical -and $codexIdentical -and $agentsIdentical
Write-Output "  real environment identical before/after: $envIdentical"

# --- Ordered scenario order, matching the Mission's own list ----------------
$order = 'S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S10', 'T21'
$ordered = $order | ForEach-Object { $id = $_; $Results | Where-Object { $_.Id -eq $id } }

Write-Output ""
Write-Output "=== Mechanical acceptance summary ==="
foreach ($r in $ordered) {
    Write-Output ("  {0,-4} {1,-32} {2}" -f $r.Id, $r.Title, $r.Verdict)
}

$failCount = @($ordered | Where-Object { $_.Verdict -eq 'FAIL' }).Count

# --- Write the report, outside the repository --------------------------------
$sha = (git -C $RepoRoot rev-parse --short HEAD 2>$null)
if (-not $sha) { $sha = 'unknown' }
$lines = New-Object System.Collections.Generic.List[string]
$lines.Add('# Second Brain -- mechanical acceptance report') | Out-Null
$lines.Add('') | Out-Null
$lines.Add("- Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')") | Out-Null
$lines.Add("- Local source: $RepoRoot") | Out-Null
$lines.Add("- HEAD: $sha") | Out-Null
$lines.Add("- Mode: test only (install.ps1 -TestMode / disposable sandbox git repos); the Owner's real environment was never touched.") | Out-Null
$lines.Add("- Real-environment fingerprint identical before/after: $envIdentical") | Out-Null
$lines.Add('') | Out-Null
$lines.Add('| Scenario | Title | Verdict | Delegated to | Detail |') | Out-Null
$lines.Add('|---|---|---|---|---|') | Out-Null
foreach ($r in $ordered) {
    $delegatedText = if ($r.Delegated) { 'existing suite' } else { 'new (this step)' }
    $lines.Add("| $($r.Id) | $($r.Title) | $($r.Verdict) | $($r.Suite) ($delegatedText) | $($r.Detail) |") | Out-Null
}
Set-Content -Path $reportPath -Value $lines -Encoding UTF8
Write-Output ""
Write-Output "Report written to: $reportPath"

if ($failCount -eq 0) {
    Write-Output ""
    Write-Output "=== RESULT: PASS ($($ordered.Count)/$($ordered.Count) mechanical scenarios) ==="
    exit 0
}
else {
    Write-Output ""
    Write-Output "=== RESULT: FAIL ($failCount/$($ordered.Count) mechanical scenario(s) failed) ==="
    exit 1
}
