#Requires -Version 5.1
<#
.SYNOPSIS
    Skill deployment by link, not by copy (Mission 168, ticket 07; combined
    budget and unconditional external deployment, Mission 171-C01 step 4).

.DESCRIPTION
    Role: dot-sourced by install.ps1. Makes every "method" skill --
    everything under <clone>/skills/ that carries a SKILL.md, INCLUDING
    skills/external/ (Owner arbitrage, 2026-09-12: "activate, for Claude
    Code and for Codex, the skills of the method -- those of skills/ and those
    of skills/external/", the Owner's words, translated from French) -- available to Claude Code and to Codex from
    every neighbouring project, not just from inside the clone itself
    (spec, Skills deployes: "toujours deployes, par lien et non par
    copie" ["always deployed, by link and not by copy"]). A correction inside the clone's skills/<name>/ then
    propagates to every place that already links to it, with no
    reinstall.

    Superseded design (Mission 168, ticket 07): skills/external/ used to be
    opt-in, requested by the installer questionnaire's eighth question
    (token 'external' among free-text $answers.skillCollections). That
    question is retired as of Mission 171-C01 step 4 -- both skills/ and
    skills/external/ are now unconditional, and warehouse collections are
    no longer linked by this installer at all (Mission 171-C01 Context:
    the rest of the warehouse is not activated here; it is delivered as zip
    packages the participant installs by hand, a separate mechanism). This
    file's only two sources are therefore skills/ and skills/external/ --
    never skills-warehouse/.

    Mission 173 (Q17, "rien dans le profil" ["nothing in the profile"]) retired this file's own
    profile-level orchestrators, Publish-DeployedSkills and
    Publish-DeployedAssistant (Mission 171-C01, steps 4 and 6): nothing is
    ever linked into ~/.claude or ~/.agents any more. The generic
    primitives below (Publish-SkillLink, Publish-FileLink, the skill-entry
    listers, the Codex budget measurement) are unchanged and still do the
    same job -- link one thing into one target directory -- just called
    from tools/project-bootstrap.sh now, with each PROJECT's own
    .claude/skills, .claude/agents and .agents/skills as the target roots
    instead of the profile.

    Codex budget and Doctrine rule 3 fallback (Mission 171-C01 step 4,
    T11's measured ~8000-character ceiling on Codex's own INITIAL skills
    list): Measure-MethodSkillsCodexBudget sums the character length of the
    `description` frontmatter field of EVERY method skill -- skills/ AND
    skills/external/ together, unlike the superseded
    Measure-DefaultSkillsCodexBudget (ticket 07), which only summed
    skills/ because skills/external/ used to be the participant's own
    opt-in choice. Measured on this repository on 2026-09-12: 6 skills/
    entries (2089 chars) + 40 skills/external/ entries (5362 chars) = 7451
    chars, under the ceiling. When the combined total exceeds the ceiling,
    Doctrine rule 3 applies (never a stop, never a thrown error): Codex
    receives skills/ only (the fabricated skills), while Claude Code still
    receives everything (skills/ plus skills/external/). Below the
    ceiling, both targets receive the same set.

    Idempotency (ticket 07 criterion 4, "aucun lien duplique, aucun
    fichier modifie" ["no duplicated link, no modified file"]) follows the same three-state model the Vault's own
    first-install skill already uses for its own junctions
    (install-checklist.md items 8-10), adapted to a fully unattended
    script (this installer never has a live Owner to ask mid-run, unlike
    that skill's own chat surface):
      - nothing at the link path -> create it;
      - a link already there, resolving to the SAME source -> already
        installed correctly, touch nothing (Publish-SkillLink returns
        'AlreadyLinked', never re-creates);
      - anything else already there (a plain file/directory, or a link
        resolving to a DIFFERENT source -- e.g. a foreign item that
        predates this installer) -> left alone and reported as a
        conflict, NEVER overwritten, NEVER deleted (Decision 110852's
        spirit: an automated, unattended installer's safe default when it
        cannot ask a human is to leave the disk exactly as it found it and
        name what it could not do, not to guess).

    Link mechanism: an NTFS junction on Windows (`New-Item -ItemType
    Junction` -- unlike a symbolic link, a junction needs no elevated
    privilege and no Developer Mode, matching ticket 04's "never
    elevated" constraint and the ticket's own literal wording, "jonction
    sous Windows" ["junction under Windows"]); a symbolic link elsewhere (`New-Item -ItemType
    SymbolicLink`, ticket's own "lien symbolique ailleurs" ["symbolic link elsewhere"] -- exercised by
    this repository's Windows-only test suite as a code path, not
    measured live, since the Mission's own main test runs on Windows).
    Always an ABSOLUTE target: NTFS junctions cannot encode a relative
    one.

    This file stays ASCII-only, like install.ps1, prerequisites.ps1 and
    generate-assistant.ps1 (see that file's own header comment): no
    byte-order mark needed, since no accented literal is ever typed here.

    A single generated file cannot be an NTFS junction's target: a junction
    (`New-Item -ItemType Junction`) only ever names a DIRECTORY on Windows.
    A skill or the Codex form of the assistant is a directory and uses
    Publish-SkillLink; the Claude Code subagent form of the assistant is a
    single file (<project>/.claude/agents/<slug>.md) and needs its own
    primitive, Publish-FileLink below: an NTFS hard link (`New-Item
    -ItemType HardLink`) plays the same no-privilege, no-copy role for one
    file that a junction plays for a directory -- unlike a symbolic link
    (WinError 1314 on this machine, the same measured constraint ticket
    04/07 already worked around), a hard link needs no elevation and no
    Developer Mode, and because both directory entries then address the
    very same on-disk data, a correction written through the source path
    is visible through the linked path too, with no reinstall -- the same
    "link, never copy" property this file's own header already promises
    for a directory.

    Usage:
        . "$PSScriptRoot\tools\deploy-skills.ps1"
        $status = Publish-SkillLink -LinkPath $linkPath -TargetPath $sourcePath
        $status = Publish-FileLink -LinkPath $linkPath -TargetPath $sourcePath

    Inputs: none at load time; each function documents its own.
    Outputs: defines the functions below in the caller's scope.
#>

# Codex's own measured initial-list ceiling (T11); applied to the combined
# description total of every method skill (skills/ plus skills/external/,
# Mission 171-C01 step 4 -- see header comment). One named place to change
# if that measured ceiling is ever revised.
$Script:MaxCodexDefaultSkillsBudget = 8000

function Test-IsWindowsPlatform {
    # .NET-level check, not $IsWindows: that automatic variable does not
    # exist at all in Windows PowerShell 5.1 (only PowerShell 6+ defines
    # it), and this installer is `#Requires -Version 5.1`, expected to run
    # under Windows PowerShell most of the time -- an undefined variable
    # would read as falsy and silently misroute every Windows run down the
    # symbolic-link branch. [System.Environment]::OSVersion.Platform is
    # available in both editions and answers the same question directly.
    return ([System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT)
}

function Get-SkillDirectoryEntries {
    # Generic, measured-from-disk listing of every immediate subdirectory
    # of $SkillsRoot that carries its own SKILL.md -- the one place this
    # file ever asks "what skills live here", used for both skills/ and
    # skills/external/ alike, so the two never drift into two separate
    # hand-maintained lists. Sorted by name for a deterministic,
    # reproducible link order.
    param(
        [Parameter(Mandatory = $true)][string] $SkillsRoot,
        [string[]] $ExcludeNames = @()
    )
    if (-not (Test-Path $SkillsRoot)) { return @() }
    $entries = @()
    Get-ChildItem -Path $SkillsRoot -Directory | Sort-Object Name | ForEach-Object {
        if ($ExcludeNames -contains $_.Name) { return }
        $skillMdPath = Join-Path $_.FullName 'SKILL.md'
        if (Test-Path $skillMdPath) {
            $entries += [PSCustomObject]@{ Name = $_.Name; SourcePath = $_.FullName }
        }
    }
    return $entries
}

function Get-DefaultSkillEntries {
    # The method-fabricated skills (T19: "les skills fabriques du Vault
    # (skills/)" ["the fabricated skills of the Vault (skills/)"]), identified the same way the Vault's own first-install
    # checklist item 8 identifies them: every skills/<name>/SKILL.md
    # except external/ (item 9's own, separate concern -- always
    # deployed too as of Mission 171-C01 step 4, see
    # Get-ExternalMethodSkillEntries below, but kept as its own entry set
    # so the Codex-budget fallback can drop it alone under Doctrine rule
    # 3). Measured, never hardcoded: a future skill added to or removed
    # from skills/ changes what this returns without editing this file.
    param([Parameter(Mandatory = $true)][string] $ClonePath)
    return Get-SkillDirectoryEntries -SkillsRoot (Join-Path $ClonePath 'skills') -ExcludeNames @('external')
}

function Get-ExternalMethodSkillEntries {
    # T24: "outils de la methode" ["tools of the method"] -- skills/external/, the adopted library
    # the method itself uses. Unconditional as of Mission 171-C01 step 4
    # (superseding ticket 07's questionnaire-gated 'external' token,
    # retired along with the eighth question): always deployed to Claude
    # Code, and to Codex too unless the combined description budget is
    # over the ceiling (Doctrine rule 3, see Measure-MethodSkillsCodexBudget).
    param([Parameter(Mandatory = $true)][string] $ClonePath)
    return Get-SkillDirectoryEntries -SkillsRoot (Join-Path $ClonePath 'skills\external')
}

function Get-SkillDescriptionFromFrontmatter {
    # Reads the `description:` frontmatter value as written (a YAML
    # double-quoted scalar, this repository's own convention for every
    # SKILL.md measured while building this ticket) -- falls back to an
    # unquoted scalar for robustness, never throws on a missing/malformed
    # field (returns an empty string instead), since a budget measurement
    # must never itself become a reason the installer fails on a skill
    # whose frontmatter this file did not anticipate.
    param([Parameter(Mandatory = $true)][string] $SkillMdPath)
    if (-not (Test-Path $SkillMdPath)) { return '' }
    $text = Get-Content -Raw -Path $SkillMdPath -Encoding UTF8
    if ($text -match '(?m)^description:\s*"((?:[^"\\]|\\.)*)"') {
        return $Matches[1]
    }
    if ($text -match '(?m)^description:\s*(.+)$') {
        return $Matches[1].Trim()
    }
    return ''
}

function Measure-MethodSkillsCodexBudget {
    # Doctrine rule 3 (Mission 171-C01, step 4): sums BOTH skills/ and
    # skills/external/ descriptions together -- unlike the superseded
    # ticket-07 measurement, which only summed skills/ because
    # skills/external/ used to be opt-in via the questionnaire's now-
    # retired eighth question. Both directories are unconditional method
    # skills now (Owner arbitrage, 2026-09-12), so both count toward the
    # one ceiling that gates what Codex receives. Never throws (Doctrine
    # rule 3: "Pas d'arret" ["No stop"]) -- returns OverBudget instead, which the
    # project-linking step (tools/project-bootstrap.sh, Mission 173) turns
    # into a per-target fallback: Codex drops skills/external/ when over
    # budget, Claude Code never does.
    param(
        [Parameter(Mandatory = $true)][psobject[]] $DefaultEntries,
        [Parameter(Mandatory = $true)][psobject[]] $ExternalEntries
    )
    $breakdown = @()
    $total = 0
    foreach ($entry in (@($DefaultEntries) + @($ExternalEntries))) {
        $description = Get-SkillDescriptionFromFrontmatter -SkillMdPath (Join-Path $entry.SourcePath 'SKILL.md')
        $length = $description.Length
        $total += $length
        $breakdown += [PSCustomObject]@{ Name = $entry.Name; Length = $length }
    }
    return [PSCustomObject]@{
        Total      = $total
        Breakdown  = $breakdown
        Ceiling    = $Script:MaxCodexDefaultSkillsBudget
        OverBudget = ($total -gt $Script:MaxCodexDefaultSkillsBudget)
    }
}

function Merge-SkillEntriesByName {
    # Concatenates entry lists in priority order, keeping the first
    # occurrence of each skill name and recording the rest as duplicates.
    # Shared by both deployment targets below so Claude Code and Codex
    # agree on which source wins a name collision between skills/ and
    # skills/external/ (should never happen in practice -- the two are
    # disjoint directories -- but a future same-named addition must not
    # link two different sources under one name).
    param([Parameter(Mandatory = $true)][psobject[][]] $EntryLists)
    $seen = New-Object 'System.Collections.Generic.HashSet[string]'
    $duplicates = @()
    $merged = @()
    foreach ($list in $EntryLists) {
        foreach ($entry in @($list)) {
            if ($seen.Contains($entry.Name)) {
                $duplicates += $entry.Name
                continue
            }
            [void]$seen.Add($entry.Name)
            $merged += $entry
        }
    }
    return [PSCustomObject]@{ Entries = $merged; DuplicateNames = $duplicates }
}

function Get-ExistingLinkInfo {
    # What is currently at $Path, if anything: Exists / IsLink / Target.
    # IsLink is decided by the ReparsePoint attribute bit, never by the
    # presence of a .Target property alone -- Get-Item exposes .Target on
    # every DirectoryInfo (empty string for a plain directory), measured
    # directly against this machine's own Windows PowerShell 5.1 while
    # building this ticket (a plain, non-link directory still has a
    # .Target property, just an empty one).
    param([Parameter(Mandatory = $true)][string] $Path)
    $item = Get-Item -Path $Path -Force -ErrorAction SilentlyContinue
    if ($null -eq $item) {
        return [PSCustomObject]@{ Exists = $false; IsLink = $false; Target = $null }
    }
    $isLink = (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0)
    $target = $null
    if ($isLink) {
        $target = @($item.Target) | Select-Object -First 1
    }
    return [PSCustomObject]@{ Exists = $true; IsLink = $isLink; Target = $target }
}

function Publish-SkillLink {
    # Idempotent single junction/symbolic-link creation -- the Vault's own
    # first-install precedent (install-checklist.md items 8-10) adapted to
    # a fully unattended script: NEVER overwrites, NEVER deletes, whatever
    # is already at $LinkPath. Returns one of:
    #   'Created'       -- nothing was there; the link now exists.
    #   'AlreadyLinked' -- a link was already there, resolving to the same
    #                      $TargetPath; nothing was touched.
    #   'Conflict'      -- something else occupies $LinkPath (a plain
    #                      file/directory, or a link to a DIFFERENT
    #                      target); left exactly as found.
    param(
        [Parameter(Mandatory = $true)][string] $LinkPath,
        [Parameter(Mandatory = $true)][string] $TargetPath
    )
    $resolvedTarget = (Resolve-Path -LiteralPath $TargetPath).ProviderPath
    $existing = Get-ExistingLinkInfo -Path $LinkPath

    if (-not $existing.Exists) {
        $parent = Split-Path $LinkPath -Parent
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
        if (Test-IsWindowsPlatform) {
            New-Item -ItemType Junction -Path $LinkPath -Target $resolvedTarget | Out-Null
        }
        else {
            New-Item -ItemType SymbolicLink -Path $LinkPath -Target $resolvedTarget | Out-Null
        }
        return 'Created'
    }

    if ($existing.IsLink -and $existing.Target) {
        $normalizedExisting = $existing.Target.TrimEnd('\', '/')
        $normalizedTarget = $resolvedTarget.TrimEnd('\', '/')
        if ($normalizedExisting -ieq $normalizedTarget) {
            return 'AlreadyLinked'
        }
    }

    return 'Conflict'
}


function Publish-FileLink {
    # File analogue of Publish-SkillLink above (Mission 171-C01 step 6, see
    # this file's own header comment): a junction cannot target a single
    # file, so this uses an NTFS hard link on Windows instead -- no
    # elevation, no Developer Mode, same no-privilege guarantee, and both
    # directory entries end up addressing the very same on-disk data (a
    # correction through the source path is visible through the link
    # immediately, never a stale copy). Same three-state idempotency
    # contract as Publish-SkillLink: Created / AlreadyLinked / Conflict,
    # never overwriting or deleting whatever is already at $LinkPath.
    #
    # A hard link is NOT a reparse point on Windows (measured directly:
    # unlike a junction or a symbolic link, its FileAttributes carry no
    # ReparsePoint bit), so Get-ExistingLinkInfo's own IsLink test -- built
    # for junctions/symlinks -- never fires for one; a plain Get-Item on a
    # hard-linked file instead exposes a `LinkType` of 'HardLink' and a
    # `Target` listing every OTHER path hard-linked to the same data
    # (measured directly on this machine's own Windows PowerShell 5.1
    # while building this ticket). That is what this function checks
    # instead of Get-ExistingLinkInfo.
    param(
        [Parameter(Mandatory = $true)][string] $LinkPath,
        [Parameter(Mandatory = $true)][string] $TargetPath
    )
    $resolvedTarget = (Resolve-Path -LiteralPath $TargetPath).ProviderPath
    $existingItem = Get-Item -LiteralPath $LinkPath -Force -ErrorAction SilentlyContinue

    if ($null -eq $existingItem) {
        $parent = Split-Path $LinkPath -Parent
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
        if (Test-IsWindowsPlatform) {
            New-Item -ItemType HardLink -Path $LinkPath -Target $resolvedTarget | Out-Null
        }
        else {
            New-Item -ItemType SymbolicLink -Path $LinkPath -Target $resolvedTarget | Out-Null
        }
        return 'Created'
    }

    if (Test-IsWindowsPlatform) {
        if ($existingItem.PSObject.Properties['LinkType'] -and $existingItem.LinkType -eq 'HardLink') {
            $linkedTargets = @($existingItem.Target) | ForEach-Object { $_.TrimEnd('\', '/') }
            if ($linkedTargets -icontains $resolvedTarget.TrimEnd('\', '/')) {
                return 'AlreadyLinked'
            }
        }
    }
    else {
        $isReparse = (($existingItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0)
        if ($isReparse) {
            $existingTarget = @($existingItem.Target) | Select-Object -First 1
            if ($existingTarget -and ($existingTarget.TrimEnd('/') -ieq $resolvedTarget.TrimEnd('/'))) {
                return 'AlreadyLinked'
            }
        }
    }

    return 'Conflict'
}

