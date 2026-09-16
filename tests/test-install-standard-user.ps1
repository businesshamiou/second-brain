#Requires -Version 5.1
<#
.SYNOPSIS
    S9: the published bootstrap line installs Second Brain under a standard
    (non-administrator) Windows account with no Git on PATH, and nothing
    in it can elevate (Mission 183-C01, Decision 142112 point 5).

.DESCRIPTION
    DISPOSABLE MACHINES ONLY. This test creates a local user account. It
    refuses to run unless the environment variable SB_DISPOSABLE_MACHINE is
    1 (set by the CI job on a throwaway GitHub-hosted runner) and the
    current process is elevated (needed to create the account). Anywhere
    else it prints "INDETERMINE" and exits 3 -- never PASS.

    Mechanism (chosen over Start-Process -Credential, which is unreliable
    without an interactive session): a scheduled task registered with
    schtasks /RU <account> /RL LIMITED runs a small script as that account.
    The script builds its own PATH without any directory holding git.exe,
    uv.exe or pre-commit.exe -- the runner's machine PATH carries Git --
    then:
      1. records who it is and whether it is in Administrators (must be
         False);
      2. records `where.exe git` (must find nothing);
      3. NEGATIVE CONTROL: tries an administrator-only write (a key under
         HKLM:\SOFTWARE) -- must be refused;
      4. runs the published line (INSTALL.md) with -Ref pointing at the
         commit under test and -AnswersFile, and records its exit code and
         output;
      5. records whether Git landed in the account's own profile and in
         the account's own user PATH (HKCU).
    Before that, the same administrator-only write is tried as the runner's
    own (administrator) account: it must SUCCEED, otherwise the negative
    control proves nothing.

    usage (CI):
        $env:SB_DISPOSABLE_MACHINE = '1'
        tests\test-install-standard-user.ps1 -Ref <sha-or-tag> -RawBase <raw url at that ref>

    Exit code: 0 PASS, 1 FAIL, 3 INDETERMINE (not a disposable machine).
#>

[CmdletBinding()]
param(
    [string] $Ref = '',
    [string] $RawBase = '',
    [string] $RepoUrl = 'https://github.com/businesshamiou/second-brain.git',
    [string] $AccountName = 'sbparticipant',
    [int] $TimeoutMinutes = 40
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path $PSScriptRoot -Parent
$failures = New-Object System.Collections.Generic.List[string]

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if ($Condition) { Write-Output "  PASS - $Message" }
    else { Write-Output "  FAIL - $Message"; $failures.Add($Message) | Out-Null }
}

$principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($env:SB_DISPOSABLE_MACHINE -ne '1' -or -not $isAdmin) {
    Write-Output "INDETERMINE (S9 needs a disposable machine: set SB_DISPOSABLE_MACHINE=1 on a throwaway runner, elevated; this one is not)"
    exit 3
}
if ([string]::IsNullOrWhiteSpace($Ref)) { $Ref = (& git -C $RepoRoot rev-parse HEAD).Trim() }
if ([string]::IsNullOrWhiteSpace($RawBase)) { $RawBase = "https://raw.githubusercontent.com/businesshamiou/second-brain/$Ref" }

$work = 'C:\sb-s9'
New-Item -ItemType Directory -Force -Path $work | Out-Null

# --- control: the administrator-only write succeeds for an administrator ---
$probeKey = 'HKLM:\SOFTWARE\SecondBrainS9Probe'
$adminWrite = $false
try {
    New-Item -Path $probeKey -Force | Out-Null
    $adminWrite = Test-Path $probeKey
    Remove-Item -Path $probeKey -Force
}
catch { $adminWrite = $false }
Assert-True $adminWrite "control: the administrator-only write succeeds under the runner's administrator account (the probe can tell the two apart)"

# --- the disposable standard account ---
$chars = [char[]]'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789'
$password = -join (1..20 | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] }) + '#9a'
$secure = ConvertTo-SecureString $password -AsPlainText -Force
if (-not (Get-LocalUser -Name $AccountName -ErrorAction SilentlyContinue)) {
    New-LocalUser -Name $AccountName -Password $secure -AccountNeverExpires -PasswordNeverExpires -Description 'Second Brain S9 test account' | Out-Null
}
$inAdmins = @(Get-LocalGroupMember -Group 'Administrators' -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*\$AccountName" }).Count -gt 0
Assert-True (-not $inAdmins) "the test account is not a member of Administrators"
& icacls $work /grant "${AccountName}:(OI)(CI)F" | Out-Null

$answers = Get-Content -Raw -Encoding UTF8 (Join-Path $RepoRoot 'tests\fixtures\install-answers.sample.json') | ConvertFrom-Json
$answers.workspacePath = Join-Path $work 'workspace'
$answers | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $work 'answers.json') -Encoding UTF8

