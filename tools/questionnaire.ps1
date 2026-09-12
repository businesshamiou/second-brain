#Requires -Version 5.1
<#
.SYNOPSIS
    Trilingual questionnaire and profile-writing helpers (Mission 168,
    ticket 05).

.DESCRIPTION
    Role: dot-sourced by install.ps1 to load the three language catalogs
    (i18n/catalog.en.json, catalog.fr.json, catalog.es.json -- same keys in
    all three, verified by tests/test-catalog-key-parity.ps1), read one
    answer at a time (real keyboard via Read-Host, or a scripted queue
    supplied only by tests -- see Read-QuestionnaireLine), and write the
    filled USER.md profile once every question has an answer.

    Every catalog file is UTF-8 without a byte-order mark. Windows
    PowerShell 5.1's `Get-Content -Raw` falls back to the system's ANSI code
    page when a file has no BOM, silently mangling every accented character
    (measured directly while testing tests/test-catalog-key-parity.ps1: an
    accented word round-tripped as mojibake). `-Encoding UTF8` is mandatory
    on every Get-Content call in this file and in install.ps1's own
    Get-Carnet / -AnswersFile reads, now that both carry real accented text
    (French and Spanish catalog strings, and any accented answer a
    participant types -- a first name, a one-sentence activity) for the
    first time; ticket 03/04's own JSON (the carnet, the sample answers
    fixture) never exercised this because nothing in it was ever non-ASCII.

    This file itself also carries non-ASCII text (the French USER.md
    section content Write-UserProfile below produces, and the Spanish
    language label), so it is saved with a UTF-8 byte-order mark --
    without one, Windows PowerShell 5.1's own script parser (not
    just Get-Content) falls back to the same ANSI code page and can
    misparse the file outright, not merely mangle a string (measured
    directly: an accented em-dash inside a double-quoted string, read
    without a BOM, was tokenized as if it were part of the quoting itself,
    producing "missing closing parenthesis" errors dozens of lines away
    from the real cause). install.ps1 and prerequisites.ps1 stay
    ASCII-only specifically to avoid needing a BOM at all.

    Usage:
        . "$PSScriptRoot\tools\questionnaire.ps1"
        $catalog = Get-Catalog -Language 'FR' -I18nDir (Join-Path $PSScriptRoot 'i18n')
        $answer = Read-QuestionnaireField -PromptText '...' -DefaultValue '...' -ScriptedInputs $queue

    Inputs: none at load time; each function documents its own.
    Outputs: defines the functions below in the caller's scope.
#>

function Get-InstallerLanguage {
    # The default Question 1 proposes (T06 complement 2: the default value
    # comes from Windows' own language). Never used to choose a
    # language for -AnswersFile mode (see install.ps1) -- an answers file is
    # an already-resolved input, not a question with a suggested default to
    # accept by pressing Enter, so silent mode falls back to EN when
    # `language` is absent, not to this detection (Class B, ticket 05
    # report: keeps tests/test-install-e2e.ps1's English-verdict assertion
    # correct regardless of the machine's own Windows language).
    try {
        $culture = Get-UICulture
    }
    catch {
        return 'EN'
    }
    switch ($culture.TwoLetterISOLanguageName) {
        'fr' { return 'FR' }
        'es' { return 'ES' }
        default { return 'EN' }
    }
}

function Get-Catalog {
    # Loads one language catalog. An unrecognized code (never produced by
    # this ticket's own callers, which always normalize to FR/EN/ES first,
    # but defended here too) falls back to English rather than throwing --
    # the fixed English first sentence already established that English is
    # the installer's universal fallback.
    param(
        [Parameter(Mandatory = $true)][string] $Language,
        [Parameter(Mandatory = $true)][string] $I18nDir
    )
    $code = $Language.ToString().ToLowerInvariant()
    if ($code -notin @('en', 'fr', 'es')) { $code = 'en' }
    $path = Join-Path $I18nDir "catalog.$code.json"
    if (-not (Test-Path $path)) {
        throw "Catalog not found: $path"
    }
    return Get-Content -Raw -Path $path -Encoding UTF8 | ConvertFrom-Json
}

