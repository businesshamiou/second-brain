#Requires -Version 5.1
<#
.SYNOPSIS
    Second Brain installer -- trilingual questionnaire, profile and install
    notebook (Mission 168, tickets 03, 04, 05 and 07).

.DESCRIPTION
    Role: drives the whole install from a local source, gathering its seven
    questions plus the first-project confirmation either from an answers
    file (silent, T04's CI mode) or by asking them one at a time in the
    terminal (T06 complements 2-3), in the language the first question
    chooses, from three catalogs under i18n/ with identical keys
    (tests/test-catalog-key-parity.ps1). The fixed first sentence, printed
    before any language is known, is always in English; everything from the
    language question onward is drawn from the chosen catalog. Naming and
    deploying the assistant across its generated forms is ticket 06's job,
    not this one -- nothing here is ever printed in the assistant's own
    voice.

    It also links every method skill (skills/, including external/) into
    the user's Claude Code and Codex skills folders, by link and never by
    copy (ticket 07, extended unconditionally to skills/external/ by
    Mission 171-C01 step 4, tools/deploy-skills.ps1) -- see that file's own
    header comment for the deployment rules, the idempotency model and the
    Codex description budget. The eighth question that used to gate
    skills/external/ and warehouse collections is retired: nothing about
    skill deployment is asked any more, and warehouse collections are never
    linked by this installer (Mission 171-C01 Context: delivered as zip
    packages instead, a separate mechanism).

    Before touching the source or the workspace at all, it ensures Git, uv
    and pre-commit are usable (tools/prerequisites.ps1, ticket 04):
    detected and reused if already on PATH, or installed into the profile
    -- Git via the official Git for Windows portable edition, uv via its
    official installer, pre-commit via `uv tool install` -- with pinned
    versions and SHA-256 fingerprints (tools/prerequisites.lock.json).
    Never elevated: none of the three ever needs, or asks for,
    administrator rights. This is also the installer's one real network
    dependency (downloading Git/uv when neither is already present) --
    tests/test-questionnaire-network-failure.ps1 simulates it going dark
    through prerequisites.ps1's own test-only hook
    ($env:SB_TEST_FORCE_NETWORK_FAILURE), never a real network change.

    It then creates the workspace, clones `second-brain` from -Source (a
    local path, never a URL -- T23, acceptance before push), pins the
    workspace marker (VAULT-ROOT.md), wires the clone's own guardians
    (core.hooksPath), generates and links the assistant and the method's
    skills (tickets 06-07), writes the participant's profile (USER.md, from
    the answers plus a measured -- never asked -- Environnement section),
    and creates the first project through tools/project-bootstrap.sh. Every
    step is idempotent: it is measured against what is actually on disk,
    never assumed from a prior run, so a second execution with the same
    inputs changes nothing and reports the same verdict (spec, Testing
    Decisions).

    An install notebook is born with the workspace, inside the clone
    (`<clone>/.install/state.json`, git-ignored, T06 complement 2): it
    records the answers used and the steps completed, and is never deleted
    on failure. A relaunch skips every already-completed step and never
    re-asks an already-answered question -- for the three interactive-only
    questions (language, assistant name, workspace path), asked before the
    notebook itself exists, this installer looks for an existing notebook
    at the deterministic default workspace path *before* asking anything:
    found and complete, it enters update mode (previous answers shown,
    "has anything changed?", untouched if not); found and incomplete, it
    resumes silently with the recorded language and answers; not found, it
    is a fresh install (Class B, ticket 05 report -- the one scenario this
    does not cover is a participant who both typed a *custom* workspace
    path on their very first run and was interrupted before that run's
    notebook was born, since there is nothing yet to look up by then; named
    as a residual, not exercised by any of the ticket's four required
    automated tests).

    Usage:
        install.ps1 -Source <path-to-local-second-brain-repo> `
                     [-AnswersFile <path-to-json>] `
                     [-TestMode -TestRoot <path>] `
                     [-ScriptedAnswers <string[]>] [-StopAfterStep <name>]

    Inputs:
        -Source          Local filesystem path to a second-brain repository
                          (a normal clone or the repository itself). Cloned
                          by `git clone`, never fetched over the network.
        -AnswersFile      Optional. Path to a JSON file (see
                          tests/fixtures/install-answers.sample.json for the
                          shape). When given, NO question is ever printed
                          (ticket 05 criterion 7): every field takes its
                          value from the file, or the same static default a
                          missing field always took, silently. When omitted,
                          the installer asks its seven questions plus the
                          first-project confirmation in the terminal.
        -TestMode         Redirects everything the installer would ever
                          write outside the workspace itself (profile-rooted
                          defaults, the per-tool skill folders -- Claude
                          Code's, Codex's AI-tool-detection probe, and
                          Codex's own official skills location every method
                          skill is linked into (ticket 07, Mission 171-C01
                          step 4) -- the user PATH, and Git/uv/pre-commit's own install
                          locations and uv's tool/cache/managed-Python
                          directories) into -TestRoot instead of the real
                          profile. Required by the Mission's constraint that
                          no test run may touch the Owner's real
                          environment.
        -TestRoot         Required with -TestMode. An empty or pre-existing
                          temporary directory; never the real user profile.
        -ScriptedAnswers  Test-only. An ordered list of answers, dequeued
                          one per question in the exact order a real person
                          would type them at the keyboard (Read-Host is
                          never called while this queue still has entries).
                          Never used outside tests/test-questionnaire-*.ps1.
        -StopAfterStep    Test-only. One of: prerequisites, workspace,
                          clone, guardians, marker, assistant,
                          skillsDeployed, firstProject, profile.
                          Throws a clean, named "forced stop" error right
                          after that step's own work completes and its
                          carnet flag is saved -- the mechanism T04
                          prescribes for testing resume (a forced,
                          interrupted run via a test flag naming the step).
                          Never used outside
                          tests/test-questionnaire-resume.ps1.

    Outputs:
        Exit code 0 and a one-line verdict on stdout on success (English in
        silent mode with no `language` field, or in the interactive path's
        chosen language otherwise); exit code 1 and a verdict naming the
        step, the cause and the remedy otherwise. The same verdict is also
        written to the install notebook.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $Source,

    [string] $AnswersFile,

    [switch] $TestMode,

    [string] $TestRoot,

    [string[]] $ScriptedAnswers,

    [ValidateSet('prerequisites', 'workspace', 'clone', 'guardians', 'marker', 'assistant', 'skillsDeployed', 'firstProject', 'profile')]
    [string] $StopAfterStep
)

$ErrorActionPreference = 'Stop'

# Shared with tests/test-install-e2e.ps1 -- one copy of the bash.exe lookup,
# never two drifting copies.
. (Join-Path $PSScriptRoot 'tools\resolve-bash-exe.ps1')

# Shared with tests/test-prerequisites-e2e.ps1 (ticket 04): ensures Git, uv
# and pre-commit are usable. Dot-sourced before Add-InstallerPathEntry /
# New-InstallerContext are even defined below is fine: PowerShell resolves a
# function call by name at invocation time, not at dot-source time.
. (Join-Path $PSScriptRoot 'tools\prerequisites.ps1')

# Ticket 05: catalog loading, scripted-input replay, profile writing.
. (Join-Path $PSScriptRoot 'tools\questionnaire.ps1')

# Ticket 06: assistant identity generator (Claude Code subagent, Codex
# skill, web package) and rename-to-_trash handling.
. (Join-Path $PSScriptRoot 'tools\generate-assistant.ps1')

# Ticket 07: deploys every method skill (skills/, including external/,
# Mission 171-C01 step 4) by link into the user's Claude Code and Codex
# skills folders. Warehouse collections are never linked here.
. (Join-Path $PSScriptRoot 'tools\deploy-skills.ps1')

# --- Small helpers ----------------------------------------------------------

function ConvertTo-PosixPath {
    # MSYS/Git-Bash reliably understands forward-slash Windows paths
    # (C:/Users/...) as arguments; backslashes are ambiguous with its own
    # escaping. Convert before ever handing a path to bash.exe.
    param([Parameter(Mandatory = $true)][string] $Path)
    return ($Path -replace '\\', '/')
}

function Invoke-BashTool {
    # Runs a Vault-native bash tool (tools/*.sh) and fails closed on a
    # non-zero exit code. Stdout is returned as an array of lines; stderr is
    # left to print directly to the console (never redirected with 2>&1 on a
    # native command here -- that would wrap stderr lines as PowerShell
    # NativeCommandError records under $ErrorActionPreference = 'Stop').
    param(
        [Parameter(Mandatory = $true)][string] $BashExe,
        [Parameter(Mandatory = $true)][string] $ScriptPath,
        # Not Mandatory: a Mandatory array parameter refuses an empty array
        # argument outright ("cannot bind ... because it is an empty
        # array") -- measured calling this for a script that takes no
        # arguments (tools/session-preflight.sh).
        [string[]] $ScriptArgs = @()
    )
    $output = & $BashExe $ScriptPath @ScriptArgs
    if ($LASTEXITCODE -ne 0) {
        throw "$(Split-Path $ScriptPath -Leaf) failed (exit $LASTEXITCODE): $($output -join [Environment]::NewLine)"
    }
    return $output
}

function Save-ClonePendingChanges {
    # Commits whatever this run just wrote inside the clone (USER.md, so
    # far) -- a no-op when there is nothing to commit, which is exactly
    # what makes writing the same content twice (an unchanged second run)
    # leave the clone's porcelain empty, same idempotency rule as every
    # other step. Without this commit, a freshly-written USER.md would sit
    # forever as an uncommitted "M USER.md" against the clone's own
    # tracked skeleton -- measured directly (ticket 05's own first pass at
    # this installer left exactly that behind, caught by
    # tests/test-install-e2e.ps1's second-run porcelain assertion).
    # session-preflight.sh is re-run every time rather than only once per
    # clone: it is what stamps a fresh preflight token the guardians
    # require, and it is itself a no-op check when the workspace is
    # already conformant.
    param(
        [Parameter(Mandatory = $true)][string] $BashExe,
        [Parameter(Mandatory = $true)][string] $ClonePath,
        [Parameter(Mandatory = $true)][string] $CommitMessage
    )
    # USER.md's own title/description change with every write (the
    # participant's first name, the notebook's "installed at" timestamp) --
    # the root index.md's own entry for USER.md goes stale the moment that
    # happens, and the fraicheur-index guardian refuses the commit outright
    # otherwise (measured directly: this call was missing on ticket 05's
    # first pass, and the guardian named exactly this file). Regenerated
    # before computing $changes so the refreshed index.md is part of the
    # same commit as the change that made it stale.
    Invoke-BashTool -BashExe $BashExe -ScriptPath (Join-Path $ClonePath 'tools\build-indexes.sh') `
        -ScriptArgs @((ConvertTo-PosixPath $ClonePath)) | Out-Null

    $changes = & git -C $ClonePath status --porcelain
    if (-not $changes) { return }

    Invoke-BashTool -BashExe $BashExe -ScriptPath (Join-Path $ClonePath 'tools\session-preflight.sh') | Out-Null

    foreach ($line in $changes) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        $changedPath = $line.Substring(3).Trim('"')
        & git -C $ClonePath add -- $changedPath
        if ($LASTEXITCODE -ne 0) { throw "git add failed for '$changedPath' in $ClonePath" }
    }
    & git -C $ClonePath commit -q -m $CommitMessage
    if ($LASTEXITCODE -ne 0) { throw "failed to commit ($CommitMessage) in $ClonePath (guardians refused)" }
}

