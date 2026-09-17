#Requires -Version 5.1
<#
.SYNOPSIS
    T1, Windows half (Mission 185-C01, gate 1 of capture
    2026-09-17-144137): a %TEMP% clone that is already there is brought to
    -Ref, never installed as it stands.

.DESCRIPTION
    The gravest defect of the human acceptance: bootstrap.ps1 skipped both
    clone and checkout as soon as <Target>\.git existed. A forgotten
    %TEMP%\second-brain-install (2026-09-14, on a 2026-09-13 commit, older
    than every tag) therefore installed a stale version -- no identity, no
    birth certificate, no Pilot prompt -- with a clean verdict. Invisible
    in CI, where every scenario starts from an empty TestRoot.

    Oracle: a TestRoot whose second-brain-install is already cloned at an
    EARLIER commit, then the line; afterwards the temp folder's HEAD equals
    <Ref>^{commit} and the installed Vault sits at the same commit.
    Negative controls, in this same file:
      - a -Ref that does not exist -> refusal naming the ref, nothing
        installed, the folder left where it was;
      - a temp folder whose origin is not -RepoUrl -> refusal naming both
        repositories and the folder to move aside, nothing installed.

    The real bootstrap is replayed against a LOCAL source (-RepoUrl and
    -RawBase), and the install is stopped right after the clone step: this
    test measures the clone stage, not a full install (measured by
    tests/test-install-e2e.ps1).

    Nothing is written outside a temporary folder (m185 prefix); no network
    call to GitHub, no model call.

    Rerun with:
        powershell -NoProfile -ExecutionPolicy Bypass -File tests\test-bootstrap-stale-temp-clone.ps1 [-KeepTemp]
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

# Le parametre ne s'appelle PAS $Args : c'est une variable automatique de
# PowerShell, et `& git @Args` dans une fonction qui la redeclare lance git
# sans aucun argument -- mesure directement ici, git repondait par son
# ecran d'aide et tout le reste du test mesurait du vide.
function Git-Out {
    param([string[]] $GitArgs)
    $ErrorActionPreference = 'Continue'
    $out = & git @GitArgs 2>&1 | ForEach-Object { "$_" }
    $script:GitExit = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    return (@($out) -join "`n").Trim()
}

