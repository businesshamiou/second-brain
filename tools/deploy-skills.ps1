#Requires -Version 5.1
<#
.SYNOPSIS
    Skill deployment by link, not by copy (Mission 168, ticket 07).

.DESCRIPTION
    Role: dot-sourced by install.ps1. Makes the six method-fabricated
    skills -- every immediate subdirectory of <clone>/skills/ that carries
    a SKILL.md, except external/ (measured from disk each run, never a
    fixed list: same discipline as the Vault's own first-install skill,
    skills/first-install/install-checklist.md item 8, "liste = dossiers
    mesures sur disque") -- available to Claude Code and to Codex from
    every neighbouring project, not just from inside the clone itself
    (spec, Skills deployes: "toujours deployes, par lien et non par
    copie"). A correction inside the clone's skills/<name>/ then
    propagates to every place that already links to it, with no
    reinstall.

    Two deployment targets, both ALWAYS populated with the six skills,
    regardless of what the questionnaire detected on the machine (T19: the
    six are unconditional, distinct from the opt-in collections below):
      - $Context.ClaudeSkillsDir (~/.claude/skills, or its -TestMode
        redirection) -- Claude Code's own personal skills folder.
      - $Context.CodexAgentsSkillsDir (~/.agents/skills, or its -TestMode
        redirection) -- Codex's measured official skills location (T11:
        developers.openai.com/codex/skills.md, read 2026-09-10/11).
        Deliberately NOT $Context.CodexSkillsDir (~/.codex/skills): that
        property is a pre-existing, unrelated AI-tool-detection heuristic
        (tools/questionnaire.ps1's Get-DetectedAiTools), not a documented
        Codex skills location -- see install.ps1's own New-InstallerContext
        header comment for the full distinction. Never confuse the two.

    Additionally, on choice only (T19, T24; the questionnaire's eighth
    question, $Answers.skillCollections, already collected by ticket 05):
      - the token 'external' resolves to every skill directly under
        <clone>/skills/external/ (T24: "les outils de la methode", not
        deployed by default because the Codex skills list is itself
        capped at roughly 8000 characters, T11 -- deploying everything
        unconditionally would blow that budget for every participant, not
        just the ones who asked for more);
      - any other token is matched, case-insensitively, against a
        warehouse collection slug actually present under
        <clone>/skills-warehouse/skill-collections/<slug>/skills/ --
        again measured from disk, never a fixed list, since the warehouse
        can grow collections between second-brain releases without this
        file needing a matching edit.
    An unrecognized token is skipped, never a fatal error (Class B,
    ticket 07 report): a typo in a free-text questionnaire answer must
    never abort the whole installation over an optional extra.

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
        resolving to a DIFFERENT source -- e.g. a same-named skill from
        two different chosen collections, or a foreign item that predates
        this installer) -> left alone and reported as a conflict, NEVER
        overwritten, NEVER deleted (Decision 110852's spirit: an
        automated, unattended installer's safe default when it cannot ask
        a human is to leave the disk exactly as it found it and name what
        it could not do, not to guess).

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

    Codex budget (ticket 07 criterion 3): Measure-DefaultSkillsCodexBudget
    sums the character length of the `description` frontmatter field of
    the six default-deployed skills ONLY -- never the opt-in collections,
    which are the participant's own informed choice and were never part
    of the "roughly 8000 characters" ceiling T11/T19 measured against
    Codex's own INITIAL list (a participant who deliberately asks for
    more accepts Codex's own documented degradation past that point:
    "descriptions raccourcies puis skills omis avec avertissement", never
    a second-brain failure). Throws if that sum ever exceeds the ceiling,
    same defensive-assertion style as tools/generate-assistant.ps1's own
    web-package-size check (ticket 06) -- today's six total 1892
    characters, comfortably under it, but a future skill added to skills/
    with an oversized description must fail loudly here, not silently
    ship an installer that quietly breaks Codex's own list.

    This file stays ASCII-only, like install.ps1, prerequisites.ps1 and
    generate-assistant.ps1 (see that file's own header comment): no
    byte-order mark needed, since no accented literal is ever typed here.

    Usage:
        . "$PSScriptRoot\tools\deploy-skills.ps1"
        $result = Publish-DeployedSkills -Context $context -ClonePath $clonePath `
            -SkillCollections $answers.skillCollections

    Inputs: none at load time; each function documents its own.
    Outputs: defines the functions below in the caller's scope.
#>

# Codex's own measured initial-list ceiling (T11, ticket 06's own web
# package ceiling comment cites the same kind of source); applied here only
# to the six default-deployed skills' descriptions (see header comment).
# One named place to change if that measured ceiling is ever revised.
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
    # file ever asks "what skills live here", used for the fabricated
    # skills, skills/external/, and every warehouse collection alike, so
    # the three never drift into three separate hand-maintained lists.
    # Sorted by name for a deterministic, reproducible link order.
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
    # The six method-fabricated skills (T19: "les six skills fabriques du
    # Vault (skills/)"), identified the same way the Vault's own
    # first-install checklist item 8 identifies them: every
    # skills/<name>/SKILL.md except external/ (item 9's own, separate
    # concern -- the adopted library, opt-in here per T24). Measured, never
    # hardcoded: a future skill added to or removed from skills/ changes
    # what this returns without editing this file.
    param([Parameter(Mandatory = $true)][string] $ClonePath)
    return Get-SkillDirectoryEntries -SkillsRoot (Join-Path $ClonePath 'skills') -ExcludeNames @('external')
}

function Get-ExternalMethodSkillEntries {
    # T24: "outils de la methode" -- skills/external/, the adopted library
    # the method itself uses, proposed at the questionnaire's collections
    # question as the token 'external', never deployed unless chosen.
    param([Parameter(Mandatory = $true)][string] $ClonePath)
    return Get-SkillDirectoryEntries -SkillsRoot (Join-Path $ClonePath 'skills\external')
}

function Get-AvailableWarehouseCollectionSlugs {
    # Every warehouse collection actually present on disk under this
    # clone's own skills-warehouse/skill-collections/ (measured, never the
    # canonical category catalog: a collection listed in
    # COLLECTIONS_STANDARD.md but not yet materialized here must never be
    # offered as if it were deployable). A slug counts only if it has its
    # own skills/ subfolder.
    param([Parameter(Mandatory = $true)][string] $ClonePath)
    $root = Join-Path $ClonePath 'skills-warehouse\skill-collections'
    if (-not (Test-Path $root)) { return @() }
    return @(
        Get-ChildItem -Path $root -Directory |
        Where-Object { Test-Path (Join-Path $_.FullName 'skills') } |
        Select-Object -ExpandProperty Name |
        Sort-Object
    )
}

function Get-WarehouseCollectionSkillEntries {
    # One chosen collection's own skills/, resolved the same measured way
    # as every other source in this file (Get-SkillDirectoryEntries) --
    # never a separate hand-maintained per-collection list. $CollectionSlug
    # is expected to already be one of Get-AvailableWarehouseCollectionSlugs'
    # own results (Resolve-RequestedSkillCollectionEntries checks that
    # before ever calling this); an unmatched slug simply returns an empty
    # list here (Test-Path inside Get-SkillDirectoryEntries), never throws.
    param(
        [Parameter(Mandatory = $true)][string] $ClonePath,
        [Parameter(Mandatory = $true)][string] $CollectionSlug
    )
    $root = Join-Path $ClonePath "skills-warehouse\skill-collections\$CollectionSlug\skills"
    return Get-SkillDirectoryEntries -SkillsRoot $root
}

function Resolve-RequestedSkillCollectionEntries {
    # Turns the questionnaire's free-text tokens (Q8, comma-split by
    # install.ps1 into $Answers.skillCollections) into actual skill
    # entries. Case-insensitive (a participant typing 'External' or
    # 'WEB-DESIGN' must not silently get nothing); an unrecognized token is
    # collected separately rather than thrown (Class B: a typo in an
    # optional extra must never abort the whole install).
    param(
        [Parameter(Mandatory = $true)][string] $ClonePath,
        [string[]] $RequestedTokens = @()
    )
    $entries = @()
    $unknownTokens = @()
    $availableWarehouseSlugs = @(Get-AvailableWarehouseCollectionSlugs -ClonePath $ClonePath | ForEach-Object { $_.ToLowerInvariant() })

    foreach ($rawToken in $RequestedTokens) {
        if ([string]::IsNullOrWhiteSpace($rawToken)) { continue }
        $token = $rawToken.Trim().ToLowerInvariant()
        if ($token -eq 'external') {
            $entries += Get-ExternalMethodSkillEntries -ClonePath $ClonePath
        }
        elseif ($availableWarehouseSlugs -contains $token) {
            $entries += Get-WarehouseCollectionSkillEntries -ClonePath $ClonePath -CollectionSlug $token
        }
        else {
            $unknownTokens += $rawToken
        }
    }

    return [PSCustomObject]@{
        Entries       = $entries
        UnknownTokens = $unknownTokens
    }
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

function Measure-DefaultSkillsCodexBudget {
    # ticket 07 criterion 3. See this file's own header comment for why
    # only the default (always-deployed) six count toward this ceiling.
    param([Parameter(Mandatory = $true)][psobject[]] $DefaultEntries)
    $breakdown = @()
    $total = 0
    foreach ($entry in $DefaultEntries) {
        $description = Get-SkillDescriptionFromFrontmatter -SkillMdPath (Join-Path $entry.SourcePath 'SKILL.md')
        $length = $description.Length
        $total += $length
        $breakdown += [PSCustomObject]@{ Name = $entry.Name; Length = $length }
    }
    if ($total -gt $Script:MaxCodexDefaultSkillsBudget) {
        throw "Default-deployed skills' descriptions total $total characters, over the $($Script:MaxCodexDefaultSkillsBudget)-character Codex budget ceiling (ticket 07 criterion 3)."
    }
    return [PSCustomObject]@{ Total = $total; Breakdown = $breakdown; Ceiling = $Script:MaxCodexDefaultSkillsBudget }
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
    # Orchestrator: links the six default skills plus any chosen
    # collections into both $Context.ClaudeSkillsDir and
    # $Context.CodexAgentsSkillsDir. Never asked to run twice for the same
    # name from two different sources within one call: the first source
    # for a given name wins (default six first, then collections in the
    # order requested), later ones are recorded as DuplicateNames and never
    # linked over the first (same "never overwrite" invariant as
    # Publish-SkillLink itself, applied before a link attempt is even
    # made).
    param(
        [Parameter(Mandatory = $true)][psobject] $Context,
        [Parameter(Mandatory = $true)][string] $ClonePath,
        [string[]] $SkillCollections = @()
    )

    $defaultEntries = Get-DefaultSkillEntries -ClonePath $ClonePath
    $budget = Measure-DefaultSkillsCodexBudget -DefaultEntries $defaultEntries

    $resolved = Resolve-RequestedSkillCollectionEntries -ClonePath $ClonePath -RequestedTokens $SkillCollections

    $seenNames = New-Object 'System.Collections.Generic.HashSet[string]'
    $duplicateNames = @()
    $entriesToLink = @()
    foreach ($entry in (@($defaultEntries) + @($resolved.Entries))) {
        if ($seenNames.Contains($entry.Name)) {
            $duplicateNames += $entry.Name
            continue
        }
        [void]$seenNames.Add($entry.Name)
        $entriesToLink += $entry
    }

    $linkResults = @()
    foreach ($entry in $entriesToLink) {
        foreach ($targetRoot in @($Context.ClaudeSkillsDir, $Context.CodexAgentsSkillsDir)) {
            $linkPath = Join-Path $targetRoot $entry.Name
            $status = Publish-SkillLink -LinkPath $linkPath -TargetPath $entry.SourcePath
            $linkResults += [PSCustomObject]@{
                Name       = $entry.Name
                TargetRoot = $targetRoot
                LinkPath   = $linkPath
                SourcePath = $entry.SourcePath
                Status     = $status
            }
        }
    }

    return [PSCustomObject]@{
        DefaultEntries         = $defaultEntries
        Budget                 = $budget
        RequestedUnknownTokens = $resolved.UnknownTokens
        DuplicateNames         = $duplicateNames
        LinkResults            = $linkResults
        ConflictCount          = @($linkResults | Where-Object { $_.Status -eq 'Conflict' }).Count
    }
}
