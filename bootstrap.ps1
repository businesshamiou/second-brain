#Requires -Version 5.1
<#
.SYNOPSIS
    Second Brain bootstrap for Windows: installs from nothing -- no Git, no
    administrator rights (Mission 183-C01, Decision 142112 point 5).

.DESCRIPTION
    The published install line used to start with `git clone`, so a
    workstation without Git could not even begin (measured by Mission 182:
    scenario S9 was impossible as written). This script is what the
    published line now downloads and runs. It needs nothing installed:

      1. reads tools/prerequisites.lock.json from the same place as this
         script (the same tag on GitHub, or -RawBase), so the pinned Git
         asset and its SHA-256 are never copied here and can never drift;
      2. if git.exe is not on PATH, downloads that pinned PortableGit,
         checks its SHA-256, and extracts it -- into the user profile, at
         the exact place install.ps1's prerequisites step looks for it
         (%USERPROFILE%\.local\share\second-brain\PortableGit, or under
         -TestRoot\profile in test mode);
      3. brings -Target to -Ref with that git.exe, without touching PATH:
         a fresh clone when the folder is absent, otherwise fetch +
         checkout on the clone already there, with HEAD proven equal to
         -Ref (Mission 185-C01, gate 1 -- a leftover %TEMP% clone used to
         be installed as it stood);
      4. runs the cloned install.ps1 -Source <Target>, in a separate
         process. install.ps1 then finds the extracted Git, re-verifies its
         archive, and adds it to the user PATH itself -- the same code path
         as any other prerequisite.

    Nothing here asks for elevation: no RunAs, no HKLM, no Program Files.

    Published line (INSTALL.md):
        powershell -NoProfile -ExecutionPolicy Bypass -Command "& ([scriptblock]::Create((irm https://raw.githubusercontent.com/businesshamiou/second-brain/v0.1.9/bootstrap.ps1)))"

    Usage (all parameters optional):
        bootstrap.ps1 [-Ref <tag-or-branch>] [-RepoUrl <url-or-path>]
                      [-RawBase <url-or-directory>] [-Target <directory>]
                      [-AnswersFile <path>] [-TestMode -TestRoot <path>]
                      [-StopAfterStep <name>]

    -RepoUrl and -RawBase accept a local repository / directory so the
    test suite can play the whole path offline against a local clone
    (tests/test-bootstrap-no-git.ps1).

    Exit code: install.ps1's own exit code, or 1 with a one-line reason if
    the bootstrap itself could not get that far.
#>

