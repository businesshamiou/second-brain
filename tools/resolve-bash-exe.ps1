#Requires -Version 5.1
<#
.SYNOPSIS
    Shared helper: locate bash.exe reliably on Windows (Mission 168, ticket 03).

.DESCRIPTION
    Role: dot-sourced by install.ps1 and by tests/test-install-e2e.ps1 so
    both use the exact same resolution logic -- kept in one place rather
    than duplicated, since a fix to one copy silently drifting from the
    other would be the kind of bug this repo's own guardians can't catch
    (neither is a tracked-file convention check, this is plain code hygiene).

    bash.exe is NOT on PowerShell's default PATH on a stock Git for Windows
    install (measured on this machine: PATH carries Git\cmd and
    Git\mingw64\bin, never Git\bin) even though git.exe is. Falls back to
    deriving it from git.exe's own location rather than assuming PATH.

    Usage:
        . "$PSScriptRoot\tools\resolve-bash-exe.ps1"
        $bashExe = Resolve-BashExe

    Inputs: none.
    Outputs: defines the Resolve-BashExe function in the caller's scope.
#>

function Resolve-BashExe {
    $onPath = Get-Command bash.exe -ErrorAction SilentlyContinue
    if ($onPath) { return $onPath.Source }

    $gitCmd = Get-Command git.exe -ErrorAction SilentlyContinue
    if ($gitCmd) {
        $gitInstallRoot = Split-Path (Split-Path $gitCmd.Source -Parent) -Parent
        $candidate = Join-Path $gitInstallRoot 'bin\bash.exe'
        if (Test-Path $candidate) { return $candidate }
    }

    throw "bash.exe not found (neither on PATH nor derived from git.exe). Install Git for Windows (ships Git Bash)."
}
