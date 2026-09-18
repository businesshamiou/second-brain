#Requires -Version 5.1
<#
.SYNOPSIS
    Windows entry point of `second-brain update <version>` (Mission 191-C01,
    Decision 152251 B3).

.DESCRIPTION
    The update itself is tools/second-brain-update.sh: one implementation,
    never two. This wrapper resolves Git's bash the way the installer does
    (tools/resolve-bash-exe.ps1, never the WSL stub) and runs it with the
    same arguments; its exit code and its closed verdict line are the
    script's own.

.EXAMPLE
    powershell -File <workspace>\second-brain\tools\second-brain-update.ps1 v0.1.8
#>
param(
    [Parameter(Mandatory = $true, Position = 0)][string]$Version,
    [string]$Vault = "",
    [string]$Lang = ""
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'resolve-bash-exe.ps1')
$bashExe = Resolve-BashExe

$script = Join-Path $PSScriptRoot 'second-brain-update.sh'
$arguments = @($script, $Version)
if ($Vault -ne '') { $arguments += @('--vault', $Vault) }
if ($Lang -ne '') { $arguments += @('--lang', $Lang) }

& $bashExe @arguments
exit $LASTEXITCODE
