#Requires -Version 5.1
<#
.SYNOPSIS
    Assistant tool-call cap test (Mission 171-C01, step 7).

.DESCRIPTION
    Rerun with one command, from the repository root:

        powershell -NoProfile -ExecutionPolicy Bypass -File tests\test-assistant-tool-call-cap.ps1

    Audit defect 6 (Mission 171-C01, step 7): the identity source
    (assistant/ASSISTANT.md) used to carry no tool-call ceiling, no search
    order and no explicit permission to answer from what was already read
    -- measured directly against a real deployed artifact
    (sb-test\second-brain\.claude\agents\brahim.md): 20 tool calls, 65
    seconds, for one ordinary question. The fix adds three things to the
    identity source's own corps-generateur body: an explicit cap (8 tool
    calls for an ordinary question), a most-precise-to-broadest search
    order, and an explicit permission to answer with what was read while
    naming what was not.

    This test does not re-run the whole installer (test-assistant-generation.ps1
    already covers install.ps1 end to end) -- it drives each generator
    directly against a throwaway clone that carries the REAL, current
    assistant/ASSISTANT.md, which is the fastest way to prove the exact
    spec requirement: "le plafond figure dans les trois formes generees".

      1. tools/generate-assistant.ps1's New-AssistantForms (PowerShell path,
         used by install.ps1) -- checked against all three generated forms:
         the Claude Code subagent, the Codex skill, and the web package
         instructions.

      2. tools/sb_installer_helper.py's render-assistant subcommand (Python
         mirror, used by install.sh) -- same three forms, same checks, to
         prove the two independent implementations do not diverge on this
         point (ticket 08's own parity promise).

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

# The three literal needles this defect requires, read straight off the
# current assistant/ASSISTANT.md corps-generateur body -- if that body's
# wording ever changes, this test (and the source) should be updated
# together, never silently left checking stale phrasing.
$capNeedle = 'at most 8 tool calls'
$orderNeedles = @(
    'named exactly'
    'closest to the topic'
    'broad search across the whole workspace'
)
$permissionNeedles = @(
    'answers with what he has read'
    'naming plainly what he did not read'
)

function Test-GeneratedForm {
    # Runs the cap/order/permission assertions against one generated file's
    # text, prefixing every assertion message with $Label so a failure names
    # exactly which generator and which form it came from.
    param([Parameter(Mandatory = $true)][string] $Path, [Parameter(Mandatory = $true)][string] $Label)
    if (-not (Test-Path $Path)) {
        Assert-True $false "$Label -- file exists at $Path"
        return
    }
    Assert-True $true "$Label -- file exists at $Path"
    $text = Get-Content -Raw -Path $Path -Encoding UTF8
    Assert-True $text.Contains($capNeedle) "$Label -- carries the exact tool-call cap ('$capNeedle')"
    foreach ($needle in $orderNeedles) {
        Assert-True $text.Contains($needle) "$Label -- carries search-order element ('$needle')"
    }
    foreach ($needle in $permissionNeedles) {
        Assert-True $text.Contains($needle) "$Label -- carries the answer-from-what-was-read permission ('$needle')"
    }
}

# Web-package knowledge-file sources (Mission 171-C01 step 8): both throwaway
# clones below need these too now, not just assistant/ASSISTANT.md --
# New-AssistantForms and render-assistant both fail loudly on a missing
# knowledge-file source (by design, see Get-WebPackageKnowledgeFileContent's
# own comment), and this test's clones only ever carried the identity
# source. Read from $Script:WebPackageKnowledgeFiles itself (populated by
# dot-sourcing generate-assistant.ps1 below) so this list can never drift
# out of sync with the generator's own.
. (Join-Path $RepoRoot 'tools\generate-assistant.ps1')
function Copy-ToolCapTestClone {
    param([Parameter(Mandatory = $true)][string] $TestRoot)
    New-Item -ItemType Directory -Force -Path (Join-Path $TestRoot 'assistant') | Out-Null
    Copy-Item -Path (Join-Path $RepoRoot 'assistant\ASSISTANT.md') -Destination (Join-Path $TestRoot 'assistant\ASSISTANT.md') -Force
    foreach ($knowledgeFile in $Script:WebPackageKnowledgeFiles) {
        $src = Join-Path $RepoRoot $knowledgeFile.SourcePath
        $dst = Join-Path $TestRoot $knowledgeFile.SourcePath
        New-Item -ItemType Directory -Force -Path (Split-Path $dst -Parent) | Out-Null
        Copy-Item -Path $src -Destination $dst -Force
    }
}

# --- 1. PowerShell generator (tools/generate-assistant.ps1) ----------------
$TestRootPs1 = Join-Path $env:TEMP ("sb-toolcap-ps1-" + [Guid]::NewGuid().ToString('N'))
Copy-ToolCapTestClone -TestRoot $TestRootPs1
Write-Output ""
Write-Output "TestRoot (PowerShell generator): $TestRootPs1"

try {
    Write-Output ""
    Write-Output "=== 1. tools/generate-assistant.ps1 -- New-AssistantForms ==="
    . (Join-Path $RepoRoot 'tools\generate-assistant.ps1')
    $slug1 = New-AssistantForms -ClonePath $TestRootPs1 -Name 'Testcap'
    Assert-True ($slug1 -eq 'testcap') "New-AssistantForms returns the expected slug ('testcap')"

    Test-GeneratedForm -Path (Join-Path $TestRootPs1 '.claude\agents\testcap.md') -Label 'PS1/Claude Code subagent'
    Test-GeneratedForm -Path (Join-Path $TestRootPs1 '.agents\skills\testcap\SKILL.md') -Label 'PS1/Codex skill'
    Test-GeneratedForm -Path (Join-Path $TestRootPs1 'web-package\testcap\INSTRUCTIONS.md') -Label 'PS1/web package instructions'
}
catch {
    Write-Output "  FAIL - unhandled error (PowerShell generator): $($_.Exception.Message)"
    $failures.Add("unhandled error (PowerShell generator): $($_.Exception.Message)") | Out-Null
}

# --- 2. Python mirror (tools/sb_installer_helper.py render-assistant) ------
$TestRootPy = Join-Path $env:TEMP ("sb-toolcap-py-" + [Guid]::NewGuid().ToString('N'))
Copy-ToolCapTestClone -TestRoot $TestRootPy
Write-Output ""
Write-Output "TestRoot (Python mirror): $TestRootPy"

try {
    Write-Output ""
    Write-Output "=== 2. tools/sb_installer_helper.py render-assistant (Python mirror) ==="
    $helperScript = Join-Path $RepoRoot 'tools\sb_installer_helper.py'
    $slug2 = & uv run --no-project $helperScript render-assistant $TestRootPy 'Testcap' 2>&1
    $pyExit = $LASTEXITCODE
    Assert-True ($pyExit -eq 0) "render-assistant exits 0 (output: $slug2)"
    Assert-True (($slug2 | Select-Object -Last 1) -eq 'testcap') "render-assistant returns the expected slug ('testcap')"

    Test-GeneratedForm -Path (Join-Path $TestRootPy '.claude\agents\testcap.md') -Label 'Python/Claude Code subagent'
    Test-GeneratedForm -Path (Join-Path $TestRootPy '.agents\skills\testcap\SKILL.md') -Label 'Python/Codex skill'
    Test-GeneratedForm -Path (Join-Path $TestRootPy 'web-package\testcap\INSTRUCTIONS.md') -Label 'Python/web package instructions'
}
catch {
    Write-Output "  FAIL - unhandled error (Python mirror): $($_.Exception.Message)"
    $failures.Add("unhandled error (Python mirror): $($_.Exception.Message)") | Out-Null
}

if (-not $KeepTemp) {
    try {
        . (Join-Path $RepoRoot 'tools\resolve-bash-exe.ps1')
        $cleanupBash = Resolve-BashExe
        & $cleanupBash -c "rm -rf -- '$($TestRootPs1 -replace '\\','/')' '$($TestRootPy -replace '\\','/')'"
    }
    catch { }
    Write-Output ""
    Write-Output "TestRoots removed: $TestRootPs1, $TestRootPy"
}
else {
    Write-Output ""
    Write-Output "TestRoots kept (-KeepTemp): $TestRootPs1, $TestRootPy"
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
