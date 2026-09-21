# Plays the test suite listed in tests/suite.tsv on Windows, from a
# PowerShell parent -- the way the former `shell: powershell` CI steps ran
# the .ps1 tests -- and the bash lines through Git for Windows' bash, the one
# GitHub's `shell: bash` uses (Mission 188). Same manifest, same verdicts and
# same summary as tests/run-suite.sh.
#
# usage: powershell -NoProfile -ExecutionPolicy Bypass -File tests/run-suite.ps1 [-Manifest <file>] [-Shard k/n] [-Changed [-Ref <ref>]] [-List]
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
# Every line for Windows is played, even after a red one; exit code 1 if a
# blocking line is red, 0 otherwise. A test exiting 77 reports SKIP. The exit
# code of each test is read straight from $LASTEXITCODE, never behind a pipe
# (Mission 185 defect: a pipe loses it).

param(
    [string]$Manifest,
    [string]$Shard,
    [switch]$Changed,
    [string]$Ref,
    [switch]$List
)

$ErrorActionPreference = 'Continue'
$RepoRoot = Split-Path -Parent $PSScriptRoot
if (-not $Manifest) { $Manifest = Join-Path $RepoRoot 'tests\suite.tsv' }
if (-not (Test-Path -LiteralPath $Manifest)) {
    Write-Output "REFUS : manifest not found: $Manifest"
    exit 2
}
Set-Location -LiteralPath $RepoRoot

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
$selectAll = $false
$changedRef = ''

function Test-ChangedSelects([string]$path, [string]$origin) {
    if ($selectAll) { return $true }
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
        if (@('tests/suite.tsv', 'tests/run-suite.sh', 'tests/run-suite.ps1') -ccontains $cf) { $selectAll = $true }
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
    if ($selectAll) { [Console]::Error.WriteLine('--changed : le lanceur ou le manifeste a change : toute la suite est selectionnee') }
    elseif ($selTests -eq 0) { [Console]::Error.WriteLine('--changed : aucun test ne nomme les fichiers changes ; seuls les gardiens jouent') }
}

$total = 0; $passed = 0; $skipped = 0; $failBlocking = 0; $failInfo = 0
$verdicts = New-Object System.Collections.Generic.List[string]

foreach ($line in (Get-Content -LiteralPath $Manifest -Encoding UTF8)) {
    if ($line -eq '' -or $line.StartsWith('#')) { continue }
    $f = $line.Split("`t")
    if ($f.Count -lt 6) { Write-Output "REFUS : malformed manifest line: $line"; exit 2 }
    $path = $f[0]; $argText = $f[1]; $interp = $f[2]; $platforms = $f[3]; $severity = $f[4]; $origin = $f[5]
    if (-not $platforms.Contains('W')) { continue }
    if ($shardK -and ($f.Count -lt 7 -or $f[6] -ne $shardK)) { continue }
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
    switch ($interp) {
        'bash'      { & $bash $path @lineArgs }
        'bash+uv'   { & $bash -c "$uvPrelude; f=`$1; shift; bash `$f `$@" run-suite $path @lineArgs }
        'uv-python' { & $bash -c "$uvPrelude; uv run --no-project `$@" run-suite $path @lineArgs }
        'ps1'       { & powershell -NoProfile -ExecutionPolicy Bypass -File $path @lineArgs }
        default     { Write-Output "REFUS : unknown interpreter '$interp' for $path"; $global:LASTEXITCODE = 2 }
    }
    $rc = $LASTEXITCODE
    $secs = [int]$sw.Elapsed.TotalSeconds
    if ($inCi) { Write-Output '::endgroup::' }

    if ($rc -eq 0) { $verdict = 'PASS'; $passed++ }
    elseif ($rc -eq 77) { $verdict = 'SKIP'; $skipped++ }
    elseif ($severity -eq 'informational') { $verdict = 'FAIL (informational)'; $failInfo++ }
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
if ($total -eq 0) {
    Write-Output "REFUS : no line for platform W in $Manifest"
    exit 1
}
if ($failBlocking -gt 0) { exit 1 }
exit 0
