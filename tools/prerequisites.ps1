#Requires -Version 5.1
<#
.SYNOPSIS
    Prerequisite tools (Git, uv, pre-commit) without administrator rights
    (Mission 168, ticket 04).

.DESCRIPTION
    Role: dot-sourced by install.ps1 (and by this ticket's own tests) to
    ensure Git, uv and pre-commit are usable before the rest of the
    installer runs a single `git`/`pre-commit` command. Every tool this
    module installs goes into the user's own profile -- never a
    machine-wide location, never through anything that could raise a UAC
    prompt (T13 revised, Q1 bis: winget/the standard NSIS Git installer both
    require elevation to finish; this module never calls either).

    Detection first, always (spec, Implementation Decisions -- "outils deja
    presents reutilises") : if `git.exe` / `uv.exe` / `pre-commit.exe`
    already resolve on the current process's PATH, that copy is reused
    as-is, whatever its version -- this module only ever fetches and
    installs its own pinned copy for a tool that is genuinely absent. This
    is also what makes the -TestMode scenario work: a caller who wants to
    prove "Git and Python absent from PATH" simulates that by trimming
    $env:Path for its own process before calling into this module (never by
    touching the real user PATH) -- see tests/test-prerequisites-e2e.ps1.

    Versions and download hashes are pinned in prerequisites.lock.json,
    next to this script. The two artifacts this module downloads directly
    (the PortableGit archive, the uv install script) are hashed
    (SHA-256) against that lock file before being extracted or executed;
    a mismatch throws immediately and nothing is extracted or run (ticket
    04, criterion 3). pre-commit is not fetched by this script directly --
    `uv tool install` resolves and installs it from PyPI, which already
    verifies package hashes itself as part of uv's normal, documented
    dependency-resolution behaviour; pinning pre-commit's exact version
    in the lock file is what "versions figees" asks for on that tool, the
    separate artifact-level SHA-256 pin is scoped to what this script
    itself fetches over the network (Class B, consigned in the ticket 04
    report).

    Every write this module ever makes -- the extracted PortableGit tree,
    uv's own binaries, uv's tool/cache/managed-Python directories, and the
    persisted PATH entry -- is redirected under $Context.ProfileRoot
    (built by install.ps1's New-InstallerContext) instead of the real user
    profile whenever $Context.TestMode is set. Real mode uses the same
    code path with $Context.ProfileRoot = $env:USERPROFILE, so there is
    only one flow to trust, not two that could drift apart.

    In -TestMode, the UV_TOOL_DIR/UV_CACHE_DIR/UV_PYTHON_*_DIR redirection
    (Initialize-UvEnvironmentRedirection) is set on *this process*
    persistently, for the whole remaining lifetime of the run -- not only
    around this module's own `uv tool install pre-commit` call. Measured
    necessary: this repo's own .githooks/pre-commit runs `uv run
    tools/check-obsolescence-guardrail.py` as one of its guardians, invoked
    later, from inside a `git commit` this module knows nothing about
    (ticket 04's own main-flow test triggers exactly this, committing the
    first project's registration into the cloned second-brain). A
    redirection scoped only to this module's one `uv tool install` call
    reverted before that guardian ever ran, so its `uv run` fell back to
    uv's real default cache directory (%LOCALAPPDATA%\uv) despite invoking
    the TestRoot-installed uv.exe -- caught by
    tests/test-prerequisites-e2e.ps1's own %LOCALAPPDATA%\uv fingerprint,
    not by inspection. Every `uv` invocation for the rest of a -TestMode
    process now inherits the same redirected directories, guardian calls
    included.

    Usage:
        . "$PSScriptRoot\tools\prerequisites.ps1"
        $prereqs = Assure-Prerequisites -Context $context -AddPersistentPathEntry ${function:Add-InstallerPathEntry}

    Inputs: $Context, the object New-InstallerContext returns (install.ps1).
    $AddPersistentPathEntry, a scriptblock/function reference of shape
    `param($Context, $Entry)` that persists one PATH entry the way
    install.ps1's own Add-InstallerPathEntry already does (real registry in
    real mode, the simulated-PATH file in -TestMode) -- passed in rather
    than duplicated here, so there is exactly one implementation of "how a
    PATH entry survives past this process."

    Outputs: an object { Git; Uv; PreCommit }, each with at least an .Exe
    path, for the caller to invoke directly rather than relying on PATH
    resolution timing within the same process.
#>

function Get-PrerequisitesLock {
    $lockPath = Join-Path $PSScriptRoot 'prerequisites.lock.json'
    if (-not (Test-Path $lockPath)) {
        throw "Prerequisites lock file not found: $lockPath"
    }
    return Get-Content -Raw -Path $lockPath | ConvertFrom-Json
}

function Get-FileSha256 {
    param([Parameter(Mandatory = $true)][string] $Path)
    return (Get-FileHash -Path $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}

function Add-ProcessPathEntry {
    # Prepends a directory to *this process's* PATH only -- never the
    # registry (that is Add-InstallerPathEntry's job, and only for real
    # runs; here we just need `git`/`uv`/`pre-commit` to resolve for the
    # remainder of *this* install.ps1 invocation, whether real or test).
    param([Parameter(Mandatory = $true)][string] $Directory)
    $parts = @($env:Path -split ';' | Where-Object { $_ -ne '' })
    if ($parts -notcontains $Directory) {
        $env:Path = "$Directory;$env:Path"
    }
}

function Invoke-WithEnvironmentOverride {
    # Runs $Script with the given environment variables set for *this
    # process only* ([Environment]::SetEnvironmentVariable(..., 'Process'),
    # never 'User' -- that would be the real registry), restoring whatever
    # was there before (including "absent", tracked as $null) once $Script
    # returns or throws. Used to hand uv's own installer and `uv tool
    # install` a fully profile-redirected set of UV_* directories without
    # ever touching $env: variables that outlive this one call.
    param(
        [Parameter(Mandatory = $true)][hashtable] $Overrides,
        [Parameter(Mandatory = $true)][scriptblock] $Script
    )
    $saved = @{}
    foreach ($key in $Overrides.Keys) {
        $saved[$key] = [Environment]::GetEnvironmentVariable($key, 'Process')
        [Environment]::SetEnvironmentVariable($key, $Overrides[$key], 'Process')
    }
    try {
        & $Script
    }
    finally {
        foreach ($key in $saved.Keys) {
            [Environment]::SetEnvironmentVariable($key, $saved[$key], 'Process')
        }
    }
}

function Resolve-ExistingOnPath {
    # Shared by all three Resolve-OrInstall-* functions: the "detect an
    # already-present tool and reuse it as-is" half of ticket 04's
    # criterion 4. One copy rather than three, so the exact same
    # Get-Command/Split-Path logic can never drift between Git, uv and
    # pre-commit's own detection.
    param([Parameter(Mandatory = $true)][string] $ExeName)
    $cmd = Get-Command $ExeName -ErrorAction SilentlyContinue
    if (-not $cmd) { return $null }
    return [PSCustomObject]@{ Exe = $cmd.Source; Dir = (Split-Path $cmd.Source -Parent) }
}

function Get-CachedOrDownloadedFile {
    # Downloads $Url into $CacheDir\$FileName, verifying SHA-256 against
    # $ExpectedSha256 -- a mismatch throws and deletes the bad file rather
    # than ever handing a caller an unverified artifact (ticket 04,
    # criterion 3: "empreinte fausse = arret, avec un verdict qui nomme la
    # cause"). A previously-cached file whose hash still matches is reused
    # untouched (no re-download) -- verified again here regardless, because
    # "empreinte verifiee avant chaque execution" means every time this
    # artifact is about to be used, not only the run that first fetched it.
    param(
        [Parameter(Mandatory = $true)][string] $Url,
        [Parameter(Mandatory = $true)][string] $ExpectedSha256,
        [Parameter(Mandatory = $true)][string] $CacheDir,
        [Parameter(Mandatory = $true)][string] $FileName
    )
    New-Item -ItemType Directory -Force -Path $CacheDir | Out-Null
    $destPath = Join-Path $CacheDir $FileName
    $expected = $ExpectedSha256.ToUpperInvariant()

    if (Test-Path $destPath) {
        if ((Get-FileSha256 -Path $destPath) -eq $expected) {
            return $destPath
        }
        # Cached copy no longer matches the lock file (corrupt, partial, or
        # a stale artifact from a previous pin) -- never trusted silently.
        Remove-Item -Force $destPath
    }

    # Test-only hook (Mission 168, ticket 05:
    # tests/test-questionnaire-network-failure.ps1). Never read outside a
    # test process -- this is the installer's one real network call, so it
    # is where a simulated network outage is injected, entirely inside this
    # process via an environment variable (never a real network change, per
    # the Mission's own constraint). A real run never sets this variable,
    # so this branch is inert in every non-test invocation.
    if ($env:SB_TEST_FORCE_NETWORK_FAILURE -eq '1') {
        throw [System.Net.WebException]::new("Simulated network failure (test-only hook, `$env:SB_TEST_FORCE_NETWORK_FAILURE=1`): unable to reach $Url")
    }

    Invoke-WebRequest -Uri $Url -OutFile $destPath -UseBasicParsing

    $actual = Get-FileSha256 -Path $destPath
    if ($actual -ne $expected) {
        Remove-Item -Force $destPath -ErrorAction SilentlyContinue
        throw "SHA-256 mismatch for '$FileName' downloaded from $Url (expected $expected, got $actual). Refusing to extract or run a download that does not match the pinned fingerprint."
    }
    return $destPath
}

function Resolve-OrInstall-GitPortable {
    # Detect-and-reuse first (ticket 04, criterion 4). Only when git.exe
    # does not resolve on this process's current PATH do we fetch and
    # extract our own pinned copy -- so a machine (or a real run on the
    # Owner's own profile) that already has Git installed, anywhere, never
    # gets a second copy.
    param(
        [Parameter(Mandatory = $true)][psobject] $Context,
        [Parameter(Mandatory = $true)][psobject] $Lock
    )

    $existing = Resolve-ExistingOnPath -ExeName 'git.exe'
    if ($existing) {
        return [PSCustomObject]@{ Source = 'existing'; GitExe = $existing.Exe; CmdDir = $existing.Dir }
    }

    $toolsRoot = Join-Path $Context.ProfileRoot '.local\share\second-brain'
    $gitRoot = Join-Path $toolsRoot 'PortableGit'
    $gitExe = Join-Path $gitRoot 'cmd\git.exe'
    $cacheDir = Join-Path $toolsRoot 'downloads'
    $cachedArchive = Join-Path $cacheDir $Lock.asset

    # "Empreinte verifiee avant chaque execution" (criterion 3): re-verify
    # the pinned, downloaded archive's SHA-256 every run this function is
    # the one managing Git -- not only the run that first extracted it --
    # so a cached archive tampered with between two runs is caught even
    # though extraction itself only happens once. Skipped only when
    # git.exe is already extracted AND the cache was removed by hand
    # (nothing left on disk to re-verify against): re-verifying "before
    # each execution" cannot force a fresh 58 MB download of an artifact
    # that already did its one job and is not being re-extracted (Class B,
    # consigned in the ticket 04 report) -- it is not a re-hash of the
    # extracted tree itself, which the lock file was never meant to pin
    # file-by-file.
    if ((Test-Path $gitExe) -and -not (Test-Path $cachedArchive)) {
        return [PSCustomObject]@{ Source = 'installed'; GitExe = $gitExe; CmdDir = (Split-Path $gitExe -Parent) }
    }

    $archive = Get-CachedOrDownloadedFile -Url $Lock.url -ExpectedSha256 $Lock.sha256 `
        -CacheDir $cacheDir -FileName $Lock.asset

    if (-not (Test-Path $gitExe)) {
        New-Item -ItemType Directory -Force -Path $gitRoot | Out-Null
        # The official Git for Windows portable edition is a self-extracting
        # 7z archive (SFX), not the NSIS installer T13 measured as requiring
        # elevation. -y (assume yes to all) and -o<dir> (output directory)
        # run its bundled 7-Zip extractor unattended: no admin rights, no
        # UAC prompt, no wizard (measured directly against this exact
        # asset). Start-Process, not the `&` call operator: measured
        # necessary -- `&` against this SFX exe returned before extraction
        # completed (empty $LASTEXITCODE, nothing on disk), while
        # Start-Process -Wait -PassThru reliably blocks for the real
        # extraction and reports its true exit code.
        $proc = Start-Process -FilePath $archive -ArgumentList @('-y', "-o$gitRoot") `
            -Wait -PassThru -WindowStyle Hidden
        if ($proc.ExitCode -ne 0) {
            throw "PortableGit extraction failed (exit $($proc.ExitCode)) from $archive"
        }
        if (-not (Test-Path $gitExe)) {
            throw "PortableGit extracted but git.exe is missing at the expected path: $gitExe"
        }
    }

    return [PSCustomObject]@{
        Source = 'installed'
        GitExe = $gitExe
        CmdDir = (Split-Path $gitExe -Parent)
    }
}

function Resolve-OrInstall-Uv {
    # Same detect-and-reuse rule as Git. uv's own official installer
    # (install.ps1, pinned and hash-verified below) is run with
    # UV_UNMANAGED_INSTALL pointed at our chosen bin directory: measured
    # (see ticket 04 report) that this single env var also forces
    # UV_NO_MODIFY_PATH behaviour and skips uv's own update-receipt file
    # under %LOCALAPPDATA%\uv -- exactly "nothing written outside the
    # directory we named" for both real and test runs, using only an
    # official, documented uv variable rather than an invented mechanism.
    param(
        [Parameter(Mandatory = $true)][psobject] $Context,
        [Parameter(Mandatory = $true)][psobject] $Lock
    )

    $existing = Resolve-ExistingOnPath -ExeName 'uv.exe'
    if ($existing) {
        return [PSCustomObject]@{ Source = 'existing'; UvExe = $existing.Exe; BinDir = $existing.Dir }
    }

    $toolsRoot = Join-Path $Context.ProfileRoot '.local'
    $binDir = Join-Path $toolsRoot 'bin'
    $uvExe = Join-Path $binDir 'uv.exe'
    $cacheDir = Join-Path $Context.ProfileRoot '.local\share\second-brain\downloads'
    $cachedInstallScript = Join-Path $cacheDir "uv-install-$($Lock.version).ps1"

    # Same "verified before each execution, for the artifact this lock
    # file actually pins" rule as Resolve-OrInstall-GitPortable -- see its
    # comment for the full reasoning (Class B, consigned in the ticket 04
    # report).
    if ((Test-Path $uvExe) -and -not (Test-Path $cachedInstallScript)) {
        return [PSCustomObject]@{ Source = 'installed'; UvExe = $uvExe; BinDir = $binDir }
    }

    $installScript = Get-CachedOrDownloadedFile -Url $Lock.installScriptUrl `
        -ExpectedSha256 $Lock.installScriptSha256 -CacheDir $cacheDir `
        -FileName "uv-install-$($Lock.version).ps1"

    if (-not (Test-Path $uvExe)) {
        New-Item -ItemType Directory -Force -Path $binDir | Out-Null
        Invoke-WithEnvironmentOverride -Overrides @{
            UV_UNMANAGED_INSTALL = $binDir
            UV_NO_MODIFY_PATH    = '1'
        } -Script {
            & powershell -NoProfile -ExecutionPolicy Bypass -File $installScript | Out-Null
            if ($LASTEXITCODE -ne 0) {
                throw "uv install script failed (exit $LASTEXITCODE): $installScript"
            }
        }
        if (-not (Test-Path $uvExe)) {
            throw "uv install script ran but uv.exe is missing at the expected path: $uvExe"
        }
    }

    return [PSCustomObject]@{
        Source = 'installed'
        UvExe  = $uvExe
        BinDir = $binDir
    }
}

function Resolve-OrInstall-PreCommit {
    # Same detect-and-reuse rule again. When absent, installed via
    # `uv tool install` -- never pip, never a bare venv -- per the Mission's
    # own decision that Vault tooling reaches Python only through uv. All of
    # uv's own directories (tool store, tool shims, package cache, and its
    # *managed Python* store/cache -- pre-commit needs a Python interpreter
    # and uv will silently download one if none is found, exactly the case
    # this ticket's test profile forces) are redirected under the same
    # profile root as Git and uv itself, so a from-scratch run never reaches
    # outside $Context.ProfileRoot. UV_SYSTEM_CERTS=1: measured necessary in
    # this environment's network (uv's bundled TLS roots rejected PyPI's
    # certificate chain; the official, documented opt-in to the OS
    # certificate store fixed it) -- kept unconditionally rather than only
    # for this one sandbox, since the audience this installer targets
    # (roughly 200 non-technical participants, spec Problem Statement) is
    # exactly the population most likely to sit behind a similar
    # TLS-inspecting corporate proxy (Class B, consigned in the ticket 04
    # report).
    #
    # No separate SHA-256 pin for pre-commit itself (unlike Git/uv, see
    # prerequisites.lock.json): this script never downloads pre-commit
    # directly -- `uv tool install` resolves and fetches it from PyPI,
    # which uv already verifies against PyPI's own published package
    # hashes as a normal, documented part of its dependency resolution.
    # The version pin below ("versions figees") is what ticket 04 asks for
    # on this tool; the artifact-level SHA-256 verification this module
    # does itself is scoped to what it fetches over the network with no
    # other integrity check of its own (Class B, consigned in the ticket
    # 04 report).
    param(
        [Parameter(Mandatory = $true)][psobject] $Context,
        [Parameter(Mandatory = $true)][psobject] $Lock,
        [Parameter(Mandatory = $true)][string] $UvExe,
        [Parameter(Mandatory = $true)][string] $UvBinDir
    )

    $existing = Resolve-ExistingOnPath -ExeName 'pre-commit.exe'
    if ($existing) {
        return [PSCustomObject]@{ Source = 'existing'; PreCommitExe = $existing.Exe; BinDir = $existing.Dir }
    }

    # Mission 183-C01: `uv tool install` puts executables in uv's own tool
    # bin directory (`uv tool dir --bin`: UV_TOOL_BIN_DIR when redirected,
    # %USERPROFILE%\.local\bin by default) -- NOT next to uv.exe. The two
    # coincide only when uv itself was installed by this module. A uv that
    # was already on PATH somewhere else (winget, scoop, a CI step) made
    # this function look in the wrong place and stop the install
    # (CI run 35157346970: "pre-commit.exe is missing at the expected path:
    # D:\a\_temp\uv-bin\pre-commit.exe"). Ask uv, never assume.
    $toolBinDir = (& $UvExe tool dir --bin 2>$null | Select-Object -First 1)
    if ([string]::IsNullOrWhiteSpace($toolBinDir)) { $toolBinDir = $UvBinDir }
    $toolBinDir = $toolBinDir.Trim()
    $preCommitExe = Join-Path $toolBinDir 'pre-commit.exe'
    if (-not (Test-Path $preCommitExe)) {
        # UV_TOOL_DIR/UV_CACHE_DIR/etc. are already set persistently on this
        # process by Assure-Prerequisites's Initialize-UvEnvironmentRedirection
        # (TestMode only) -- not narrowly scoped to this one call -- so that a
        # *later* `uv run`/`uv tool` invocation this module does not control
        # (this repo's own .githooks/pre-commit guardian) inherits the same
        # redirection. See this function's header comment and the module's
        # own .DESCRIPTION for the bug that shipped without this.
        & $UvExe tool install "pre-commit==$($Lock.version)" | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "uv tool install pre-commit failed (exit $LASTEXITCODE)"
        }
        if (-not (Test-Path $preCommitExe)) {
            throw "uv tool install pre-commit ran but pre-commit.exe is missing at the expected path: $preCommitExe"
        }
    }

    return [PSCustomObject]@{
        Source       = 'installed'
        PreCommitExe = $preCommitExe
        BinDir       = $toolBinDir
    }
}

