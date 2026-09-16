#Requires -Version 5.1
<#
.SYNOPSIS
    The Windows bootstrap installs from a PATH with no Git and no uv
    (Mission 183-C01, Decision 142112 point 5).

.DESCRIPTION
    Plays bootstrap.ps1 end to end, in test mode, in a child process whose
    PATH has every directory holding git.exe, uv.exe or pre-commit.exe
    removed -- the state of a workstation where nothing is installed yet.
    The repository is taken from this local checkout (-RepoUrl and -RawBase
    point at it, branch of the current HEAD), so the test plays the exact
    committed tree, offline apart from the pinned downloads themselves
    (PortableGit, uv, pre-commit, a managed Python).

    Checks:
      - the child PATH really has no git.exe before the bootstrap runs
        (control: otherwise the test proves nothing);
      - the bootstrap exits 0 with the installer's success verdict;
      - Git, uv, pre-commit and a Python interpreter all sit under the test
        profile;
      - the PortableGit directory was persisted to the (simulated) user
        PATH by install.ps1 itself;
      - the Owner's real environment fingerprint is identical before/after.

    This is the local, same-account half of S9. The other half -- a
    standard, non-administrator account -- needs a disposable machine and
    is played by tests/test-install-standard-user.ps1 in CI.

    Rerun with:
        powershell -NoProfile -ExecutionPolicy Bypass -File tests\test-bootstrap-no-git.ps1 [-KeepTemp]
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

. (Join-Path $RepoRoot 'tools\environment-fingerprint.ps1')
$before = Get-EnvironmentFingerprint

$TestRoot = Join-Path $env:TEMP ("sb-bootstrap-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $TestRoot | Out-Null
Write-Output "TestRoot: $TestRoot"

try {
    $branch = (& git -C $RepoRoot rev-parse --abbrev-ref HEAD).Trim()
    $answers = Get-Content -Raw -Encoding UTF8 (Join-Path $RepoRoot 'tests\fixtures\install-answers.sample.json') | ConvertFrom-Json
    $answers.workspacePath = Join-Path $TestRoot 'workspace'
    $answersPath = Join-Path $TestRoot 'answers.json'
    $answers | ConvertTo-Json -Depth 5 | Set-Content -Path $answersPath -Encoding UTF8

    # A PATH without any directory that holds git, uv or pre-commit.
    $kept = @($env:Path -split ';' | Where-Object {
        $_ -ne '' -and
        -not (Test-Path (Join-Path $_ 'git.exe')) -and
        -not (Test-Path (Join-Path $_ 'uv.exe')) -and
        -not (Test-Path (Join-Path $_ 'pre-commit.exe'))
    })
    $bareRoot = Join-Path $TestRoot 'bare-path.txt'
    ($kept -join ';') | Set-Content -Path $bareRoot -Encoding ASCII

    $child = @"
`$env:Path = (Get-Content -Raw '$bareRoot').Trim()
if (Get-Command git.exe -ErrorAction SilentlyContinue) { Write-Output 'CONTROL: git.exe still on PATH'; exit 97 }
Write-Output 'CONTROL: no git.exe on PATH'
& '$(Join-Path $RepoRoot 'bootstrap.ps1')' -Ref '$branch' -RepoUrl '$RepoRoot' -RawBase '$RepoRoot' -TestMode -TestRoot '$TestRoot' -AnswersFile '$answersPath'
exit `$LASTEXITCODE
"@
    $childPath = Join-Path $TestRoot 'child.ps1'
    $child | Set-Content -Path $childPath -Encoding UTF8

    Write-Output ""
    Write-Output "=== Bootstrap with no Git and no uv on PATH ==="
    $output = & powershell -NoProfile -ExecutionPolicy Bypass -File $childPath 2>&1 | ForEach-Object { "$_" }
    $rc = $LASTEXITCODE
    $output | Select-Object -Last 12 | ForEach-Object { Write-Output "    $_" }

    Assert-True (@($output) -contains 'CONTROL: no git.exe on PATH') "control: the child PATH holds no git.exe before the bootstrap runs"
    Assert-True ($rc -eq 0) "bootstrap.ps1 exits 0 (exit $rc)"
    Assert-True ((@($output) -join "`n") -match 'Installation complete') "the installer's success verdict is printed"

    $profileRoot = Join-Path $TestRoot 'profile'
    $gitExe = Join-Path $profileRoot '.local\share\second-brain\PortableGit\cmd\git.exe'
    Assert-True (Test-Path $gitExe) "Git sits in the test profile ($gitExe)"
    Assert-True (Test-Path (Join-Path $profileRoot '.local\bin\uv.exe')) "uv sits in the test profile"
    Assert-True (Test-Path (Join-Path $profileRoot '.local\bin\pre-commit.exe')) "pre-commit sits in the test profile"
    $python = @(Get-ChildItem -Path $profileRoot -Recurse -Filter 'python.exe' -ErrorAction SilentlyContinue | Select-Object -First 1)
    Assert-True ($python.Count -eq 1) "a Python interpreter sits in the test profile ($(if ($python.Count) { $python[0].FullName }))"

    $simulatedPath = Join-Path $TestRoot 'simulated-user-path.txt'
    $persisted = if (Test-Path $simulatedPath) { @(Get-Content $simulatedPath) } else { @() }
    Assert-True ($persisted -contains (Split-Path $gitExe -Parent)) "install.ps1 persisted the PortableGit directory to the user PATH"
}
catch {
    Write-Output "  FAIL - unhandled error: $($_.Exception.Message)"
    $failures.Add("unhandled error: $($_.Exception.Message)") | Out-Null
}

$after = Get-EnvironmentFingerprint
Assert-True ($after.PathHash -eq $before.PathHash) "real user PATH is byte-identical before/after"
Assert-True (@(Compare-Object $before.ClaudeSkills $after.ClaudeSkills).Count -eq 0) "real ~/.claude/skills listing is identical before/after"
Assert-True (@(Compare-Object $before.CodexSkills $after.CodexSkills).Count -eq 0) "real ~/.codex/skills listing is identical before/after"
Assert-True (@(Compare-Object $before.LocalBin $after.LocalBin).Count -eq 0) "real ~/.local/bin listing is identical before/after"

if ($KeepTemp) {
    Write-Output "TestRoot kept (-KeepTemp): $TestRoot"
}
else {
    . (Join-Path $RepoRoot 'tools\resolve-bash-exe.ps1')
    try { & (Resolve-BashExe) -c "rm -rf -- '$($TestRoot -replace '\\','/')'" } catch { }
    Write-Output "TestRoot removed: $TestRoot"
}

Write-Output ""
if ($failures.Count -eq 0) {
    Write-Output "=== RESULT: PASS (all checks green) ==="
    exit 0
}
Write-Output "=== RESULT: FAIL ($($failures.Count) check(s) failed) ==="
$failures | ForEach-Object { Write-Output "  - $_" }
exit 1
