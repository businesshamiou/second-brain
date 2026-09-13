#Requires -Version 5.1
<#
.SYNOPSIS
    Assistant identity generator (Mission 168, ticket 06).

.DESCRIPTION
    Role: dot-sourced by install.ps1. Reads the single generic identity
    source (assistant/ASSISTANT.md -- the name lives there only as the
    {{ASSISTANT_NAME}} token, "Brian" appearing exactly once, as the
    documented default value) and derives three forms under the chosen
    assistant name:
      - a Claude Code subagent, .claude/agents/<slug>.md, restricted to
        read-only tools (tools: Read, Glob, Grep -- mechanical restriction,
        T03's resolved sub-agent format);
      - a Codex skill at its measured official location,
        .agents/skills/<slug>/SKILL.md (T11: developers.openai.com/codex/
        skills.md redirects to learn.chatgpt.com/docs/build-skills.md,
        read 2026-09-10/11 -- Codex scans .agents/skills at every directory
        from cwd up to the repo root; .codex/skills/ is not a documented
        location). Codex has no per-skill mechanical tool restriction
        (measured this ticket: developers.openai.com/codex/subagents and
        /permissions, both redirecting to learn.chatgpt.com -- Codex DOES
        support a restricted-tool custom subagent, but as a standalone
        .codex/agents/*.toml construct with its own sandbox_mode, session
        permission profiles otherwise being global; building that second,
        TOML-shaped artifact is named as a measured possibility in this
        ticket's report, not built here, to keep this generator to the
        ticket's own six criteria) -- so this skill is read-only by
        instruction (its own body already refuses writing/executing), never
        by mechanism;
      - a web package, web-package/<slug>/ (INSTRUCTIONS.md -- the text a
        person pastes into a claude.ai or ChatGPT Project's custom
        instructions field, always under $Script:MaxInstructionsChars --
        plus the knowledge files in $Script:WebPackageKnowledgeFiles, copied
        verbatim from documents this repository already carries, and
        README.md, a short usage note in English so this generator stays
        ASCII-only, describing exactly what the folder holds), capped at
        $Script:MaxWebPackageFiles files. That cap is 25 (ChatGPT Plus/Pro
        Projects, DECLARED, T19) -- Anthropic's own claude.ai Projects
        documentation (support.claude.com/en/articles/8241126-upload-files-
        to-claude, read via WebFetch 2026-09-11) states file count is
        "Unlimited" for Projects (only a 200k-token aggregate window and a
        30MB-per-file size cap apply), so there is no lower real
        Claude-side ceiling to clamp to; 25 stands as the technical ceiling.
        The package this generator actually produces (Mission 171-C01 step
        8, audit defects 8 and 9; knowledge-file selection revised by
        Mission 172 to also cover assistant/ASSISTANT.md's own "Trois
        questions de test") stays far below that ceiling on purpose:
        INSTRUCTIONS.md, README.md and three knowledge files, five files
        total -- see $Script:WebPackageKnowledgeFiles's own comment for why
        those three and not more.

    This file itself stays ASCII-only, like install.ps1 and
    prerequisites.ps1 (never questionnaire.ps1's own reasoning: no French
    prose is ever written as a literal string in this file's own source --
    every accented sentence a generated form carries is read at runtime
    from assistant/ASSISTANT.md via -Encoding UTF8, so no byte-order mark
    is needed here). Frontmatter `description` fields and the web
    package's own README are in English on purpose, mirroring this
    repository's own skills (e.g. skills/ecriture-de-mission/SKILL.md's
    English description over a French body) -- machine-facing trigger text
    and a short technical usage note, not the assistant's own voice.

    A rename (the assistant's name changes between two runs of the
    installer, ticket 05's update mode) must never overwrite the old
    forms silently: Move-AssistantFormsToTrash relocates every generated
    path for the OLD slug under _trash/assistant-rename-<old
    slug>-<timestamp>/, preserving each path's own relative structure, one
    finding this ticket names as prescribed product behaviour (not the
    Vault workshop's own _trash/ discipline) -- never a deletion.

    Usage:
        . "$PSScriptRoot\tools\generate-assistant.ps1"
        $slug = New-AssistantForms -ClonePath $clonePath -Name $vaultName

    Inputs: none at load time; each function documents its own.
    Outputs: defines the functions below in the caller's scope.
#>

# Web package ceilings (ticket 06 criterion 4; see this file's own header
# comment for the measured sources behind both numbers). One named place
# to change if either platform's documented ceiling ever changes.
$Script:MaxInstructionsChars = 8000
$Script:MaxWebPackageFiles = 25

# Knowledge files bundled into the web package alongside INSTRUCTIONS.md
# (Mission 171-C01 step 8, audit defects 8 and 9: the generator used to
# write only INSTRUCTIONS.md and README.md -- no knowledge at all -- so a
# Project built from this package knew nothing beyond the pasted
# instructions). Chosen from documents this repository already carries,
# never invented for this package, each picked because it is the kind of
# thing user story 23 (spec) says the web package needs to be useful
# without Claude Code's or Codex's own file access.
#
# Mission 172 closed a second audit finding on top of that: two of the
# three "Trois questions de test" in assistant/ASSISTANT.md's own
# corps-generateur body -- "Comment j'ouvre une session ?" and "Qu'est-ce
# qu'une Mission et ou je l'ecris ?" -- had no source anywhere in this
# package. A Project has no filesystem of its own; it can only answer from
# what is pasted into its instructions or uploaded as knowledge, and
# neither the session-start skill nor the Mission template/operating model
# were ever in either place.
#
# Each entry below carries SourcePaths (plural, always an array, even for
# a single source) rather than a single SourcePath, because closing that
# finding without breaking the Owner's own five-file ceiling for this
# package (see the comment at the end of this block) meant condensing
# several sources into one new file BY THEME (Doctrine rule 2: condense
# rather than drop content) instead of adding a file per source:
#   - CONTEXT.md is this repository's own validated product glossary (T18)
#     -- the vocabulary both the instructions and every other generated
#     form already assume;
#   - the project/Second-Brain boundary rule is the single rule the spec
#     (user story 29), this repository's own README FAQ, and CONTEXT.md's
#     own glossary note all point back to as the one participants most need
#     answered ("where does this belong, second-brain or my project?");
#   - HOW-TO.md answers the two remaining test questions, condensed from
#     five sources by theme rather than shrunk word by word: the
#     session-start skill and its reading list answer "how do I open a
#     session" (skills/session-start/SKILL.md,
#     skills/session-start/reading-list.md); the Mission template and the
#     project operating model -- named by assistant/ASSISTANT.md itself as
#     "le gabarit de Mission" and "le modele operatoire des projets" --
#     answer "what is a Mission and where do I write it"
#     (templates/mission-template.md,
#     knowledge/BRIEF-2026-08-17-211522-project-operating-model-v2.md),
#     together with the rule those two point back to for the actual path
#     convention (rules/RULES-2026-08-17-211522-mission-versioning-and-
#     generated-output.md, section 1: "<projet>/missions/MISSION-...").
# This repository's own README.md (formerly copied verbatim as
# OVERVIEW.md) is dropped to make room: of the original three knowledge
# files it is the only one that answered none of the three test questions
# in assistant/ASSISTANT.md -- the sole acceptance bar this package is
# measured against (tests/test-web-package-answers-test-questions.ps1) --
# so dropping it costs no answer to any of those three while staying under
# the file ceiling below. assistant/ASSISTANT.md's own body remains
# excluded from this list for the reason it always was: it is already
# INSTRUCTIONS.md's entire content once expanded, so uploading it again as
# a knowledge file would duplicate what the Project's own instructions
# field already carries, not add anything.
#
# Every source is still copied verbatim (Get-WebPackageKnowledgeFileContent
# below), never rewritten or name-substituted, and CONTEXT.md still mentions
# "Brian" exactly the way assistant/ASSISTANT.md's own excluded preamble
# does -- as the documented system default, a true statement about Second
# Brain regardless of what name this installation chose. Rewriting that
# sentence to the chosen name would make it read as a false claim about the
# system's own documented default; leaving it be is why
# tests/test-assistant-generation.ps1 scopes its own "no generated form
# contains 'Brian'" scan to the three personalized identity files (the
# subagent, the Codex skill, INSTRUCTIONS.md) rather than the whole
# web-package tree -- these copied documents are reference material, not
# identity text, the same distinction this file's own header comment
# already draws for ASSISTANT.md's preamble.
#
# Three knowledge files plus INSTRUCTIONS.md plus README.md is five files
# total in the finished package -- far under $Script:MaxWebPackageFiles
# (25, the measured platform ceiling above) and landing, unplanned, on the
# same number the Owner set early in grilling, before the platform ceiling
# above was ever measured (playbook journal, Manche 1, tickets T13-T16 and
# T19-T21: "Brian web = Projet, paquet de 5 fichiers au plus", DECIDED).
# That earlier figure is not re-derived here -- it is simply honoured as
# the more conservative of the two: fewer, load-bearing files a person
# uploads by hand beats maximizing toward the technical ceiling. It is also
# why the fix for Mission 172's finding is one condensed file replacing
# OVERVIEW.md rather than three new files added alongside it: three new
# knowledge-file slots plus the existing three would be six, over this
# five-file ceiling even before the 25-file platform ceiling comes into it.
$Script:WebPackageKnowledgeFiles = @(
    @{
        SourcePaths = @('CONTEXT.md')
        FileName    = 'GLOSSARY.md'
        Purpose     = "the product glossary (validated terms this assistant's own instructions and this package both use)"
    },
    @{
        SourcePaths = @('rules\RULES-2026-09-11-190000-project-second-brain-boundary.md')
        FileName    = 'PROJECT-BOUNDARY.md'
        Purpose     = 'the rule deciding whether something belongs in Second Brain itself or in one of your projects'
    },
    @{
        SourcePaths = @(
            'skills\session-start\SKILL.md',
            'skills\session-start\reading-list.md',
            'templates\mission-template.md',
            'knowledge\BRIEF-2026-08-17-211522-project-operating-model-v2.md',
            'rules\RULES-2026-08-17-211522-mission-versioning-and-generated-output.md'
        )
        FileName    = 'HOW-TO.md'
        Purpose     = 'how to open a session (skills/session-start/SKILL.md, skills/session-start/reading-list.md) and what a Mission is and where to write one (templates/mission-template.md, knowledge/BRIEF-2026-08-17-211522-project-operating-model-v2.md, rules/RULES-2026-08-17-211522-mission-versioning-and-generated-output.md) -- condensed by theme, each source named where its section begins'
    }
)

function ConvertTo-AssistantSlug {
    # Lowercase, no accents, no spaces (T07 complement: "un identifiant de
    # fichier derive, minuscules, sans accents ni espaces"). Accents are
    # stripped by Unicode decomposition (FormD) followed by dropping every
    # non-spacing-mark character, not by a fixed substitution table -- this
    # covers any Latin-script name a participant might type, not just the
    # French/Spanish accents this installer's own catalogs use. An empty or
    # entirely non-alphanumeric name (defensive only: the questionnaire
    # itself never accepts a blank assistant name, Read-QuestionnaireField
    # falls back to the 'Brian' default) falls back to 'assistant'.
    param([Parameter(Mandatory = $true)][string] $Name)
    $decomposed = $Name.Normalize([System.Text.NormalizationForm]::FormD)
    $builder = New-Object System.Text.StringBuilder
    foreach ($ch in $decomposed.ToCharArray()) {
        $category = [System.Globalization.CharUnicodeInfo]::GetUnicodeCategory($ch)
        if ($category -ne [System.Globalization.UnicodeCategory]::NonSpacingMark) {
            [void]$builder.Append($ch)
        }
    }
    $ascii = $builder.ToString().Normalize([System.Text.NormalizationForm]::FormC)
    $slug = $ascii.ToLowerInvariant()
    $slug = [regex]::Replace($slug, '[^a-z0-9]+', '-')
    $slug = $slug.Trim('-')
    if ([string]::IsNullOrWhiteSpace($slug)) { return 'assistant' }
    return $slug
}

function Get-AssistantIdentityBody {
    # Reads assistant/ASSISTANT.md and returns ONLY the text strictly
    # between its two <!-- corps-generateur:debut/fin --> markers -- never
    # "everything after the front matter", because the source's own
    # preamble (explaining the generator mechanism, and the one place the
    # literal word "Brian" is allowed to appear, as the documented default)
    # describes the SOURCE FILE ITSELF and must never be copied into a
    # generated form; embedding it there would both leak "Brian" into every
    # form regardless of the chosen name (measured directly: the first
    # version of this function extracted the whole preamble too, and this
    # ticket's own "no form contains Brian" test caught it) and read as
    # nonsense inside a subagent's own system prompt (it would describe
    # itself as "this file"). '## Liens' and its links belong to the
    # source alone for a different reason: every generated form gets its
    # own '## Liens' pointing back at this source with a relative path
    # computed for its own location -- the source's own links would
    # resolve to nothing three levels down from .agents/skills/<slug>/.
    # -Encoding UTF8 is mandatory here, same reasoning as Get-Carnet /
    # Get-Catalog: the source carries real accented French prose, and
    # Windows PowerShell 5.1's un-annotated Get-Content mangles it in a
    # BOM-less file.
    param([Parameter(Mandatory = $true)][string] $ClonePath)
    $sourcePath = Join-Path $ClonePath 'assistant\ASSISTANT.md'
    if (-not (Test-Path $sourcePath)) {
        throw "Assistant identity source not found: $sourcePath"
    }
    $raw = (Get-Content -Raw -Path $sourcePath -Encoding UTF8) -replace "`r`n", "`n"
    $startMarker = '<!-- corps-generateur:debut -->'
    $endMarker = '<!-- corps-generateur:fin -->'
    $startIndex = $raw.IndexOf($startMarker)
    $endIndex = $raw.IndexOf($endMarker)
    if ($startIndex -lt 0 -or $endIndex -lt 0 -or $endIndex -le $startIndex) {
        throw "Assistant identity source is missing its corps-generateur markers: $sourcePath"
    }
    $bodyStart = $startIndex + $startMarker.Length
    $body = $raw.Substring($bodyStart, $endIndex - $bodyStart)
    return $body.Trim() + "`n"
}

function Get-WebPackageKnowledgeFileContent {
    # Reads one or more knowledge-file sources (UTF8, same BOM-less-source
    # reasoning as Get-AssistantIdentityBody) and prepares them for the web
    # package: the words are never rewritten or name-substituted (see
    # $Script:WebPackageKnowledgeFiles's own comment for why: CONTEXT.md
    # mentions "Brian" as Second Brain's documented default, a true
    # statement regardless of the name this installation chose) -- but each
    # source's own '## Liens' section and every OTHER relative Markdown
    # link in its body are stripped, because both are correct only from
    # the source's OWN location in this repository, never from
    # web-package/<slug>/, always two levels below the clone root.
    # Measured directly: the first version of this function copied these
    # files unchanged, and the very first end-to-end test run against that
    # version failed tools/check-links.sh and
    # tools/check-obsolescence-guardrail.py on exactly these now-dangling
    # links (e.g. CONTEXT.md's own './README.md' resolves from the clone
    # root, not from two directories below it). Flattening a relative link
    # to its plain text, rather than recomputing its new relative path, is
    # deliberate, not a shortcut: once this file leaves the repository for
    # a claude.ai or ChatGPT Project upload, a Markdown link to a sibling
    # document that was never itself uploaded resolves to nothing on
    # either platform anyway -- an unclickable but guardian-correct '[text]
    # (../../rules/...)' is not meaningfully better than plain text once it
    # can never be clicked in the first place.
    #
    # A single source produces exactly the output this function always
    # produced (byte for byte -- GLOSSARY.md and PROJECT-BOUNDARY.md are
    # unaffected by Mission 172): the flattened body, then one '## Liens'
    # entry pointing back at it. More than one source (HOW-TO.md, Mission
    # 172) condenses them into one file BY THEME (Doctrine rule 2: condense
    # rather than drop content, and never hand-write substantial prose
    # disconnected from the sources) -- each source's flattened body kept
    # in full, separated by a rule and a heading that names its own source
    # path, so a reader can always tell which paragraph came from which
    # file; the '## Liens' section then lists every source in the same
    # order. Absolute links (http/https/mailto) and in-page anchors (#...)
    # are left untouched in every case -- those still work wherever this
    # content ends up. A missing source fails the whole generation loudly
    # (thrown, not skipped) -- same fail-closed posture as
    # Get-AssistantIdentityBody's own missing-source check, because a
    # silently thinner package is exactly the defect (8) this ticket
    # exists to close.
    param(
        [Parameter(Mandatory = $true)][string] $ClonePath,
        [Parameter(Mandatory = $true)][string[]] $SourceRelativePaths
    )
    $sections = @()
    foreach ($sourceRelativePath in $SourceRelativePaths) {
        $sourcePath = Join-Path $ClonePath $sourceRelativePath
        if (-not (Test-Path $sourcePath)) {
            throw "Web package knowledge file source not found: $sourcePath"
        }
        $raw = (Get-Content -Raw -Path $sourcePath -Encoding UTF8) -replace "`r`n", "`n"

        $liensMarker = "`n## Liens"
        $liensIndex = $raw.IndexOf($liensMarker)
        $body = if ($liensIndex -ge 0) { $raw.Substring(0, $liensIndex) } else { $raw }
        $body = $body.TrimEnd()
        $body = [regex]::Replace($body, '\[([^\]]+)\]\((?!https?://|mailto:|#)[^)]+\)', '$1')
        $sections += , $body
    }

    if ($SourceRelativePaths.Count -eq 1) {
        $body = $sections[0]
    }
    else {
        $parts = @()
        for ($i = 0; $i -lt $SourceRelativePaths.Count; $i++) {
            $sourceLink = $SourceRelativePaths[$i].Replace('\', '/')
            $parts += ('---' + "`n`n" + '### Source : `' + $sourceLink + '`' + "`n")
            $parts += $sections[$i]
        }
        $body = $parts -join "`n`n"
    }

    $liensLines = @()
    foreach ($sourceRelativePath in $SourceRelativePaths) {
        $sourceLink = $sourceRelativePath.Replace('\', '/')
        $liensLines += ('- `see also` -- [' + $sourceLink + '](../../' + $sourceLink + ')')
    }
    $lines = @($body, '', '## Liens', '') + $liensLines + @('')
    return ($lines -join "`n")
}

function Expand-AssistantPlaceholder {
    # Plain literal substitution (.NET String.Replace, never -replace/regex)
    # -- an assistant name a participant typed is arbitrary free text and
    # must never be interpreted as a regex replacement pattern (a name
    # containing '$' or a backslash sequence would otherwise corrupt the
    # substitution).
    param(
        [Parameter(Mandatory = $true)][string] $Text,
        [Parameter(Mandatory = $true)][string] $Name
    )
    return $Text.Replace('{{ASSISTANT_NAME}}', $Name)
}

function ConvertTo-YamlDoubleQuotedSafe {
    # Escapes a string for safe embedding inside a YAML double-quoted
    # scalar (backslash first, then the double quote itself -- order
    # matters, escaping the quote first would re-escape the backslash just
    # introduced). $Name is free text a participant typed at the
    # questionnaire; without this, a name containing a literal '"' would
    # break out of the frontmatter's quoted description value and corrupt
    # the generated file's YAML (code-review finding, ticket 06: found by
    # inspection, not exercised by this ticket's own tests, which only use
    # punctuation-free names).
    param([Parameter(Mandatory = $true)][string] $Text)
    return $Text.Replace('\', '\\').Replace('"', '\"')
}

function Get-AssistantGeneratedPaths {
    # Every path this generator ever writes for one slug, relative to the
    # clone root -- the single list Move-AssistantFormsToTrash (rename) and
    # this ticket's own tests both read, so the two can never drift apart.
    param([Parameter(Mandatory = $true)][string] $Slug)
    return @(
        (Join-Path '.claude\agents' "$Slug.md")
        (Join-Path '.agents\skills' $Slug)
        (Join-Path 'web-package' $Slug)
    )
}

function New-AssistantForms {
    # Orchestrator: (re)writes all three forms for $Name under $ClonePath.
    # Idempotent -- called with the same name and the same identity source
    # twice in a row writes byte-identical content both times, so a
    # no-change relaunch leaves the clone's porcelain empty (the same
    # idempotency rule every other installer step already follows).
    # Renaming (the old slug differing from the new one) is the caller's
    # concern: install.ps1 calls Move-AssistantFormsToTrash for the old
    # slug before calling this function for the new one.
    param(
        [Parameter(Mandatory = $true)][string] $ClonePath,
        [Parameter(Mandatory = $true)][string] $Name
    )
    $slug = ConvertTo-AssistantSlug -Name $Name
    $body = Expand-AssistantPlaceholder -Text (Get-AssistantIdentityBody -ClonePath $ClonePath) -Name $Name

    $subagentPath = Join-Path $ClonePath ".claude\agents\$slug.md"
    New-Item -ItemType Directory -Force -Path (Split-Path $subagentPath -Parent) | Out-Null
    Set-Content -Path $subagentPath -Encoding UTF8 -Value (New-ClaudeCodeSubagentContent -Name $Name -Slug $slug -Body $body)

    $skillPath = Join-Path $ClonePath ".agents\skills\$slug\SKILL.md"
    New-Item -ItemType Directory -Force -Path (Split-Path $skillPath -Parent) | Out-Null
    Set-Content -Path $skillPath -Encoding UTF8 -Value (New-CodexSkillContent -Name $Name -Slug $slug -Body $body)

    $webPackageDir = Join-Path $ClonePath "web-package\$slug"
    New-Item -ItemType Directory -Force -Path $webPackageDir | Out-Null
    $instructionsText = New-WebPackageInstructions -Name $Name -Body $body
    if ($instructionsText.Length -gt $Script:MaxInstructionsChars) {
        throw "Generated web package instructions for '$Name' are $($instructionsText.Length) characters, over the $($Script:MaxInstructionsChars)-character ceiling (ticket 06 criterion 4)."
    }
    Set-Content -Path (Join-Path $webPackageDir 'INSTRUCTIONS.md') -Encoding UTF8 -Value $instructionsText

    foreach ($knowledgeFile in $Script:WebPackageKnowledgeFiles) {
        $content = Get-WebPackageKnowledgeFileContent -ClonePath $ClonePath -SourceRelativePaths $knowledgeFile.SourcePaths
        Set-Content -Path (Join-Path $webPackageDir $knowledgeFile.FileName) -Encoding UTF8 -Value $content
    }

    Set-Content -Path (Join-Path $webPackageDir 'README.md') -Encoding UTF8 -Value (New-WebPackageReadme -Name $Name -Slug $slug)

    $packageFileCount = @(Get-ChildItem -Path $webPackageDir -File).Count
    if ($packageFileCount -gt $Script:MaxWebPackageFiles) {
        throw "Web package for '$Name' has $packageFileCount files, over the $($Script:MaxWebPackageFiles)-file ceiling (ticket 06 criterion 4)."
    }

    return $slug
}

function New-ClaudeCodeSubagentContent {
    # T03's resolved sub-agent format: frontmatter name/description/tools,
    # body = system prompt. `tools: Read, Glob, Grep` is the exact,
    # complete list -- no Bash, no Edit, no Write, nothing else -- the
    # mechanical read-only restriction ticket 06 criterion 2 requires.
    param(
        [Parameter(Mandatory = $true)][string] $Name,
        [Parameter(Mandatory = $true)][string] $Slug,
        [Parameter(Mandatory = $true)][string] $Body
    )
    $safeName = ConvertTo-YamlDoubleQuotedSafe -Text $Name
    $description = "Read-only assistant for this Second Brain workspace: answers questions about its rules, decisions, knowledge and skills, always citing the source file by path. Use when asked about $safeName, Second Brain, the Vault, or how something in this workspace works. Never writes or runs anything."
    $lines = @(
        '---'
        "name: $Slug"
        "description: `"$description`""
        'tools: Read, Glob, Grep'
        '---'
        ''
        $Body.TrimEnd()
        ''
        '## Liens'
        ''
        '- `see also` -- [assistant/ASSISTANT.md](../../assistant/ASSISTANT.md)'
        ''
    )
    return ($lines -join "`n")
}

function New-CodexSkillContent {
    # Agent Skills format (SKILL.md, name + description frontmatter, T03),
    # at Codex's measured official location (.agents/skills/<slug>/, T11).
    # Read-only by instruction only, not by mechanism: Codex has no
    # per-skill tool restriction (measured this ticket -- see this file's
    # own header comment); the body's own "Ce qu'il refuse" section is the
    # only thing standing between this skill and writing or running
    # something, which is exactly why it is worth naming as a residual in
    # this ticket's report rather than silently presenting it as
    # equivalent to the Claude Code subagent's mechanical restriction.
    param(
        [Parameter(Mandatory = $true)][string] $Name,
        [Parameter(Mandatory = $true)][string] $Slug,
        [Parameter(Mandatory = $true)][string] $Body
    )
    $safeName = ConvertTo-YamlDoubleQuotedSafe -Text $Name
    $description = "Read-only assistant for this Second Brain workspace: answers questions about its rules, decisions, knowledge and skills, always citing the source file by path. Use when asked about $safeName, Second Brain, or how something in this workspace works."
    $lines = @(
        '---'
        "name: $Slug"
        "description: `"$description`""
        '---'
        ''
        $Body.TrimEnd()
        ''
        '## Liens'
        ''
        '- `see also` -- [assistant/ASSISTANT.md](../../../assistant/ASSISTANT.md)'
        ''
    )
    return ($lines -join "`n")
}

function New-WebPackageInstructions {
    # The text a person pastes into a claude.ai or ChatGPT Project's own
    # custom-instructions field (never itself one of the package's
    # "files" -- it is copied by hand, not uploaded). Body only, plus the
    # same back-reference every generated form carries; no frontmatter,
    # since a Project's instructions field is plain text, not a Markdown
    # file with YAML front matter.
    param(
        [Parameter(Mandatory = $true)][string] $Name,
        [Parameter(Mandatory = $true)][string] $Body
    )
    $lines = @(
        $Body.TrimEnd()
        ''
        '## Liens'
        ''
        '- `see also` -- [assistant/ASSISTANT.md](../../assistant/ASSISTANT.md)'
        ''
    )
    return ($lines -join "`n")
}

function New-WebPackageReadme {
    # English on purpose (this file's own header comment: keeps
    # generate-assistant.ps1 ASCII-only, no byte-order mark needed) -- a
    # short technical usage note, not the assistant's own voice.
    #
    # Rewritten for Mission 171-C01 step 8 (audit defects 8 and 9): this
    # README now names every file New-AssistantForms actually writes into
    # this folder, generated from the same $Script:WebPackageKnowledgeFiles
    # list New-AssistantForms itself copies from -- so the two can never
    # drift apart, the same reasoning Get-AssistantGeneratedPaths already
    # applies to the rename path list. The earlier text ("nothing else
    # needs uploading") was accurate only while this package held two
    # files; it directly contradicted acceptance scenario S8's old wording
    # in tools/acceptance-wizard.sh, which described a chat-Skills zip
    # upload gesture that belongs to the warehouse deliverables (step 5),
    # not this Project package (defect 9, fixed in that file, this same
    # step). tests/test-web-package-readme-matches-contents.ps1 (this
    # step's own explicitly required test) checks this file's list against
    # the folder's real contents, in both directions.
    param(
        [Parameter(Mandatory = $true)][string] $Name,
        [Parameter(Mandatory = $true)][string] $Slug
    )
    $knowledgeLines = @()
    foreach ($k in $Script:WebPackageKnowledgeFiles) {
        $knowledgeLines += "- ``$($k.FileName)`` -- $($k.Purpose)."
    }
    $lines = @(
        "# $Name -- web package"
        ''
        "Generated by tools/generate-assistant.ps1 (or tools/sb_installer_helper.py on macOS/Linux) from assistant/ASSISTANT.md and this repository's own documents (Mission 171-C01). This is a claude.ai or ChatGPT **Project** package -- custom instructions plus a few project-knowledge files -- not a Skill package: nothing in this folder is a zip meant to be uploaded so it can trigger on its own."
        ''
        "To use $Name in a claude.ai or ChatGPT Project:"
        ''
        '1. Create a Project (requires a paid plan -- Claude Pro or above, or ChatGPT Plus or above; this package is not designed or tested against free-tier accounts).'
        "2. Paste the contents of ``INSTRUCTIONS.md`` into the Project's custom instructions field. Do not upload INSTRUCTIONS.md itself as a file -- it belongs in that field."
        "3. Upload each of these files to the Project's knowledge (or files) section:"
        ''
        $knowledgeLines
        ''
        "This README ($($Script:WebPackageKnowledgeFiles.Count + 2) files total in this folder) is for your own reference and never needs uploading itself."
        ''
        '## Liens'
        ''
        '- `see also` -- [assistant/ASSISTANT.md](../../assistant/ASSISTANT.md)'
        ''
    )
    return ($lines -join "`n")
}

function Move-AssistantFormsToTrash {
    # Rename handling (ticket 06 criterion 5): every generated path for
    # $OldSlug is moved -- filesystem Move-Item, never `git mv` (git sees a
    # plain delete-plus-add, the exact shape install.ps1's own
    # Save-ClonePendingChanges already knows how to stage line by line;
    # a detected rename's "R  old -> new" porcelain line would not parse
    # under that loop's `$line.Substring(3)` extraction) -- under
    # _trash/assistant-rename-<old slug>-<timestamp>/, preserving each
    # path's own relative structure. Never a deletion (Decision 110852):
    # the old forms stay fully readable at their new address. A path that
    # does not exist (nothing was ever generated under that slug) is
    # skipped rather than treated as an error -- the very first install
    # has no "old slug" to move at all.
    param(
        [Parameter(Mandatory = $true)][string] $ClonePath,
        [Parameter(Mandatory = $true)][string] $OldSlug,
        [datetime] $At = (Get-Date)
    )
    $timestamp = $At.ToString('yyyyMMdd-HHmmss')
    $trashRoot = Join-Path $ClonePath "_trash\assistant-rename-$OldSlug-$timestamp"
    $movedAny = $false
    foreach ($relativePath in (Get-AssistantGeneratedPaths -Slug $OldSlug)) {
        $sourcePath = Join-Path $ClonePath $relativePath
        if (-not (Test-Path $sourcePath)) { continue }
        $destinationPath = Join-Path $trashRoot $relativePath
        New-Item -ItemType Directory -Force -Path (Split-Path $destinationPath -Parent) | Out-Null
        Move-Item -Path $sourcePath -Destination $destinationPath -Force
        $movedAny = $true
    }
    return $movedAny
}