function Format-CatalogText {
    # `-f` (the .NET composite-format operator) needs its argument as a
    # single array, not a comma-separated argument list, when there is more
    # than one placeholder -- passing $FormatArgs (already an array)
    # directly to `-f` does the right thing for zero, one or several
    # placeholders alike.
    param(
        [Parameter(Mandatory = $true)][psobject] $Catalog,
        [Parameter(Mandatory = $true)][string] $Key,
        [string[]] $FormatArgs = @()
    )
    $template = $Catalog.$Key
    if ($null -eq $template) {
        throw "Missing catalog key: $Key"
    }
    if ($FormatArgs.Count -eq 0) {
        return $template
    }
    return ($template -f $FormatArgs)
}

function Format-PromptWithDefault {
    # install.ps1 builds every multi-choice/free-text prompt the same way:
    # the question's own text, then a separate catalog key spelling out the
    # default in parentheses (the two need to stay separate keys because the
    # default note's placeholder differs per question -- a name, a path, a
    # detected-tools list, or nothing at all). One place for the
    # concatenation instead of five near-identical inline expressions.
    param(
        [Parameter(Mandatory = $true)][psobject] $Catalog,
        [Parameter(Mandatory = $true)][string] $PromptKey,
        [Parameter(Mandatory = $true)][string] $DefaultNoteKey,
        [string[]] $DefaultNoteArgs = @()
    )
    $prompt = Format-CatalogText -Catalog $Catalog -Key $PromptKey
    $note = Format-CatalogText -Catalog $Catalog -Key $DefaultNoteKey -FormatArgs $DefaultNoteArgs
    return "$prompt $note"
}

function Test-AffirmativeAnswer {
    # The one place that recognizes a "yes" across all three languages --
    # used for both the update-mode "has anything changed?" question and the
    # first-project confirmation in install.ps1, which independently needed
    # the exact same FR/EN/ES yes-token set before this existed. Spanish
    # "si" is matched without its accent deliberately (Class B, ticket 05
    # report): accepting both spellings costs nothing here, and every .ps1
    # source file in this installer is kept ASCII-only (see this file's own
    # header comment on the BOM/encoding pitfall), so the accented "si" is
    # never spelled out literally in code, only tolerated as an input.
    param([string] $Answer)
    return $Answer.ToString().Trim().ToLowerInvariant() -in @('y', 'yes', 'o', 'oui', 's', 'si')
}

function New-ScriptedInputQueue {
    # Builds the test-only replay queue install.ps1's -ScriptedAnswers
    # parameter is turned into: one entry per keystroke line a real person
    # would type, dequeued in the exact order the questionnaire asks (see
    # Read-QuestionnaireLine). The leading comma prevents PowerShell from
    # unrolling the queue into its elements across a function return/pipeline
    # boundary -- a bare `return $queue` would otherwise hand the *last*
    # element to the caller instead of the queue object itself.
    param([string[]] $Inputs = @())
    $queue = New-Object 'System.Collections.Generic.Queue[string]'
    foreach ($i in $Inputs) { $queue.Enqueue($i) }
    return , $queue
}

function Read-QuestionnaireLine {
    # The seam tests replay through: real usage never passes -ScriptedInputs
    # (or passes an already-drained queue), so Read-Host runs exactly as it
    # would for a person at the keyboard; a test supplies a queue built by
    # New-ScriptedInputQueue and this function dequeues from it instead,
    # never touching the real console. $PromptText is printed with
    # Write-Host, deliberately never Write-Output: this function's actual
    # return value is the answer, and Write-Output would append the prompt
    # text itself onto that same return stream (a caller doing
    # `$line = Read-QuestionnaireLine ...` would receive a two-element
    # array -- prompt, then answer -- instead of the answer alone). Measured
    # directly: this function's first version corrupted every field it
    # touched, e.g. writing the *workspace prompt sentence* into
    # $answers.workspacePath, which then reached `New-Item -Path` and
    # PowerShell tried to parse a colon inside that sentence as a drive
    # qualifier ("Lecteur introuvable"). Write-Host goes to the Information
    # stream, never the success stream -- invisible to any variable
    # assignment or pipeline, visible to a real terminal and to a test that
    # captures every stream explicitly (`*>&1`, not `2>&1`).
    param(
        [Parameter(Mandatory = $true)][string] $PromptText,
        [System.Collections.Generic.Queue[string]] $ScriptedInputs
    )
    Write-Host $PromptText
    if ($null -ne $ScriptedInputs -and $ScriptedInputs.Count -gt 0) {
        return $ScriptedInputs.Dequeue()
    }
    return Read-Host
}

