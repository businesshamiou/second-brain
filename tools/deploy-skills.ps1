#Requires -Version 5.1
<#
.SYNOPSIS
    Skill deployment by link, not by copy (Mission 168, ticket 07; combined
    budget and unconditional external deployment, Mission 171-C01 step 4).

.DESCRIPTION
    Role: dot-sourced by install.ps1. Makes every "method" skill --
    everything under <clone>/skills/ that carries a SKILL.md, INCLUDING
    skills/external/ (Owner arbitrage, 2026-09-12: "activer, pour Claude
    Code et pour Codex, les skills de la methode -- ceux de skills/ et ceux
    de skills/external/") -- available to Claude Code and to Codex from
    every neighbouring project, not just from inside the clone itself
    (spec, Skills deployes: "toujours deployes, par lien et non par
    copie"). A correction inside the clone's skills/<name>/ then
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

    Two deployment targets:
      - $Context.ClaudeSkillsDir (~/.claude/skills, or its -TestMode
        redirection) -- Claude Code's own personal skills folder. Always
        receives every method skill (skills/ and skills/external/).
      - $Context.CodexAgentsSkillsDir (~/.agents/skills, or its -TestMode
        redirection) -- Codex's measured official skills location (T11:
        developers.openai.com/codex/skills.md, read 2026-09-10/11).
        Deliberately NOT $Context.CodexSkillsDir (~/.codex/skills): that
        property is a pre-existing, unrelated AI-tool-detection heuristic
        (tools/questionnaire.ps1's Get-DetectedAiTools), not a documented
        Codex skills location -- see install.ps1's own New-InstallerContext
        header comment for the full distinction. Never confuse the two.

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
    fichier modifie") follows the same three-state model the Vault's own
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
    sous Windows"); a symbolic link elsewhere (`New-Item -ItemType
    SymbolicLink`, ticket's own "lien symbolique ailleurs" -- exercised by
    this repository's Windows-only test suite as a code path, not
    measured live, since the Mission's own main test runs on Windows).
    Always an ABSOLUTE target: NTFS junctions cannot encode a relative
    one.

    This file stays ASCII-only, like install.ps1, prerequisites.ps1 and
    generate-assistant.ps1 (see that file's own header comment): no
    byte-order mark needed, since no accented literal is ever typed here.

    Usage:
        . "$PSScriptRoot\tools\deploy-skills.ps1"
        $result = Publish-DeployedSkills -Context $context -ClonePath $clonePath

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
    # (skills/)"), identified the same way the Vault's own first-install
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
    # T24: "outils de la methode" -- skills/external/, the adopted library
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
    # rule 3: "Pas d'arret") -- returns OverBudget instead, which
    # Publish-DeployedSkills below turns into a per-target fallback: Codex
    # drops skills/external/ when over budget, Claude Code never does.
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

function Publish-DeployedSkills {
    # Orchestrator (Mission 171-C01, step 4): links every method skill --
    # skills/ (default) plus skills/external/ -- into both
    # $Context.ClaudeSkillsDir and $Context.CodexAgentsSkillsDir,
    # unconditionally (Owner arbitrage, 2026-09-12: no questionnaire choice
    # gates this anymore -- the retired eighth question used to gate
    # skills/external/, and used to also offer warehouse collections,
    # neither of which this function accepts as input any more). Doctrine
    # rule 3: when the combined description budget exceeds the Codex
    # ceiling, Codex receives skills/ only while Claude Code still
    # receives skills/ plus skills/external/; below the ceiling both
    # targets receive the same set. Warehouse collections
    # (skills-warehouse/) are never linked here (Mission 171-C01 Context:
    # delivered as zip packages instead, a separate mechanism).
    param(
        [Parameter(Mandatory = $true)][psobject] $Context,
        [Parameter(Mandatory = $true)][string] $ClonePath
    )

    $defaultEntries = Get-DefaultSkillEntries -ClonePath $ClonePath
    $externalEntries = Get-ExternalMethodSkillEntries -ClonePath $ClonePath
    $budget = Measure-MethodSkillsCodexBudget -DefaultEntries $defaultEntries -ExternalEntries $externalEntries

    $claudeMerge = Merge-SkillEntriesByName -EntryLists @($defaultEntries, $externalEntries)
    $codexSourceLists = if ($budget.OverBudget) { @(, $defaultEntries) } else { @($defaultEntries, $externalEntries) }
    $codexMerge = Merge-SkillEntriesByName -EntryLists $codexSourceLists

    $targets = @(
        [PSCustomObject]@{ TargetRoot = $Context.ClaudeSkillsDir; Entries = $claudeMerge.Entries }
        [PSCustomObject]@{ TargetRoot = $Context.CodexAgentsSkillsDir; Entries = $codexMerge.Entries }
    )

    $linkResults = @()
    foreach ($target in $targets) {
        foreach ($entry in $target.Entries) {
            $linkPath = Join-Path $target.TargetRoot $entry.Name
            $status = Publish-SkillLink -LinkPath $linkPath -TargetPath $entry.SourcePath
            $linkResults += [PSCustomObject]@{
                Name       = $entry.Name
                TargetRoot = $target.TargetRoot
                LinkPath   = $linkPath
                SourcePath = $entry.SourcePath
                Status     = $status
            }
        }
    }

    return [PSCustomObject]@{
        DefaultEntries  = $defaultEntries
        ExternalEntries = $externalEntries
        Budget          = $budget
        FallbackApplied = $budget.OverBudget
        ClaudeNames     = @($claudeMerge.Entries | ForEach-Object { $_.Name })
        CodexNames      = @($codexMerge.Entries | ForEach-Object { $_.Name })
        DuplicateNames  = @(@($claudeMerge.DuplicateNames) + @($codexMerge.DuplicateNames) | Select-Object -Unique)
        LinkResults     = $linkResults
        ConflictCount   = @($linkResults | Where-Object { $_.Status -eq 'Conflict' }).Count
    }
}
