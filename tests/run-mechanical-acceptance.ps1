#Requires -Version 5.1
<#
.SYNOPSIS
    The acceptance of Second Brain: replays S1-S10 and T21 and writes a
    dated, one-line-per-scenario report (Mission 170, step 3; Mission
    183-C01, Decision 142112 -- acceptance is fully mechanical).

.DESCRIPTION
    Since Decision 142112 there is no human acceptance wizard any more: this
    runner's report IS the written acceptance of a commit. Eleven lines:

      S1  Fresh install, Windows          -> test-install-e2e.ps1
      S2  Re-run without changes          -> test-questionnaire-update-mode.ps1
      S3  Resume after a forced stop      -> test-questionnaire-resume.ps1
      S4  First project                   -> test-install-e2e.ps1
      S5  A guardian refuses              -> test-guardian-secret-refusal.sh
      S6  Cold session (session-start)    -> test-install-e2e.ps1
      S7  The assistant answers           -> tools/acceptance-harness.sh
      S8  Web package (by equivalence)    -> tools/acceptance-harness.sh
      S9  No Git, no admin rights         -> test-install-standard-user.ps1
      S10 Offline commit                  -> test-guardian-offline-commit.sh
      T21 No atelier vocabulary           -> test-nominal-flow-no-atelier-vocabulary.ps1

    Verdicts are closed: PASS, FAIL, SKIP (no provider credentials in CI),
    INDETERMINE (cause named). A scenario that could not be measured is
    never PASS.

    S7 and S8 call a model (admitted for these two only, Decision 142112
    point 2): the harness asks the three questions of assistant/ASSISTANT.md
    three times each, through two providers -- the Claude Code sub-agent and
    the Codex skill -- against a test-mode installation this runner makes
    for them. Both providers PASS 3/3 = PASS; any FAIL = FAIL; otherwise a
    provider that could not answer makes the line INDETERMINE (one provider
    does not prove the harness provider-agnostic). S8 plays the web package
    by equivalence (instructions as system prompt, knowledge files as
    documents): the upload gesture in a web interface is not proven.

    S9 needs a disposable machine (it creates a local standard account):
    tests/test-install-standard-user.ps1 refuses anywhere else and the line
    is INDETERMINE, with the local, same-account half
    (tests/test-bootstrap-no-git.ps1) named in its detail. The CI
    acceptance job runs it for real, with -RequireS9.

    S1, S4 and S6 share one run of test-install-e2e.ps1, as before. Every
    suite works in test mode or in a disposable sandbox; this runner also
    fingerprints the real environment before and after.

    The report is a Markdown file written OUTSIDE this repository (default:
    a sibling of the checkout, timestamped). A custom -Out is honoured but
    refused if it resolves inside this repository.

    Usage (from the repository root):

        powershell -NoProfile -ExecutionPolicy Bypass -File tests\run-mechanical-acceptance.ps1
        powershell -NoProfile -ExecutionPolicy Bypass -File tests\run-mechanical-acceptance.ps1 -Out C:\path\outside\report.md [-RequireS9]

    Exit code 0 means no line is FAIL (and, with -RequireS9, S9 is PASS).
    Exit code 1 otherwise, or if the report path was refused.
#>

[CmdletBinding()]
param(
    [string] $Out,
    [switch] $RequireS9
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
        [string] $Verdict,
        [string] $Detail
    )
    $Results.Add([PSCustomObject]@{
        Id      = $Id
        Title   = $Title
        Suite   = $Suite
        Verdict = $Verdict
        Detail  = $Detail
    }) | Out-Null
}

function ConvertTo-Verdict {
    param([bool] $Pass)
    if ($Pass) { return 'PASS' } else { return 'FAIL' }
}

function Invoke-PsSuite {
    param([string] $RelativePath, [string[]] $Arguments = @())
    $full = Join-Path $RepoRoot $RelativePath
    $output = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $full @Arguments
    $exit = $LASTEXITCODE
    return [PSCustomObject]@{ Output = ($output | Out-String); Exit = $exit }
}