[CmdletBinding()]
param(
    [string] $Ref = 'v0.1.9',
    [string] $RepoUrl = 'https://github.com/businesshamiou/second-brain.git',
    [string] $RawBase = '',
    [string] $Target = '',
    [string] $AnswersFile = '',
    [switch] $TestMode,
    [string] $TestRoot = '',
    # Test-only, relayed as is to install.ps1 (same plumbing as -TestMode):
    # tests/test-bootstrap-stale-temp-clone.ps1 measures the clone stage on
    # three systems without paying for a full install on each.
    [string] $StopAfterStep = ''
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Stop-Bootstrap {
    param([string] $Reason)
    Write-Output "Second Brain bootstrap stopped: $Reason"
    exit 1
}

# Two spellings of the SAME origin must not read as two origins: a local
# test clone is given as a Windows path, Git hands it back with forward
# slashes, and a URL may or may not carry its .git suffix or a trailing
# slash. Windows paths and GitHub URLs are both case-insensitive here.
function Normalize-RepoUrl {
    param([string] $Url)
    if ([string]::IsNullOrWhiteSpace($Url)) { return '' }
    $u = $Url.Trim().Replace('\', '/')
    $u = $u.TrimEnd('/')
    if ($u.EndsWith('.git')) { $u = $u.Substring(0, $u.Length - 4).TrimEnd('/') }
    return $u.ToLowerInvariant()
}

# Two names for the SAME repository. Text first (the ordinary case: a URL),
# then folder identity when both sides are local: a local path can be
# spelled several ways (forward or back slashes, a short 8.3 name, a
# different case), and Git records its own spelling rather than the one the
# line used -- the same folder must not read as two repositories
# (tests/test-bootstrap-stale-temp-clone.ps1).
function Test-SameRepoUrl {
    param([string] $Existing, [string] $Wanted)
    if ((Normalize-RepoUrl $Existing) -eq (Normalize-RepoUrl $Wanted)) { return $true }
    $a = $null; $b = $null
    try { $a = (Resolve-Path -LiteralPath $Existing -ErrorAction Stop).Path } catch { return $false }
    try { $b = (Resolve-Path -LiteralPath $Wanted -ErrorAction Stop).Path } catch { return $false }
    return ($a.TrimEnd('\', '/') -eq $b.TrimEnd('\', '/'))
}

try {
    if ($TestMode -and [string]::IsNullOrWhiteSpace($TestRoot)) {
        Stop-Bootstrap '-TestRoot is required with -TestMode.'
    }
    if ([string]::IsNullOrWhiteSpace($RawBase)) {
        $RawBase = "https://raw.githubusercontent.com/businesshamiou/second-brain/$Ref"
    }
    $profileRoot = if ($TestMode) { Join-Path $TestRoot 'profile' } else { $env:USERPROFILE }
    if ([string]::IsNullOrWhiteSpace($Target)) {
        $Target = if ($TestMode) { Join-Path $TestRoot 'second-brain-install' } else { Join-Path $env:TEMP 'second-brain-install' }
    }

    # --- 1. the pinned Git asset, read from the same origin as this script ---
    $lockRelative = 'tools/prerequisites.lock.json'
    if (Test-Path -LiteralPath $RawBase -PathType Container) {
        $lockText = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $RawBase $lockRelative)
    }
    else {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        $lockText = (Invoke-WebRequest -UseBasicParsing -Uri "$RawBase/$lockRelative").Content
    }
    $gitLock = ($lockText | ConvertFrom-Json).git

    # --- 2. Git: reuse it if present, otherwise the pinned portable copy ---
    $gitExe = $null
    $onPath = Get-Command git.exe -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($onPath) {
        $gitExe = $onPath.Source
    }
    else {
        $toolsRoot = Join-Path $profileRoot '.local\share\second-brain'
        $gitRoot = Join-Path $toolsRoot 'PortableGit'
        $gitExe = Join-Path $gitRoot 'cmd\git.exe'
        $cacheDir = Join-Path $toolsRoot 'downloads'
        $archive = Join-Path $cacheDir $gitLock.asset
        New-Item -ItemType Directory -Force -Path $cacheDir | Out-Null
        $needsDownload = $true
        if (Test-Path -LiteralPath $archive) {
            $needsDownload = ((Get-FileHash -Algorithm SHA256 -LiteralPath $archive).Hash -ne $gitLock.sha256.ToUpperInvariant())
        }
        if ($needsDownload) {
            Write-Output "Downloading Git $($gitLock.version) (portable, into your profile)..."
            [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest -UseBasicParsing -Uri $gitLock.url -OutFile $archive
        }
        $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $archive).Hash
        if ($actual -ne $gitLock.sha256.ToUpperInvariant()) {
            Remove-Item -LiteralPath $archive -Force
            Stop-Bootstrap "the downloaded Git archive does not match its pinned SHA-256 (expected $($gitLock.sha256), got $actual)."
        }
        if (-not (Test-Path -LiteralPath $gitExe)) {
            New-Item -ItemType Directory -Force -Path $gitRoot | Out-Null
            # Same unattended self-extracting 7z call as tools/prerequisites.ps1.
            $proc = Start-Process -FilePath $archive -ArgumentList @('-y', "-o$gitRoot") -Wait -PassThru -WindowStyle Hidden
            if ($proc.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $gitExe)) {
                Stop-Bootstrap "Git could not be extracted into $gitRoot (exit $($proc.ExitCode))."
            }
        }
    }

    # --- 3. the repository, cloned with that git.exe (PATH untouched) ---
    # An EXISTING clone here is the normal case on a workstation that has
    # already played the published line: %TEMP%\second-brain-install
    # survives. Until Mission 185-C01 this whole block was skipped when
    # .git was there, so the installer ran whatever commit that leftover
    # folder happened to sit on -- measured on the Owner's workstation
    # (capture 2026-09-17-144137, gate 1): a 2026-09-13 commit, older than
    # every tag, installed with a clean verdict. The folder is now brought
    # to -Ref instead: same origin, fetch, checkout, and HEAD proven equal
    # to -Ref. Never --force, never a deletion: a mismatch refuses and
    # names the folder to move aside.
    if (Test-Path -LiteralPath (Join-Path $Target '.git')) {
        # `config --get` rather than `remote get-url`: it is silent on a
        # missing remote (exit 1, nothing on stderr), and this script runs
        # under $ErrorActionPreference = 'Stop', where a native command
        # writing to stderr throws.
        #
        # @(...) rather than `| Select-Object -First 1`: -First stops the
        # pipeline, which stops the native command, and $LASTEXITCODE is then
        # whatever that interruption produced. Measured on the CI Windows
        # runner (Mission 185-C01, round 1): git had printed the origin, the
        # exit code read non-zero anyway, the value was blanked, and the line
        # refused a folder that was in fact the right clone.
        $originLines = @(& $gitExe -C $Target config --get remote.origin.url)
        $originExit = $LASTEXITCODE
        $existingOrigin = ''
        if ($originExit -eq 0 -and $originLines.Count -gt 0) { $existingOrigin = "$($originLines[0])".Trim() }
        if (-not (Test-SameRepoUrl $existingOrigin $RepoUrl)) {
            Stop-Bootstrap "$Target is a clone of '$existingOrigin', not of '$RepoUrl'; move $Target aside and run the line again."
        }
        & $gitExe -C $Target config core.longpaths true
        & $gitExe -C $Target fetch --quiet --tags origin
        if ($LASTEXITCODE -ne 0) {
            Stop-Bootstrap "git fetch of $RepoUrl failed in $Target (exit $LASTEXITCODE); move $Target aside and run the line again."
        }
        # A tag first, then the remote-tracking branch, then a raw commit
        # id: a stale LOCAL branch named `main` must never win over what
        # the fetch just brought in.
        $wanted = ''
        foreach ($candidate in @("refs/tags/$Ref^{commit}", "refs/remotes/origin/$Ref^{commit}", "$Ref^{commit}")) {
            # --quiet keeps stderr empty when the ref does not exist.
            $resolvedLines = @(& $gitExe -C $Target rev-parse --verify --quiet $candidate)
            $resolvedExit = $LASTEXITCODE
            if ($resolvedExit -eq 0 -and $resolvedLines.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace($resolvedLines[0])) {
                $wanted = "$($resolvedLines[0])".Trim()
                break
            }
        }
        if ([string]::IsNullOrWhiteSpace($wanted)) {
            Stop-Bootstrap "$Ref does not exist in $RepoUrl; nothing was installed."
        }
        & $gitExe -C $Target -c advice.detachedHead=false checkout --quiet --detach $wanted
        if ($LASTEXITCODE -ne 0) {
            Stop-Bootstrap "$Ref could not be checked out in $Target (exit $LASTEXITCODE); move $Target aside and run the line again."
        }
        $headLines = @(& $gitExe -C $Target rev-parse HEAD)
        $head = if ($headLines.Count -gt 0) { "$($headLines[0])".Trim() } else { '' }
        if ($head -ne $wanted) {
            Stop-Bootstrap "$Target is at $head, not at $Ref ($wanted); move $Target aside and run the line again."
        }
    }
    else {
        if (Test-Path -LiteralPath $Target) {
            Stop-Bootstrap "$Target exists but is not a Git repository; move it aside and run the line again."
        }
        # --no-checkout, then checkout: -Ref may be a branch, a tag or a
        # commit id (CI plays the exact commit under test), which
        # `clone --branch` does not accept.
        & $gitExe -c core.longpaths=true clone --quiet --no-checkout $RepoUrl $Target
        if ($LASTEXITCODE -ne 0) {
            Stop-Bootstrap "git clone of $RepoUrl failed (exit $LASTEXITCODE)."
        }
        & $gitExe -C $Target config core.longpaths true
        & $gitExe -C $Target -c advice.detachedHead=false checkout --quiet $Ref
        if ($LASTEXITCODE -ne 0) {
            Stop-Bootstrap "$Ref could not be checked out from $RepoUrl (exit $LASTEXITCODE)."
        }
    }

    # --- 4. the installer, from the clone ---
    $installArgs = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $Target 'install.ps1'), '-Source', $Target)
    if (-not [string]::IsNullOrWhiteSpace($AnswersFile)) { $installArgs += @('-AnswersFile', $AnswersFile) }
    if ($TestMode) { $installArgs += @('-TestMode', '-TestRoot', $TestRoot) }
    if (-not [string]::IsNullOrWhiteSpace($StopAfterStep)) { $installArgs += @('-StopAfterStep', $StopAfterStep) }
    & powershell @installArgs
    exit $LASTEXITCODE
}
catch {
    Stop-Bootstrap $_.Exception.Message
}
