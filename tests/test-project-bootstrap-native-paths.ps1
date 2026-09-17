#Requires -Version 5.1
<#
.SYNOPSIS
    T7 (Mission 185-C01, gate 9 of capture 2026-09-17-144137): under
    Windows, the paths project-bootstrap.sh hands to the Pilot and to the
    participant are native (C:\...), never Git Bash's /c/... form.

.DESCRIPTION
    Measured on the Owner's workstation: state/PILOT-PROMPT.md carried
    the project path in Git Bash form, while the MCP server, the
    desktop application and the participant all read `C:\Users\...`. The
    Pilot had to reason its way from one to the other; nothing guaranteed
    it would.

    This half runs from PowerShell -- the shell a Windows participant
    actually uses -- and drives tools/project-bootstrap.sh through Git's
    own bash, exactly as INSTALL.md now tells them to. It checks the three
    surfaces gate 9 names:
      - <project>/state/PILOT-PROMPT.md
      - the project record projects/PROJECT-*.md
      - the "block to consume" printed on the output

    The negative control lives in the shell twin,
    tests/test-project-bootstrap-native-paths.sh, which runs on macOS and
    Linux: with no cygpath, the POSIX path must come back rigorously
    unchanged. Both halves are chained in CI, neither is informational.

    Nothing is written outside a temporary folder (m185 prefix).

    Rerun with:
        powershell -NoProfile -ExecutionPolicy Bypass -File tests\test-project-bootstrap-native-paths.ps1
#>

[CmdletBinding()]
param([switch] $KeepTemp)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path $PSScriptRoot -Parent
$failures = New-Object System.Collections.Generic.List[string]

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if ($Condition) { Write-Output "  PASS - $Message" }
    else { Write-Output "  FAIL - $Message"; $failures.Add($Message) | Out-Null }
}

. (Join-Path $RepoRoot 'tools\resolve-bash-exe.ps1')
$bashExe = Resolve-BashExe

function To-Posix {
    param([string] $Path)
    $out = & $bashExe -c "cygpath -u '$($Path -replace '\\', '\\')'" 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $out) { return ($Path -replace '\\', '/') }
    return ("$out").Trim()
}

$TestRoot = Join-Path $env:TEMP ("m185-native-" + [Guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Force -Path $TestRoot | Out-Null
Write-Output "=== T7 (PowerShell) : chemins natifs sous Windows ==="
Write-Output "TestRoot: $TestRoot"

try {
    $workspace = Join-Path $TestRoot 'ws'
    New-Item -ItemType Directory -Force -Path $workspace | Out-Null
    $vault = Join-Path $workspace 'second-brain'

    # Vault jetable construit a partir de l'ARBRE DE TRAVAIL (jamais un
    # clone, qui jouerait le code committe) : meme aide que les tests shell.
    $sandbox = To-Posix (Join-Path $RepoRoot 'tests\sandbox-vault.sh')
    $srcPosix = To-Posix $RepoRoot
    $vaultPosix = To-Posix $vault
    $wsPosix = To-Posix $workspace
    $ErrorActionPreference = 'Continue'
    & $bashExe -c ". '$sandbox'; sandbox_find_uv || exit 1; sandbox_vault '$srcPosix' '$vaultPosix'" 2>&1 | Out-Null
    $built = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    Assert-True ($built -eq 0) "Vault jetable construit depuis l'arbre de travail"
    if ($built -ne 0) { throw "sandbox_vault failed ($built)" }

    & $bashExe -c ". '$sandbox'; sandbox_find_uv; bash '$vaultPosix/tools/write-marker.sh' '$wsPosix'" 2>&1 | Out-Null

    $project = Join-Path $workspace 'projet'
    $projectPosix = To-Posix $project
    $ErrorActionPreference = 'Continue'
    $output = & $bashExe -c ". '$sandbox'; sandbox_find_uv; bash '$vaultPosix/tools/project-bootstrap.sh' create '$projectPosix' 'Projet' --vcs none < /dev/null" 2>&1 | ForEach-Object { "$_" }
    $rc = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    Assert-True ($rc -eq 0) "project-bootstrap.sh create rend 0 (exit $rc)"
    if ($rc -ne 0) { $output | Select-Object -Last 8 | ForEach-Object { Write-Output "    $_" } }

    $pilotPrompt = Join-Path $project 'state\PILOT-PROMPT.md'
    $fiche = @(Get-ChildItem -Path (Join-Path $vault 'projects') -Filter 'PROJECT-*.md' -File |
               Where-Object { $_.Name -ne 'PROJECT-REGISTRY.md' } | Select-Object -First 1)
    Assert-True (Test-Path $pilotPrompt) "state\PILOT-PROMPT.md existe"
    Assert-True ($fiche.Count -eq 1) "la fiche de projet existe"

    # La forme native attendue, telle que Windows l'ecrit.
    $nativeProject = (Resolve-Path $project).Path

    $surfaces = @()
    if (Test-Path $pilotPrompt) { $surfaces += ,@('PILOT-PROMPT.md', (Get-Content -Raw -Encoding UTF8 $pilotPrompt)) }
    if ($fiche.Count -eq 1) { $surfaces += ,@($fiche[0].Name, (Get-Content -Raw -Encoding UTF8 $fiche[0].FullName)) }
    $surfaces += ,@('bloc a consommer', ((@($output) -join "`n")))

    foreach ($s in $surfaces) {
        $name = $s[0]
        $text = "$($s[1])"
        Assert-True ($text.Contains($nativeProject)) "$name porte le chemin natif ($nativeProject)"
        # /c/Users, /c/Windows, /d/... : la forme Git Bash d'un chemin de
        # lecteur. Cherchee telle quelle, jamais par un motif large qui
        # confondrait un lien relatif avec un chemin absolu.
        $posixDrive = [regex]::IsMatch($text, '(?<![A-Za-z0-9_.-])/[A-Za-z]/(Users|Windows|Temp|home)')
        Assert-True (-not $posixDrive) "$name ne porte aucun chemin /c/..."
    }
}
catch {
    Write-Output "  FAIL - unhandled error: $($_.Exception.Message)"
    $failures.Add("unhandled error: $($_.Exception.Message)") | Out-Null
}

if ($KeepTemp) {
    Write-Output "TestRoot kept (-KeepTemp): $TestRoot"
}
else {
    try { & $bashExe -c "rm -rf -- '$(To-Posix $TestRoot)'" } catch { }
}

Write-Output ""
if ($failures.Count -eq 0) {
    Write-Output "=== RESULT: PASS (all checks green) ==="
    exit 0
}
Write-Output "=== RESULT: FAIL ($($failures.Count) check(s) failed) ==="
$failures | ForEach-Object { Write-Output "  - $_" }
exit 1