function New-InstallerContext {
    # Builds the redirection context (Mission constraint: "Environnement de
    # l'Owner intact"). Real mode reads/would-write the real profile; test
    # mode redirects the same things (profile-rooted defaults, the skill
    # folders, PATH) under -TestRoot.
    #
    # CodexSkillsDir vs CodexAgentsSkillsDir (ticket 07 vigilance point):
    # these are two DIFFERENT folders, never to be confused.
    #   - CodexSkillsDir (.codex\skills) existed before this ticket
    #     (tools/questionnaire.ps1's Get-DetectedAiTools/
    #     Get-ProfileEnvironmentFacts): a heuristic probe only, asking "does
    #     something that looks like Codex exist here" -- .codex/skills/ is
    #     NOT a documented Codex location (T11), so nothing is ever deployed
    #     there.
    #   - CodexAgentsSkillsDir (.agents\skills) is Codex's own measured
    #     official skills location (T11: developers.openai.com/codex/
    #     skills.md, read 2026-09-10/11 -- "$HOME/.agents/skills"), already
    #     used by tools/generate-assistant.ps1 (ticket 06) for the
    #     assistant's own Codex skill INSIDE the clone
    #     (<clone>/.agents/skills/<slug>/) and now used by
    #     tools/deploy-skills.ps1 (ticket 07) as the actual link target
    #     OUTSIDE the clone, in the profile -- exactly the property that was
    #     missing from this context before ticket 07: without it, a
    #     ticket-07 link function would have had no redirected path to write
    #     to at all and could only have reached for the real profile by
    #     hand, defeating -TestMode. Both branches below add it the same way
    #     ClaudeSkillsDir/CodexSkillsDir already were.
    param([switch] $TestMode, [string] $TestRoot)

    if ($TestMode) {
        if ([string]::IsNullOrWhiteSpace($TestRoot)) {
            throw "-TestRoot is required with -TestMode."
        }
        $profileRoot = Join-Path $TestRoot 'profile'
        New-Item -ItemType Directory -Force -Path $profileRoot | Out-Null
        return [PSCustomObject]@{
            TestMode              = $true
            ProfileRoot           = $profileRoot
            ClaudeSkillsDir       = Join-Path $profileRoot '.claude\skills'
            CodexSkillsDir        = Join-Path $profileRoot '.codex\skills'
            CodexAgentsSkillsDir  = Join-Path $profileRoot '.agents\skills'
            SimulatedPathFile     = Join-Path $TestRoot 'simulated-user-path.txt'
            DefaultWorkspacePath  = Join-Path $TestRoot 'workspace'
        }
    }

    return [PSCustomObject]@{
        TestMode              = $false
        ProfileRoot           = $env:USERPROFILE
        ClaudeSkillsDir       = Join-Path $env:USERPROFILE '.claude\skills'
        CodexSkillsDir        = Join-Path $env:USERPROFILE '.codex\skills'
        CodexAgentsSkillsDir  = Join-Path $env:USERPROFILE '.agents\skills'
        SimulatedPathFile     = $null
        DefaultWorkspacePath  = Join-Path $env:USERPROFILE 'second-brain-workspace'
    }
}

