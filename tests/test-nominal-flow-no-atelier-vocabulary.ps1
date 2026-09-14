#Requires -Version 5.1
<#
.SYNOPSIS
    End-to-end non-regression guardian (Mission 174, step 5, T21): a fresh
    install, a session opening, and a trial commit in the resulting project
    must never show a participant any name or word of the atelier.

.DESCRIPTION
    Rerun this exact test with one command, from the repository root:

        powershell -NoProfile -ExecutionPolicy Bypass -File tests\test-nominal-flow-no-atelier-vocabulary.ps1

    Replays the three phases the Mission's Objectif names -- "une
    installation neuve, suivie d'une session et d'un commit" -- in a single
    fresh, blank temporary workspace, capturing the FULL console output of
    each phase exactly as a real participant would see it:

      1. install.ps1, no sibling repository declared anywhere (the nominal
         case for every real participant), launched as a genuine child
         process with both stdout and stderr redirected to files
         (Start-Process, same technique as
         tests/test-install-log-line-count.ps1) -- a `$out = & script`
         capture inside this same process would miss text a nested bash.exe
         writes straight to the console, exactly the gap that let the old
         "depot frere introuvable en ../workshop-build" warning go
         unnoticed by every prior installer test.
      2. tools/session-preflight.sh in the freshly cloned second-brain
         ("opening a session").
      3. A trial commit in the first project created by the installer.

    All three phases' output is concatenated and checked against two
    things:
      (a) every name/word of Mission 174's own Doctrine rule 2 (the
          Owner's atelier -- repository names, machine/account identifiers,
          a legacy-project codename, all of it catalogued once by
          tools/check-private-patterns.sh's own PLAIN_PATTERNS and derived
          from there at runtime, Mission 176, rather than repeated here as
          a second literal copy) and a bare "Mission NNN" citation in a
          displayed message;
      (b) the exact defect strings step 3/4 of this Mission removed
          (regression guard on the specific fixes, not just the general
          vocabulary list).

    A single match anywhere fails the test and prints the offending line(s).

    -TestMode throughout; nothing this test does can reach the real profile
    (PATH, ~/.claude, ~/.codex) or the real workspace.

    Exit code 0 means the nominal flow showed nothing but participant-
    relevant output. Exit code 1 means at least one forbidden string was
    found; the offending line(s) and their source phase are printed.
#>

[CmdletBinding()]
param([switch] $KeepTemp)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path $PSScriptRoot -Parent
$failures = New-Object System.Collections.Generic.List[string]

. (Join-Path $RepoRoot 'tools\resolve-bash-exe.ps1')

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if ($Condition) { Write-Output "  PASS - $Message" }
    else { Write-Output "  FAIL - $Message"; $failures.Add($Message) | Out-Null }
}

# Mission 176: the three P4 (privacy) patterns are never written a second
# time into a tracked file -- tools/check-private-patterns.sh's own
# PLAIN_PATTERNS array is the sole source that already catalogs them
# (already exempted from its own sweep by pathspec). Derived here at
# runtime instead of duplicated as a literal; a missing source or an empty
# derived list fails loudly (throw) rather than silently running this
# sweep blind.
function Get-GuardianPrivatePatterns {
    param([string] $RepoRoot)
    $guardianPath = Join-Path $RepoRoot 'tools\check-private-patterns.sh'
    if (-not (Test-Path -LiteralPath $guardianPath)) {
        throw "Cannot derive P4 patterns -- guardian script not found: $guardianPath"
    }
    $text = Get-Content -Raw -LiteralPath $guardianPath
    $block = [regex]::Match($text, '(?s)PLAIN_PATTERNS=\((.*?)\)')
    if (-not $block.Success) {
        throw "Cannot derive P4 patterns -- PLAIN_PATTERNS array not found in $guardianPath"
    }
    $patterns = [regex]::Matches($block.Groups[1].Value, '"([^"]+)"') | ForEach-Object { $_.Groups[1].Value }
    if (-not $patterns -or @($patterns).Count -eq 0) {
        throw "Cannot derive P4 patterns -- PLAIN_PATTERNS array is empty in $guardianPath"
    }
    return @($patterns)
}
$PrivatePatterns = Get-GuardianPrivatePatterns -RepoRoot $RepoRoot