function Read-QuestionnaireField {
    # Pressing Enter accepts the proposed default (T06 complement 2): a
    # blank or whitespace-only line returns $DefaultValue untouched;
    # anything else is trimmed and returned as-is.
    param(
        [Parameter(Mandatory = $true)][string] $PromptText,
        [string] $DefaultValue = '',
        [System.Collections.Generic.Queue[string]] $ScriptedInputs
    )
    $line = Read-QuestionnaireLine -PromptText $PromptText -ScriptedInputs $ScriptedInputs
    if ([string]::IsNullOrWhiteSpace($line)) {
        return $DefaultValue
    }
    return $line.Trim()
}

function Read-RequiredQuestionnaireField {
    # For the one or two answers a blank default cannot stand in for (a
    # first name): loops the same prompt until a non-blank line comes back,
    # rather than silently accepting an empty identity field -- ticket 05's
    # own criterion 3 ("aucun champ de gabarit restant") rules out ever
    # writing USER.md with nothing where a person's name belongs.
    param(
        [Parameter(Mandatory = $true)][string] $PromptText,
        [System.Collections.Generic.Queue[string]] $ScriptedInputs
    )
    while ($true) {
        $line = Read-QuestionnaireLine -PromptText $PromptText -ScriptedInputs $ScriptedInputs
        if (-not [string]::IsNullOrWhiteSpace($line)) {
            return $line.Trim()
        }
        # A scripted queue that never supplies a non-blank answer would spin
        # forever -- defended by every test that drives this function always
        # queuing a real value for it (never relying on this loop against a
        # scripted queue).
    }
}

function Set-AnswerField {
    # One helper for every write to the growing $answers object, in both
    # question flows below and in install.ps1's own resume/update-mode code.
    # Plain dot-assignment ($Answers.Name = $Value) throws
    # ("property ... cannot be found") the first time a field is set on a
    # PSCustomObject that never had that NoteProperty to begin with --
    # exactly the shape of a fresh, empty $answers scaffold built for
    # interactive mode. Add-Member -Force covers both "does not exist yet"
    # and "already exists, overwrite it" (the second case matters for the
    # update-mode rewrite path), so every caller uses this instead of ever
    # choosing between the two forms itself.
    param(
        [Parameter(Mandatory = $true)][psobject] $Answers,
        [Parameter(Mandatory = $true)][string] $Name,
        $Value
    )
    $Answers | Add-Member -MemberType NoteProperty -Name $Name -Value $Value -Force
}

function Test-AbsolutePath {
    # True for a Windows drive-letter absolute path (C:\... or C:/...) or a
    # UNC path (\\server\share\...) -- every path shape a real install.ps1
    # participant can type here. Deliberately not
    # [System.IO.Path]::IsPathRooted: that also returns $true for a
    # drive-relative path like '\foo' (rooted, but resolved against
    # whatever drive happens to be current -- not what "absolute" means
    # for a workspace that must never move once created, T06).
    param([string] $Path)
    if ($Path -match '^[A-Za-z]:[\\/]') { return $true }
    if ($Path -match '^\\\\') { return $true }
    return $false
}

function ConvertTo-ComparablePath {
    # String-only normalization for Test-PathInsideOrEqual below:
    # backslashes become slashes, a trailing slash is stripped, and the
    # comparison is case-insensitive (Windows' own filesystem semantics).
    # Never a filesystem canonicalization (Resolve-Path/GetFullPath): the
    # candidate workspace usually does not exist yet.
    param([string] $Path)
    $normalized = $Path -replace '\\', '/'
    $normalized = $normalized.TrimEnd('/')
    return $normalized.ToLowerInvariant()
}

function Test-PathInsideOrEqual {
    # True when $Candidate is $Root itself, or a descendant of it.
    param([string] $Candidate, [string] $Root)
    $c = ConvertTo-ComparablePath -Path $Candidate
    $r = ConvertTo-ComparablePath -Path $Root
    if ($c -eq $r) { return $true }
    return $c.StartsWith("$r/")
}

