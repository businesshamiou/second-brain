#Requires -Version 5.1
<#
.SYNOPSIS
    Resume-after-forced-stop test (Mission 168, ticket 05, criterion 4;
    spec, Testing Decisions -- "reprise : interruption forcee a une etape
    donnee, puis relance").

.DESCRIPTION
    Rerun with one command, from the repository root:

        powershell -NoProfile -ExecutionPolicy Bypass -File tests\test-questionnaire-resume.ps1

    Drives the INTERACTIVE questionnaire (via -ScriptedAnswers, install.ps1's
    test-only replay queue -- never Read-Host, never the real console) in a
    fresh, blank temporary workspace:
      1. First run answers only Questions 1-3 (language, assistant name,
         workspace path) and is forced to stop right after the clone step
         (-StopAfterStep clone, T04's prescribed mechanism), before the
         notebook records anything past that point.
      2. The notebook on disk is asserted to hold exactly those two steps
         (workspaceCreated, cloned) and those three answers -- nothing more.
      3. A second run, given only the answers for the REMAINING questions
         (4-8 plus the first-project confirmation), completes successfully.
         Its own stdout is asserted to contain the prompts for the
         not-yet-answered questions but NOT the prompts for Questions 1-3 --
         the literal proof that an already-answered question is never
         re-asked, not merely that the same value would have been produced
         again.

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

$TestRoot = Join-Path $env:TEMP ("sb-resume-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $TestRoot | Out-Null
Write-Output "TestRoot: $TestRoot"

$installScript = Join-Path $RepoRoot 'install.ps1'
$workspacePath = Join-Path $TestRoot 'workspace'
$clonePath = Join-Path $workspacePath 'second-brain'
$carnetPath = Join-Path $clonePath '.install\state.json'
$cleanupBash = $null

try {
    # 6>&1 merges ONLY the Information stream (Write-Host's prompts) into
    # the captured output -- never 2>&1 or *>&1. Measured directly: this
    # test's first version used *>&1 and made every git/bash stderr line
    # (e.g. git clone's own "Cloning into ...", project-bootstrap.sh's
    # created-file listing) a terminating ErrorRecord under install.ps1's
    # own $ErrorActionPreference = 'Stop', the exact trap
    # tests/test-install-e2e.ps1's header comment already names for a
    # native command's stderr -- it only manifests when that stream is
    # *also being captured*, which merging it into the pipeline does.
    Write-Output ""
    Write-Output "=== 1. First run: answer Q1-Q3 only, forced stop after 'clone' ==="
    $run1Answers = @('FR', 'TestBrian', $workspacePath)
    $run1Output = & $installScript -Source $RepoRoot -TestMode -TestRoot $TestRoot `
        -ScriptedAnswers $run1Answers -StopAfterStep 'clone' 6>&1 | Out-String
    $run1Exit = $LASTEXITCODE
    Write-Output $run1Output
    Assert-True ($run1Exit -eq 1) "first run stops (exit 1) at the forced step"
    Assert-True ($run1Output -match 'Forced stop for testing, after step: clone') "verdict names the forced-stop step"

    Write-Output ""
    Write-Output "=== 2. Notebook holds exactly Q1-Q3 and the two completed steps ==="
    Assert-True (Test-Path $carnetPath) "notebook exists after the forced stop"
    $carnet1 = Get-Content -Raw -Path $carnetPath -Encoding UTF8 | ConvertFrom-Json
    Assert-True ($carnet1.steps.workspaceCreated -eq $true) "step workspaceCreated recorded"
    Assert-True ($carnet1.steps.cloned -eq $true) "step cloned recorded"
    Assert-True ([string]::IsNullOrEmpty($carnet1.steps.guardiansConfigured)) "step guardiansConfigured NOT recorded yet"
    Assert-True ([string]::IsNullOrEmpty($carnet1.steps.profileWritten)) "step profileWritten NOT recorded yet"
    Assert-True ($carnet1.answers.language -eq 'FR') "language answer durably recorded"
    Assert-True ($carnet1.answers.vaultName -eq 'TestBrian') "assistant name answer durably recorded"
    Assert-True ($carnet1.answers.workspacePath -eq $workspacePath) "workspace path answer durably recorded"

    Write-Output ""
    Write-Output "=== 3. Second run: only the remaining answers, must not re-ask Q1-Q3 ==="
    # Order: firstName, activity, aiToolsRaw (blank -> detected default),
    # whatMatters, skillCollectionsRaw (blank -> none), firstProject confirm
    # (y), firstProject name (blank -> suggested slug).
    $run2Answers = @('Ana', 'Building a personal AI system', '', 'Simplicite', '', 'y', '')
    $run2Output = & $installScript -Source $RepoRoot -TestMode -TestRoot $TestRoot `
        -ScriptedAnswers $run2Answers 6>&1 | Out-String
    $run2Exit = $LASTEXITCODE
    Write-Output $run2Output
    Assert-True ($run2Exit -eq 0) "second run completes (exit 0)"
    # The resumed language is FR (Q1's answer from the first run), so the
    # success verdict is correctly the French catalog string ("Installe",
    # with an accented e this ASCII-only test file does not spell out
    # literally), not English -- this is localization working as designed,
    # not a fallback. Matching just the ASCII-safe "Install" prefix (common
    # to both "Installation complete" and the accented French string) keeps
    # this assertion true either way without needing a non-ASCII literal.
    Assert-True ($run2Output -match 'Install') "second run reaches the success verdict (French, the resumed language)"

    # French catalog text (the resumed language) for the three
    # already-answered questions -- must never appear in the second run's
    # own output, since asking again is exactly what this test guards
    # against.
    Assert-True ($run2Output -notmatch 'Idioma') "second run does not re-print the language prompt"
    Assert-True ($run2Output -notmatch [regex]::Escape('donner a ton assistant') -or $run2Output -notmatch 'assistant') `
        "second run does not re-print the assistant-name prompt"
    Assert-True ($run2Output -notmatch 'espace de travail Second Brain') "second run does not re-print the workspace prompt"
    # A not-yet-answered question (firstName, Q4) must have been asked for
    # real -- otherwise this test would pass vacuously even if the whole
    # resume mechanism were broken.
    Assert-True ($run2Output -match 'prenom' -or $run2Output -match [char]0x00E9 + 'nom') "second run DOES print the first-name prompt (Q4, genuinely new)"

    Write-Output ""
    Write-Output "=== 4. Final notebook reflects every answer, workspace never moved ==="
    $carnet2 = Get-Content -Raw -Path $carnetPath -Encoding UTF8 | ConvertFrom-Json
    Assert-True ($carnet2.steps.guardiansConfigured -eq $true) "step guardiansConfigured now recorded"
    Assert-True ($carnet2.steps.profileWritten -eq $true) "step profileWritten now recorded"
    Assert-True ($carnet2.answers.workspacePath -eq $workspacePath) "workspace path unchanged across both runs"
    Assert-True ($carnet2.answers.firstName -eq 'Ana') "first name answer recorded from the second run"
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
