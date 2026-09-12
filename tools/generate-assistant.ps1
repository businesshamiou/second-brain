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
        and README.md, a short usage note in English so this generator
        stays ASCII-only), capped at $Script:MaxWebPackageFiles files. That
        cap is 25 (ChatGPT Plus/Pro Projects, DECLARED, T19) -- Anthropic's
        own claude.ai Projects documentation
        (support.claude.com/en/articles/8241126-upload-files-to-claude,
        read via WebFetch 2026-09-11) states file count is "Unlimited" for
        Projects (only a 200k-token aggregate window and a 30MB-per-file
        size cap apply), so there is no lower real Claude-side ceiling to
        clamp to; 25 stands.

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
    param(
        [Parameter(Mandatory = $true)][string] $Name,
        [Parameter(Mandatory = $true)][string] $Slug
    )
    $lines = @(
        "# $Name -- web package"
        ''
        "Generated by tools/generate-assistant.ps1 from assistant/ASSISTANT.md (Mission 168, ticket 06). To use $Name in a claude.ai or ChatGPT Project:"
        ''
        '1. Create a Project (requires a paid plan -- Claude Pro or above, or ChatGPT Plus or above; this package is not designed or tested against free-tier accounts).'
        '2. Paste the contents of INSTRUCTIONS.md into the Project''s custom instructions field.'
        "3. That is the whole package for now -- $Name's identity lives entirely in those instructions; nothing else needs uploading."
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