$published = "& ([scriptblock]::Create((irm $RawBase/bootstrap.ps1))) -Ref '$Ref' -RawBase '$RawBase' -RepoUrl '$RepoUrl' -Target '$work\source' -AnswersFile '$work\answers.json'"
$publishedPath = Join-Path $work 'published-line.ps1'
$published | Set-Content -Path $publishedPath -Encoding UTF8
$inner = @"
`$ErrorActionPreference = 'Continue'
`$log = '$work\s9.log'
function Say([string] `$line) { Add-Content -Path `$log -Value `$line -Encoding UTF8 }
`$env:Path = ((`$env:Path -split ';') | Where-Object { `$_ -ne '' -and -not (Test-Path (Join-Path `$_ 'git.exe')) -and -not (Test-Path (Join-Path `$_ 'uv.exe')) -and -not (Test-Path (Join-Path `$_ 'pre-commit.exe')) }) -join ';'
Say ("S9 WHOAMI: " + (whoami))
`$p = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
Say ("S9 ISADMIN: " + `$p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
`$where = (& where.exe git 2>`$null)
Say ("S9 WHERE_GIT: [" + (`$where -join ';') + "]")
try { New-Item -Path '$probeKey' -Force -ErrorAction Stop | Out-Null; Say 'S9 ELEVATED_WRITE: SUCCEEDED' } catch { Say ('S9 ELEVATED_WRITE: REFUSED (' + `$_.Exception.GetType().Name + ')') }
`$out = & powershell -NoProfile -ExecutionPolicy Bypass -File '$publishedPath' 2>&1 | ForEach-Object { "`$_" }
`$rc = `$LASTEXITCODE
`$out | ForEach-Object { Say ("S9 OUT: " + `$_) }
Say ("S9 RC: " + `$rc)
`$gitExe = Join-Path `$env:USERPROFILE '.local\share\second-brain\PortableGit\cmd\git.exe'
Say ("S9 GIT_IN_PROFILE: " + (Test-Path `$gitExe))
`$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
Say ("S9 GIT_IN_USER_PATH: " + ((`$userPath -split ';') -contains (Split-Path `$gitExe -Parent)))
Say 'S9 DONE'
"@
$innerPath = Join-Path $work 'run-as-participant.ps1'
$inner | Set-Content -Path $innerPath -Encoding UTF8
$logPath = Join-Path $work 's9.log'
if (Test-Path $logPath) { Clear-Content $logPath }

$taskName = 'SecondBrainS9'
& schtasks /Create /TN $taskName /TR "powershell -NoProfile -ExecutionPolicy Bypass -File $innerPath" /SC ONCE /ST 23:59 /RU $AccountName /RP $password /RL LIMITED /F | Out-Null
Assert-True ($LASTEXITCODE -eq 0) "scheduled task registered to run as $AccountName with limited rights (exit $LASTEXITCODE)"
& schtasks /Run /TN $taskName | Out-Null

$deadline = (Get-Date).AddMinutes($TimeoutMinutes)
$done = $false
while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 15
    if ((Test-Path $logPath) -and (Select-String -Path $logPath -Pattern '^S9 DONE' -Quiet)) { $done = $true; break }
}
$lines = if (Test-Path $logPath) { @(Get-Content $logPath -Encoding UTF8) } else { @() }
$lines | ForEach-Object { Write-Output "    $_" }
function Get-S9Value([string] $key) {
    $hit = $lines | Where-Object { $_ -like "S9 ${key}: *" } | Select-Object -First 1
    if ($hit) { return $hit.Substring(("S9 ${key}: ").Length) } else { return $null }
}

Assert-True $done "the task ran to its end within $TimeoutMinutes minutes"
Assert-True ((Get-S9Value 'WHOAMI') -like "*\$AccountName") "the line ran as the standard account ($(Get-S9Value 'WHOAMI'))"
Assert-True ((Get-S9Value 'ISADMIN') -eq 'False') "the account is not an administrator (IsInRole Administrator = $(Get-S9Value 'ISADMIN'))"
Assert-True ((Get-S9Value 'WHERE_GIT') -eq '[]') "where.exe git finds nothing before the line runs ($(Get-S9Value 'WHERE_GIT'))"
Assert-True ((Get-S9Value 'ELEVATED_WRITE') -like 'REFUSED*') "negative control: the administrator-only write is refused under the account ($(Get-S9Value 'ELEVATED_WRITE'))"
Assert-True ((Get-S9Value 'RC') -eq '0') "the published line exits 0 (exit $(Get-S9Value 'RC'))"
Assert-True ([bool]($lines | Where-Object { $_ -like 'S9 OUT:*Installation complete*' })) "the installer's success verdict is printed"
Assert-True ((Get-S9Value 'GIT_IN_PROFILE') -eq 'True') "Git sits in the account's own profile"
Assert-True ((Get-S9Value 'GIT_IN_USER_PATH') -eq 'True') "Git was added to the account's own user PATH"

& schtasks /Delete /TN $taskName /F | Out-Null

Write-Output ""
if ($failures.Count -eq 0) {
    Write-Output "=== RESULT: PASS (all checks green) ==="
    exit 0
}
Write-Output "=== RESULT: FAIL ($($failures.Count) check(s) failed) ==="
$failures | ForEach-Object { Write-Output "  - $_" }
exit 1
