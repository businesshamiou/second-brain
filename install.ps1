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
                          clone, guardians, marker, assistant, firstProject,
                          profile.
                          Throws a clean, named "forced stop" error right
                          after that step's own work completes and its
                          carnet flag is saved -- the mechanism T04
                          prescribes for testing resume (a forced,
                          interrupted run via a test flag naming the step).
                          Never used outside
                          tests/test-questionnaire-resume.ps1.
        -Verbose          Common parameter (this script has [CmdletBinding()]).
                          Restores the full per-index detail
                          tools/build-indexes.sh used to always print
                          (Mission 172, audit defect 3: a nominal install is
                          quiet by default -- one summary line per
                          index-regeneration call instead of one line per
                          regenerated index.md/archive).

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

    [ValidateSet('prerequisites', 'workspace', 'clone', 'guardians', 'marker', 'assistant', 'firstProject', 'profile')]
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

function Write-StepLine {
    # Mission 173 step 7 (Q17): one line per real installer step, in
    # order, with its result -- the journal's own spine. Deliberately not
    # numbered ("Step N/8"): 'firstProject' and 'projectLinks' are
    # skipped entirely when the participant declines a first project, and
    # a fixed denominator would then either lie about the total or need
    # its own conditional logic for no real benefit over a plain list.
    # Write-Host, not Write-Output: this line must reach a real console (and
    # a redirected-stdout child process, which is how a real user's terminal
    # and tests/test-install-log-line-count.ps1 both see it) without also
    # landing in the PowerShell success stream -- ticket 05 criterion 7
    # (tests/test-install-e2e.ps1) requires that `$verdict = & install.ps1 ...`
    # capture the verdict line and nothing else in silent (-AnswersFile) mode.
    param([string] $Name)
    Write-Host "Step: $Name -- OK"
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

function Invoke-QuietGit {
    # Mission 172, audit defect 3 (same family as the index-list dump this
    # Mission also fixed): git add/commit calls this installer makes
    # internally (Save-ClonePendingChanges, first-project registration, the
    # new project's own initial scaffold commit) each trigger this
    # repository's own pre-commit guardian banner (12 lines) plus any
    # CRLF-conversion notice -- measured at acceptance to be the dominant
    # remaining noise once the index-list dump itself was fixed. Quiet by
    # default; -Verbose restores it; a failure is NEVER swallowed -- its
    # full output is always shown, since that is exactly when a person
    # needs to see why the guardians refused.
    #
    # Redirects to a temp FILE (*>), never merges via 2>&1 into a captured
    # variable or pipeline meant for further processing -- same trap
    # Invoke-BashTool's own comment documents. Measured directly: under
    # this script's $ErrorActionPreference = 'Stop', ANY redirection of a
    # native command's stderr through a PowerShell stream operator (2>,
    # *>, 2>&1 alike) still wraps each line as a NativeCommandError and
    # terminates immediately -- a plain git-add CRLF notice, exit code 0,
    # was observed aborting the whole install this way. Flipping
    # $ErrorActionPreference to 'Continue' only around this one call
    # (restored in `finally`, even on an early return or throw) turns that
    # wrap into a non-terminating error that still lands in the redirected
    # file instead of the console, which is all this needs: the file is
    # only ever read back when $LASTEXITCODE itself says the command
    # failed.
    param(
        [Parameter(Mandatory = $true)][string[]] $ArgumentList,
        [Parameter(Mandatory = $true)][string] $FailureMessage
    )
    if ($VerbosePreference -eq 'Continue') {
        & git @ArgumentList
        if ($LASTEXITCODE -ne 0) { throw $FailureMessage }
        return
    }
    $tempFile = [System.IO.Path]::GetTempFileName()
    $previousEap = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & git @ArgumentList *> $tempFile
        $exitCode = $LASTEXITCODE
        $ErrorActionPreference = $previousEap
        if ($exitCode -ne 0) {
            Get-Content -Path $tempFile | ForEach-Object { Write-Output $_ }
            throw $FailureMessage
        }
    }
    finally {
        $ErrorActionPreference = $previousEap
        Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
    }
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
    # Mission 172, audit defect 3: build-indexes.sh (-> build_indexes.py) is
    # quiet by default since that Mission (one summary line instead of one
    # line per regenerated index -- this call alone used to dump the whole
    # repository's index tree to the console, measured at acceptance). -v
    # restores the detail, forwarded only when the installer itself was run
    # with the common -Verbose switch -- never on by default.
    $buildIndexesArgs = @()
    if ($VerbosePreference -eq 'Continue') { $buildIndexesArgs += '-v' }
    $buildIndexesArgs += (ConvertTo-PosixPath $ClonePath)
    Invoke-BashTool -BashExe $BashExe -ScriptPath (Join-Path $ClonePath 'tools\build-indexes.sh') `
        -ScriptArgs $buildIndexesArgs | Out-Null

    $changes = & git -C $ClonePath status --porcelain
    if (-not $changes) { return }

    Invoke-BashTool -BashExe $BashExe -ScriptPath (Join-Path $ClonePath 'tools\session-preflight.sh') | Out-Null

    foreach ($line in $changes) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        $changedPath = $line.Substring(3).Trim('"')
        Invoke-QuietGit -ArgumentList @('-C', $ClonePath, 'add', '--', $changedPath) `
            -FailureMessage "git add failed for '$changedPath' in $ClonePath"
    }
    Invoke-QuietGit -ArgumentList @('-C', $ClonePath, 'commit', '-q', '-m', $CommitMessage) `
        -FailureMessage "failed to commit ($CommitMessage) in $ClonePath (guardians refused)"
}

function New-InstallerContext {
    # Builds the redirection context (Mission constraint: "Environnement de
    # l'Owner intact" ["Owner's environment intact"]). Real mode reads the real profile; test mode redirects
    # the same things (profile-rooted defaults, PATH) under -TestRoot.
    #
    # Mission 173 (Q17, "rien dans le profil" ["nothing in the profile"]): ClaudeAgentsDir and
    # CodexAgentsSkillsDir -- the profile-level WRITE targets Mission
    # 171-C01 (steps 4 and 6) added here -- are retired. Nothing this
    # installer does writes into the profile any more: the assistant and
    # the method skills are linked into each PROJECT instead, at
    # project-creation time (tools/project-bootstrap.sh), never into
    # ~/.claude or ~/.agents.
    #
    # ClaudeSkillsDir (.claude\skills) and CodexSkillsDir (.codex\skills)
    # both stay: pre-existing, unrelated heuristics
    # (tools/questionnaire.ps1's Get-DetectedAiTools/
    # Get-ProfileEnvironmentFacts) that only READ whether something that
    # looks like Claude Code/Codex already exists on this machine -- never
    # write targets, and .codex/skills/ was never a documented Codex
    # location (T11) besides.
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
            SimulatedPathFile     = Join-Path $TestRoot 'simulated-user-path.txt'
            DefaultWorkspacePath  = Join-Path $TestRoot 'workspace'
        }
    }

    return [PSCustomObject]@{
        TestMode              = $false
        ProfileRoot           = $env:USERPROFILE
        ClaudeSkillsDir       = Join-Path $env:USERPROFILE '.claude\skills'
        CodexSkillsDir        = Join-Path $env:USERPROFILE '.codex\skills'
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
    Write-StepLine -Name 'Prerequisites'
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
        # (T06: "sans deplacement ulterieur" ["with no later move"]), never this one. Offered with
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
    Write-StepLine -Name 'Workspace'
    Test-ForcedStop -StopAfterStep $StopAfterStep -StepName 'workspace'

    # Step: clone second-brain from the local source (T23 -- never a URL,
    # never the network; `git clone` of a local path uses hardlinks only).
    # -q (Mission 173 step 7): "Cloning into '...'... done." is exactly the
    # kind of noise this step retires -- the Write-StepLine below is this
    # step's own, single, named result line instead.
    $currentStepKey = 'clone'
    if (-not (Test-Path (Join-Path $clonePath '.git'))) {
        & git -c core.longpaths=true clone -q -- $Source $clonePath
        if ($LASTEXITCODE -ne 0) { throw "git clone failed (source: $Source, dest: $clonePath)" }
        & git -C $clonePath config core.longpaths true
        & git -C $clonePath config user.name $gitUserName
        & git -C $clonePath config user.email $gitUserEmail
        # Gate 2 of capture 2026-09-17-144137: the source is the clone the
        # bootstrap dropped in the temp folder, so the installed clone's
        # `origin` -- and through it VAULT-IDENTITY.md's vault_origin, the
        # marker and every project birth certificate -- named
        # %TEMP%\second-brain-install instead of where all of it came from.
        # The REAL origin is the source's own, when it has one; otherwise
        # the source path, said out loud rather than set in silence.
        # @(...) rather than `| Select-Object -First 1`: -First stops the
        # pipeline, which stops the native command, and $LASTEXITCODE is then
        # whatever that interruption produced -- measured on the CI Windows
        # runner (Mission 185-C01, round 1). Reading the value back through an
        # array keeps git's own exit code readable.
        $originLines = @(& git -C $sourceAbs config --get remote.origin.url)
        $originExit = $LASTEXITCODE
        $sourceOrigin = ''
        if ($originExit -eq 0 -and $originLines.Count -gt 0) { $sourceOrigin = "$($originLines[0])".Trim() }
        if ($sourceOrigin) {
            & git -C $clonePath remote set-url origin $sourceOrigin
        }
        else {
            [Console]::Error.WriteLine((Format-CatalogText -Catalog $catalog -Key 'install.vaultOrigin.fallback' -FormatArgs @($sourceAbs)))
        }
        # A fresh clone is a new Vault (Mission 191-C01): it never inherits a
        # generated identity its source may carry (the laboratory Vault,
        # Decision 152251 A2, carries its own). The identity step below
        # generates this installation's.
        $identityFile = Join-Path $clonePath 'VAULT-IDENTITY.md'
        if ((Test-Path $identityFile) -and (Select-String -Path $identityFile -Pattern '^status: generated\s*$' -Quiet)) {
            Remove-Item -LiteralPath $identityFile -Force
        }
    }
    else {
        # An installation is already there (Decision 152251 B3, Mission
        # 191-C01): if it does not contain the version this line brings, the
        # line does not reinstall over it -- it names the update command.
        # Nothing is touched.
        $sourceHeadLines = @(& git -C $sourceAbs rev-parse HEAD)
        $sourceHead = ''
        if ($LASTEXITCODE -eq 0 -and $sourceHeadLines.Count -gt 0) { $sourceHead = "$($sourceHeadLines[0])".Trim() }
        if ($sourceHead) {
            & git -C $clonePath merge-base --is-ancestor $sourceHead HEAD 2>$null
            if ($LASTEXITCODE -ne 0) {
                $versionLines = @(& git -C $sourceAbs describe --tags --exact-match HEAD 2>$null)
                $sourceVersion = $sourceHead
                if ($LASTEXITCODE -eq 0 -and $versionLines.Count -gt 0) { $sourceVersion = "$($versionLines[0])".Trim() }
                Write-Output (Format-CatalogText -Catalog $catalog -Key 'install.existingInstall' -FormatArgs @($clonePath, $sourceVersion, "powershell -File $(Join-Path $sourceAbs 'tools\second-brain-update.ps1') $sourceVersion -Vault $clonePath"))
                exit 1
            }
        }
    }
    Set-CarnetStep -Carnet $carnet -Name 'cloned'
    # The notebook is born here (T06 complement 2: this is where the
    # notebook itself starts existing) -- this is also the first point at
    # which language/assistant name/workspace path become durable, so they
    # are never re-asked again.
    Save-Carnet -Path $carnetPath -Carnet $carnet
    Write-StepLine -Name 'Clone'
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
    Write-StepLine -Name 'Guardians'
    Test-ForcedStop -StopAfterStep $StopAfterStep -StepName 'guardians'

    # Step: workspace marker (VAULT-ROOT.md, plus its own CLAUDE.md/AGENTS.md,
    # Mission 173 step 5).
    $currentStepKey = 'marker'
    # The installed Vault's own identity (vault_id, vault_origin), generated
    # once and tracked like USER.md (Decision 2026-09-17-000545, A1/A7):
    # every project birth certificate and the marker below name this Vault
    # by it. Idempotent -- an identity already generated is never rewritten,
    # so a second run commits nothing.
    Invoke-BashTool -BashExe $bashExe -ScriptPath (Join-Path $clonePath 'tools\vault-identity.sh') `
        -ScriptArgs @('ensure', (ConvertTo-PosixPath $clonePath)) | Out-Null
    Save-ClonePendingChanges -BashExe $bashExe -ClonePath $clonePath -CommitMessage 'Generate vault identity'
    if (-not (Test-Path $markerPath)) {
        $writeMarkerScript = Join-Path $clonePath 'tools\write-marker.sh'
        Invoke-BashTool -BashExe $bashExe -ScriptPath $writeMarkerScript `
            -ScriptArgs @((ConvertTo-PosixPath $workspacePath), $vaultName) | Out-Null
    }
    Set-CarnetStep -Carnet $carnet -Name 'markerWritten'
    Save-Carnet -Path $carnetPath -Carnet $carnet
    Write-StepLine -Name 'Workspace CLAUDE.md/AGENTS.md'
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
    New-AssistantForms -ClonePath $clonePath -Name $vaultName -Language $language | Out-Null
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
    Write-StepLine -Name 'Assistant'
    Test-ForcedStop -StopAfterStep $StopAfterStep -StepName 'assistant'

    # Mission 173 (Q17, "rien dans le profil" ["nothing in the profile"]): the 'assistantDeployed' and
    # 'skillsDeployed' steps that used to live here (Mission 171-C01, steps
    # 6 and 4) linked the assistant and the method skills into the user's
    # PROFILE (~/.claude/agents, ~/.claude/skills, ~/.agents/skills) so they
    # were reachable from any neighbouring project. Both steps, their
    # conflict-note code (Mission 172, audit defect 4 -- now moot, nothing
    # writes to a shared profile location any more so there is nothing left
    # to conflict over) and their carnet fields are retired outright: the
    # assistant and the method skills are instead linked into each PROJECT
    # itself at project-creation time (tools/project-bootstrap.sh, Mission
    # 173 step 4), never into the profile.

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
            # Mission 173 step 4 (Q17): project-bootstrap.sh now also links
            # the assistant and the method skills into the new project's own
            # folders (tools/sb_installer_helper.py's link-project) and
            # prints catalog-driven notes about it (conflicts, Codex budget
            # fallback, Mission 177) -- captured and relayed here instead of
            # discarded, the fiche path itself (also on stdout, always the
            # last line) is not needed by this caller and dropped by
            # position.
            $bootstrapOutput = Invoke-BashTool -BashExe $bashExe -ScriptPath $bootstrapScript `
                -ScriptArgs @((ConvertTo-PosixPath $firstProjectPath), $firstProjectDisplayName, $language)
            Write-StepLine -Name 'First project'
            # Write-Host, not Write-Output -- same reason as Write-StepLine
            # above: these notes must reach the console without joining the
            # PowerShell success stream that ticket 05's silent-mode
            # assertion (tests/test-install-e2e.ps1) captures. Every line
            # but the last (the fiche path), never a match on an English
            # prefix ("Note:", "  - ", "  To use") -- since
            # project-bootstrap.sh speaks through i18n/ catalogs (Mission
            # 177 step 5), that prefix changes with the language
            # ("Remarque :", "Nota:") and a prefix fixed on English would
            # have swallowed the translated notes in silence, exactly the
            # defect this step fixes.
            $bootstrapOutput | Select-Object -SkipLast 1 | ForEach-Object { Write-Host $_ }
            Write-StepLine -Name 'Project links'

            $registrationChanges = & git -C $clonePath status --porcelain
            if ($registrationChanges) {
                Invoke-BashTool -BashExe $bashExe -ScriptPath (Join-Path $clonePath 'tools\session-preflight.sh') | Out-Null

                foreach ($line in $registrationChanges) {
                    if ([string]::IsNullOrWhiteSpace($line)) { continue }
                    $changedPath = $line.Substring(3).Trim('"')
                    Invoke-QuietGit -ArgumentList @('-C', $clonePath, 'add', '--', $changedPath) `
                        -FailureMessage "git add failed for '$changedPath' in $clonePath"
                }
                Invoke-QuietGit -ArgumentList @('-C', $clonePath, 'commit', '-q', '-m', "Register first project: $firstProjectDisplayName") `
                    -FailureMessage "failed to commit project registration in $clonePath (guardians refused)"
            }

            Push-Location $firstProjectPath
            try {
                # tools/project-bootstrap.sh already creates the repository
                # when Git is on its PATH (Decision 2026-09-17-000545, vcs:
                # git); re-running `git init -b` there would only print a
                # re-init warning.
                if (-not (Test-Path (Join-Path $firstProjectPath '.git'))) {
                    & git init -q -b main
                    if ($LASTEXITCODE -ne 0) { throw "git init failed in $firstProjectPath" }
                }
                & git config user.name $gitUserName
                & git config user.email $gitUserEmail
                Invoke-QuietGit -ArgumentList @('add', '-A') -FailureMessage "git add failed in $firstProjectPath"
                & pre-commit install *> $null
                if ($LASTEXITCODE -ne 0) { throw "pre-commit install failed in $firstProjectPath" }
                Invoke-QuietGit -ArgumentList @('commit', '-q', '-m', 'Initial scaffold from project-bootstrap') `
                    -FailureMessage "initial commit failed in $firstProjectPath (guardians refused)"
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

    # End of installation: the installed Vault is handed over clean.
    # Gate 8 of capture 2026-09-17-144137: the install used to end on a
    # clone whose porcelain was not empty (an untracked project record,
    # modified indexes), so the participant's very first commit inherited
    # files they never wrote. This last pass regenerates the indexes and
    # commits whatever is left -- and nothing at all when everything is
    # already committed (the function is a no-op at empty porcelain), so a
    # second run still manufactures no commit.
    Save-ClonePendingChanges -BashExe $bashExe -ClonePath $clonePath -CommitMessage 'Installation complete'

    # Signed by the assistant's own chosen name (T07: "il signe... en fin de
    # verdict" ["it signs... at the end of the verdict"]; ticket 05's own report named this explicitly out of scope
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