function Test-ValidWorkspacePath {
    # The one place that decides whether a typed workspace-path answer is
    # acceptable (Defects 1/2, Mission 171-C01): 'oui'/'non'/'y'/'n' and a
    # blank line are not paths -- the literal 'oui' folder found under
    # _trash-oui-20260912 is this exact defect's own physical proof -- a
    # relative path is not usable ('git clone' would resolve it against
    # install.ps1's own current directory, not the participant's intent),
    # and a path inside the source repository would clone second-brain
    # into itself. Returns 'Valid', 'BlankOrYesNo', 'NotAbsolute' or
    # 'InsideSource' -- never throws, so the caller's loop can print a
    # cause-naming message (a "questionnaire.workspace.error.<cause>"
    # catalog key, first letter lowercased) and ask again.
    param([string] $Candidate, [string] $SourceRoot)
    $trimmed = $Candidate.Trim()
    $lower = $trimmed.ToLowerInvariant()
    if ($lower -eq '' -or ($lower -in @('oui', 'non', 'y', 'n'))) {
        return 'BlankOrYesNo'
    }
    if (-not (Test-AbsolutePath -Path $trimmed)) {
        return 'NotAbsolute'
    }
    if (Test-PathInsideOrEqual -Candidate $trimmed -Root $SourceRoot) {
        return 'InsideSource'
    }
    return 'Valid'
}

function Resolve-WorkspacePathAnswer {
    # Same resolution contract as Resolve-QuestionnaireAnswer (an already
    # recorded value is returned untouched; this is only ever called from
    # the interactive path, install.ps1's own $interactive branch) but
    # adds Test-ValidWorkspacePath's validation loop: a typed answer is
    # asked again, with a cause-naming message, until it is an absolute
    # path outside the source repository (Defects 1/2, Mission 171-C01).
    param(
        [Parameter(Mandatory = $true)][psobject] $Answers,
        [Parameter(Mandatory = $true)][string] $PromptText,
        [Parameter(Mandatory = $true)][string] $DefaultValue,
        [Parameter(Mandatory = $true)][string] $SourceRoot,
        [Parameter(Mandatory = $true)][psobject] $Catalog,
        [System.Collections.Generic.Queue[string]] $ScriptedInputs
    )
    $existing = $Answers.workspacePath
    $hasExisting = ($null -ne $existing) -and -not [string]::IsNullOrWhiteSpace($existing)
    if ($hasExisting) {
        return $existing
    }

    while ($true) {
        $candidate = Read-QuestionnaireField -PromptText $PromptText -DefaultValue $DefaultValue -ScriptedInputs $ScriptedInputs
        $verdict = Test-ValidWorkspacePath -Candidate $candidate -SourceRoot $SourceRoot
        if ($verdict -eq 'Valid') {
            $resolved = $candidate.Trim()
            Set-AnswerField -Answers $Answers -Name 'workspacePath' -Value $resolved
            return $resolved
        }
        $causeKey = $verdict.Substring(0, 1).ToLowerInvariant() + $verdict.Substring(1)
        Write-Host (Format-CatalogText -Catalog $Catalog -Key "questionnaire.workspace.error.$causeKey" -FormatArgs @($candidate, $DefaultValue))
    }
}

function Get-DetectedAiTools {
    # Tools already present on this machine come pre-checked (T06 Q4 /
    # complement 2 Q6) -- Claude Code and Codex are the only two of the four options a
    # local measurement can ever confirm (claude.ai and ChatGPT are web
    # accounts, nothing on disk to check). Reads $Context.ClaudeSkillsDir /
    # CodexSkillsDir -- already profile-rooted in real mode and
    # TestRoot-rooted in -TestMode by New-InstallerContext (install.ps1), so
    # this measurement is redirected the same way every other profile touch
    # in this installer is, and a -TestMode run never reports a false
    # positive from the Owner's real ~/.claude or ~/.codex.
    param([Parameter(Mandatory = $true)][psobject] $Context)
    $detected = @()
    if (Test-Path $Context.ClaudeSkillsDir) { $detected += 'claude-code' }
    if (Test-Path $Context.CodexSkillsDir) { $detected += 'codex' }
    return $detected
}

function Get-ProfileEnvironmentFacts {
    # USER.md's "Environnement" section: measured automatically by the
    # installer, never asked (skeleton, ticket 01) -- exactly the
    # measurable facts T06 says a question must never ask for (OS, shell,
    # tools present; timezone is the one T06 explicitly lists that this
    # function also measures). `git --version`'s failure is swallowed
    # deliberately: prerequisites.ps1 (ticket 04) already guarantees a
    # working git by the time this runs, from install.ps1's own step -1, so
    # a caught failure here would only ever fire if that guarantee were
    # somehow broken, and "unknown" is a truthful fact to record rather than
    # aborting profile-writing over a cosmetic detail.
    param([Parameter(Mandatory = $true)][psobject] $Context)
    $gitVersion = 'unknown'
    try {
        $out = & git --version 2>$null
        if ($LASTEXITCODE -eq 0 -and $out) { $gitVersion = ($out | Select-Object -First 1).ToString() }
    }
    catch { }
    $timezoneId = 'unknown'
    try { $timezoneId = (Get-TimeZone).Id } catch { }

    return [PSCustomObject]@{
        OS                = [System.Environment]::OSVersion.VersionString
        Shell             = "PowerShell $($PSVersionTable.PSVersion)"
        Timezone          = $timezoneId
        Git               = $gitVersion
        ClaudeCodeDetected = (Test-Path $Context.ClaudeSkillsDir)
        CodexDetected     = (Test-Path $Context.CodexSkillsDir)
    }
}