function Add-InstallerPathEntry {
    # Called by tools/prerequisites.ps1's Assure-Prerequisites (ticket 04)
    # whenever it installs Git, uv or pre-commit itself -- never for a tool
    # that was already on PATH. Persists the entry for a *future* shell.
    param(
        [Parameter(Mandatory = $true)][psobject] $Context,
        [Parameter(Mandatory = $true)][string] $Entry
    )
    if ($Context.TestMode) {
        $existing = @()
        if (Test-Path $Context.SimulatedPathFile) {
            $existing = Get-Content $Context.SimulatedPathFile
        }
        if ($existing -notcontains $Entry) {
            Add-Content -Path $Context.SimulatedPathFile -Value $Entry
        }
        return
    }
    $current = (Get-ItemProperty -Path 'HKCU:\Environment' -Name Path -ErrorAction SilentlyContinue).Path
    $parts = @($current -split ';' | Where-Object { $_ -ne '' })
    if ($parts -notcontains $Entry) {
        $parts += $Entry
        [Environment]::SetEnvironmentVariable('Path', ($parts -join ';'), 'User')
    }
}

function Get-Carnet {
    # -Encoding UTF8 is mandatory here (ticket 05): the carnet now carries
    # real accented answers (a first name, a one-sentence activity) once a
    # participant types one, and Windows PowerShell 5.1's default
    # Get-Content decoding mangles any non-ASCII byte in a BOM-less file --
    # measured directly (see tools/questionnaire.ps1's own header comment
    # for the exact corruption this produced during this ticket's testing).
    param([string] $Path)
    if (Test-Path $Path) {
        return Get-Content -Raw -Path $Path -Encoding UTF8 | ConvertFrom-Json
    }
    return [PSCustomObject]@{
        schemaVersion = 1
        answers       = [PSCustomObject]@{}
        steps         = [PSCustomObject]@{}
        verdict       = $null
        lastRunAt     = $null
    }
}

function Save-Carnet {
    param([string] $Path, [psobject] $Carnet)
    New-Item -ItemType Directory -Force -Path (Split-Path $Path -Parent) | Out-Null
    $Carnet | ConvertTo-Json -Depth 10 | Set-Content -Path $Path -Encoding UTF8
}

function Set-CarnetStep {
    param([psobject] $Carnet, [string] $Name)
    $Carnet.steps | Add-Member -MemberType NoteProperty -Name $Name -Value $true -Force
}

