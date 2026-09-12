#Requires -Version 5.1
<#
.SYNOPSIS
    Workspace-path validation test for install.ps1 (Mission 171-C01, step 3;
    spec -- "L'espace de travail n'est accepte que si le chemin est absolu
    et hors du depot source ; sinon message qui nomme la cause, propose un
    chemin valide, et repose la question. oui, non, y, n et une chaine
    vide sont refuses comme chemins.").

.DESCRIPTION
    Rerun with one command, from the repository root:

        powershell -NoProfile -ExecutionPolicy Bypass -File tests\test-install-workspace-path-validation.ps1

    Drives install.ps1's INTERACTIVE questionnaire via -ScriptedAnswers
    (its own test-only replay queue -- never Read-Host, never the real
    console), stopped right after the 'workspace' step
    (-StopAfterStep, the same forced-stop mechanism
    tests/test-questionnaire-resume.ps1 already uses) so each case runs in
    a couple of seconds: no git clone, no prerequisite install, only the
    language/assistant-name/workspace-path questions and the workspace
    New-Item.

    Four cases, each in its own fresh -TestRoot (Mission constraint: never
    the real user profile):
      1. A relative path is refused (a cause-naming message is printed,
         the question is asked again), then a valid absolute path outside
         the source repository is accepted.
      2. 'oui' is refused the same way, then a valid path is accepted --
         this is Defect 2's own physical proof: the literal 'oui' folder
         found under _trash-oui-20260912 (out of this Mission's scope,
         never touched here) is exactly what this case exists to prevent.
      3. A path INSIDE the source repository (the repository this test
         itself runs from) is refused, then a valid path outside it is
         accepted.
      4. A valid absolute path outside the source repository is accepted
         on the very first try -- no error message, no re-ask.

    Exit code 0 means every assertion passed. Exit code 1 means at least
    one did not; details are printed to stdout as each check runs.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path $PSScriptRoot -Parent
$installScript = Join-Path $RepoRoot 'install.ps1'
$failures = New-Object System.Collections.Generic.List[string]

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if ($Condition) { Write-Output "  PASS - $Message" }
    else { Write-Output "  FAIL - $Message"; $failures.Add($Message) | Out-Null }
}

