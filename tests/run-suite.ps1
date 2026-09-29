# Plays the test suite listed in tests/suite.tsv on Windows, from a
# PowerShell parent -- the way the former `shell: powershell` CI steps ran
# the .ps1 tests -- and the bash lines through Git for Windows' bash, the one
# GitHub's `shell: bash` uses (Mission 188). Same manifest, same verdicts and
# same summary as tests/run-suite.sh.
#
# usage: powershell -NoProfile -ExecutionPolicy Bypass -File tests/run-suite.ps1 [-Manifest <file>] [-Shard k/n] [-Changed [-Ref <ref>]] [-List] [-OnDemand]
#
# -Shard k/n (Mission 189) plays only the lines whose shard column is k, and
# refuses when the manifest's highest Windows shard is not n.
#
# -Changed [-Ref <ref>] (Mission 209) is the twin of `run-suite.sh --changed
# [<ref>]`: same selection, same messages (on standard error), same intersection
# with -Shard. PowerShell cannot give a switch an optional value, so the ref is
# the separate -Ref parameter; without it, origin/main, or HEAD when there is
# no origin/main. Parity with the bash runner is proved by
# tests/test-run-suite-changed.sh.
#
# Like the bash runner, -Changed NEVER selects the whole suite: a change to
# tests/suite.tsv, tests/run-suite.sh or tests/run-suite.ps1 is an ordinary change
# (the lines named `suite` / `run-suite`, and the lines it adds); the whole suite is
# played explicitly (without -Changed), when a Mission prescribes it (Decision 170838).
#
# Every line for Windows is played, even after a red one; exit code 1 if a
# blocking line is red, 0 otherwise. A test exiting 77 reports SKIP. The exit
# code of each test is read straight from $LASTEXITCODE, never behind a pipe
# (Mission 185 defect: a pipe loses it). Mission 237: every SKIP is named under
# the RESULT line with its reason (the test's last line that says SKIP), and a
# platform letter followed by `!` (`W!UM`) marks a test REQUIRED there: its
# SKIP is a blocking FAIL. The test's standard output is collected, then
# written, so that the reason can be read (same verdicts as run-suite.sh).

param(
    [string]$Manifest,
    [string]$Shard,
    [switch]$Changed,
    [string]$Ref,
    [switch]$List,
    [switch]$OnDemand
)

$ErrorActionPreference = 'Continue'
$RepoRoot = Split-Path -Parent $PSScriptRoot
if (-not $Manifest) { $Manifest = Join-Path $RepoRoot 'tests\suite.tsv' }
if (-not (Test-Path -LiteralPath $Manifest)) {
    Write-Output "REFUS : manifest not found: $Manifest"
    exit 2
}
Set-Location -LiteralPath $RepoRoot

