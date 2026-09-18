# Plays the test suite listed in tests/suite.tsv on Windows, from a
# PowerShell parent -- the way the former `shell: powershell` CI steps ran
# the .ps1 tests -- and the bash lines through Git for Windows' bash, the one
# GitHub's `shell: bash` uses (Mission 188). Same manifest, same verdicts and
# same summary as tests/run-suite.sh.
#
# usage: powershell -NoProfile -ExecutionPolicy Bypass -File tests/run-suite.ps1 [-Manifest <file>] [-List]
#
# Every line for Windows is played, even after a red one; exit code 1 if a
# blocking line is red, 0 otherwise. A test exiting 77 reports SKIP. The exit
# code of each test is read straight from $LASTEXITCODE, never behind a pipe
# (Mission 185 defect: a pipe loses it).

param(
    [string]$Manifest,
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

$total = 0; $passed = 0; $skipped = 0; $failBlocking = 0; $failInfo = 0
$verdicts = New-Object System.Collections.Generic.List[string]

foreach ($line in (Get-Content -LiteralPath $Manifest -Encoding UTF8)) {
    if ($line -eq '' -or $line.StartsWith('#')) { continue }
    $f = $line.Split("`t")
    if ($f.Count -lt 6) { Write-Output "REFUS : malformed manifest line: $line"; exit 2 }
    $path = $f[0]; $argText = $f[1]; $interp = $f[2]; $platforms = $f[3]; $severity = $f[4]; $origin = $f[5]
    if (-not $platforms.Contains('W')) { continue }
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
Write-Output "=== SUITE (W, $(Split-Path -Leaf $Manifest)) ==="
foreach ($v in $verdicts) { Write-Output $v }
Write-Output "RESULT: $passed/$total PASS ($skipped SKIP, $failBlocking FAIL blocking, $failInfo FAIL informational)"
if ($total -eq 0) {
    Write-Output "REFUS : no line for platform W in $Manifest"
    exit 1
}
if ($failBlocking -gt 0) { exit 1 }
exit 0