function Write-UserProfile {
    # Rewrites <clonePath>/USER.md from the skeleton's own section headers
    # (ticket 01: Qui, Activité, Façon de travailler, Environnement, Origine
    # -- kept as fixed structural vocabulary of the product, in French
    # regardless of the installer's chosen language, the same way the
    # skeleton itself never changed language; only the *values* are the
    # participant's own words, or this function's measured/derived facts).
    # Ticket 05 criterion 3 ("aucun champ de gabarit restant"): every value
    # below is either a real answer or a concrete, non-placeholder fallback
    # (an empty tools list renders as "aucun renseigné", never as
    # "_(à remplir)_").
    param(
        [Parameter(Mandatory = $true)][string] $Path,
        [Parameter(Mandatory = $true)][psobject] $Answers,
        [Parameter(Mandatory = $true)][psobject] $EnvironmentFacts,
        [Parameter(Mandatory = $true)][string] $InstalledAt
    )
    $languageLabels = @{ FR = 'français (FR)'; EN = 'English (EN)'; ES = 'español (ES)' }
    $lang = $Answers.language
    $languageLabel = if ($languageLabels.ContainsKey($lang)) { $languageLabels[$lang] } else { "$lang" }

    $aiToolsList = @($Answers.aiTools)
    $aiTools = if ($aiToolsList.Count -gt 0) { ($aiToolsList -join ', ') } else { 'aucun renseigné' }

    $skillCollectionsList = @($Answers.skillCollections)
    $skillCollections = if ($skillCollectionsList.Count -gt 0) { ($skillCollectionsList -join ', ') } else { 'aucune' }

    $firstName = $Answers.firstName
    $activity = $Answers.activity
    $whatMatters = $Answers.whatMatters
    $assistantName = $Answers.vaultName
    $workspacePath = $Answers.workspacePath

    $lines = @(
        '---'
        'type: profile'
        "title: ""Fiche utilisateur — $firstName"""
        "description: ""Rédigée par le questionnaire d'installation (Mission 168, ticket 05), à partir des réponses données le $InstalledAt."""
        'status: active'
        '---'
        ''
        '# FICHE UTILISATEUR'
        ''
        '## Qui'
        ''
        "- **Prénom :** $firstName"
        "- **Langue de travail :** $languageLabel"
        ''
        '## Activité'
        ''
        "$activity"
        ''
        '## Façon de travailler'
        ''
        "- **Outils IA :** $aiTools"
        "- **Ce qui compte :** $whatMatters"
        ''
        '## Environnement'
        ''
        "- **Système :** $($EnvironmentFacts.OS)"
        "- **Shell :** $($EnvironmentFacts.Shell)"
        "- **Fuseau horaire :** $($EnvironmentFacts.Timezone)"
        "- **Git :** $($EnvironmentFacts.Git)"
        "- **Claude Code détecté :** $($EnvironmentFacts.ClaudeCodeDetected)"
        "- **Codex détecté :** $($EnvironmentFacts.CodexDetected)"
        ''
        '## Origine'
        ''
        "- **Assistant :** $assistantName"
        "- **Espace de travail :** $workspacePath"
        "- **Collections de skills :** $skillCollections"
        "- **Installé le :** $InstalledAt"
        ''
        '## Liens'
        ''
        '- `see also` — [AGENTS.md](./AGENTS.md)'
        ''
    )
    Set-Content -Path $Path -Value ($lines -join [Environment]::NewLine) -Encoding UTF8
}

