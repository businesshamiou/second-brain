#Requires -Version 5.1
<#
.SYNOPSIS
    Mission 236: the Windows launcher of sb (tools\sb\bin\sb.cmd) answers from
    PowerShell and from cmd, with the exit codes of the rule.

.DESCRIPTION
    Rerun with one command, from the repository root:

        powershell -NoProfile -ExecutionPolicy Bypass -File tests\test-sb-command-windows.ps1

    Oracle:
      (a) sb.cmd --version answers, exit 0, and names this Vault;
      (b) sb.cmd help, in French, English and Spanish, exit 0, lists the verbs
          and keeps the accents readable (no replacement character);
      (c) an unknown verb is exit 2, from PowerShell and from cmd /c -- the
          launcher passes the code through (a batch file that expands
          %ERRORLEVEL% inside a parenthesised block would answer 0);
      (d) sb.cmd open at the root of a folder outside any workspace is exit 3;
      (e) sb.cmd is stored with CRLF line endings (tools\sb\bin\.gitattributes).
      (f) Mission 241: sb.cmd help start, in French, English and Spanish,
          exit 0, carries the step of the welcome Pilot (sb pilot-prompt
          --accueil, SB - Accueil) and ten numbered steps, accents readable;
      (g) sb.cmd pilot-prompt --accueil, in the three languages, from inside
          the workspace, exit 0, prints the welcome block between two lines
          -- no bash typed; outside any workspace it is served in sb's own
          Vault's workspace (Mission 244);
      (h) sb.cmd doctor with a PATH that holds no bash (uv, Git's cmd folder
          and Windows only, as in a bare PowerShell) says so on a WARN line
          with the form to type, and ends non-blocking (exit 0).
    Writes nothing outside a folder of its own under the declared temporary
    folder (tools\lib\tmp.ps1).

    Exit code 0 means every assertion passed; 1 otherwise.
#>

# Continue, not Stop: a native command that writes on stderr (the refusals)
# would otherwise end the script under Windows PowerShell 5.1.
$ErrorActionPreference = 'Continue'
# sb writes UTF-8. A console shows it as is (sb sets the console to UTF-8); a
# capture is decoded by PowerShell with [Console]::OutputEncoding, which is the
# OEM code page when PowerShell runs without a console (under a runner, or
# launched from Git Bash): set it, so the check reads what sb wrote.
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch { }
$RepoRoot = Split-Path $PSScriptRoot -Parent
$Launcher = Join-Path $RepoRoot 'tools\sb\bin\sb.cmd'
$failures = New-Object System.Collections.Generic.List[string]

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if ($Condition) { Write-Output "  PASS - $Message" }
    else { Write-Output "  FAIL - $Message"; $failures.Add($Message) | Out-Null }
}

Write-Output "=== Mission 236 : sb.cmd sous PowerShell et cmd ==="

$out = & $Launcher --version 2>&1 | Out-String
Assert-True ($LASTEXITCODE -eq 0 -and $out -match '^sb ' -and $out -match [regex]::Escape($RepoRoot)) "(a) sb.cmd --version (exit $LASTEXITCODE)"

foreach ($lang in 'fr', 'en', 'es') {
    $out = & $Launcher help --lang $lang 2>&1 | Out-String
    $ok = ($LASTEXITCODE -eq 0) -and ($out -match 'pilot-prompt') -and ($out -match 'add-skill') -and ($out -notmatch [char]0xFFFD)
    Assert-True $ok "(b) sb.cmd help --lang $lang (exit $LASTEXITCODE)"
}
$out = & $Launcher help --lang fr 2>&1 | Out-String
$needle = 'O' + [char]0x00F9 + ' suis-je'
Assert-True ($out.Contains($needle)) "(b) accents lisibles : 'Ou suis-je' (u accent grave) present dans la sortie capturee"

& $Launcher frobnicate 2>&1 | Out-Null
Assert-True ($LASTEXITCODE -eq 2) "(c) verbe inconnu depuis PowerShell : exit $LASTEXITCODE"
cmd /c "`"$Launcher`" frobnicate >nul 2>nul"
Assert-True ($LASTEXITCODE -eq 2) "(c) verbe inconnu depuis cmd /c : exit $LASTEXITCODE"

. (Join-Path $RepoRoot 'tools\lib\tmp.ps1')
$outside = Join-Path (Get-SbTmpDir 'tests') ("m236-sbwin-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path $outside | Out-Null
try {
    Push-Location $outside
    & $Launcher open 2>&1 | Out-Null
    $code = $LASTEXITCODE
    Pop-Location
    Assert-True ($code -eq 3) "(d) sb.cmd open hors de tout espace : exit $code"

    # (g) Mission 244 (finding 1): outside any workspace -- a PowerShell opens
    # in system32 -- the welcome block is served in the workspace of sb's own
    # Vault, said in one line, instead of a refusal.
    Push-Location $outside
    $gOut = (& $Launcher pilot-prompt --accueil 2>&1 | Out-String)
    $code = $LASTEXITCODE
    Pop-Location
    Assert-True ($code -eq 0 -and $gOut -match 'welcome Pilot') "(g) sb.cmd pilot-prompt --accueil hors de tout espace : exit $code, bloc d'accueil"
}
finally {
    Remove-Item -Recurse -Force $outside -ErrorAction SilentlyContinue
}

$bytes = [System.IO.File]::ReadAllBytes($Launcher)
$text = [System.Text.Encoding]::ASCII.GetString($bytes)
$lf = ([regex]::Matches($text, "`n")).Count
$crlf = ([regex]::Matches($text, "`r`n")).Count
Assert-True ($lf -gt 0 -and $lf -eq $crlf) "(e) sb.cmd en CRLF ($crlf/$lf fins de ligne)"

