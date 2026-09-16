#Requires -Version 5.1
<#
.SYNOPSIS
    tools/resolve-bash-exe.ps1 finds real Git Bash, never a decoy or the
    Windows Subsystem for Linux stub (Mission 183-C01).

.DESCRIPTION
    Two causes measured on CI run 35148321095 and reproduced locally:

      1. Resolve-BashExe used to try `Get-Command bash.exe` before deriving
         from git.exe -- any bash.exe placed earlier on PATH than Git's own
         directories won, including the WSL redirector Windows ships under
         %WINDIR%\System32 even without an installed distribution. Fixed by
         trying the git.exe-derived path first, and refusing a PATH-found
         bash.exe that lives under %WINDIR%.
      2. The git.exe-to-root derivation assumed git.exe always sits exactly
         two directories below the Git install root (<root>\cmd\git.exe or
         <root>\bin\git.exe). A shell descended from Git Bash itself puts
         <root>\mingw64\bin ahead of <root>\cmd on PATH, three directories
         below the root, and the fixed-depth formula missed it. Fixed by a
         bounded walk up from git.exe's own directory.

    Each case runs Resolve-BashExe in a child PowerShell process with a
    manipulated PATH (and, for the WSL case, $env:WINDIR), so this
    process's own real PATH is never touched.

    Cases:
      1. decoy-on-path-ignored -- a non-Git bash.exe placed ahead of Git's
         own directories on PATH: the git-derived Git Bash wins.
      2. wsl-stub-under-windir-refused -- a bash.exe under a directory this
         run treats as $env:WINDIR, no git.exe reachable: refused with a
         named cause, never silently accepted.
      3. mingw64-bin-derivation -- git.exe reachable only via a
         <root>\mingw64\bin layout: the real <root>\bin\bash.exe is still
         found (proves the bounded walk, not just the immediate parent).
      4. real-bash-still-resolved -- control, unmodified PATH: resolves to
         an existing, real bash.exe (proves the fixes did not break the
         nominal case).

    usage: tests/test-resolve-bash-exe.ps1
#>

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path $PSScriptRoot -Parent
$Helper = Join-Path $RepoRoot 'tools\resolve-bash-exe.ps1'
$failures = New-Object System.Collections.Generic.List[string]

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if ($Condition) { Write-Output "  PASS - $Message" }
    else { Write-Output "  FAIL - $Message"; $failures.Add($Message) | Out-Null }
}

function Invoke-Child {
    param([string] $Body)
    $tmp = Join-Path $env:TEMP ("sb-resolve-bash-child-" + [Guid]::NewGuid().ToString('N') + '.ps1')
    $Body | Set-Content -Path $tmp -Encoding UTF8
    $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $tmp 2>&1 | ForEach-Object { "$_" }
    Remove-Item -Force $tmp -ErrorAction SilentlyContinue
    return ($out -join "`n")
}

$realGit = Get-Command git.exe -ErrorAction SilentlyContinue
if (-not $realGit) {
    Write-Output "FAIL: git.exe not found on this machine -- cannot exercise the real-bash control case"
    exit 1
}

# --- 1. decoy-on-path-ignored ------------------------------------------------
$out1 = Invoke-Child @"
`$decoy = Join-Path `$env:TEMP ('decoy-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path `$decoy | Out-Null
New-Item -ItemType File -Force -Path (Join-Path `$decoy 'bash.exe') | Out-Null
`$env:Path = "`$decoy;`$env:Path"
. '$Helper'
Write-Output (Resolve-BashExe)
Remove-Item -Recurse -Force `$decoy
"@
Assert-True ($out1 -notmatch 'decoy-' -and $out1 -match 'bash\.exe$') "1-decoy-on-path-ignored: resolved [$out1], not the decoy"

# --- 2. wsl-stub-under-windir-refused ----------------------------------------
$out2 = Invoke-Child @"
`$fakeWindir = Join-Path `$env:TEMP ('fakewindir-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path (Join-Path `$fakeWindir 'System32') | Out-Null
New-Item -ItemType File -Force -Path (Join-Path `$fakeWindir 'System32\bash.exe') | Out-Null
`$env:WINDIR = `$fakeWindir
`$env:Path = ((`$env:Path -split ';') | Where-Object { `$_ -ne '' -and -not (Test-Path (Join-Path `$_ 'git.exe')) }) -join ';'
`$env:Path = "`$fakeWindir\System32;`$env:Path"
. '$Helper'
try { Write-Output (Resolve-BashExe) } catch { Write-Output "THREW: `$(`$_.Exception.Message)" }
Remove-Item -Recurse -Force `$fakeWindir
"@
Assert-True ($out2 -match '^THREW:.*not found') "2-wsl-stub-under-windir-refused: $out2"

# --- 3. mingw64-bin-derivation ------------------------------------------------
# The true Git install root is two directories above git.exe for the
# <root>\cmd\git.exe and <root>\bin\git.exe layouts, three above for
# <root>\mingw64\bin\git.exe (which is what this dev machine's own PATH
# resolves to when a session descends from Git Bash itself).
if ($realGit.Source -like '*\mingw64\bin\git.exe') {
    $gitRoot = Split-Path (Split-Path (Split-Path $realGit.Source -Parent) -Parent) -Parent
}
else {
    $gitRoot = Split-Path (Split-Path $realGit.Source -Parent) -Parent
}
$mingwGit = Join-Path $gitRoot 'mingw64\bin\git.exe'
if (Test-Path $mingwGit) {
    $out3 = Invoke-Child @"
`$env:Path = ((`$env:Path -split ';') | Where-Object { `$_ -ne '' -and -not (Test-Path (Join-Path `$_ 'git.exe')) }) -join ';'
`$env:Path = "$(Split-Path $mingwGit -Parent);`$env:Path"
. '$Helper'
Write-Output (Resolve-BashExe)
"@
    Assert-True ($out3 -eq (Join-Path $gitRoot 'bin\bash.exe')) "3-mingw64-bin-derivation: resolved [$out3], want $(Join-Path $gitRoot 'bin\bash.exe')"
}
else {
    Write-Output "  SKIP [3-mingw64-bin-derivation]: this machine's Git for Windows has no mingw64\bin\git.exe to exercise"
}

# --- 4. real-bash-still-resolved ----------------------------------------------
. $Helper
$resolved = Resolve-BashExe
Assert-True (Test-Path $resolved) "4-real-bash-still-resolved: $resolved exists"
$version = & $resolved --version 2>&1
Assert-True ("$version" -match 'GNU bash') "4-real-bash-still-resolved: $resolved answers --version as GNU bash"

Write-Output ""
if ($failures.Count -eq 0) {
    Write-Output "=== RESULT: PASS (all checks green) ==="
    exit 0
}
Write-Output "=== RESULT: FAIL ($($failures.Count) check(s) failed) ==="
$failures | ForEach-Object { Write-Output "  - $_" }
exit 1
