#Requires -Version 5.1
<#
.SYNOPSIS
    Mission 237, step 1: under Windows PowerShell 5.1, the Project name a
    participant types, 'SB - <display name>', equals the name the tools write.

.DESCRIPTION
    Rerun with one command, from the repository root:

        powershell -NoProfile -ExecutionPolicy Bypass -File tests\test-project-name-ascii.ps1

    Builds a throwaway Vault and workspace (tests/sandbox-vault.sh, through
    Git Bash) under the declared temporary folder, creates a project named
    'Demo Name', then:
      (a) the name typed here, 'SB - Demo Name', is -ceq to the
          pilot_project_name read from state/PILOT-PROMPT.md (UTF-8);
      (b) it is pure ASCII (every character below 128);
      (c) the output of `sb.cmd pilot-prompt`, captured by PowerShell,
          contains the typed name.
    This file is ASCII on purpose: Windows PowerShell 5.1 reads a script
    without a byte-order mark in the ANSI code page.

    Exit code 0 means every assertion passed; 1 otherwise.
#>

$ErrorActionPreference = 'Continue'
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch { }
$RepoRoot = Split-Path $PSScriptRoot -Parent
$failures = New-Object System.Collections.Generic.List[string]

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if ($Condition) { Write-Output "  PASS - $Message" }
    else { Write-Output "  FAIL - $Message"; $failures.Add($Message) | Out-Null }
}

. (Join-Path $RepoRoot 'tools\resolve-bash-exe.ps1')
. (Join-Path $RepoRoot 'tools\lib\tmp.ps1')
$bash = Resolve-BashExe
$root = Join-Path (Get-SbTmpDir 'tests') ("m237-ascii-ps-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path $root | Out-Null
$ws = Join-Path $root 'ws'
$repoFwd = $RepoRoot -replace '\\', '/'
$wsFwd = $ws -replace '\\', '/'

Write-Output "=== Mission 237 : le nom tape sous PowerShell 5.1 = le nom ecrit par les outils ==="
try {
    $script = ". '$repoFwd/tests/sandbox-vault.sh' && sandbox_find_uv && mkdir -p '$wsFwd' && sandbox_vault '$repoFwd' '$wsFwd/vault' && bash '$wsFwd/vault/tools/write-marker.sh' --marker-only '$wsFwd' >/dev/null && bash '$wsFwd/vault/tools/project-bootstrap.sh' create '$wsFwd/demo' 'Demo Name' EN --vcs none >/dev/null 2>&1"
    & $bash -c $script
    Assert-True ($LASTEXITCODE -eq 0) "espace jetable et projet cree (exit $LASTEXITCODE)"

    $typed = 'SB - Demo Name'
    $prompt = Join-Path $ws 'demo\state\PILOT-PROMPT.md'
    $line = Get-Content -Path $prompt -Encoding UTF8 | Where-Object { $_ -like 'pilot_project_name:*' } | Select-Object -First 1
    $written = ($line -replace '^pilot_project_name:\s*"', '') -replace '"\s*$', ''
    Assert-True ($typed -ceq $written) "(a) nom tape = nom ecrit ('$written')"
    $ascii = -not ($written.ToCharArray() | Where-Object { [int]$_ -gt 127 })
    Assert-True $ascii "(b) le nom ecrit est ASCII"

    Push-Location (Join-Path $ws 'demo')
    $out = & (Join-Path $ws 'vault\tools\sb\bin\sb.cmd') pilot-prompt --lang en 2>&1 | Out-String
    Pop-Location
    Assert-True ($out.Contains($typed)) "(c) sb.cmd pilot-prompt rend le nom tape"
}
finally {
    if (-not $env:KEEP_TMP) { Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue }
}

Write-Output ""
if ($failures.Count -eq 0) { Write-Output "=== RESULT: PASS ==="; exit 0 }
Write-Output "=== RESULT: FAIL ($($failures.Count)) ==="
exit 1