function ConvertTo-ProjectSlug {
    # Derives a suggested first-project name from the Activite answer
    # (spec, user story 12: a first project named from the participant's own
    # activity) when the caller does not already have an explicit
    # firstProject.name. Lowercase, non-alphanumeric runs collapsed to a
    # single hyphen, trimmed of leading/trailing hyphens, capped at 40
    # characters so a long sentence never produces an unwieldy folder name.
    # An empty or entirely non-alphanumeric activity falls back to
    # 'premier-projet' -- the same default install.ps1 already used before
    # this ticket, never removed, only pre-empted when a real slug exists.
    param([string] $Activity)
    if ([string]::IsNullOrWhiteSpace($Activity)) { return 'premier-projet' }
    $slug = $Activity.ToLowerInvariant()
    $slug = [regex]::Replace($slug, '[^a-z0-9]+', '-')
    $slug = $slug.Trim('-')
    if ($slug.Length -gt 40) { $slug = $slug.Substring(0, 40).Trim('-') }
    if ([string]::IsNullOrWhiteSpace($slug)) { return 'premier-projet' }
    return $slug
}

function Resolve-QuestionnaireAnswer {
    # The one place that decides, for a single field, whether to ask at all
    # -- used by install.ps1 for every one of the eight questions plus the
    # first-project confirmation, so the resume/update-mode/silent-mode
    # decision is made identically for all of them instead of drifting
    # field by field:
    #   - a field that already has a value on $Answers (durably recorded by
    #     a prior run's carnet, or already present in an -AnswersFile) is
    #     never re-asked -- unless $ForceReask is set (the update-mode "yes,
    #     something changed" branch only), in which case the prior value
    #     becomes the offered default instead of $DefaultValue, so pressing
    #     Enter reproduces it unchanged;
    #   - -AnswersFile mode ($Interactive = $false) never prompts, ever
    #     (ticket 05 criterion 7): a missing field silently takes its
    #     existing value or $DefaultValue.
    param(
        [Parameter(Mandatory = $true)][psobject] $Answers,
        [Parameter(Mandatory = $true)][string] $Name,
        # Not Mandatory despite always being a real prompt in interactive
        # mode: a Mandatory string parameter refuses an empty-string
        # argument outright, and every silent-mode call site passes ''
        # (never shown, since $Interactive is $false there) -- measured
        # directly (silent mode's very first call failed to bind before
        # this was relaxed).
        [string] $PromptText = '',
        [string] $DefaultValue = '',
        [bool] $Interactive = $false,
        [bool] $ForceReask = $false,
        [System.Collections.Generic.Queue[string]] $ScriptedInputs,
        [switch] $Required
    )
    $existing = $Answers.$Name
    $hasExisting = ($null -ne $existing) -and -not ($existing -is [string] -and [string]::IsNullOrWhiteSpace($existing))

    if ($hasExisting -and -not $ForceReask) {
        return $existing
    }

    if (-not $Interactive) {
        $value = if ($hasExisting) { $existing } else { $DefaultValue }
        Set-AnswerField -Answers $Answers -Name $Name -Value $value
        return $value
    }

    $effectiveDefault = if ($hasExisting) { $existing } else { $DefaultValue }
    if ($Required) {
        $value = Read-RequiredQuestionnaireField -PromptText $PromptText -ScriptedInputs $ScriptedInputs
    }
    else {
        $value = Read-QuestionnaireField -PromptText $PromptText -DefaultValue $effectiveDefault -ScriptedInputs $ScriptedInputs
    }
    Set-AnswerField -Answers $Answers -Name $Name -Value $value
    return $value
}

function Test-InstallComplete {
    # Update-mode gate (T06/T22: if everything is done, a relaunch switches
    # to update mode): every step install.ps1's own flow can record must be
    # present -- 'skillsDeployed' added by ticket 07, same reasoning as
    # every other required step here -- firstProjectCreated only required
    # when the recorded answers actually asked for a first project -- a
    # participant who declined one (firstProject.create = false) is still
    # "complete" without it.
    param([Parameter(Mandatory = $true)][psobject] $Carnet)
    $steps = $Carnet.steps
    if ($null -eq $steps) { return $false }
    $required = @('workspaceCreated', 'cloned', 'guardiansConfigured', 'markerWritten', 'assistantGenerated', 'skillsDeployed', 'profileWritten')
    foreach ($name in $required) {
        if (-not $steps.$name) { return $false }
    }
    $wantsFirstProject = $true
    if ($Carnet.answers -and ($null -ne $Carnet.answers.firstProject) -and ($null -ne $Carnet.answers.firstProject.create)) {
        $wantsFirstProject = [bool]$Carnet.answers.firstProject.create
    }
    if ($wantsFirstProject -and -not $steps.firstProjectCreated) { return $false }
    return $true
}
