#Requires -Version 5.1
<#
.SYNOPSIS
    Shared helper: fingerprint the Owner's real environment (Mission 168,
    ticket 03; extended by ticket 04's own test).

.DESCRIPTION
    Role: dot-sourced by tests/test-install-e2e.ps1 and
    tests/test-prerequisites-e2e.ps1 so both measure the Mission's own
    "environnement de l'Owner intact" constraint the exact same way --
    the real user PATH (HKCU\Environment\Path, hashed) and the skill
    folder listings (~/.claude/skills, ~/.codex/skills, ~/.agents/skills)
    -- rather than two copies that could silently drift (same motive as
    tools/resolve-bash-exe.ps1).

    ~/.agents/skills added (Mission 168, ticket 07): tools/deploy-skills.ps1
    is the first code in this repository that can ever write a link inside
    the real .agents/skills (Codex's own measured official location, T11)
    when -TestMode is somehow not honoured -- this fingerprint is the
    safety net that would catch exactly that leak, so it must cover the new
    write target, not just the two folders older tickets already touched.

    ~/.claude/agents added (Mission 171-C01 step 6): tools/deploy-skills.ps1's
    own Publish-DeployedAssistant is the first code in this repository that
    can ever write a link inside the real .claude/agents (Claude Code's own
    profile-level sub-agent folder) when -TestMode is somehow not honoured --
    same reasoning as ~/.agents/skills above, one more real write target this
    fingerprint must cover.

    Usage:
        . "$PSScriptRoot\tools\environment-fingerprint.ps1"
        $before = Get-EnvironmentFingerprint
        ...
        $after = Get-EnvironmentFingerprint

    Inputs: none.
    Outputs: defines the Get-EnvironmentFingerprint function in the
    caller's scope. Returns an object { PathValue; PathHash; ClaudeSkills;
    ClaudeAgents; CodexSkills; CodexAgentsSkills; LocalBin }.
#>

function Get-EnvironmentFingerprint {
    $pathValue = (Get-ItemProperty -Path 'HKCU:\Environment' -Name Path -ErrorAction SilentlyContinue).Path
    $pathHash = $null
    if ($null -ne $pathValue) {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($pathValue)
        $sha256 = [System.Security.Cryptography.SHA256]::Create()
        $pathHash = [System.BitConverter]::ToString($sha256.ComputeHash($bytes)) -replace '-', ''
    }
    $claudeSkills = @(Get-ChildItem "$env:USERPROFILE\.claude\skills" -Name -ErrorAction SilentlyContinue | Sort-Object)
    $claudeAgents = @(Get-ChildItem "$env:USERPROFILE\.claude\agents" -Name -ErrorAction SilentlyContinue | Sort-Object)
    $codexSkills = @(Get-ChildItem "$env:USERPROFILE\.codex\skills" -Name -ErrorAction SilentlyContinue | Sort-Object)
    $codexAgentsSkills = @(Get-ChildItem "$env:USERPROFILE\.agents\skills" -Name -ErrorAction SilentlyContinue | Sort-Object)
    # uv's default tool executable folder (Mission 181, parity with
    # environment-fingerprint.sh): an unredirected test-mode install writes
    # pre-commit here.
    $localBin = @(Get-ChildItem "$env:USERPROFILE\.local\bin" -Name -ErrorAction SilentlyContinue | Sort-Object)
    return [PSCustomObject]@{
        PathValue         = $pathValue
        PathHash          = $pathHash
        ClaudeSkills      = $claudeSkills
        ClaudeAgents      = $claudeAgents
        CodexSkills       = $codexSkills
        CodexAgentsSkills = $codexAgentsSkills
        LocalBin          = $localBin
    }
}