function Test-ForcedStop {
    # T04's prescribed test mechanism (a run interrupted by a test flag
    # naming the step to stop after): throws right after the named step's
    # own carnet flag has already been saved, so the notebook on disk is
    # exactly what a real interruption at that instant would leave behind
    # -- never a half-written flag, never a lost one.
    param([string] $StopAfterStep, [string] $StepName)
    if ($StopAfterStep -eq $StepName) {
        throw "Forced stop for testing, after step: $StepName"
    }
}

# --- Load and validate inputs, then run all steps ---------------------------
# Wrapped as one try/catch from here on (input validation included) so that
# any terminating error -- not just a failure inside a step -- reaches the
# single catch below and always sets an explicit exit code.

$carnetPath = $null
$carnet = $null
$catalog = $null
$currentStepKey = 'prerequisites'
$scriptedQueue = New-ScriptedInputQueue -Inputs $ScriptedAnswers

try {
    # Step: prerequisites (ticket 04). -TestMode/-TestRoot are this script's
    # own parameters, independent of -AnswersFile, so the context and the
    # prerequisite check both happen before any `git` call below.
    $context = New-InstallerContext -TestMode:$TestMode -TestRoot $TestRoot
    Assure-Prerequisites -Context $context -AddPersistentPathEntry ${function:Add-InstallerPathEntry} | Out-Null
    $bashExe = Resolve-BashExe
    Test-ForcedStop -StopAfterStep $StopAfterStep -StepName 'prerequisites'

    if (-not (Test-Path $Source)) {
        throw "Source not found: $Source"
    }
    & git -C $Source rev-parse --is-inside-work-tree *> $null
    if ($LASTEXITCODE -ne 0) {
        throw "Source is not a git repository: $Source"
    }
    # Resolved once, here, to an absolute path -- the workspace-path
    # question below (Resolve-WorkspacePathAnswer/Test-ValidWorkspacePath)
    # compares every typed candidate against this, never against the raw
    # (possibly relative) $Source.
    $sourceAbs = (Resolve-Path $Source).Path

    $i18nDir = Join-Path $PSScriptRoot 'i18n'
    $interactive = [string]::IsNullOrWhiteSpace($AnswersFile)
    $isUpdateRun = $false
    $priorCarnetAtDefault = $null

    if (-not $interactive) {
        # --- Silent mode (ticket 05 criterion 7): never a single prompt. ---
        if (-not (Test-Path $AnswersFile)) {
            throw "Answers file not found: $AnswersFile"
        }
        $answers = Get-Content -Raw -Path $AnswersFile -Encoding UTF8 | ConvertFrom-Json
        if (-not $answers.workspacePath) {
            throw "Answers file is missing required field: workspacePath"
        }
        # Never auto-detected from Windows in this mode (Class B, ticket 05
        # report): an answers file is an already-resolved input, not a
        # question with a suggested default to accept by pressing Enter.
        Resolve-QuestionnaireAnswer -Answers $answers -Name 'language' -PromptText '' -DefaultValue 'EN' -Interactive:$false | Out-Null
        $language = $answers.language.ToString().ToUpperInvariant()
        Set-AnswerField -Answers $answers -Name 'language' -Value $language
    }
    else {
        # --- Interactive mode: fixed English sentence before any language
        # is chosen (T06 complement 3). ---
        Write-Output 'Second Brain installer -- answer each question, or press Enter to accept the default shown in parentheses.'

        $defaultWorkspacePath = $context.DefaultWorkspacePath
        $probedClonePath = Join-Path $defaultWorkspacePath 'second-brain'
        $probedCarnetPath = Join-Path $probedClonePath '.install\state.json'
        $answers = [PSCustomObject]@{}
        if (Test-Path $probedCarnetPath) {
            $priorCarnetAtDefault = Get-Carnet -Path $probedCarnetPath
            if ($priorCarnetAtDefault.answers) {
                $answers = $priorCarnetAtDefault.answers
            }
        }

        $defaultLanguage = Get-InstallerLanguage
        Resolve-QuestionnaireAnswer -Answers $answers -Name 'language' `
            -PromptText "Language / Langue / Idioma -- FR, EN or ES [$defaultLanguage]:" `
            -DefaultValue $defaultLanguage -Interactive:$true -ScriptedInputs $scriptedQueue | Out-Null
        $language = $answers.language.ToString().ToUpperInvariant()
        if ($language -notin @('FR', 'EN', 'ES')) { $language = $defaultLanguage }
        Set-AnswerField -Answers $answers -Name 'language' -Value $language
    }

    $catalog = Get-Catalog -Language $language -I18nDir $i18nDir

    if ($interactive -and $priorCarnetAtDefault -and (Test-InstallComplete -Carnet $priorCarnetAtDefault)) {
        # --- Update mode (T06/T22): the install at the default workspace is
        # already complete. Show what was recorded, ask if anything
        # changed; a "no" touches nothing (ticket 05 criterion 6). ---
        $isUpdateRun = $true
        Write-Output (Format-CatalogText -Catalog $catalog -Key 'update.header')
        Write-Output ($answers | ConvertTo-Json -Depth 5)
        $changedAnswer = Read-QuestionnaireField `
            -PromptText (Format-CatalogText -Catalog $catalog -Key 'update.anythingChanged') `
            -DefaultValue 'n' -ScriptedInputs $scriptedQueue
        $changed = Test-AffirmativeAnswer -Answer $changedAnswer
        if (-not $changed) {
            $verdict = Format-CatalogText -Catalog $catalog -Key 'update.noChangeNote'
            Write-Output $verdict
            exit 0
        }
        Write-Output (Format-CatalogText -Catalog $catalog -Key 'update.rewriting')
    }
    $forceReask = $isUpdateRun

    if ($forceReask) {
        # Language (Q1) is just as updatable as any other answer once
        # "something changed" is confirmed -- T06 complement 2 orders it as
        # Question 1 like the rest, and nothing in the spec exempts it from
        # update mode. Only the workspace path is architecturally fixed
        # (T06: "sans deplacement ulterieur"), never this one. Offered with
        # the previously recorded language as the default, so Enter keeps
        # it unchanged; the catalog is reloaded if it actually changed, so
        # every question asked from here on speaks the newly chosen
        # language, not the stale one the header/confirmation used.
        $languagePrompt = "Language / Langue / Idioma -- FR, EN or ES [$language]:"
        Resolve-QuestionnaireAnswer -Answers $answers -Name 'language' -PromptText $languagePrompt `
            -DefaultValue $language -Interactive:$true -ForceReask:$true -ScriptedInputs $scriptedQueue | Out-Null
        $language = $answers.language.ToString().ToUpperInvariant()
        if ($language -notin @('FR', 'EN', 'ES')) { $language = 'EN' }
        Set-AnswerField -Answers $answers -Name 'language' -Value $language
        $catalog = Get-Catalog -Language $language -I18nDir $i18nDir
    }

    # Assistant name (Q2) and workspace path (Q3) -- interactive only past
    # this point still means "ask if not already known" (silent mode has
    # already fully resolved $answers above).
    $defaultAssistantName = 'Brian'
    if ($interactive) {
        $assistantPrompt = Format-PromptWithDefault -Catalog $catalog `
            -PromptKey 'questionnaire.assistantName.prompt' -DefaultNoteKey 'questionnaire.assistantName.defaultNote' `
            -DefaultNoteArgs @($defaultAssistantName)
        Resolve-QuestionnaireAnswer -Answers $answers -Name 'vaultName' -PromptText $assistantPrompt `
            -DefaultValue $defaultAssistantName -Interactive:$true -ForceReask:$forceReask -ScriptedInputs $scriptedQueue | Out-Null

        $workspacePrompt = Format-PromptWithDefault -Catalog $catalog `
            -PromptKey 'questionnaire.workspace.prompt' -DefaultNoteKey 'questionnaire.workspace.defaultNote' `
            -DefaultNoteArgs @($context.DefaultWorkspacePath)
        # Workspace never moves once a real install exists there (T06: no
        # later displacement) -- never force-reasked even in update mode,
        # only ever asked when truly unknown. Resolve-WorkspacePathAnswer,
        # not Resolve-QuestionnaireAnswer: a typed answer is validated in a
        # loop (Defects 1/2, Mission 171-C01) instead of accepted as-is.
        Resolve-WorkspacePathAnswer -Answers $answers -PromptText $workspacePrompt `
            -DefaultValue $context.DefaultWorkspacePath -SourceRoot $sourceAbs -Catalog $catalog `
            -ScriptedInputs $scriptedQueue | Out-Null
    }
    else {
        Resolve-QuestionnaireAnswer -Answers $answers -Name 'vaultName' -PromptText '' `
            -DefaultValue $defaultAssistantName -Interactive:$false | Out-Null
    }

    $vaultName = $answers.vaultName
    $gitUserName = if ($answers.git.userName) { $answers.git.userName } else { 'Second Brain Installer' }
    $gitUserEmail = if ($answers.git.userEmail) { $answers.git.userEmail } else { 'installer@example.invalid' }

    $workspacePath = $answers.workspacePath
    $clonePath = Join-Path $workspacePath 'second-brain'
    $markerPath = Join-Path $workspacePath 'VAULT-ROOT.md'
    $carnetPath = Join-Path $clonePath '.install\state.json'

    $carnet = Get-Carnet -Path $carnetPath
    # Captured before the next line overwrites $carnet.answers -- the only
    # place the previously-generated assistant slug (ticket 06) is still
    # readable, needed to detect a rename against the freshly-resolved one.
    $previousAssistantSlug = $null
    if ($carnet.assistant -and $carnet.assistant.slug) { $previousAssistantSlug = $carnet.assistant.slug }
    $carnet.answers = $answers
    $carnet | Add-Member -MemberType NoteProperty -Name 'context' -Force -Value ([PSCustomObject]@{
        testMode    = $context.TestMode
        profileRoot = $context.ProfileRoot
    })

    # --- Steps (idempotent: each is measured against disk) -----------------

    # Step: workspace directory. The carnet cannot be saved yet -- it lives
    # inside the clone, which does not exist until the clone step.
    New-Item -ItemType Directory -Force -Path $workspacePath | Out-Null
    Set-CarnetStep -Carnet $carnet -Name 'workspaceCreated'
    $currentStepKey = 'workspace'
    Test-ForcedStop -StopAfterStep $StopAfterStep -StepName 'workspace'

    # Step: clone second-brain from the local source (T23 -- never a URL,
    # never the network; `git clone` of a local path uses hardlinks only).
    $currentStepKey = 'clone'
    if (-not (Test-Path (Join-Path $clonePath '.git'))) {
        & git -c core.longpaths=true clone -- $Source $clonePath
        if ($LASTEXITCODE -ne 0) { throw "git clone failed (source: $Source, dest: $clonePath)" }
        & git -C $clonePath config core.longpaths true
        & git -C $clonePath config user.name $gitUserName
        & git -C $clonePath config user.email $gitUserEmail
    }
    Set-CarnetStep -Carnet $carnet -Name 'cloned'
    # The notebook is born here (T06 complement 2: this is where the
    # notebook itself starts existing) -- this is also the first point at
    # which language/assistant name/workspace path become durable, so they
    # are never re-asked again.
    Save-Carnet -Path $carnetPath -Carnet $carnet
    Test-ForcedStop -StopAfterStep $StopAfterStep -StepName 'clone'

    # Questions 4-8 (T06 complement 2): asked one at a time, each saved to
    # the notebook immediately, so a forced stop between any two of them
    # resumes at the next unanswered one, never redoing an answered one.
    if ($interactive) {
        Resolve-QuestionnaireAnswer -Answers $answers -Name 'firstName' `
            -PromptText (Format-CatalogText -Catalog $catalog -Key 'questionnaire.firstName.prompt') `
            -Interactive:$true -ForceReask:$forceReask -Required -ScriptedInputs $scriptedQueue | Out-Null
        Save-Carnet -Path $carnetPath -Carnet $carnet

        $activityDefault = Format-CatalogText -Catalog $catalog -Key 'questionnaire.activity.default'
        Resolve-QuestionnaireAnswer -Answers $answers -Name 'activity' `
            -PromptText (Format-CatalogText -Catalog $catalog -Key 'questionnaire.activity.prompt') `
            -DefaultValue $activityDefault -Interactive:$true -ForceReask:$forceReask -ScriptedInputs $scriptedQueue | Out-Null
        Save-Carnet -Path $carnetPath -Carnet $carnet

        $detectedTools = Get-DetectedAiTools -Context $context
        $aiToolsPrompt = Format-PromptWithDefault -Catalog $catalog `
            -PromptKey 'questionnaire.aiTools.prompt' -DefaultNoteKey 'questionnaire.aiTools.detectedNote' `
            -DefaultNoteArgs @(($detectedTools -join ', '))
        $aiToolsDefault = ($detectedTools -join ', ')
        Resolve-QuestionnaireAnswer -Answers $answers -Name 'aiToolsRaw' -PromptText $aiToolsPrompt `
            -DefaultValue $aiToolsDefault -Interactive:$true -ForceReask:$forceReask -ScriptedInputs $scriptedQueue | Out-Null
        $aiToolsValue = @(($answers.aiToolsRaw -split ',') | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
        Set-AnswerField -Answers $answers -Name 'aiTools' -Value $aiToolsValue
        Save-Carnet -Path $carnetPath -Carnet $carnet

        $whatMattersDefault = Format-CatalogText -Catalog $catalog -Key 'questionnaire.whatMatters.default'
        Resolve-QuestionnaireAnswer -Answers $answers -Name 'whatMatters' `
            -PromptText (Format-CatalogText -Catalog $catalog -Key 'questionnaire.whatMatters.prompt') `
            -DefaultValue $whatMattersDefault -Interactive:$true -ForceReask:$forceReask -ScriptedInputs $scriptedQueue | Out-Null
        Save-Carnet -Path $carnetPath -Carnet $carnet
    }
    else {
        Resolve-QuestionnaireAnswer -Answers $answers -Name 'firstName' -PromptText '' `
            -DefaultValue 'Second Brain user' -Interactive:$false | Out-Null
        Resolve-QuestionnaireAnswer -Answers $answers -Name 'activity' -PromptText '' `
            -DefaultValue (Format-CatalogText -Catalog $catalog -Key 'questionnaire.activity.default') -Interactive:$false | Out-Null
        if ($null -eq $answers.aiTools) { Set-AnswerField -Answers $answers -Name 'aiTools' -Value @() }
        Resolve-QuestionnaireAnswer -Answers $answers -Name 'whatMatters' -PromptText '' `
            -DefaultValue (Format-CatalogText -Catalog $catalog -Key 'questionnaire.whatMatters.default') -Interactive:$false | Out-Null
    }

    # Step: wire the clone's own guardians. core.hooksPath is local git
    # config -- never carried over by `git clone` -- so this must always be
    # set explicitly after cloning.
    $currentStepKey = 'guardians'
    & git -C $clonePath config core.hooksPath .githooks
    if ($LASTEXITCODE -ne 0) { throw "git config core.hooksPath failed in $clonePath" }
    Set-CarnetStep -Carnet $carnet -Name 'guardiansConfigured'
    Save-Carnet -Path $carnetPath -Carnet $carnet
    Test-ForcedStop -StopAfterStep $StopAfterStep -StepName 'guardians'

    # Step: workspace marker.
    $currentStepKey = 'marker'
    if (-not (Test-Path $markerPath)) {
        $writeMarkerScript = Join-Path $clonePath 'tools\write-marker.sh'
        Invoke-BashTool -BashExe $bashExe -ScriptPath $writeMarkerScript `
            -ScriptArgs @((ConvertTo-PosixPath $workspacePath), $vaultName) | Out-Null
    }
    Set-CarnetStep -Carnet $carnet -Name 'markerWritten'
    Save-Carnet -Path $carnetPath -Carnet $carnet
    Test-ForcedStop -StopAfterStep $StopAfterStep -StepName 'marker'

    # Step: assistant identity forms (ticket 06). Regenerated every run now
    # that the assistant's name is known -- idempotent, so an unchanged
    # name/source reproduces byte-identical files and leaves the clone's
    # porcelain empty, same rule as every other step. A rename (the name
    # resolved this run differs from the slug the carnet recorded last time)
    # moves the OLD slug's forms to _trash/ first (ticket 06 criterion 5,
    # Decision 110852 -- never a deletion) before the new forms are written.
    $currentStepKey = 'assistant'
    $assistantSlug = ConvertTo-AssistantSlug -Name $vaultName
    $assistantRenamed = $previousAssistantSlug -and ($previousAssistantSlug -ne $assistantSlug)
    if ($assistantRenamed) {
        Move-AssistantFormsToTrash -ClonePath $clonePath -OldSlug $previousAssistantSlug | Out-Null
    }
    New-AssistantForms -ClonePath $clonePath -Name $vaultName | Out-Null
    $carnet | Add-Member -MemberType NoteProperty -Name 'assistant' -Force -Value ([PSCustomObject]@{
        name = $vaultName
        slug = $assistantSlug
    })
    Set-CarnetStep -Carnet $carnet -Name 'assistantGenerated'
    Save-Carnet -Path $carnetPath -Carnet $carnet
    $assistantCommitMessage = if ($assistantRenamed) {
        "Rename assistant from '$previousAssistantSlug' to '$assistantSlug' (old forms moved to _trash)"
    }
    else {
        "Generate assistant forms for '$vaultName'"
    }
    Save-ClonePendingChanges -BashExe $bashExe -ClonePath $clonePath -CommitMessage $assistantCommitMessage
    Test-ForcedStop -StopAfterStep $StopAfterStep -StepName 'assistant'

    # Step: deploy skills by link (ticket 07; unconditional external and
    # combined Codex budget, Mission 171-C01 step 4). Always links every
    # method skill -- skills/ and skills/external/ -- into both the Claude
    # Code and Codex skills folders (unconditional, regardless of what
    # Get-DetectedAiTools found, and regardless of any questionnaire
    # answer: the eighth question that used to gate skills/external/ and
    # warehouse collections is retired). Codex drops skills/external/ under
    # Doctrine rule 3 when the combined description budget is over the
    # ceiling; Claude Code never does (see tools/deploy-skills.ps1's own
    # header comment). Idempotent (tools/deploy-skills.ps1's own
    # Publish-SkillLink): a relaunch creates no new link and touches no
    # file, the same rule every other step already follows. Nothing here
    # is git-tracked content inside the clone -- the link targets live in
    # the user's profile ($context.ClaudeSkillsDir /
    # CodexAgentsSkillsDir), so unlike 'assistant' this step never calls
    # Save-ClonePendingChanges.
    $currentStepKey = 'skillsDeployed'
    $deployResult = Publish-DeployedSkills -Context $context -ClonePath $clonePath
    if ($deployResult.DuplicateNames.Count -gt 0) {
        Write-Output "Note: duplicate skill name(s) across sources, only the first source was linked: $($deployResult.DuplicateNames -join ', ')"
    }
    if ($deployResult.FallbackApplied) {
        Write-Output "Note: combined skill description budget ($($deployResult.Budget.Total) chars) exceeds the $($deployResult.Budget.Ceiling)-character Codex ceiling -- Codex received skills/ only, Claude Code received everything (Doctrine rule 3)."
    }
    if ($deployResult.ConflictCount -gt 0) {
        $conflictPaths = @($deployResult.LinkResults | Where-Object { $_.Status -eq 'Conflict' } | ForEach-Object { $_.LinkPath }) -join ', '
        Write-Output "Note: $($deployResult.ConflictCount) skill link path(s) already occupied by something else, left untouched: $conflictPaths"
    }
    $carnet | Add-Member -MemberType NoteProperty -Name 'skillsDeployment' -Force -Value ([PSCustomObject]@{
        defaultSkillNames  = @($deployResult.DefaultEntries | ForEach-Object { $_.Name })
        externalSkillNames = @($deployResult.ExternalEntries | ForEach-Object { $_.Name })
        codexBudgetTotal   = $deployResult.Budget.Total
        codexBudgetCeiling = $deployResult.Budget.Ceiling
        fallbackApplied    = $deployResult.FallbackApplied
        duplicateNames     = $deployResult.DuplicateNames
        conflictCount      = $deployResult.ConflictCount
    })
    Set-CarnetStep -Carnet $carnet -Name 'skillsDeployed'
    Save-Carnet -Path $carnetPath -Carnet $carnet
    Test-ForcedStop -StopAfterStep $StopAfterStep -StepName 'skillsDeployed'

    # First-project confirmation (T06 complement 2's final question) plus
    # its own step, first-project. Nested (create/name/displayName), so
    # handled directly rather than through Resolve-QuestionnaireAnswer
    # (which only knows flat string fields).
    if ($null -eq $answers.firstProject) {
        Set-AnswerField -Answers $answers -Name 'firstProject' -Value ([PSCustomObject]@{ create = $null; name = $null; displayName = $null })
    }
    $fp = $answers.firstProject
    $needsFirstProjectAsk = $interactive -and (($null -eq $fp.create) -or $forceReask)
    if ($needsFirstProjectAsk) {
        $defaultCreateAnswer = if (($null -ne $fp.create) -and -not [bool]$fp.create) { 'n' } else { 'y' }
        $fpPrompt = Format-PromptWithDefault -Catalog $catalog `
            -PromptKey 'questionnaire.firstProject.prompt' -DefaultNoteKey 'questionnaire.firstProject.defaultNote'
        $createAnswer = Read-QuestionnaireField -PromptText $fpPrompt -DefaultValue $defaultCreateAnswer -ScriptedInputs $scriptedQueue
        $fp.create = Test-AffirmativeAnswer -Answer $createAnswer
        if ($fp.create) {
            $suggestedName = if ($fp.name) { $fp.name } else { ConvertTo-ProjectSlug -Activity $answers.activity }
            $fp.name = Read-QuestionnaireField `
                -PromptText (Format-CatalogText -Catalog $catalog -Key 'questionnaire.firstProject.namePrompt') `
                -DefaultValue $suggestedName -ScriptedInputs $scriptedQueue
            $fp.displayName = $fp.name
        }
        Save-Carnet -Path $carnetPath -Carnet $carnet
    }
    elseif ($null -eq $fp.create) {
        # Silent mode, never asked -- same static defaults as before ticket 05.
        $fp.create = $true
    }
    if ($fp.create -and -not $fp.name) { $fp.name = ConvertTo-ProjectSlug -Activity $answers.activity }
    if ($fp.create -and -not $fp.displayName) { $fp.displayName = $fp.name }

    $createFirstProject = [bool]$fp.create
    $firstProjectName = if ($fp.name) { $fp.name } else { 'premier-projet' }
    $firstProjectDisplayName = if ($fp.displayName) { $fp.displayName } else { $firstProjectName }
    $firstProjectPath = Join-Path $workspacePath $firstProjectName

    # Step: first project, via the project-creation skill/tool
    # (tools/project-bootstrap.sh). Skipped entirely if already created.
    $currentStepKey = 'firstProject'
    if ($createFirstProject) {
        if (-not (Test-Path $firstProjectPath)) {
            $bootstrapScript = Join-Path $clonePath 'tools\project-bootstrap.sh'
            Invoke-BashTool -BashExe $bashExe -ScriptPath $bootstrapScript `
                -ScriptArgs @((ConvertTo-PosixPath $firstProjectPath), $firstProjectDisplayName) | Out-Null

            $registrationChanges = & git -C $clonePath status --porcelain
            if ($registrationChanges) {
                Invoke-BashTool -BashExe $bashExe -ScriptPath (Join-Path $clonePath 'tools\session-preflight.sh') | Out-Null

                foreach ($line in $registrationChanges) {
                    if ([string]::IsNullOrWhiteSpace($line)) { continue }
                    $changedPath = $line.Substring(3).Trim('"')
                    & git -C $clonePath add -- $changedPath
                    if ($LASTEXITCODE -ne 0) { throw "git add failed for '$changedPath' in $clonePath" }
                }
                & git -C $clonePath commit -q -m "Register first project: $firstProjectDisplayName"
                if ($LASTEXITCODE -ne 0) { throw "failed to commit project registration in $clonePath (guardians refused)" }
            }

            Push-Location $firstProjectPath
            try {
                & git init -q -b main
                if ($LASTEXITCODE -ne 0) { throw "git init failed in $firstProjectPath" }
                & git config user.name $gitUserName
                & git config user.email $gitUserEmail
                & git add -A
                & pre-commit install *> $null
                if ($LASTEXITCODE -ne 0) { throw "pre-commit install failed in $firstProjectPath" }
                & git commit -q -m "Initial scaffold from project-bootstrap"
                if ($LASTEXITCODE -ne 0) { throw "initial commit failed in $firstProjectPath (guardians refused)" }
            }
            finally {
                Pop-Location
            }
        }
        Set-CarnetStep -Carnet $carnet -Name 'firstProjectCreated'
        Save-Carnet -Path $carnetPath -Carnet $carnet
    }
    Test-ForcedStop -StopAfterStep $StopAfterStep -StepName 'firstProject'

    # Step: profile. Ticket 05 criterion 3 -- filled from the answers, with
    # a measured (never asked) Environnement section; no template field left.
    $currentStepKey = 'profile'
    $userProfilePath = Join-Path $clonePath 'USER.md'
    if (-not $carnet.steps.profileWritten -or $isUpdateRun) {
        $environmentFacts = Get-ProfileEnvironmentFacts -Context $context
        $installedAt = (Get-Date).ToString('o')
        Write-UserProfile -Path $userProfilePath -Answers $answers -EnvironmentFacts $environmentFacts -InstalledAt $installedAt
        Save-ClonePendingChanges -BashExe $bashExe -ClonePath $clonePath -CommitMessage 'Write user profile from installer answers'
    }
    Set-CarnetStep -Carnet $carnet -Name 'profileWritten'
    Save-Carnet -Path $carnetPath -Carnet $carnet
    Test-ForcedStop -StopAfterStep $StopAfterStep -StepName 'profile'

    # Signed by the assistant's own chosen name (T07: "il signe... en fin de
    # verdict"; ticket 05's own report named this explicitly out of scope
    # until the assistant had a name -- ticket 06 closes that gap here).
    $verdict = (Format-CatalogText -Catalog $catalog -Key 'verdict.success') + ' ' + `
        (Format-CatalogText -Catalog $catalog -Key 'verdict.signature' -FormatArgs @($vaultName))
    $carnet.verdict = $verdict
    $carnet.lastRunAt = (Get-Date).ToString('o')
    Save-Carnet -Path $carnetPath -Carnet $carnet

    Write-Output $verdict
    exit 0
}
catch {
    $ex = $_.Exception
    $stepKey = $currentStepKey
    $stepLabel = $stepKey
    $cause = $ex.Message
    $remedyKey = 'remedy.generic'

    if ($ex -is [System.Net.WebException]) {
        $remedyKey = 'remedy.networkUnreachable'
        if ($catalog) {
            $cause = Format-CatalogText -Catalog $catalog -Key 'cause.networkUnreachable'
        }
        else {
            $cause = 'Network unreachable while downloading a required tool.'
        }
    }

    if ($catalog) {
        $stepLabel = Format-CatalogText -Catalog $catalog -Key "step.name.$stepKey"
        $remedy = Format-CatalogText -Catalog $catalog -Key $remedyKey
        $verdict = (Format-CatalogText -Catalog $catalog -Key 'verdict.stoppedAtStep' -FormatArgs @($stepLabel, $cause)) + ' ' + `
            (Format-CatalogText -Catalog $catalog -Key 'verdict.remedy' -FormatArgs @($remedy))
    }
    else {
        # No language chosen yet (failure during prerequisites, before
        # Question 1) -- the fixed-English-first-sentence rule extends to
        # this case: there is no catalog to draw from yet, so the verdict
        # stays in English rather than guessing a language.
        $remedy = if ($remedyKey -eq 'remedy.networkUnreachable') {
            'Check your internet connection, then run the installer line again.'
        }
        else {
            'Review the error above; once it is fixed, run the installer line again to resume.'
        }
        $verdict = "Stopped at step $stepLabel`: $cause What to do: $remedy"
    }

    # Best-effort: the notebook must stay intact on failure (T22's state
    # model) -- steps already recorded are never erased.
    if ($null -ne $carnet -and $null -ne $carnetPath) {
        $carnet.verdict = $verdict
        $carnet.lastRunAt = (Get-Date).ToString('o')
        try { Save-Carnet -Path $carnetPath -Carnet $carnet } catch { }
    }

    Write-Output $verdict
    exit 1
}