function Initialize-UvEnvironmentRedirection {
    # In -TestMode ONLY, redirects uv's own tool/cache/managed-Python
    # directories under $Context.ProfileRoot for the *entire remaining
    # lifetime of this process* -- set persistently
    # ([Environment]::SetEnvironmentVariable(..., 'Process'), never
    # restored), not scoped to a single call. Real mode sets nothing here:
    # uv's own defaults are already profile-scoped correctly (this
    # machine's own real uv already lives under %USERPROFILE%\.local and
    # %LOCALAPPDATA%\uv), so there is nothing to redirect.
    #
    # Measured necessary (not merely cautious): this repo's own
    # .githooks/pre-commit runs `uv run tools/check-obsolescence-guardrail.py`
    # as one of its guardians, invoked later by `git commit` -- from a
    # child process this module never sees directly -- and inherits
    # whatever environment variables are ambient on this process at that
    # moment. A redirection scoped only around Resolve-OrInstall-PreCommit's
    # own `uv tool install` call had already been restored (reverted) by
    # the time that guardian ran, so its `uv run` silently fell back to
    # uv's real default cache directory (%LOCALAPPDATA%\uv) even though it
    # invoked the TestRoot-installed uv.exe -- caught by
    # tests/test-prerequisites-e2e.ps1's own %LOCALAPPDATA%\uv fingerprint.
    # UV_NO_MODIFY_PATH and UV_SYSTEM_CERTS are set the same persistent way
    # in both modes: harmless defaults (PATH is only ever changed by this
    # module itself; system certs help any `uv run`/`uv tool` reach the
    # network under a TLS-inspecting proxy -- Class B, consigned in the
    # ticket 04 report) that should govern every uv invocation for the rest
    # of this process, not just the ones this module makes directly.
    param([Parameter(Mandatory = $true)][psobject] $Context)

    $overrides = @{
        UV_NO_MODIFY_PATH = '1'
        UV_SYSTEM_CERTS   = '1'
    }
    if ($Context.TestMode) {
        $uvDataRoot = Join-Path $Context.ProfileRoot '.local\share\uv'
        $uvBinDir = Join-Path $Context.ProfileRoot '.local\bin'
        $overrides['UV_TOOL_DIR'] = Join-Path $uvDataRoot 'tools'
        $overrides['UV_TOOL_BIN_DIR'] = $uvBinDir
        $overrides['UV_CACHE_DIR'] = Join-Path $Context.ProfileRoot '.cache\uv'
        $overrides['UV_PYTHON_INSTALL_DIR'] = Join-Path $uvDataRoot 'python'
        $overrides['UV_PYTHON_CACHE_DIR'] = Join-Path $Context.ProfileRoot '.cache\uv\python'
        $overrides['UV_PYTHON_BIN_DIR'] = Join-Path $uvBinDir 'python-shims'
    }
    foreach ($key in $overrides.Keys) {
        [Environment]::SetEnvironmentVariable($key, $overrides[$key], 'Process')
    }
}