function Invoke-WorkspaceCase {
    # $TestRoot = a fresh temporary directory. $ScriptedAnswers = the
    # language/assistant-name/workspace-path answers, in order. Always
    # stops right after the 'workspace' step (a forced stop, never a real
    # failure) -- so a workspace directory existing under $TestRoot is
    # this function's own proof that the loop eventually accepted an
    # answer. 6>&1 merges ONLY the Information stream (Write-Host's
    # prompts and error messages) into the captured output -- never 2>&1
    # or *>&1 (see tests/test-questionnaire-resume.ps1's own header
    # comment: that would wrap a native command's stderr as a terminating
    # NativeCommandError under install.ps1's $ErrorActionPreference =
    # 'Stop').
    param([string] $TestRoot, [string[]] $ScriptedAnswers)
    $output = & $installScript -Source $RepoRoot -TestMode -TestRoot $TestRoot `
        -ScriptedAnswers $ScriptedAnswers -StopAfterStep 'workspace' 6>&1 | Out-String
    return [PSCustomObject]@{ Output = $output; ExitCode = $LASTEXITCODE }
}

try {
    Write-Output ""
    Write-Output "=== 1. Relative path: refused, then a valid absolute path is accepted ==="
    $testRoot1 = Join-Path $env:TEMP ("sb-wksp-" + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force -Path $testRoot1 | Out-Null
    $workspace1 = Join-Path $testRoot1 'workspace'
    $result1 = Invoke-WorkspaceCase -TestRoot $testRoot1 -ScriptedAnswers @('EN', 'TestBrian', 'relative\path', $workspace1)
    Write-Output $result1.Output
    Assert-True ($result1.ExitCode -eq 1) "forced stop still reached (exit 1) -- the loop did not hang or crash"
    Assert-True ($result1.Output -match [regex]::Escape('is not an absolute path')) "a cause-naming message is printed for the relative path"
    Assert-True ($result1.Output -match 'Forced stop for testing, after step: workspace') "the question was re-asked and eventually reached the workspace step"
    Assert-True (Test-Path $workspace1) "the second, valid answer was accepted (workspace directory created)"

    Write-Output ""
    Write-Output "=== 2. 'oui': refused, then a valid absolute path is accepted (Defect 2) ==="
    $testRoot2 = Join-Path $env:TEMP ("sb-wksp-" + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force -Path $testRoot2 | Out-Null
    $workspace2 = Join-Path $testRoot2 'workspace'
    $result2 = Invoke-WorkspaceCase -TestRoot $testRoot2 -ScriptedAnswers @('EN', 'TestBrian', 'oui', $workspace2)
    Write-Output $result2.Output
    Assert-True ($result2.ExitCode -eq 1) "forced stop still reached (exit 1)"
    Assert-True ($result2.Output -match [regex]::Escape("is not a workspace path")) "a cause-naming message is printed for 'oui' (never silently accepted as a path)"
    Assert-True (Test-Path $workspace2) "the second, valid answer was accepted (workspace directory created)"
    Assert-True (-not (Test-Path (Join-Path $testRoot2 'oui'))) "no folder literally named 'oui' was ever created (the _trash-oui-20260912 defect, reproduced and closed)"

    Write-Output ""
    Write-Output "=== 3. Path inside the source repository: refused, then a valid path is accepted ==="
    $testRoot3 = Join-Path $env:TEMP ("sb-wksp-" + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force -Path $testRoot3 | Out-Null
    $workspace3 = Join-Path $testRoot3 'workspace'
    $result3 = Invoke-WorkspaceCase -TestRoot $testRoot3 -ScriptedAnswers @('EN', 'TestBrian', $RepoRoot, $workspace3)
    Write-Output $result3.Output
    Assert-True ($result3.ExitCode -eq 1) "forced stop still reached (exit 1)"
    Assert-True ($result3.Output -match [regex]::Escape('is inside the source repository')) "a cause-naming message is printed for a path inside the source repository"
    Assert-True (Test-Path $workspace3) "the second, valid answer was accepted (workspace directory created)"

    Write-Output ""
    Write-Output "=== 4. Valid absolute path outside the source: accepted on the first try ==="
    $testRoot4 = Join-Path $env:TEMP ("sb-wksp-" + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force -Path $testRoot4 | Out-Null
    $workspace4 = Join-Path $testRoot4 'workspace'
    $result4 = Invoke-WorkspaceCase -TestRoot $testRoot4 -ScriptedAnswers @('EN', 'TestBrian', $workspace4)
    Write-Output $result4.Output
    Assert-True ($result4.ExitCode -eq 1) "forced stop reached (exit 1) -- the only failure this run should hit"
    $noErrorPrinted = -not (
        $result4.Output -match [regex]::Escape('is not an absolute path') -or
        $result4.Output -match [regex]::Escape('is not a workspace path') -or
        $result4.Output -match [regex]::Escape('is inside the source repository')
    )
    Assert-True $noErrorPrinted "no validation error is printed for an already-valid path"
    Assert-True (Test-Path $workspace4) "the workspace directory was created at the given valid path"
}
catch {
    Write-Output "  FAIL - unhandled error: $($_.Exception.Message)"
    $failures.Add("unhandled error: $($_.Exception.Message)") | Out-Null
}
finally {
    foreach ($root in @($testRoot1, $testRoot2, $testRoot3, $testRoot4)) {
        if ($root -and (Test-Path $root)) {
            try { Remove-Item -Recurse -Force -Path $root -ErrorAction SilentlyContinue } catch { }
        }
    }
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
