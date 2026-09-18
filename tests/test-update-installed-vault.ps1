#Requires -Version 5.1
<#
.SYNOPSIS
    T5, Windows side (Mission 191-C01): tools/second-brain-update.ps1 runs
    the one implementation (second-brain-update.sh through Git's bash) and
    keeps its closed verdict and its exit code.

.DESCRIPTION
    The merge itself is proven by tests/test-update-installed-vault.sh (run
    on the three systems, Windows included). Here, the wrapper only:
      (a) a folder that is not a Git clone -> VERDICT: REFUSED, exit 1;
      (b) a Git clone without a generated identity -> VERDICT: REFUSED,
          exit 1, the message naming VAULT-IDENTITY.md;
      (c) negative control: the same clone with uncommitted changes -> the
          refusal names the uncommitted file, which proves the arguments and
          the -Vault path reach the script.
    Writes only in a temporary folder.
#>
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$wrapper = Join-Path $repoRoot 'tools\second-brain-update.ps1'
$failures = 0
function Pass([string]$m) { Write-Output "  PASS - $m" }
function Fail([string]$m) { Write-Output "  FAIL - $m"; $script:failures++ }

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("m191-update-ps1-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
try {
    Write-Output "=== T5 (Windows) : enveloppe second-brain-update.ps1 ==="

    $notGit = Join-Path $tmp 'not-a-clone'
    New-Item -ItemType Directory -Force -Path $notGit | Out-Null
    $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $wrapper v0.1.8 -Vault $notGit -Lang EN 2>&1 | Out-String
    $code = $LASTEXITCODE
    if ($code -eq 1 -and $out -match 'VERDICT: REFUSED' -and $out -match 'not a Git clone') { Pass "(a) dossier hors Git : REFUSED, sortie 1" } else { Fail "(a) dossier hors Git : sortie $code -- $out" }

    $clone = Join-Path $tmp 'clone'
    New-Item -ItemType Directory -Force -Path $clone | Out-Null
    & git -C $clone init -q 2>$null
    & git -C $clone config user.email t@example.invalid
    & git -C $clone config user.name t
    Set-Content -Path (Join-Path $clone 'README.md') -Value 'x' -Encoding ASCII
    & git -C $clone add README.md
    & git -C $clone commit -q -m init 2>$null
    $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $wrapper v0.1.8 -Vault $clone -Lang EN 2>&1 | Out-String
    $code = $LASTEXITCODE
    if ($code -eq 1 -and $out -match 'VERDICT: REFUSED' -and $out -match 'VAULT-IDENTITY.md') { Pass "(b) clone sans identite : REFUSED nommant VAULT-IDENTITY.md" } else { Fail "(b) clone sans identite : sortie $code -- $out" }

    Set-Content -Path (Join-Path $clone 'pending-change.txt') -Value 'y' -Encoding ASCII
    $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $wrapper v0.1.8 -Vault $clone -Lang EN 2>&1 | Out-String
    $code = $LASTEXITCODE
    if ($code -eq 1 -and $out -match 'pending-change.txt') { Pass "(c) temoin : changement non commite nomme (arguments et -Vault transmis)" } else { Fail "(c) temoin : sortie $code -- $out" }
}
finally {
    Remove-Item -Recurse -Force -LiteralPath $tmp -ErrorAction SilentlyContinue
}

Write-Output ""
if ($failures -eq 0) { Write-Output "=== RESULT: PASS ==="; exit 0 }
Write-Output "=== RESULT: FAIL ($failures) ==="
exit 1
