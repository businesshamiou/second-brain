#Requires -Version 5.1
<#
.SYNOPSIS
    Main test for tools/prerequisites.ps1 (Mission 168, ticket 04).

.DESCRIPTION
    Rerun this exact test with one command, from the repository root:

        powershell -NoProfile -ExecutionPolicy Bypass -File tests\test-prerequisites-e2e.ps1

    What it proves, in a single fresh, blank temporary workspace, with Git,
    uv, pre-commit and Python hidden from this *process's own* PATH (never
    the real user PATH -- see "PATH simulation" below):
      1. With the three tools hidden, install.ps1 -TestMode still succeeds:
         it detects their absence, installs its own pinned Git (portable
         Git for Windows), uv (official installer) and pre-commit (`uv
         tool install`) into -TestRoot's simulated profile, and the
         resulting verdict, session-preflight READY check and trial commit
         are identical to ticket 03's own main test (ticket 04, criterion
         5's "le test principal passe").
      2. Each installed tool resolves from *inside* -TestRoot, never from
         the real machine install, and reports the exact version pinned in
         tools/prerequisites.lock.json (criterion 3, "versions figees").
      3. A second run, unchanged inputs and still-hidden PATH, is a true
         no-op: identical verdict, empty porcelain -- proving the tools
         already installed on the first run are reused, not reinstalled
         (criterion 4, "aucun doublon installe").
      4. A deliberately wrong pinned SHA-256 stops the download outright,
         names the cause, and never leaves the mismatching file on disk
         (criterion 3, "empreinte fausse = arret").
      5. Neither install.ps1 nor tools/prerequisites.ps1 contains an
         elevation trigger (-Verb RunAs), and this process is never
         elevated before or after (criterion 5, "le processus n'est jamais
         eleve").
      6. Throughout, the Owner's real environment is untouched: the user
         PATH (HKCU\Environment\Path) and both skill folders
         (~/.claude/skills, ~/.codex/skills) are fingerprinted before and
         after and asserted identical.

    PATH simulation (Mission constraint, "environnement de l'Owner
    intact"): this script hides Git/uv/pre-commit/Python by rewriting
    $env:Path -- a .NET/PowerShell process-local environment variable --
    for *this test process only*, restored in a `finally` block. This never
    touches HKCU\Environment (the real, persistent user PATH); a child
    process (install.ps1, invoked in-process via the `&` call operator)
    inherits the trimmed PATH exactly like it would inherit a genuinely
    bare machine's PATH.

    Exit code 0 means every assertion above passed. Exit code 1 means at
    least one did not; details are printed to stdout as each check runs.
#>

[CmdletBinding()]
param(
    [switch] $KeepTemp
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path $PSScriptRoot -Parent
$failures = New-Object System.Collections.Generic.List[string]

# Shared with install.ps1 -- one copy each of the bash.exe lookup, the
# environment fingerprint, and the prerequisites module itself.
. (Join-Path $RepoRoot 'tools\resolve-bash-exe.ps1')
. (Join-Path $RepoRoot 'tools\environment-fingerprint.ps1')
. (Join-Path $RepoRoot 'tools\prerequisites.ps1')

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if ($Condition) {
        Write-Output "  PASS - $Message"
    }
    else {
        Write-Output "  FAIL - $Message"
        $failures.Add($Message) | Out-Null
    }
}

function Test-ProcessIsElevated {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

Write-Output "=== 1. Real-environment fingerprint (before) ==="
$before = Get-EnvironmentFingerprint
Write-Output "  PATH SHA-256: $($before.PathHash)"
Write-Output "  .claude/skills entries: $($before.ClaudeSkills.Count)"
Write-Output "  .claude/agents entries: $($before.ClaudeAgents.Count)"
Write-Output "  .codex/skills entries: $($before.CodexSkills.Count)"
Write-Output "  .agents/skills entries: $($before.CodexAgentsSkills.Count)"
Assert-True (-not (Test-ProcessIsElevated)) "test process is not elevated before anything runs"

# uv's own official installer writes an update-receipt under the real
# %LOCALAPPDATA%\uv when it manages the PATH/update lifecycle itself;
# tools/prerequisites.ps1 relies on UV_UNMANAGED_INSTALL to suppress that
# (code comment in Resolve-OrInstall-Uv). Proven here, not just asserted in
# a comment: fingerprint this real directory too, the same way the real
# user PATH and skill folders are fingerprinted below.
$realLocalAppDataUv = Join-Path $env:LOCALAPPDATA 'uv'
$realUvBefore = @(Get-ChildItem -Recurse -File $realLocalAppDataUv -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName | Sort-Object)

Write-Output ""
Write-Output "=== 2. Static guarantee: no elevation trigger in the prerequisites code path ==="
$sourceText = (Get-Content -Raw (Join-Path $RepoRoot 'install.ps1')) `
    + (Get-Content -Raw (Join-Path $RepoRoot 'tools\prerequisites.ps1'))
Assert-True ($sourceText -notmatch '(?i)-Verb\s+RunAs') "no -Verb RunAs (UAC elevation) in install.ps1 or tools/prerequisites.ps1"

Write-Output ""
Write-Output "=== 3. Wrong pinned fingerprint stops the download, names the cause (criterion 3) ==="
$lock = Get-PrerequisitesLock
$hashMismatchDir = Join-Path $env:TEMP ("sb-hash-check-" + [Guid]::NewGuid().ToString('N'))
$threw = $false
$errorMessage = $null
try {
    Get-CachedOrDownloadedFile -Url $lock.uv.installScriptUrl `
        -ExpectedSha256 ('0' * 64) -CacheDir $hashMismatchDir -FileName 'deliberately-wrong.ps1' | Out-Null
}
catch {
    $threw = $true
    $errorMessage = $_.Exception.Message
}
Assert-True $threw "a wrong pinned SHA-256 throws instead of silently accepting the download"
Assert-True ($null -ne $errorMessage -and $errorMessage -match 'SHA-256 mismatch') "the stop names the cause (SHA-256 mismatch): $errorMessage"
Assert-True (-not (Test-Path (Join-Path $hashMismatchDir 'deliberately-wrong.ps1'))) "the mismatching download is not left on disk"
Remove-Item -Recurse -Force $hashMismatchDir -ErrorAction SilentlyContinue

$TestRoot = Join-Path $env:TEMP ("sb-prereq-e2e-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $TestRoot | Out-Null
Write-Output ""
Write-Output "=== 4. Fresh, blank temporary workspace ==="
Write-Output "  TestRoot: $TestRoot"

$workspacePath = Join-Path $TestRoot 'workspace'
$answersPath = Join-Path $TestRoot 'answers.json'
$sampleAnswers = Get-Content -Raw -Path (Join-Path $PSScriptRoot 'fixtures\install-answers.sample.json') | ConvertFrom-Json
$sampleAnswers.workspacePath = $workspacePath
$sampleAnswers | ConvertTo-Json -Depth 10 | Set-Content -Path $answersPath -Encoding UTF8

$installScript = Join-Path $RepoRoot 'install.ps1'
$clonePath = Join-Path $workspacePath 'second-brain'
$firstProjectPath = Join-Path $workspacePath $sampleAnswers.firstProject.name

# --- PATH simulation: hide Git, uv, pre-commit and Python from *this
# process's own* PATH (never the real, persistent user PATH -- see the
# header comment). Directories are derived from what is genuinely on this
# machine's PATH right now, not hard-coded, so the test does not assume a
# particular dev machine layout. ---------------------------------------
$originalPath = $env:Path
try {
    $toolsToHide = @('git.exe', 'uv.exe', 'pre-commit.exe', 'python.exe')
    $dirsToExclude = New-Object System.Collections.Generic.List[string]
    foreach ($tool in $toolsToHide) {
        $cmd = Get-Command $tool -ErrorAction SilentlyContinue
        if ($cmd) { $dirsToExclude.Add((Split-Path $cmd.Source -Parent)) }
    }
    # Git for Windows contributes more than one PATH directory (cmd\,
    # mingw64\bin\); hiding only the cmd\ one would leave `git` resolvable
    # through the other. Exclude every current PATH entry that lives under
    # the same install root as git.exe.
    $gitCmd = Get-Command git.exe -ErrorAction SilentlyContinue
    if ($gitCmd) {
        $gitRoot = Split-Path (Split-Path $gitCmd.Source -Parent) -Parent
        foreach ($entry in ($originalPath -split ';')) {
            if ($entry -like "$gitRoot*") { $dirsToExclude.Add($entry) }
        }
    }
    $dirsToExclude = $dirsToExclude | Select-Object -Unique

    $restrictedParts = $originalPath -split ';' | Where-Object {
        $entry = $_
        ($entry -ne '') -and (-not ($dirsToExclude -contains $entry))
    }
    $env:Path = ($restrictedParts -join ';')

    Write-Output ""
    Write-Output "=== 5. Simulated PATH: Git, uv, pre-commit and Python are absent ==="
    Assert-True ($null -eq (Get-Command git.exe -ErrorAction SilentlyContinue)) "git.exe absent from the simulated PATH"
    Assert-True ($null -eq (Get-Command uv.exe -ErrorAction SilentlyContinue)) "uv.exe absent from the simulated PATH"
    Assert-True ($null -eq (Get-Command pre-commit.exe -ErrorAction SilentlyContinue)) "pre-commit.exe absent from the simulated PATH"
    Assert-True ($null -eq (Get-Command python.exe -ErrorAction SilentlyContinue)) "python.exe absent from the simulated PATH"

    Write-Output ""
    Write-Output "=== 6. First run: prerequisites install into -TestRoot, then the main flow ==="
    $verdict1 = & $installScript -Source $RepoRoot -AnswersFile $answersPath -TestMode -TestRoot $TestRoot
    $exit1 = $LASTEXITCODE
    Write-Output "  verdict: $verdict1"
    Assert-True ($exit1 -eq 0) "first run exits 0 (with Git/uv/pre-commit hidden)"
    Assert-True ($verdict1 -match 'Installation complete') "first run verdict reports success"

    Write-Output ""
    Write-Output "=== 7. Each tool resolves from inside -TestRoot, at its pinned version ==="
    $gitAfter = Get-Command git.exe -ErrorAction SilentlyContinue
    $uvAfter = Get-Command uv.exe -ErrorAction SilentlyContinue
    $preCommitAfter = Get-Command pre-commit.exe -ErrorAction SilentlyContinue
    Assert-True ($null -ne $gitAfter) "git.exe resolvable after Assure-Prerequisites"
    Assert-True ($null -ne $uvAfter) "uv.exe resolvable after Assure-Prerequisites"
    Assert-True ($null -ne $preCommitAfter) "pre-commit.exe resolvable after Assure-Prerequisites"
    if ($gitAfter) { Assert-True ($gitAfter.Source -like "$TestRoot*") "git.exe resolved from inside TestRoot ($($gitAfter.Source))" }
    if ($uvAfter) { Assert-True ($uvAfter.Source -like "$TestRoot*") "uv.exe resolved from inside TestRoot ($($uvAfter.Source))" }
    if ($preCommitAfter) { Assert-True ($preCommitAfter.Source -like "$TestRoot*") "pre-commit.exe resolved from inside TestRoot ($($preCommitAfter.Source))" }

    if ($gitAfter) {
        # `git --version` prints Git for Windows' own release string (e.g.
        # "git version 2.55.0.windows.5"), not the dash-joined asset-name
        # version ("2.55.0.5") the lock file also carries -- compare
        # against releaseTag (minus its "v" prefix), the field that is
        # actually spelled the same way `--version` prints it.
        $gitVersionText = (& $gitAfter.Source --version)
        $expectedGitVersion = $lock.git.releaseTag -replace '^v', ''
        Assert-True ($gitVersionText -match [regex]::Escape($expectedGitVersion)) "installed git reports the pinned version ($expectedGitVersion): $gitVersionText"
    }
    if ($uvAfter) {
        $uvVersionText = (& $uvAfter.Source --version)
        Assert-True ($uvVersionText -match [regex]::Escape($lock.uv.version)) "installed uv reports the pinned version ($($lock.uv.version)): $uvVersionText"
    }
    if ($preCommitAfter) {
        $preCommitVersionText = (& $preCommitAfter.Source --version)
        Assert-True ($preCommitVersionText -match [regex]::Escape($lock.preCommit.version)) "installed pre-commit reports the pinned version ($($lock.preCommit.version)): $preCommitVersionText"
    }

    Write-Output ""
    Write-Output "=== 8. Workspace conformity tool: tools/session-preflight.sh -> READY ==="
    $bashExe = Resolve-BashExe
    Push-Location $clonePath
    try {
        # No `2>$null` here: same reason as ticket 03's own main test --
        # redirecting a native command's stderr under PS 5.1's
        # $ErrorActionPreference = 'Stop' turns a harmless diagnostic
        # warning into a terminating error.
        $preflightOutput = & $bashExe 'tools/session-preflight.sh'
        $preflightExit = $LASTEXITCODE
    }
    finally { Pop-Location }
    Write-Output "  output: $preflightOutput"
    Assert-True ($preflightExit -eq 0) "session-preflight.sh exits 0"
    Assert-True ($preflightOutput -contains 'READY') "session-preflight.sh reports READY"

    Write-Output ""
    Write-Output "=== 9. Trial commit in the first project passes all guardians ==="
    Push-Location $firstProjectPath
    try {
        $journalScript = Join-Path $clonePath 'tools\append-journal.sh'
        & $bashExe $journalScript '.' 'STATE: trial commit for Mission 168 ticket 04 main test' | Out-Null
        & git add -- state/journal.md
        & git commit -q -m "Trial commit: ticket 04 main test"
        $commitExit = $LASTEXITCODE
    }
    finally { Pop-Location }
    Assert-True ($commitExit -eq 0) "trial commit passes guardians (git commit exits 0)"

    Write-Output ""
    Write-Output "=== 10. Second run, PATH still simulated, is a true no-op (no duplicate install) ==="
    $verdict2 = & $installScript -Source $RepoRoot -AnswersFile $answersPath -TestMode -TestRoot $TestRoot
    $exit2 = $LASTEXITCODE
    Write-Output "  verdict: $verdict2"
    Assert-True ($exit2 -eq 0) "second run exits 0"
    Assert-True ($verdict2 -eq $verdict1) "second run verdict is identical to the first"

    $clonePorcelain = & git -C $clonePath status --porcelain
    $projectPorcelain = & git -C $firstProjectPath status --porcelain
    Assert-True ([string]::IsNullOrEmpty(($clonePorcelain -join ''))) "second-brain clone porcelain is empty after the second run"
    Assert-True ([string]::IsNullOrEmpty(($projectPorcelain -join ''))) "first project porcelain is empty after the second run"

    $gitAfterSecondRun = Get-Command git.exe -ErrorAction SilentlyContinue
    Assert-True ($null -ne $gitAfterSecondRun -and $gitAfterSecondRun.Source -eq $gitAfter.Source) "second run reused the same git.exe, no duplicate install"
}
catch {
    Write-Output "  FAIL - unhandled error: $($_.Exception.Message)"
    $failures.Add("unhandled error: $($_.Exception.Message)") | Out-Null
}
finally {
    # Restored before anything else, including cleanup below: cleanup uses
    # bash.exe resolved from the REAL Git installation, not the one just
    # installed inside the TestRoot we are about to delete.
    $env:Path = $originalPath
}

Assert-True (-not (Test-ProcessIsElevated)) "process is still not elevated after installing prerequisites (never asked for UAC)"

# --- 11. Real-environment fingerprint, after -------------------------------
Write-Output ""
Write-Output "=== 11. Real-environment fingerprint (after) ==="
$after = Get-EnvironmentFingerprint
Write-Output "  PATH SHA-256: $($after.PathHash)"
Write-Output "  .claude/skills entries: $($after.ClaudeSkills.Count)"
Write-Output "  .claude/agents entries: $($after.ClaudeAgents.Count)"
Write-Output "  .codex/skills entries: $($after.CodexSkills.Count)"
Write-Output "  .agents/skills entries: $($after.CodexAgentsSkills.Count)"
Assert-True ($after.PathHash -eq $before.PathHash) "real user PATH is byte-identical before/after"
Assert-True (@(Compare-Object $before.ClaudeSkills $after.ClaudeSkills).Count -eq 0) "real ~/.claude/skills listing is identical before/after"
Assert-True (@(Compare-Object $before.ClaudeAgents $after.ClaudeAgents).Count -eq 0) "real ~/.claude/agents listing is identical before/after"
Assert-True (@(Compare-Object $before.CodexSkills $after.CodexSkills).Count -eq 0) "real ~/.codex/skills listing is identical before/after"
Assert-True (@(Compare-Object $before.CodexAgentsSkills $after.CodexAgentsSkills).Count -eq 0) "real ~/.agents/skills listing is identical before/after"

$realUvAfter = @(Get-ChildItem -Recurse -File $realLocalAppDataUv -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName | Sort-Object)
Assert-True (@(Compare-Object $realUvBefore $realUvAfter).Count -eq 0) "real %LOCALAPPDATA%\uv is untouched (uv's own installer never wrote its update-receipt there)"

if (-not $KeepTemp) {
    # Not Remove-Item: same long-path debris issue ticket 03 measured
    # (skills-warehouse/ nested a few levels under TestRoot). bash's
    # `rm -rf` handles it without issue.
    $cleanupBash = Resolve-BashExe
    & $cleanupBash -c "rm -rf -- '$($TestRoot -replace '\\','/')'"
    Write-Output ""
    Write-Output "TestRoot removed: $TestRoot"
}
else {
    Write-Output ""
    Write-Output "TestRoot kept (-KeepTemp): $TestRoot"
}

Write-Output ""
if ($failures.Count -eq 0) {
    Write-Output "=== RESULT: PASS (all checks green) ==="
    exit 0
}
else {
    Write-Output "=== RESULT: FAIL ($($failures.Count) check(s) failed) ==="
    $failures | ForEach-Object { Write-Output "  - $_" }
    exit 1
}