# Declared temporary folder (Mission 234): every test this runner plays writes
# its throwaway files under <SB_TMP>\tests -- TEMP/TMP for PowerShell and .NET,
# TMPDIR for bash and Python, SB_TMP for the access function itself.
# A manifest played from another checkout without tools\lib keeps its TEMP.
$sbTmpLib = Join-Path $RepoRoot 'tools\lib\tmp.ps1'
if (Test-Path -LiteralPath $sbTmpLib) {
    . $sbTmpLib
    $sbTestsTmp = Get-SbTmpDir -Use tests
    $env:SB_TMP = Get-SbTmpRoot
    $env:TEMP = $sbTestsTmp
    $env:TMP = $sbTestsTmp
    # TMPDIR in Git Bash's own form (/c/...), never C:/...: a drive colon in the
    # paths mktemp returns breaks `file:line:` parsing (measured, Mission 234).
    $env:TMPDIR = '/' + $sbTestsTmp.Substring(0, 1).ToLower() + $sbTestsTmp.Substring(2).Replace('\', '/')
}

$shardK = ''
if ($Shard) {
    if ($Shard -notmatch '^([0-9]+)/([0-9]+)$') {
        Write-Output "REFUS : -Shard expects k/n, got '$Shard'"
        exit 2
    }
    $shardK = $Matches[1]
    $shardN = [int]$Matches[2]
    $maxShard = 0
    foreach ($l in (Get-Content -LiteralPath $Manifest -Encoding UTF8)) {
        if ($l -eq '' -or $l.StartsWith('#')) { continue }
        $g = $l.Split("`t")
        if ($g.Count -ge 7 -and $g[3].Contains('W') -and $g[6] -match '^[0-9]+$') {
            if ([int]$g[6] -gt $maxShard) { $maxShard = [int]$g[6] }
        }
    }
    if ($maxShard -ne $shardN) {
        Write-Output "REFUS : -Shard $Shard, but the manifest splits platform W into $maxShard shard(s)"
        exit 2
    }
}

# Git for Windows' bash, never System32\bash.exe (WSL).
$bash = $null
$candidates = @()
if ($env:ProgramFiles) { $candidates += (Join-Path $env:ProgramFiles 'Git\bin\bash.exe') }
if (${env:ProgramFiles(x86)}) { $candidates += (Join-Path ${env:ProgramFiles(x86)} 'Git\bin\bash.exe') }
$git = Get-Command git.exe -ErrorAction SilentlyContinue
if ($git) { $candidates += (Join-Path (Split-Path -Parent (Split-Path -Parent $git.Source)) 'bin\bash.exe') }
foreach ($c in $candidates) {
    if ($c -and (Test-Path -LiteralPath $c)) { $bash = $c; break }
}
if (-not $bash) {
    Write-Output "REFUS : Git for Windows' bash.exe not found"
    exit 2
}

# No double quote inside: Windows PowerShell 5.1 does not escape them when it
# hands an argument to a native program. Manifest paths hold no space.
$uvPrelude = '. tests/sandbox-vault.sh; sandbox_find_uv || { echo REFUS : uv introuvable; exit 1; }'
$inCi = ($env:GITHUB_ACTIONS -eq 'true')

# --- -Changed (Mission 209): which files changed, which lines they call for ---
$guardians = @('tools/session-preflight.sh', '.githooks/pre-commit')
$changedFiles = @()
$changedBases = @()
$changedRef = ''

function Test-ChangedSelects([string]$path, [string]$origin) {
    if ($guardians -ccontains $path) { return $true }
    if ($changedFiles -ccontains $path) { return $true }
    $lc = ("$path $origin").ToLowerInvariant()
    foreach ($b in $changedBases) { if ($lc.Contains($b)) { return $true } }
    return $false
}

if ($Changed) {
    & git -C $RepoRoot rev-parse --git-dir *> $null
    if ($LASTEXITCODE -ne 0) { Write-Output "REFUS : -Changed needs a Git checkout: $RepoRoot"; exit 2 }
    $changedRef = $Ref
    if (-not $changedRef) {
        & git -C $RepoRoot rev-parse --verify -q ('origin/main' + '^{commit}') *> $null
        if ($LASTEXITCODE -eq 0) { $changedRef = 'origin/main' } else { $changedRef = 'HEAD' }
    }
    & git -C $RepoRoot rev-parse --verify -q ($changedRef + '^{commit}') *> $null
    if ($LASTEXITCODE -ne 0) { Write-Output "REFUS : -Changed: unknown ref '$changedRef'"; exit 2 }
    # Tracked files that differ from the ref (staged or not), then untracked ones.
    $diffOut = & git -C $RepoRoot -c core.quotepath=off diff --name-only $changedRef -- 2>$null
    $untrackedOut = & git -C $RepoRoot -c core.quotepath=off ls-files --others --exclude-standard 2>$null
    $changedFiles = @((@($diffOut) + @($untrackedOut)) | Where-Object { $_ -and $_.Trim() -ne '' })
    foreach ($cf in $changedFiles) {
        if ($cf -clike 'tools/*' -or $cf -clike 'tests/*' -or $cf -clike '.githooks/*') {
            $b = ($cf -split '/')[-1]
            $dot = $b.LastIndexOf('.')
            if ($dot -ge 0) { $b = $b.Substring(0, $dot) }
            if ($b -eq '' -or $b -eq 'index' -or $b.StartsWith('index-archive')) { continue }
            $changedBases += $b.ToLowerInvariant()
        }
    }
    # Announce the selection before anything is played ("N sur M" counts the
    # lines of Windows, and of the shard when one is given).
    $selN = 0; $selM = 0; $selTests = 0
    foreach ($pl in (Get-Content -LiteralPath $Manifest -Encoding UTF8)) {
        if ($pl -eq '' -or $pl.StartsWith('#')) { continue }
        $pf = $pl.Split("`t")
        if ($pf.Count -lt 6) { continue }
        if (-not $pf[3].Contains('W')) { continue }
        if ($shardK -and ($pf.Count -lt 7 -or $pf[6] -ne $shardK)) { continue }
        $selM++
        if (Test-ChangedSelects $pf[0] $pf[5]) {
            $selN++
            if ($guardians -cnotcontains $pf[0]) { $selTests++ }
        }
    }
    [Console]::Error.WriteLine("--changed : $selN ligne(s) selectionnee(s) sur $selM (ref $changedRef)")
    if ($selTests -eq 0) { [Console]::Error.WriteLine('--changed : aucun test ne nomme les fichiers changes ; seuls les gardiens jouent') }
}

$total = 0; $passed = 0; $skipped = 0; $failBlocking = 0; $failInfo = 0
$verdicts = New-Object System.Collections.Generic.List[string]
$skipLines = New-Object System.Collections.Generic.List[string]

foreach ($line in (Get-Content -LiteralPath $Manifest -Encoding UTF8)) {
    if ($line -eq '' -or $line.StartsWith('#')) { continue }
    $f = $line.Split("`t")
    if ($f.Count -lt 6) { Write-Output "REFUS : malformed manifest line: $line"; exit 2 }
    $path = $f[0]; $argText = $f[1]; $interp = $f[2]; $platforms = $f[3]; $severity = $f[4]; $origin = $f[5]
    if (-not $platforms.Contains('W')) { continue }
    if ($shardK -and ($f.Count -lt 7 -or $f[6] -ne $shardK)) { continue }
    # Mission 234: severity on-demand -- played only with -OnDemand, and then alone.
    if ($severity -eq 'on-demand') { if (-not $OnDemand) { continue } } elseif ($OnDemand) { continue }
    if ($Changed -and -not (Test-ChangedSelects $path $origin)) { continue }
    $lineArgs = @()
    if ($argText -ne '-') { $lineArgs = @($argText.Split(' ') | Where-Object { $_ -ne '' }) }
    $total++
    $label = $path
    if ($lineArgs.Count -gt 0) { $label = "$path $($lineArgs -join ' ')" }
    if ($List) { Write-Output "$label`t$interp`t$severity"; continue }

    if ($inCi) { Write-Output "::group::[$total] $label ($severity)" }
    else { Write-Output "=== [$total] $label ($interp, $severity) ===" }
    Write-Output "    $origin"
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $global:LASTEXITCODE = 0
    $lineOut = @(switch ($interp) {
        'bash'      { & $bash $path @lineArgs }
        'bash+uv'   { & $bash -c "$uvPrelude; f=`$1; shift; bash `$f `$@" run-suite $path @lineArgs }
        'uv-python' { & $bash -c "$uvPrelude; uv run --no-project `$@" run-suite $path @lineArgs }
        'ps1'       { & powershell -NoProfile -ExecutionPolicy Bypass -File $path @lineArgs }
        default     { Write-Output "REFUS : unknown interpreter '$interp' for $path"; $global:LASTEXITCODE = 2 }
    })
    $rc = $LASTEXITCODE
    foreach ($l in $lineOut) { Write-Output $l }
    $secs = [int]$sw.Elapsed.TotalSeconds
    if ($inCi) { Write-Output '::endgroup::' }

    if ($rc -eq 0) { $verdict = 'PASS'; $passed++ }
    elseif ($rc -eq 77) {
        $reason = @($lineOut | ForEach-Object { "$_" } | Where-Object { $_ -match '(?i)skip' -and $_ -notmatch '^--- ' }) | Select-Object -Last 1
        if (-not $reason) { $reason = @($lineOut | ForEach-Object { "$_" } | Where-Object { $_.Trim() }) | Select-Object -Last 1 }
        $reason = "$reason".Trim()
        if ($reason.Length -gt 200) { $reason = $reason.Substring(0, 200) }
        # Enforced on a workstation only: the CI runners carry neither gum pinned nor tui-test.
        if ($platforms.Contains('W!') -and $inCi) { $reason = "$reason (required on W, not enforced in CI)" }
        if ($platforms.Contains('W!') -and -not $inCi) {
            $verdict = 'FAIL (required, skipped)'; $failBlocking++
            $skipLines.Add("SKIP (required on W, counted FAIL): $label -- $reason")
            if ($inCi) { Write-Output "::error::$label is required on W and skipped" }
        }
        else {
            $verdict = 'SKIP'; $skipped++
            $skipLines.Add("SKIP: $label -- $reason")
        }
    }
    elseif ($severity -eq 'informational' -or $severity -eq 'on-demand') { $verdict = 'FAIL (informational)'; $failInfo++ }
    else {
        $verdict = 'FAIL'; $failBlocking++
        if ($inCi) { Write-Output "::error::$label failed (exit $rc)" }
    }
    Write-Output "--- $verdict ($rc) ${secs}s $label"
    $verdicts.Add(('{0,-22} {1,5}s  {2}' -f $verdict, $secs, $label))
}

if ($List) { exit 0 }

Write-Output ''
$shardLabel = ''
if ($Shard) { $shardLabel = ", shard $Shard" }
Write-Output "=== SUITE (W$shardLabel, $(Split-Path -Leaf $Manifest)) ==="
foreach ($v in $verdicts) { Write-Output $v }
Write-Output "RESULT: $passed/$total PASS ($skipped SKIP, $failBlocking FAIL blocking, $failInfo FAIL informational)"
foreach ($l in $skipLines) { Write-Output $l }
if ($total -eq 0) {
    Write-Output "REFUS : no line for platform W in $Manifest"
    exit 1
}
if ($failBlocking -gt 0) { exit 1 }
exit 0