function Invoke-BashSuite {
    param([string] $RelativePath, [string[]] $Arguments = @())
    $bashExe = Resolve-BashExe
    Push-Location $RepoRoot
    try {
        $output = & $bashExe $RelativePath @Arguments 2>&1 | ForEach-Object { "$_" }
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
Write-Output "  .local/bin entries: $($before.LocalBin.Count)"

# --- S1, S4, S6: one shared run of test-install-e2e.ps1 ----------------------
Write-Output ""
Write-Output "=== Running tests/test-install-e2e.ps1 (backs S1, S4, S6) ==="
$installRun = Invoke-PsSuite -RelativePath 'tests\test-install-e2e.ps1'
Write-Output $installRun.Output
$installVerdict = ConvertTo-Verdict ($installRun.Exit -eq 0)
Add-Result -Id 'S1' -Title 'Fresh install, Windows' -Suite 'tests/test-install-e2e.ps1' -Verdict $installVerdict `
    -Detail 'shared run backing S1/S4/S6: first run success verdict'
Add-Result -Id 'S4' -Title 'First project' -Suite 'tests/test-install-e2e.ps1' -Verdict $installVerdict `
    -Detail 'shared run backing S1/S4/S6: first-project creation + trial commit passes guardians'
Add-Result -Id 'S6' -Title 'Cold session (session-start)' -Suite 'tests/test-install-e2e.ps1' -Verdict $installVerdict `
    -Detail 'shared run backing S1/S4/S6: tools/session-preflight.sh reports READY'

# --- S2: re-run without changes ----------------------------------------------
Write-Output ""
Write-Output "=== Running tests/test-questionnaire-update-mode.ps1 (backs S2) ==="
$updateRun = Invoke-PsSuite -RelativePath 'tests\test-questionnaire-update-mode.ps1'
Write-Output $updateRun.Output
Add-Result -Id 'S2' -Title 'Re-run without changes' -Suite 'tests/test-questionnaire-update-mode.ps1' -Verdict (ConvertTo-Verdict ($updateRun.Exit -eq 0)) `
    -Detail 'update-mode re-run: "Nothing changed" verdict, empty porcelain'

# --- S3: resume after a forced stop ------------------------------------------
Write-Output ""
Write-Output "=== Running tests/test-questionnaire-resume.ps1 (backs S3) ==="
$resumeRun = Invoke-PsSuite -RelativePath 'tests\test-questionnaire-resume.ps1'
Write-Output $resumeRun.Output
Add-Result -Id 'S3' -Title 'Resume after a forced stop' -Suite 'tests/test-questionnaire-resume.ps1' -Verdict (ConvertTo-Verdict ($resumeRun.Exit -eq 0)) `
    -Detail 'forced stop after "clone", resumed without re-asking answered questions'

# --- S5: a guardian refuses, then accepts ------------------------------------
Write-Output ""
Write-Output "=== Running tests/test-guardian-secret-refusal.sh (backs S5) ==="
$secretRun = Invoke-BashSuite -RelativePath 'tests/test-guardian-secret-refusal.sh'
Write-Output $secretRun.Output
Add-Result -Id 'S5' -Title 'A guardian refuses, then accepts' -Suite 'tests/test-guardian-secret-refusal.sh' -Verdict (ConvertTo-Verdict ($secretRun.Exit -eq 0)) `
    -Detail 'check-secrets.sh: refuses a staged ghp_ token, accepts once removed'

# --- S7, S8: the assistant and the web package, through two providers ---------
Write-Output ""
Write-Output "=== Test-mode installation for S7/S8 ==="
$harnessRoot = Join-Path $env:TEMP ("sb-acceptance-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $harnessRoot | Out-Null
$answers = Get-Content -Raw -Encoding UTF8 (Join-Path $RepoRoot 'tests\fixtures\install-answers.sample.json') | ConvertFrom-Json
$answers.workspacePath = Join-Path $harnessRoot 'workspace'
$answersPath = Join-Path $harnessRoot 'answers.json'
$answers | ConvertTo-Json -Depth 5 | Set-Content -Path $answersPath -Encoding UTF8
$installOut = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $RepoRoot 'install.ps1') -Source $RepoRoot -AnswersFile $answersPath -TestMode -TestRoot $harnessRoot 2>&1 | ForEach-Object { "$_" }
$harnessInstallOk = ($LASTEXITCODE -eq 0)
Write-Output ($installOut | Select-Object -Last 3)
$harnessClone = (Join-Path $answers.workspacePath 'second-brain') -replace '\\', '/'

foreach ($scenario in @(
        @{ Id = 'S7'; Title = 'The assistant answers (two providers)' },
        @{ Id = 'S8'; Title = 'Web package, by equivalence' })) {
    $perProvider = @()
    foreach ($provider in @('claude', 'codex')) {
        if (-not $harnessInstallOk) {
            $perProvider += [PSCustomObject]@{ Provider = $provider; Exit = 3; Line = 'INDETERMINE (the test-mode installation for the harness failed)' }
            continue
        }
        Write-Output ""
        Write-Output "=== Running tools/acceptance-harness.sh --scenario $($scenario.Id) --provider $provider ==="
        $run = Invoke-BashSuite -RelativePath 'tools/acceptance-harness.sh' -Arguments @('--scenario', $scenario.Id, '--provider', $provider, '--clone', $harnessClone, '--runs', '3')
        Write-Output $run.Output
        $line = (@($run.Output -split "`r?`n" | Where-Object { $_ -match '^(PASS|FAIL|SKIP|INDETERMINE)' }) | Select-Object -Last 1)
        $perProvider += [PSCustomObject]@{ Provider = $provider; Exit = $run.Exit; Line = "$line" }
    }
    $codes = @($perProvider | ForEach-Object { $_.Exit })
    $verdict = if ($codes -contains 1) { 'FAIL' }
        elseif (@($codes | Where-Object { $_ -eq 0 }).Count -eq $codes.Count) { 'PASS' }
        elseif (@($codes | Where-Object { $_ -eq 2 }).Count -eq $codes.Count) { 'SKIP (no provider credentials in CI)' }
        else { 'INDETERMINE (two providers required, see detail)' }
    $detail = ($perProvider | ForEach-Object { "$($_.Provider): $($_.Line)" }) -join '; '
    if ($scenario.Id -eq 'S8') { $detail += '; not proven: the upload gesture in a web interface' }
    Add-Result -Id $scenario.Id -Title $scenario.Title -Suite 'tools/acceptance-harness.sh' -Verdict $verdict -Detail $detail
}

# The harness installation is this runner's own temporary folder: removed
# the same way the install suites remove theirs (bash rm -rf copes with the
# long paths the tree carries).
try { & (Resolve-BashExe) -c "rm -rf -- '$($harnessRoot -replace '\\','/')'" } catch { }

# --- S9: no Git, no admin rights -----------------------------------------------
Write-Output ""
Write-Output "=== Running tests/test-install-standard-user.ps1 (backs S9) ==="
$s9Run = Invoke-PsSuite -RelativePath 'tests\test-install-standard-user.ps1'
Write-Output $s9Run.Output
if ($s9Run.Exit -eq 3) {
    Write-Output ""
    Write-Output "=== Running tests/test-bootstrap-no-git.ps1 (S9, local same-account half) ==="
    $halfRun = Invoke-PsSuite -RelativePath 'tests\test-bootstrap-no-git.ps1'
    Write-Output $halfRun.Output
    $half = ConvertTo-Verdict ($halfRun.Exit -eq 0)
    Add-Result -Id 'S9' -Title 'No Git, no admin rights' -Suite 'tests/test-install-standard-user.ps1' `
        -Verdict 'INDETERMINE (a disposable machine is required for the standard account)' `
        -Detail "local half, same account, no Git on PATH (tests/test-bootstrap-no-git.ps1): $half"
}
else {
    Add-Result -Id 'S9' -Title 'No Git, no admin rights' -Suite 'tests/test-install-standard-user.ps1' -Verdict (ConvertTo-Verdict ($s9Run.Exit -eq 0)) `
        -Detail 'published bootstrap line under a standard account, no Git on PATH; negative control: administrator-only write refused'
}

# --- S10: offline commit ------------------------------------------------------
Write-Output ""
Write-Output "=== Running tests/test-guardian-offline-commit.sh (backs S10) ==="
$offlineRun = Invoke-BashSuite -RelativePath 'tests/test-guardian-offline-commit.sh'
Write-Output $offlineRun.Output
Add-Result -Id 'S10' -Title 'Offline commit' -Suite 'tests/test-guardian-offline-commit.sh' -Verdict (ConvertTo-Verdict ($offlineRun.Exit -eq 0)) `
    -Detail 'no guardian calls the network; standalone.sh commit survives a poisoned proxy'

# --- T21: nominal flow shows no atelier vocabulary (Mission 174, step 5) -------
Write-Output ""
Write-Output "=== Running tests/test-nominal-flow-no-atelier-vocabulary.ps1 (T21) ==="
$noAtelierRun = Invoke-PsSuite -RelativePath 'tests\test-nominal-flow-no-atelier-vocabulary.ps1'
Write-Output $noAtelierRun.Output
Add-Result -Id 'T21' -Title 'No atelier vocabulary in the nominal flow' -Suite 'tests/test-nominal-flow-no-atelier-vocabulary.ps1' -Verdict (ConvertTo-Verdict ($noAtelierRun.Exit -eq 0)) `
    -Detail 'fresh install + session opening + trial commit: combined output carries no atelier name/word'

Write-Output ""
Write-Output "=== Environment fingerprint (after) ==="
$after = Get-EnvironmentFingerprint
Write-Output "  PATH SHA-256: $($after.PathHash)"
Write-Output "  .claude/skills entries: $($after.ClaudeSkills.Count)"
Write-Output "  .codex/skills entries: $($after.CodexSkills.Count)"
Write-Output "  .agents/skills entries: $($after.CodexAgentsSkills.Count)"
Write-Output "  .local/bin entries: $($after.LocalBin.Count)"

$pathIdentical = ($after.PathHash -eq $before.PathHash)
$claudeIdentical = (@(Compare-Object $before.ClaudeSkills $after.ClaudeSkills).Count -eq 0)
$codexIdentical = (@(Compare-Object $before.CodexSkills $after.CodexSkills).Count -eq 0)
$agentsIdentical = (@(Compare-Object $before.CodexAgentsSkills $after.CodexAgentsSkills).Count -eq 0)
$localBinIdentical = (@(Compare-Object $before.LocalBin $after.LocalBin).Count -eq 0)
$envIdentical = $pathIdentical -and $claudeIdentical -and $codexIdentical -and $agentsIdentical -and $localBinIdentical
Write-Output "  real environment identical before/after: $envIdentical"

# --- Ordered as the playbook numbers them -------------------------------------
$order = 'S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7', 'S8', 'S9', 'S10', 'T21'
$ordered = $order | ForEach-Object { $id = $_; $Results | Where-Object { $_.Id -eq $id } }

Write-Output ""
Write-Output "=== Acceptance summary ==="
foreach ($r in $ordered) {
    Write-Output ("  {0,-4} {1,-40} {2}" -f $r.Id, $r.Title, $r.Verdict)
}

$failCount = @($ordered | Where-Object { $_.Verdict -eq 'FAIL' }).Count
$s9Line = $ordered | Where-Object { $_.Id -eq 'S9' }
$s9Blocking = $RequireS9 -and ($s9Line.Verdict -ne 'PASS')

# --- Write the report, outside the repository --------------------------------
$sha = (git -C $RepoRoot rev-parse --short HEAD 2>$null)
if (-not $sha) { $sha = 'unknown' }
$tags = @(git -C $RepoRoot tag --points-at HEAD 2>$null)
$lines = New-Object System.Collections.Generic.List[string]
$lines.Add('# Second Brain -- acceptance report') | Out-Null
$lines.Add('') | Out-Null
$lines.Add("- Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')") | Out-Null
$lines.Add("- Local source: $RepoRoot") | Out-Null
$lines.Add("- HEAD: $sha") | Out-Null
$lines.Add("- Tags on HEAD: $(if ($tags.Count) { $tags -join ', ' } else { 'none' })") | Out-Null
$lines.Add("- Mode: test only (install.ps1 -TestMode / disposable sandbox git repos); the Owner's real environment was never touched.") | Out-Null
$lines.Add("- Real-environment fingerprint identical before/after: $envIdentical") | Out-Null
$lines.Add("- Verdicts: PASS, FAIL, SKIP (no provider credentials in CI), INDETERMINE (cause named); never PASS by default.") | Out-Null
$lines.Add('') | Out-Null
$lines.Add('| Scenario | Title | Verdict | Delegated to | Detail |') | Out-Null
$lines.Add('|---|---|---|---|---|') | Out-Null
foreach ($r in $ordered) {
    $lines.Add("| $($r.Id) | $($r.Title) | $($r.Verdict) | $($r.Suite) | $($r.Detail) |") | Out-Null
}
Set-Content -Path $reportPath -Value $lines -Encoding UTF8
Write-Output ""
Write-Output "Report written to: $reportPath"

if ($failCount -eq 0 -and -not $s9Blocking -and $envIdentical) {
    Write-Output ""
    Write-Output "=== RESULT: PASS ($($ordered.Count) lines, 0 FAIL) ==="
    exit 0
}
else {
    Write-Output ""
    Write-Output "=== RESULT: FAIL ($failCount FAIL line(s); S9 required and not PASS: $s9Blocking; environment identical: $envIdentical) ==="
    exit 1
}
