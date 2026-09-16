#Requires -Version 5.1
<#
.SYNOPSIS
    Windows launcher for the Second Brain acceptance wizard (Mission 170,
    step 2).

.DESCRIPTION
    Role: PowerShell cannot run a .sh script directly, so an Owner on
    Windows without Git Bash on PATH has no way to start
    tools/acceptance-wizard.sh from the shell they actually have open. This
    launcher locates Bash without ever hardcoding an install path: it
    resolves git.exe from PATH (Get-Command), derives the Git for Windows
    install root from that one measured location, then tries both Bash
    layouts Git for Windows can ship under that root -- 'bin\bash.exe' and
    'usr\bin\bash.exe' -- since a participant's install can expose either
    one, or both (measured on the authoring machine: both exist).

    Every argument this script receives is forwarded unchanged, via the
    automatic $args array, to tools/acceptance-wizard.sh; this script exits
    with that script's own exit code ($LASTEXITCODE). It never writes to
    this repository and never modifies PATH, the Git installation, or any
    other part of the real environment -- it only locates and invokes Bash.
    No param() block is declared on purpose, so every argument the Owner
    passes lands in $args and is forwarded as-is, never parsed here.

    Not reused: tools/resolve-bash-exe.ps1 already derives a Bash path from
    git.exe for install.ps1, but only tries 'bin\bash.exe' and throws an
    unhandled exception when nothing is found. Mission 170 requires trying
    both layouts and a clean, handled error message, and modifying that
    shared helper is outside this step's scope (it also backs
    tests/test-install-e2e.ps1, which this step must not risk regressing).
    So this launcher's detection is intentionally self-contained; the
    resulting duplication is named here rather than silently resolved.

    Test hook (not for end users, same pattern as tools/prerequisites.ps1's
    SB_TEST_FORCE_NETWORK_FAILURE): if the environment variable
    SB_TEST_GIT_EXE_PATH is set, its value is used instead of resolving
    git.exe from PATH -- the sentinel '__NONE__' simulates Git itself being
    unreachable (Windows environment variables cannot hold an empty string
    as distinct from unset, so a literal sentinel is used instead), and a
    path under a directory with neither Bash layout simulates a broken Git
    install. This lets both "Bash not found" branches be exercised without
    touching the real Git installation or PATH. Leave it unset for normal
    use.
#>

# Resolve-BashPath -- given the path to git.exe (or $null/empty when it could
# not be found), returns the resolved bash.exe path, or $null plus a message
# naming the cause and the remedy.
function Resolve-BashPath {
    param(
        [AllowNull()]
        [AllowEmptyString()]
        [string]$GitExePath
    )

    if ([string]::IsNullOrEmpty($GitExePath)) {
        return [PSCustomObject]@{
            BashPath = $null
            Message  = 'Cause: Git for Windows was not found on PATH (git.exe did not resolve). ' +
                       'Remedy: install Git for Windows (https://git-scm.com/download/win), which bundles Bash.'
        }
    }

    # On a standard Git for Windows install, git.exe resolves to
    # '<GitRoot>\cmd\git.exe' -- the Git root is two directory levels above
    # git.exe itself. Derived from this one measured path every time, never
    # assumed from a fixed install location.
    $gitRoot = Split-Path -Parent (Split-Path -Parent $GitExePath)

    # Git for Windows can expose Bash under either layout depending on the
    # install; try 'bin\bash.exe' first (the conventional external entry
    # point other tools invoke), then 'usr\bin\bash.exe' (the MSYS2 Bash it
    # wraps) -- both are tried because either can be the one present, not
    # just assumed from the other.
    $candidates = @(
        (Join-Path $gitRoot 'bin\bash.exe'),
        (Join-Path $gitRoot 'usr\bin\bash.exe')
    )

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return [PSCustomObject]@{ BashPath = $candidate; Message = $null }
        }
    }

    return [PSCustomObject]@{
        BashPath = $null
        Message  = "Cause: git.exe resolved to '$GitExePath' (derived Git root: '$gitRoot'), but neither " +
                   "'bin\bash.exe' nor 'usr\bin\bash.exe' exists under that root. " +
                   'Remedy: repair or reinstall Git for Windows so it includes Bash.'
    }
}

try {
    if (Test-Path Env:\SB_TEST_GIT_EXE_PATH) {
        # Test-only override -- see .DESCRIPTION above. Never set by this
        # script itself, and never touches the real Git installation or PATH.
        $resolvedGitExePath = $env:SB_TEST_GIT_EXE_PATH
        if ($resolvedGitExePath -eq '__NONE__') { $resolvedGitExePath = $null }
    }
    else {
        $gitCommand = Get-Command git.exe -ErrorAction SilentlyContinue
        $resolvedGitExePath = if ($gitCommand) { $gitCommand.Source } else { $null }
    }

    $resolution = Resolve-BashPath -GitExePath $resolvedGitExePath
    if (-not $resolution.BashPath) {
        [Console]::Error.WriteLine($resolution.Message)
        exit 1
    }

    $wizardScript = Join-Path $PSScriptRoot 'tools\acceptance-wizard.sh'

    & $resolution.BashPath $wizardScript @args
    exit $LASTEXITCODE
}
catch {
    [Console]::Error.WriteLine("Unexpected error while launching the acceptance wizard: $($_.Exception.Message)")
    exit 1
}