$TestRoot = Join-Path $env:TEMP ("m185-stale-" + [Guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Force -Path $TestRoot | Out-Null
Write-Output "=== T1 (PowerShell) : dossier temporaire deja clone ==="
Write-Output "TestRoot: $TestRoot"

try {
    # --- A local source with TWO commits and a tag posted AFTER the first.
    $src = Join-Path $TestRoot 'source'
    $sandbox = To-Posix (Join-Path $RepoRoot 'tests\sandbox-vault.sh')
    $ErrorActionPreference = 'Continue'
    & $bashExe -c ". '$sandbox'; sandbox_find_uv || exit 1; sandbox_vault '$(To-Posix $RepoRoot)' '$(To-Posix $src)'" 2>&1 | Out-Null
    $built = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    Assert-True ($built -eq 0) "source jetable construite depuis l'arbre de travail"
    if ($built -ne 0) { throw "sandbox_vault failed ($built)" }

    $oldRef = Git-Out @('-C', $src, 'rev-parse', 'HEAD')
    Add-Content -Path (Join-Path $src 'USER.md') -Value "`nUne ligne de la version suivante." -Encoding UTF8
    Git-Out @('-C', $src, 'add', '--', 'USER.md') | Out-Null
    Git-Out @('-C', $src, 'commit', '-q', '-m', 'version suivante') | Out-Null
    $newRef = Git-Out @('-C', $src, 'rev-parse', 'HEAD')
    Git-Out @('-C', $src, 'tag', 'v-test') | Out-Null
    $wanted = Git-Out @('-C', $src, 'rev-parse', 'v-test^{commit}')
    Assert-True (($oldRef -ne $newRef) -and ($wanted -eq $newRef)) "controle : deux commits, etiquette v-test sur le second"

    function New-StaleClone {
        param([string] $CaseRoot)
        $target = Join-Path $CaseRoot 'second-brain-install'
        New-Item -ItemType Directory -Force -Path $CaseRoot | Out-Null
        Git-Out @('clone', '--quiet', '--no-checkout', '--', $src, $target) | Out-Null
        Git-Out @('-C', $target, '-c', 'advice.detachedHead=false', 'checkout', '--quiet', '--detach', $oldRef) | Out-Null
        # The Owner's forgotten folder predated publication: it knew no tag.
        # `git clone` always brings them along, so they are removed here to
        # reproduce that state exactly -- the line's own `fetch --tags` is
        # what must bring them back.
        Git-Out @('-C', $target, 'tag', '-d', 'v-test') | Out-Null
        return $target
    }

    function New-AnswersFile {
        param([string] $CaseRoot)
        $answers = Get-Content -Raw -Encoding UTF8 (Join-Path $RepoRoot 'tests\fixtures\install-answers.sample.json') | ConvertFrom-Json
        $answers.workspacePath = Join-Path $CaseRoot 'workspace'
        $path = Join-Path $CaseRoot 'answers.json'
        $answers | ConvertTo-Json -Depth 5 | Set-Content -Path $path -Encoding UTF8
        return $path
    }

    function Invoke-Bootstrap {
        param([string] $CaseRoot, [string] $Ref)
        $ErrorActionPreference = 'Continue'
        $out = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $RepoRoot 'bootstrap.ps1') `
            -Ref $Ref -RepoUrl $src -RawBase $src -TestMode -TestRoot $CaseRoot `
            -AnswersFile (New-AnswersFile $CaseRoot) -StopAfterStep clone 2>&1 | ForEach-Object { "$_" }
        $script:BootExit = $LASTEXITCODE
        $ErrorActionPreference = 'Stop'
        return (@($out) -join "`n")
    }

    # --- (a) oracle -------------------------------------------------------
    Write-Output ""
    Write-Output "=== (a) oracle : le dossier perime est amene a l'etiquette ==="
    $caseA = Join-Path $TestRoot 'a'
    $targetA = New-StaleClone $caseA
    Assert-True ((Git-Out @('-C', $targetA, 'rev-parse', 'HEAD')) -eq $oldRef) "(a) controle : le dossier part d'un commit anterieur"
    Git-Out @('-C', $targetA, 'rev-parse', '--verify', '--quiet', 'refs/tags/v-test') | Out-Null
    Assert-True ($script:GitExit -ne 0) "(a) controle : le dossier ne connait pas encore l'etiquette"

    $outA = Invoke-Bootstrap $caseA 'v-test'
    ($outA -split "`n") | Select-Object -Last 3 | ForEach-Object { Write-Output "    $_" }
    Assert-True ($outA -match 'after step: clone') "(a) l'installation a bien atteint l'etape de clone"
    Assert-True ((Git-Out @('-C', $targetA, 'rev-parse', 'HEAD')) -eq $wanted) "(a) dossier temporaire : HEAD = v-test^{commit} ($wanted)"
    $installedA = Join-Path $caseA 'workspace\second-brain'
    $installedHead = if (Test-Path (Join-Path $installedA '.git')) { Git-Out @('-C', $installedA, 'rev-parse', 'HEAD') } else { 'absent' }
    Assert-True ($installedHead -eq $wanted) "(a) Vault installe : HEAD = v-test^{commit} (lu : $installedHead)"
    $userMd = Join-Path $installedA 'USER.md'
    Assert-True ((Test-Path $userMd) -and ((Get-Content -Raw -Encoding UTF8 $userMd) -match 'Une ligne de la version suivante')) `
        "(a) le contenu installe est celui de v-test, pas celui du dossier perime"

    # --- (b) temoin : -Ref inexistant -------------------------------------
    Write-Output ""
    Write-Output "=== (b) temoin : -Ref inexistant ==="
    $caseB = Join-Path $TestRoot 'b'
    $targetB = New-StaleClone $caseB
    $outB = Invoke-Bootstrap $caseB 'v-inexistante'
    Assert-True ($script:BootExit -ne 0) "(b) rend un code non nul (exit $($script:BootExit))"
    Assert-True ($outB -match 'v-inexistante') "(b) le refus nomme le ref demande"
    Assert-True (-not (Test-Path (Join-Path $caseB 'workspace\second-brain'))) "(b) rien n'est installe"
    Assert-True ((Git-Out @('-C', $targetB, 'rev-parse', 'HEAD')) -eq $oldRef) "(b) le dossier temporaire est laisse ou il etait, jamais supprime"

    # --- (c) temoin : une AUTRE origine -----------------------------------
    Write-Output ""
    Write-Output "=== (c) temoin : dossier temporaire d'une AUTRE origine ==="
    $caseC = Join-Path $TestRoot 'c'
    $targetC = New-StaleClone $caseC
    $other = Join-Path $TestRoot 'autre-depot'
    New-Item -ItemType Directory -Force -Path $other | Out-Null
    Git-Out @('-C', $targetC, 'remote', 'set-url', 'origin', $other) | Out-Null
    $outC = Invoke-Bootstrap $caseC 'v-test'
    Assert-True ($script:BootExit -ne 0) "(c) rend un code non nul (exit $($script:BootExit))"
    # Chaque URL est nommee telle que sa source l'ecrit (celle du dossier
    # vient de son .git/config) : on compare les depots nommes, pas une
    # orthographe.
    Assert-True (($outC -match [regex]::Escape((Split-Path $other -Leaf))) -and ($outC -match [regex]::Escape((Split-Path $src -Leaf)))) `
        "(c) le refus nomme les DEUX depots"
    Assert-True ($outC -match [regex]::Escape($targetC)) "(c) le refus nomme le dossier a ecarter"
    Assert-True (-not (Test-Path (Join-Path $caseC 'workspace\second-brain'))) "(c) rien n'est installe"
    Assert-True (Test-Path (Join-Path $targetC '.git')) "(c) le dossier temporaire n'est jamais supprime"
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