# Mission 241 -- (f) the first steps, (g) the welcome block, (h) doctor without bash.
foreach ($lang in 'fr', 'en', 'es') {
    $out = & $Launcher help start --lang $lang 2>&1 | Out-String
    $ok = ($LASTEXITCODE -eq 0) -and $out.Contains('sb pilot-prompt --accueil') -and $out.Contains('SB - Accueil') -and
          ($out -match '(?m)^  10\. ') -and ($out -notmatch '(?m)^  11\. ') -and ($out -notmatch [char]0xFFFD)
    Assert-True $ok "(f) sb.cmd help start --lang $lang : etape SB - Accueil, dix etapes (exit $LASTEXITCODE)"
}
$out = & $Launcher help start --lang fr 2>&1 | Out-String
$needle = 'Te pr' + [char]0x00E9 + 'senter'
Assert-True ($out.Contains($needle)) "(f) accents lisibles : 'Te presenter' (e accent aigu) present dans la sortie capturee"

# (g) and (h) need this Vault inside a workspace (a VAULT-ROOT.md above it);
# a bare checkout, as in CI, has none: said, and those cases are not played
# (tests/test-sb-command.sh plays them on a throwaway workspace).
$workspace = $null
$dir = Split-Path $RepoRoot -Parent
while ($dir) {
    if (Test-Path (Join-Path $dir 'VAULT-ROOT.md')) { $workspace = $dir; break }
    $parent = Split-Path $dir -Parent
    if ($parent -eq $dir) { break }
    $dir = $parent
}
if (-not $workspace) {
    Write-Output "  NOTE - (g)(h) non joues : aucun VAULT-ROOT.md au-dessus de $RepoRoot (checkout nu) ; tests/test-sb-command.sh les joue sur un espace jetable"
}
else {
Push-Location $RepoRoot
try {
    foreach ($lang in 'fr', 'en', 'es') {
        $out = & $Launcher pilot-prompt --accueil --lang $lang 2>&1 | Out-String
        $dashes = ([regex]::Matches($out, '(?m)^---\r?$')).Count
        $ok = ($LASTEXITCODE -eq 0) -and $out.Contains('SB - Accueil') -and $out.Contains('You are the welcome Pilot') -and
              ($dashes -eq 2) -and ($out -notmatch [char]0xFFFD)
        Assert-True $ok "(g) sb.cmd pilot-prompt --accueil --lang $lang : bloc d'accueil entre deux traits (exit $LASTEXITCODE)"
    }

    # (h) A bare PowerShell: uv, Git's cmd folder (git.exe, never bash.exe) and
    # Windows. The child inherits this PATH; the session's is restored after.
    $savedPath = $env:PATH
    try {
        $uvDir = Split-Path (Get-Command uv -ErrorAction Stop).Source -Parent
        $gitCmd = Split-Path (Get-Command git -ErrorAction Stop).Source -Parent
        if ((Split-Path $gitCmd -Leaf) -ne 'cmd') {
            $gitCmd = Join-Path (Split-Path (Split-Path $gitCmd -Parent) -Parent) 'cmd'
        }
        $env:PATH = "$uvDir;$gitCmd;$env:WINDIR\System32;$env:WINDIR"
        $bashSeen = [bool](Get-Command bash -ErrorAction SilentlyContinue | Where-Object { $_.Source -notlike "$env:WINDIR*" })
        $out = & $Launcher doctor --lang en 2>&1 | Out-String
        $code = $LASTEXITCODE
    }
    finally {
        $env:PATH = $savedPath
    }
    $ok = (-not $bashSeen) -and ($code -eq 0) -and ($out -match '(?m)^  WARN  bash ') -and $out.Contains('bash.exe"') -and $out.Contains('Nothing blocking')
    Assert-True $ok "(h) sb.cmd doctor sans bash dans le PATH : WARN bash avec la forme a taper, non bloquant (exit $code)"
}
finally {
    Pop-Location
}
}

Write-Output ""
if ($failures.Count -eq 0) { Write-Output "=== RESULT: PASS ==="; exit 0 }
Write-Output "=== RESULT: FAIL ($($failures.Count)) ==="
exit 1
