#Requires -Version 5.1
<#
.SYNOPSIS
    Shared helper: locate bash.exe reliably on Windows (Mission 168, ticket 03;
    corrected Mission 183-C01 -- WSL's own bash.exe stub was being preferred
    over Git Bash, and the git.exe-to-root derivation assumed a fixed depth).

.DESCRIPTION
    Role: dot-sourced by install.ps1 and by tests/test-install-e2e.ps1 so
    both use the exact same resolution logic -- kept in one place rather
    than duplicated, since a fix to one copy silently drifting from the
    other would be the kind of bug this repo's own guardians can't catch
    (neither is a tracked-file convention check, this is plain code hygiene).

    bash.exe is NOT on PowerShell's default PATH on a stock Git for Windows
    install (measured on this machine: PATH carries Git\cmd and
    Git\mingw64\bin, never Git\bin) even though git.exe is.

    Mission 183-C01, two causes named and reproduced, same family:

    1. This function used to try `Get-Command bash.exe` FIRST, before
       deriving from git.exe. Windows ships a `bash.exe` redirector for the
       Windows Subsystem for Linux feature under %WINDIR%\System32 even
       when no distribution is installed -- present on the GitHub-hosted
       windows-2025 runner image, and plausible on a real participant's
       machine with WSL enabled but no distro. `Get-Command bash.exe`
       matched that stub first (System32 is always on PATH), and invoking
       it failed with "Windows Subsystem for Linux has no installed
       distributions" -- install.ps1's own tools/write-marker.sh step then
       stopped dead (tests/test-bootstrap-no-git.ps1, CI run 35148321095,
       job "Windows -- install.ps1, full suite", step "Main -- bootstrap
       installs with no Git on PATH"). Fixed by trying git.exe-derivation
       first, and only falling back to a PATH-found bash.exe when it does
       not live under %WINDIR% (the one location no real Git Bash install
       ever uses).

    2. The git.exe-to-root derivation assumed a fixed depth (git.exe always
       exactly two directories below the Git install root, as with
       <root>\cmd\git.exe or <root>\bin\git.exe). Reproduced locally: a
       shell already descended from Git Bash puts <root>\mingw64\bin ahead
       of <root>\cmd on PATH, so `Get-Command git.exe` resolves there
       instead -- three directories below the root -- and the fixed-depth
       formula pointed at a bash.exe that does not exist. Fixed by walking
       up from git.exe's own directory (bounded to the three real layouts
       Git for Windows ships: cmd\git.exe, bin\git.exe,
       mingw64\bin\git.exe) instead of assuming one fixed depth.

    Usage:
        . "$PSScriptRoot\tools\resolve-bash-exe.ps1"
        $bashExe = Resolve-BashExe

    Inputs: none.
    Outputs: defines the Resolve-BashExe function in the caller's scope.
#>

function Resolve-BashExe {
    $gitCmd = Get-Command git.exe -ErrorAction SilentlyContinue
    if ($gitCmd) {
        $dir = Split-Path $gitCmd.Source -Parent
        # Bounded to 3 hops: covers <root>\cmd\git.exe and <root>\bin\git.exe
        # (root two levels up) and <root>\mingw64\bin\git.exe (root three
        # levels up) -- the only layouts Git for Windows ships git.exe
        # under. Never walks past the drive root (Split-Path Parent of a
        # drive root returns the same value).
        for ($hop = 0; $hop -lt 3 -and $dir; $hop++) {
            $candidate = Join-Path $dir 'bin\bash.exe'
            if (Test-Path $candidate) { return $candidate }
            $parent = Split-Path $dir -Parent
            if (-not $parent -or $parent -eq $dir) { break }
            $dir = $parent
        }
    }

    $onPath = Get-Command bash.exe -ErrorAction SilentlyContinue
    if ($onPath) {
        $windir = $env:WINDIR
        $underWindir = $windir -and $onPath.Source.StartsWith($windir, [System.StringComparison]::OrdinalIgnoreCase)
        if (-not $underWindir) { return $onPath.Source }
    }

    throw "bash.exe not found (neither derived from git.exe nor a usable one on PATH -- a Windows Subsystem for Linux stub under `$env:WINDIR does not count). Install Git for Windows (ships Git Bash)."
}