# Rule 2's own list, plus "Mission NNN" as a displayed-message pattern, plus
# the derived P4 patterns above. Real machine/account identifiers (rule 2:
# "noms de machine ou de compte") checked the same way
# check-private-patterns.sh does: exact strings, not guessed from
# environment variables (a participant's own machine name would trivially
# differ; this list is THIS repository's own known, already-catalogued leak
# class, per tools/check-private-patterns.sh).
$ForbiddenPatterns = @(
    'workshop-build',
    'workshop-production',
    '\bworkshops\b',
    '\bLegacy\b',
    'businesshamiou',
    'Mission [0-9]{2,3}(-C[0-9]+)?',
    # Exact defect strings this Mission's steps 3/4 removed -- regression
    # guard on the specific fixes, not just the general vocabulary list.
    'depot frere introuvable',
    'Pre-vol agregateur vault',
    'AVERTI \(hors depot'
) + $PrivatePatterns

# Reusable so the same detection logic backs both the real sweep (step 4)
# and the negative case (step 5). No Write-Output inside: a function's
# return value in PowerShell is EVERY unsuppressed pipeline write, not just
# its `return` expression -- printing here would silently turn the boolean
# callers expect into a System.Object[] (measured: this exact trap, on the
# first version of this function). Purely a detector; callers print.
function Test-ForbiddenPatterns {
    param([string[]] $Patterns, [string] $Text)
    $hitReports = @()
    foreach ($pattern in $Patterns) {
        $hits = @($Text -split "`n" | Select-String -Pattern $pattern)
        if ($hits.Count -gt 0) {
            $hitReports += [PSCustomObject]@{
                Pattern = $pattern
                Lines   = @($hits | ForEach-Object { $_.Line.Trim() })
            }
        }
    }
    return [PSCustomObject]@{
        AnyMatch = ($hitReports.Count -gt 0)
        Hits     = $hitReports
    }
}