function Assure-Prerequisites {
    # Top-level entry point: ensures Git, uv and pre-commit are resolvable
    # -- reused if already present, installed into $Context.ProfileRoot
    # (real profile or -TestRoot, per install.ps1's New-InstallerContext)
    # otherwise -- then extends *this process's* PATH so the rest of
    # install.ps1's own run can call `git`/`pre-commit` immediately, and
    # persists each newly-installed directory via $AddPersistentPathEntry
    # so a *future* shell finds them too (ticket 04, criterion 1: "ajoutee
    # au PATH de l'utilisateur"). Never called for a tool that was already
    # on PATH -- reusing an existing install never re-adds or duplicates
    # its directory.
    param(
        [Parameter(Mandatory = $true)][psobject] $Context,
        [Parameter(Mandatory = $true)] $AddPersistentPathEntry
    )

    $lock = Get-PrerequisitesLock
    Initialize-UvEnvironmentRedirection -Context $Context

    $git = Resolve-OrInstall-GitPortable -Context $Context -Lock $lock.git
    if ($git.Source -eq 'installed') {
        Add-ProcessPathEntry -Directory $git.CmdDir
        & $AddPersistentPathEntry $Context $git.CmdDir
    }

    $uv = Resolve-OrInstall-Uv -Context $Context -Lock $lock.uv
    if ($uv.Source -eq 'installed') {
        Add-ProcessPathEntry -Directory $uv.BinDir
        & $AddPersistentPathEntry $Context $uv.BinDir
    }

    # pre-commit's BinDir is uv's tool bin directory. It equals $uv.BinDir
    # only when uv was installed here; when uv was reused from elsewhere it
    # is a distinct directory (Mission 183-C01), so it gets its own PATH
    # entry -- never added twice.
    $preCommit = Resolve-OrInstall-PreCommit -Context $Context -Lock $lock.preCommit -UvExe $uv.UvExe -UvBinDir $uv.BinDir
    if ($preCommit.Source -eq 'installed' -and $preCommit.BinDir -ne $uv.BinDir) {
        Add-ProcessPathEntry -Directory $preCommit.BinDir
        & $AddPersistentPathEntry $Context $preCommit.BinDir
    }

    return [PSCustomObject]@{
        Git       = $git
        Uv        = $uv
        PreCommit = $preCommit
    }
}
