#Requires -Version 5.1
<#
.SYNOPSIS
    Lists, then removes on confirmation, profile-level links a pre-Mission-173
    installation left behind (Q17: "rien dans le profil").

.DESCRIPTION
    Mission 171-C01 (steps 4 and 6) used to link the assistant and the
    method skills into the user's PROFILE (~/.claude/agents, ~/.claude/skills,
    ~/.agents/skills). Mission 173 retired that mechanism entirely (nothing
    is written to the profile any more; the same content is linked into
    each PROJECT instead). An installation made before Mission 173 can
    still carry those old profile-level links, pointing at a given
    workspace's second-brain clone.

    This script finds them, names each one and what it still points at,
    and removes ONLY the link/junction/hard link itself on confirmation --
    it never touches the target it points at (the content stays exactly
    where Mission 171-C01 left it, inside the clone). Never scans or
    removes anything that is not a reparse point/hard link resolving
    inside the given workspace: a foreign skill or agent a participant
    installed from elsewhere is left untouched, same discipline the
    retired Publish-SkillLink/Publish-FileLink always followed.

    Also lists a DEAD junction (Mission 175, step 8): one whose stored
    target no longer exists at all -- the clone it once pointed at was
    itself moved or deleted before this script ran, so it can never match
    the -WorkspacePath given here. Reported only when its target text still
    names a "second-brain" path segment, the one fixed clone folder name
    this whole mechanism ever used -- never a broader guess that could
    catch some unrelated tool's own broken link sharing this profile
    folder. A hard link has no such state (it IS the file, not a pointer)
    so this applies to junctions only.

    -WhatIf (the built-in common parameter) lists without prompting or
    removing anything -- the safe default a first run should use. Without
    -WhatIf, each removal is asked individually (-Confirm's own per-item
    prompt), never a single "remove everything" blanket confirmation: a
    participant who wants to keep one foreign-looking link is never forced
    to accept or decline the whole batch at once.

    This script is NEVER executed by an Executor session against the
    Owner's real profile (Mission 173 Gates: "toute écriture dans le
    profil réel, y compris pour le nettoyer" is not granted) -- it is
    written and tested here only against a disposable test profile built
    for that purpose (tests/test-remove-profile-links.ps1), and the exact
    command the Owner would run against their own real profile is named in
    this Mission's own report, never run from this session.

    Usage (on your OWN real profile, never from an Executor session):
        powershell -NoProfile -ExecutionPolicy Bypass -File tools\remove-profile-links.ps1 -WorkspacePath "C:\path\to\your\workspace"
        # review the list, then re-run without -WhatIf to actually remove:
        powershell -NoProfile -ExecutionPolicy Bypass -File tools\remove-profile-links.ps1 -WorkspacePath "C:\path\to\your\workspace" -Confirm:$false -Remove
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true)]
    [string] $WorkspacePath,

    # Real profile by default (this is the whole point of the script);
    # a test harness overrides this to point at a disposable fake profile.
    [string] $ProfileRoot = $env:USERPROFILE,

    # Without -Remove, this script only ever lists -- -WhatIf/-Confirm
    # alone are not enough to opt OUT of a real removal by accident, since
    # ConfirmImpact='High' only prompts, it does not require an explicit
    # extra flag. -Remove is that explicit flag.
    [switch] $Remove
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $WorkspacePath)) {
    throw "Workspace path not found: $WorkspacePath"
}
$workspaceResolved = (Resolve-Path -LiteralPath $WorkspacePath).ProviderPath.TrimEnd('\', '/')
$clonePath = Join-Path $workspaceResolved 'second-brain'
if (-not (Test-Path -LiteralPath $clonePath)) {
    throw "No second-brain clone found at $clonePath -- pass the WORKSPACE path (the folder that contains VAULT-ROOT.md and second-brain\), not the clone itself."
}

function Test-PointsInsideClone {
    param([string] $TargetPath, [string] $ClonePath)
    if ([string]::IsNullOrWhiteSpace($TargetPath)) { return $false }
    $normalizedTarget = $TargetPath.TrimEnd('\', '/')
    $normalizedClone = $ClonePath.TrimEnd('\', '/')
    return ($normalizedTarget -ieq $normalizedClone) -or ($normalizedTarget -ilike "$normalizedClone\*") -or ($normalizedTarget -ilike "$normalizedClone/*")
}

function Test-TargetMissing {
    # A junction/symlink whose stored target no longer resolves at all --
    # the given $WorkspacePath's own clone moved or was deleted before this
    # script ran, so Test-PointsInsideClone (a string match against THAT
    # clone) never fires for it (Mission 175, etape 8).
    param([string] $TargetPath)
    if ([string]::IsNullOrWhiteSpace($TargetPath)) { return $true }
    return -not (Test-Path -LiteralPath $TargetPath)
}

function Test-NamesSecondBrainClone {
    # A dead target can only be judged by the text it still carries, never
    # by resolving it (it does not resolve, by definition) -- accepted only
    # when one of its path segments is literally "second-brain", the one
    # fixed clone folder name every install.sh/install.ps1 and this same
    # script's own $clonePath ever use. Anything looser would risk offering
    # to remove some OTHER tool's own broken link in this shared profile
    # folder (.claude/skills, .claude/agents, .agents/skills) -- the same
    # foreign-link discipline Test-PointsInsideClone already follows for
    # links that DO still resolve.
    param([string] $TargetPath)
    if ([string]::IsNullOrWhiteSpace($TargetPath)) { return $false }
    $segments = $TargetPath -split '[\\/]'
    return (@($segments | Where-Object { $_ -ieq 'second-brain' })).Count -gt 0
}

function Get-ProfileLinkCandidates {
    # Mirrors exactly what the retired Publish-SkillLink/Publish-FileLink
    # (Mission 171-C01) used to write: a junction per skill directory
    # under .claude/skills and .agents/skills, plus a hard link per
    # assistant file under .claude/agents and a junction per assistant
    # Codex skill under .agents/skills. Scans only the immediate children
    # of these four folders -- never recurses into a foreign, unrelated
    # subtree that happens to live there.
    param([string] $ProfileRoot, [string] $ClonePath)
    $candidateDirs = @(
        (Join-Path $ProfileRoot '.claude\skills'),
        (Join-Path $ProfileRoot '.claude\agents'),
        (Join-Path $ProfileRoot '.agents\skills')
    )
    $found = @()
    foreach ($dir in $candidateDirs) {
        if (-not (Test-Path -LiteralPath $dir)) { continue }
        foreach ($item in Get-ChildItem -LiteralPath $dir -Force) {
            $isReparsePoint = (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0)
            $isHardLink = ($item.PSObject.Properties['LinkType'] -and $item.LinkType -eq 'HardLink')
            if (-not $isReparsePoint -and -not $isHardLink) { continue }
            $targets = @($item.Target)
            $pointsInside = $false
            foreach ($t in $targets) {
                if (Test-PointsInsideClone -TargetPath $t -ClonePath $ClonePath) { $pointsInside = $true; break }
            }
            if ($pointsInside) {
                $found += [PSCustomObject]@{
                    Path   = $item.FullName
                    Kind   = if ($isHardLink) { 'HardLink' } else { 'Junction' }
                    Target = ($targets -join '; ')
                }
                continue
            }
            # Dead-link path (Mission 175, etape 8): a reparse point never
            # resolves nothing at all -- it just points at a directory that
            # no longer exists (a hard link has no such state: it IS a file,
            # not a pointer, so $isReparsePoint alone gates this branch).
            # Reported only when EVERY stored target is both missing and
            # still names a second-brain clone segment: a link that is only
            # partly dead, or that never named second-brain, is left to the
            # two checks above (or to a foreign tool, untouched either way).
            if (-not $isReparsePoint) { continue }
            $allDeadAndNamed = ($targets.Count -gt 0) -and `
                (@($targets | Where-Object { Test-TargetMissing -TargetPath $_ })).Count -eq $targets.Count -and `
                (@($targets | Where-Object { Test-NamesSecondBrainClone -TargetPath $_ })).Count -eq $targets.Count
            if ($allDeadAndNamed) {
                $found += [PSCustomObject]@{
                    Path   = $item.FullName
                    Kind   = 'DeadJunction'
                    Target = ($targets -join '; ')
                }
            }
        }
    }
    return $found
}

$candidates = @(Get-ProfileLinkCandidates -ProfileRoot $ProfileRoot -ClonePath $clonePath)

Write-Output "Second Brain (Mission 173) -- profile links pointing at $clonePath"
Write-Output ""
if ($candidates.Count -eq 0) {
    Write-Output "None found under $ProfileRoot (.claude/skills, .claude/agents, .agents/skills). Nothing to do."
    exit 0
}

Write-Output "Found $($candidates.Count) link(s) left by a pre-Mission-173 installation:"
foreach ($c in $candidates) {
    Write-Output "  - [$($c.Kind)] $($c.Path)"
    Write-Output "      -> $($c.Target)"
}
Write-Output ""
Write-Output "Only the link/junction/hard link itself would be removed above -- never the target content inside second-brain, which stays exactly where it is."

if (-not $Remove) {
    Write-Output ""
    Write-Output "Listing only (pass -Remove to actually remove, after reviewing the list above)."
    exit 0
}

$removed = @()
foreach ($c in $candidates) {
    if ($PSCmdlet.ShouldProcess($c.Path, "Remove profile link (target untouched: $($c.Target))")) {
        if ($c.Kind -eq 'HardLink') {
            Remove-Item -LiteralPath $c.Path -Force
        }
        else {
            Remove-Item -LiteralPath $c.Path -Force -Recurse
        }
        $removed += $c.Path
    }
}

Write-Output ""
Write-Output "Removed $($removed.Count) of $($candidates.Count) link(s)."