$TestRoot = Join-Path $env:TEMP ("sb-noatelier-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $TestRoot | Out-Null
Write-Output ""
Write-Output "TestRoot: $TestRoot"

$AllPhaseOutput = New-Object System.Collections.Generic.List[string]

function Add-PhaseOutput {
    param([string] $Phase, [string] $Text)
    Write-Output ""
    Write-Output "--- captured output: $Phase ---"
    Write-Output $Text
    $AllPhaseOutput.Add("### $Phase`n$Text") | Out-Null
}

try {
    Write-Output ""
    Write-Output "=== 1. Fresh install, real child process, both streams captured, no sibling declared ==="
    $workspacePath = Join-Path $TestRoot 'workspace'
    $answersPath = Join-Path $TestRoot 'answers.json'
    $sampleAnswers = Get-Content -Raw -Path (Join-Path $PSScriptRoot 'fixtures\install-answers.sample.json') | ConvertFrom-Json
    $sampleAnswers.workspacePath = $workspacePath
    $sampleAnswers | ConvertTo-Json -Depth 10 | Set-Content -Path $answersPath -Encoding UTF8

    $installScript = Join-Path $RepoRoot 'install.ps1'
    $clonePath = Join-Path $workspacePath 'second-brain'
    $firstProjectPath = Join-Path $workspacePath $sampleAnswers.firstProject.name
    $stdoutPath = Join-Path $TestRoot 'install-stdout.log'
    $stderrPath = Join-Path $TestRoot 'install-stderr.log'
    $psExe = (Get-Process -Id $PID).Path
    if (-not $psExe) { $psExe = 'powershell.exe' }
    $argList = @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $installScript,
        '-Source', $RepoRoot, '-AnswersFile', $answersPath, '-TestMode', '-TestRoot', $TestRoot
    )
    # SECOND_BRAIN_SIBLING_REPO deliberately left unset: the nominal case for
    # every real participant is no declaration at all (step 3 of this
    # Mission).
    $proc = Start-Process -FilePath $psExe -ArgumentList $argList -NoNewWindow -Wait -PassThru `
        -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
    Assert-True ($proc.ExitCode -eq 0) "install.ps1 exits 0"
    $installOutput = (Get-Content -Path $stdoutPath -ErrorAction SilentlyContinue) + (Get-Content -Path $stderrPath -ErrorAction SilentlyContinue) | Out-String
    Add-PhaseOutput -Phase 'install.ps1 (fresh install)' -Text $installOutput

    # On a runner with no uv preinstalled (every GitHub-hosted Windows
    # runner), install.ps1 above bootstraps uv under its own -TestRoot
    # profile, but as a genuine separate process (Start-Process, needed to
    # capture nested bash.exe console text) -- so that $env:Path update dies
    # with it. Reproduced locally by hiding uv from PATH: this script's own
    # later bash/git calls then fail with "exec: uv: not found" at guardians
    # `vault-check-indexes-fresh`/`vault-check-index-weight`, matching CI.
    # Fixed by reusing the profile bin install.ps1 already made, on this
    # process's own PATH.
    $testProfileUvBin = Join-Path $TestRoot 'profile\.local\bin'
    if (Test-Path $testProfileUvBin) {
        $env:Path = "$testProfileUvBin;$env:Path"
    }

    Write-Output ""
    Write-Output "=== 2. Session opening: tools/session-preflight.sh in the fresh clone ==="
    $bashExe = Resolve-BashExe
    # bash's own `2>&1` (internal to the single bash.exe invocation) merges
    # its streams before PowerShell ever sees them -- never a PowerShell-level
    # redirection of a native command's stderr (the NativeCommandError trap
    # documented across this suite).
    $preflightOutput = & $bashExe -c "cd '$($clonePath -replace '\\','/')' && bash tools/session-preflight.sh 2>&1"
    $preflightExit = $LASTEXITCODE
    Assert-True ($preflightExit -eq 0) "session-preflight.sh exits 0 (READY)"
    Add-PhaseOutput -Phase 'session-preflight.sh (session opening)' -Text ($preflightOutput | Out-String)

    Write-Output ""
    Write-Output "=== 3. Trial commit in the first project ==="
    $journalScript = ($clonePath -replace '\\','/') + '/tools/append-journal.sh'
    $projectPosix = $firstProjectPath -replace '\\','/'
    $commitOutput = & $bashExe -c "cd '$projectPosix' && bash '$journalScript' . 'STATE: trial commit, Mission 174 step 5 no-atelier-vocabulary test' && git add -- state/journal.md && git commit -q -m 'Trial commit: no-atelier-vocabulary test' 2>&1"
    $commitExit = $LASTEXITCODE
    Assert-True ($commitExit -eq 0) "trial commit passes all project guardians (git commit exits 0)"
    Add-PhaseOutput -Phase 'trial commit in the first project' -Text ($commitOutput | Out-String)

    Write-Output ""
    Write-Output "=== 4. Forbidden-vocabulary sweep across all three phases ==="
    $combined = ($AllPhaseOutput -join "`n")
    $sweepResult = Test-ForbiddenPatterns -Patterns $ForbiddenPatterns -Text $combined
    foreach ($r in $sweepResult.Hits) {
        Write-Output "  FAIL - forbidden pattern '$($r.Pattern)' found:"
        foreach ($line in $r.Lines) { Write-Output "      $line" }
        $failures.Add("forbidden pattern '$($r.Pattern)' found in nominal flow output") | Out-Null
    }
    Assert-True (-not $sweepResult.AnyMatch) "no atelier name/word, Mission-number citation, or removed defect string appears anywhere in the nominal flow"

    Write-Output ""
    Write-Output "=== 5. Negative case: the sweep still detects a P4 pattern when present ==="
    # Built at runtime from the derived array (never a literal P4 string in
    # this tracked file) and fed only to the in-memory sweep, never written
    # to disk (Mission 176 rule 4: a green suite that detects nothing is
    # worse than the defect it fixed).
    $syntheticLeak = "some diagnostic line mentions $($PrivatePatterns[0]) in passing"
    $negativeResult = Test-ForbiddenPatterns -Patterns $ForbiddenPatterns -Text $syntheticLeak
    foreach ($r in $negativeResult.Hits) {
        Write-Output "  detected (expected) - pattern '$($r.Pattern)' matched $($r.Lines.Count) line(s)"
    }
    Assert-True $negativeResult.AnyMatch "sweep detects a fabricated P4 pattern ($($PrivatePatterns[0])) built at runtime, never written to disk"
}
catch {
    Write-Output "  FAIL - unhandled error: $($_.Exception.Message)"
    $failures.Add("unhandled error: $($_.Exception.Message)") | Out-Null
}
finally {
    if (-not $KeepTemp) {
        $cleanupBash = Resolve-BashExe
        & $cleanupBash -c "rm -rf -- '$($TestRoot -replace '\\','/')'"
        Write-Output ""
        Write-Output "TestRoot removed: $TestRoot"
    }
    else {
        Write-Output ""
        Write-Output "TestRoot kept (-KeepTemp): $TestRoot"
    }
}

Write-Output ""
if ($failures.Count -gt 0) {
    Write-Output "=== FAILURES ($($failures.Count)) ==="
    $failures | ForEach-Object { Write-Output "  - $_" }
    exit 1
}
Write-Output "All assertions passed."
exit 0
