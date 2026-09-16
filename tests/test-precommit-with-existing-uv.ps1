#Requires -Version 5.1
<#
.SYNOPSIS
    The prerequisites step installs pre-commit when uv is already present
    somewhere else than its own tool directory (Mission 183-C01).

.DESCRIPTION
    Resolve-OrInstall-PreCommit looked for pre-commit.exe next to uv.exe.
    `uv tool install` puts it in uv's tool bin directory instead
    (`uv tool dir --bin`). The two coincide only when this module installed
    uv itself; a uv reused from elsewhere (winget, scoop, a CI step) stopped
    the install with "pre-commit.exe is missing at the expected path"
    (CI run 35157346970, acceptance job).

    This test copies the machine's uv.exe into an unrelated folder, builds a
    PATH where that copy is the only uv and no pre-commit is reachable, and
    runs Assure-Prerequisites in test mode (every uv folder redirected under
    this test's own root; the real profile is never written).

    Checks:
      - control: uv resolves to the copy, pre-commit resolves nowhere;
      - Assure-Prerequisites completes;
      - pre-commit.exe sits in the redirected tool bin directory, not next
        to uv.exe, and resolves on this process's PATH afterwards;
      - that directory was handed to the persistent PATH hook.

    Needs network access to PyPI (and to uv's installer when this machine
    has no uv), like every other install test.

    usage: tests/test-precommit-with-existing-uv.ps1
#>

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path $PSScriptRoot -Parent
$failures = New-Object System.Collections.Generic.List[string]

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if ($Condition) { Write-Output "  PASS - $Message" }
    else { Write-Output "  FAIL - $Message"; $failures.Add($Message) | Out-Null }
}

$TestRoot = Join-Path $env:TEMP ("sb-precommit-uv-" + [Guid]::NewGuid().ToString('N'))
$uvDir = Join-Path $TestRoot 'uv-elsewhere'
New-Item -ItemType Directory -Force -Path $uvDir | Out-Null
Write-Output "TestRoot: $TestRoot"

# A uv binary to reuse: this machine's own if it has one, otherwise one the
# prerequisites module installs into a side folder of this test's root (the
# GitHub Windows runner carries no uv on PATH).
$realUv = Get-Command uv.exe -ErrorAction SilentlyContinue
if ($realUv) {
    $uvSource = $realUv.Source
}
else {
    . (Join-Path $RepoRoot 'tools\prerequisites.ps1')
    $sideContext = [PSCustomObject]@{ TestMode = $true; ProfileRoot = (Join-Path $TestRoot 'uv-source') }
    New-Item -ItemType Directory -Force -Path $sideContext.ProfileRoot | Out-Null
    $uvSource = (Resolve-OrInstall-Uv -Context $sideContext -Lock (Get-PrerequisitesLock).uv).UvExe
}
Copy-Item $uvSource (Join-Path $uvDir 'uv.exe')
Write-Output "uv copied from: $uvSource"

$originalPath = $env:Path
try {
    $env:Path = (($env:Path -split ';') | Where-Object {
            $_ -ne '' -and
            -not (Test-Path (Join-Path $_ 'uv.exe')) -and
            -not (Test-Path (Join-Path $_ 'pre-commit.exe'))
        }) -join ';'
    $env:Path = "$uvDir;$env:Path"

    $uvNow = (Get-Command uv.exe -ErrorAction SilentlyContinue).Source
    Assert-True ($uvNow -eq (Join-Path $uvDir 'uv.exe')) "control: uv resolves to the copy outside its tool directory ($uvNow)"
    Assert-True ($null -eq (Get-Command pre-commit.exe -ErrorAction SilentlyContinue)) "control: no pre-commit reachable before the step"

    . (Join-Path $RepoRoot 'tools\prerequisites.ps1')
    $context = [PSCustomObject]@{ TestMode = $true; ProfileRoot = (Join-Path $TestRoot 'profile') }
    New-Item -ItemType Directory -Force -Path $context.ProfileRoot | Out-Null
    $script:persisted = New-Object System.Collections.Generic.List[string]
    $hook = { param($c, $entry) $script:persisted.Add($entry) | Out-Null }

    $ErrorActionPreference = 'Continue'
    $result = $null
    $thrown = $null
    try { $result = Assure-Prerequisites -Context $context -AddPersistentPathEntry $hook }
    catch { $thrown = $_.Exception.Message }
    $ErrorActionPreference = 'Stop'

    Assert-True ($null -eq $thrown) "Assure-Prerequisites completes ($thrown)"
    if ($result) {
        $expectedDir = Join-Path $context.ProfileRoot '.local\bin'
        Assert-True ($result.PreCommit.PreCommitExe -eq (Join-Path $expectedDir 'pre-commit.exe')) "pre-commit.exe sits in uv's redirected tool bin directory ($($result.PreCommit.PreCommitExe))"
        Assert-True (Test-Path $result.PreCommit.PreCommitExe) "pre-commit.exe exists on disk"
        $resolved = (Get-Command pre-commit.exe -ErrorAction SilentlyContinue).Source
        Assert-True ($resolved -eq $result.PreCommit.PreCommitExe) "pre-commit resolves on this process's PATH afterwards ($resolved)"
        Assert-True ($script:persisted -contains $expectedDir) "the tool bin directory was handed to the persistent PATH hook"
    }
}
finally {
    $env:Path = $originalPath
}

. (Join-Path $RepoRoot 'tools\resolve-bash-exe.ps1')
try { & (Resolve-BashExe) -c "rm -rf -- '$($TestRoot -replace '\\','/')'" } catch { }
Write-Output "TestRoot removed: $TestRoot"

Write-Output ""
if ($failures.Count -eq 0) {
    Write-Output "=== RESULT: PASS (all checks green) ==="
    exit 0
}
Write-Output "=== RESULT: FAIL ($($failures.Count) check(s) failed) ==="
$failures | ForEach-Object { Write-Output "  - $_" }
exit 1
