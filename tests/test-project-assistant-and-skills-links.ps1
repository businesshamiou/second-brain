#Requires -Version 5.1
<#
.SYNOPSIS
    Project-level assistant/skills linking test (Mission 173 step 4, Q17).

.DESCRIPTION
    Rerun with one command, from the repository root:

        powershell -NoProfile -ExecutionPolicy Bypass -File tests\test-project-assistant-and-skills-links.ps1

    Replaces test-assistant-deployment.ps1 and test-skills-deployment.ps1
    (Mission 173 step 3 retired the profile-level mechanism they tested).
    Proves the new mechanism: tools/project-bootstrap.sh links the method
    skills (skills/ and skills/external/) and the current assistant's two
    linkable forms into the CREATED PROJECT's own .claude/skills,
    .claude/agents and .agents/skills -- never the profile.

    Runs a real, full, silent install (-AnswersFile, -TestMode) so the
    first project is created for real by the real installer, then:
      1. checks every expected link exists and resolves to its real
         source (Resolve-Path, not just Test-Path -- proves it is a link
         to the right target, not a coincidental plain file/folder);
      2. reruns project-bootstrap.sh a second time for the SAME project
         path found already existing (guarded by install.ps1's own
         Test-Path check) -- instead calls the link-project subcommand a
         second time directly against the same project, proving no
         duplicate link and no drift (AlreadyLinked, not a second Created
         nor a Conflict against itself);
      3. HYPOTHESIS, not measured live: a real /memory probe inside a
         running Claude Code session (Mesures prealables, regle 4) is
         outside what an automated test in this environment can drive --
         the on-disk link resolution this test DOES measure is exactly
         what Claude Code's and Codex's own file-discovery mechanisms
         would traverse (same reasoning already applied to every prior
         Mission's own project-level file-discovery claims).

    Exit code 0 means every assertion passed. Exit code 1 means at least one
    did not; details are printed to stdout as each check runs.
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

function Test-LinkResolvesTo {
    # Resolve-Path does NOT dereference a junction or a hard link -- it
    # returns the LINK's own path unchanged (measured directly while
    # writing this test). A junction's real target lives on Get-Item's own
    # .Target property; a hard link is not a reparse point at all
    # (LinkType 'HardLink', same file data under two paths) -- checked via
    # .Target too (a hard link's own .Target lists every other path
    # hard-linked to the same data, same technique
    # tools/deploy-skills.ps1's own Publish-FileLink already uses).
    param([string] $LinkPath, [string] $ExpectedTargetPath)
    if (-not (Test-Path -LiteralPath $LinkPath)) { return $false }
    $item = Get-Item -LiteralPath $LinkPath -Force
    $resolvedTarget = (Resolve-Path -LiteralPath $ExpectedTargetPath).ProviderPath.TrimEnd('\', '/')
    $linkedTargets = @($item.Target) | ForEach-Object { $_.TrimEnd('\', '/') }
    return ($linkedTargets -icontains $resolvedTarget)
}

# GetLongPathName (Mission 177 step 2, third CI cause): on the GitHub
# Windows runner, $env:TEMP itself resolves through an 8.3 short-name
# segment ("C:\Users\RUNNER~1\...", measured directly in run 34895686688's
# own log) -- never on this machine, same shape as the two prior Windows-
# only causes in this Mission's own commit history. Resolve-Path preserves
# a short segment unchanged (measured directly), but the installer's own
# junction/hardlink creation (tools/sb_installer_helper.py,
# os.path.realpath()) canonicalizes its target to the long form before
# writing it into the reparse point / hard link -- so every
# Test-LinkResolvesTo comparison below compared a short-form Resolve-Path
# against a long-form .Target and failed on a string mismatch alone, never
# a real linking defect (reproduced: forcing $env:TEMP to a short form
# locally reproduces the exact 4 failures byte-for-byte; the links
# themselves were always correct). Canonicalizing $TestRoot once, up front,
# keeps every path derived from it (Join-Path) in the same long form the
# installer's own realpath() will produce.
Add-Type -Namespace Sb177 -Name PathNative -MemberDefinition @'
[DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
public static extern uint GetLongPathName(string lpszShortPath, System.Text.StringBuilder lpszLongPath, uint cchBuffer);
'@

function Get-LongPath {
    param([string] $Path)
    $sb = New-Object System.Text.StringBuilder 1024
    $len = [Sb177.PathNative]::GetLongPathName($Path, $sb, $sb.Capacity)
    if ($len -gt 0 -and $len -lt $sb.Capacity) { return $sb.ToString(0, $len) }
    return $Path
}

$TestRoot = Join-Path $env:TEMP ("sb-projectlinks-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $TestRoot | Out-Null
$TestRoot = Get-LongPath -Path $TestRoot
Write-Output ""
Write-Output "TestRoot: $TestRoot"

try {
    Write-Output ""
    Write-Output "=== Fresh install creates the first project with its links ==="
    $workspacePath = Join-Path $TestRoot 'workspace'
    $answersPath = Join-Path $TestRoot 'answers.json'
    $sampleAnswers = Get-Content -Raw -Path (Join-Path $PSScriptRoot 'fixtures\install-answers.sample.json') | ConvertFrom-Json
    $sampleAnswers.workspacePath = $workspacePath
    $sampleAnswers | ConvertTo-Json -Depth 10 | Set-Content -Path $answersPath -Encoding UTF8

    $installScript = Join-Path $RepoRoot 'install.ps1'
    $verdict = & $installScript -Source $RepoRoot -AnswersFile $answersPath -TestMode -TestRoot $TestRoot
    Assert-True ($LASTEXITCODE -eq 0) "install exits 0"
    Assert-True ($verdict -match 'Installation complete') "verdict reports success"

    $clonePath = Join-Path $workspacePath 'second-brain'
    $projectPath = Join-Path $workspacePath $sampleAnswers.firstProject.name
    Assert-True (Test-Path $projectPath) "the first project exists"

    Write-Output ""
    Write-Output "=== Every method skill resolves from the project to the clone ==="
    $methodSkillNames = @(Get-ChildItem -Path (Join-Path $clonePath 'skills') -Directory | Where-Object { $_.Name -ne 'external' -and (Test-Path (Join-Path $_.FullName 'SKILL.md')) } | ForEach-Object { $_.Name })
    $methodSkillNames += @(Get-ChildItem -Path (Join-Path $clonePath 'skills\external') -Directory -ErrorAction SilentlyContinue | Where-Object { Test-Path (Join-Path $_.FullName 'SKILL.md') } | ForEach-Object { $_.Name })
    Assert-True ($methodSkillNames.Count -gt 0) "measured at least one method skill to check ($($methodSkillNames.Count) found)"
    $claudeSkillsOk = $true
    $codexSkillsOk = $true
    foreach ($name in $methodSkillNames) {
        $source = Join-Path $clonePath "skills\$name"
        if (-not (Test-Path $source)) { $source = Join-Path $clonePath "skills\external\$name" }
        if (-not (Test-LinkResolvesTo -LinkPath (Join-Path $projectPath ".claude\skills\$name") -ExpectedTargetPath $source)) { $claudeSkillsOk = $false }
        if (-not (Test-LinkResolvesTo -LinkPath (Join-Path $projectPath ".agents\skills\$name") -ExpectedTargetPath $source)) { $codexSkillsOk = $false }
    }
    Assert-True $claudeSkillsOk "every method skill resolves from the project's .claude/skills to its real source in the clone"
    Assert-True $codexSkillsOk "every method skill resolves from the project's .agents/skills to its real source in the clone"

    Write-Output ""
    Write-Output "=== The current assistant resolves from the project to the clone ==="
    $carnetPath = Join-Path $clonePath '.install\state.json'
    $carnet = Get-Content -Raw -Path $carnetPath | ConvertFrom-Json
    $slug = $carnet.assistant.slug
    Assert-True (-not [string]::IsNullOrWhiteSpace($slug)) "the clone's own carnet names the current assistant's slug ('$slug')"
    Assert-True (Test-LinkResolvesTo -LinkPath (Join-Path $projectPath ".claude\agents\$slug.md") -ExpectedTargetPath (Join-Path $clonePath ".claude\agents\$slug.md")) `
        "the project's .claude/agents/$slug.md resolves to the clone's own subagent file"
    Assert-True (Test-LinkResolvesTo -LinkPath (Join-Path $projectPath ".agents\skills\$slug") -ExpectedTargetPath (Join-Path $clonePath ".agents\skills\$slug")) `
        "the project's .agents/skills/$slug resolves to the clone's own Codex skill"

    Write-Output ""
    Write-Output "=== Rerunning link-project against the same project: no duplicate, no drift ==="
    $helperScript = Join-Path $RepoRoot 'tools\sb_installer_helper.py'
    $secondRunOutput = & uv run --no-project $helperScript link-project $clonePath $projectPath
    Assert-True ($LASTEXITCODE -eq 0) "second link-project run exits 0"
    Assert-True (-not ($secondRunOutput -match '^CONFLICT ')) "second run reports no conflict against its own, already-correct links (CONFLICT_COUNT alone would false-positive-match a bare 'CONFLICT' substring check)"
    Assert-True (($secondRunOutput -join "`n") -match "ASSISTANT_SLUG $slug") "second run still resolves the same assistant slug"
    $claudeSkillsAfterRerun = @(Get-ChildItem -Path (Join-Path $projectPath '.claude\skills') -ErrorAction SilentlyContinue)
    Assert-True ($claudeSkillsAfterRerun.Count -eq $methodSkillNames.Count) "no duplicate skill link after a second run ($($claudeSkillsAfterRerun.Count) entries, expected $($methodSkillNames.Count))"

    Write-Output ""
    Write-Output "=== HYPOTHESIS (not measured live in this environment) ==="
    Write-Output "  A running Claude Code session's own /memory (or Codex's own AGENTS.md/skill"
    Write-Output "  discovery) was not driven live from this automated test -- the on-disk link"
    Write-Output "  resolution proven above is exactly what those mechanisms are documented to"
    Write-Output "  traverse from a project's own working directory upward (Mesures prealables,"
    Write-Output "  regle 4 fallback: HYPOTHESE, poursuivre)."
}
finally {
    if (-not $KeepTemp) {
        Remove-Item -Recurse -Force -Path $TestRoot -ErrorAction SilentlyContinue
    }
    else {
        Write-Output ""
        Write-Output "Kept: $TestRoot"
    }
}

Write-Output ""
if ($failures.Count -gt 0) {
    Write-Output "=== FAILURES ($($failures.Count)) ==="
    $failures | ForEach-Object { Write-Output "  - $_" }
    exit 1
}
Write-Output "All assertions passed."
exit 0
