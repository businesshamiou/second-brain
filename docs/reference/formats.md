---
type: reference
title: "File formats"
description: "Every file format a participant meets in Second Brain: its name pattern, where it lives, its required front matter and sections, who writes it and who reads it."
status: active
---

# FILE FORMATS

This page lists the files you meet while working with Second Brain: for each one, its name, where it lives, what it must contain, who writes it and who reads it. Everything below comes from the templates in `templates/` and from the tools that write or read each file. `<workspace>` is the absolute path of your workspace, `<project>` a project folder in it, and the installed Vault is `<workspace>/second-brain`. The roles (Owner, Pilot, Executor) are described in [roles and permissions](./roles-and-permissions.md).

**Under Windows.** A `bash …/tools/…` line of this page, typed in PowerShell where `bash` is unknown, starts with `& "C:\Program Files\Git\bin\bash.exe"` instead of `bash`; where an `sb` verb carries the same gesture ([Commands](commands.md)), type the verb. `sb doctor` says whether `bash` is on your PATH.

## At a glance

| Format | File | Written by | Read by |
|---|---|---|---|
| Mission | `<project>/missions/MISSION-<YYYY-MM-DD-HHMMSS>-<NNN>-<slug>.md` | Pilot | Executor |
| Execution Note | `<project>/missions/NOTE-<YYYY-MM-DD-HHMMSS>-<slug>.md` | Pilot, or Executor (mode 2) | `tools/check-work-regime.sh`, Executor |
| Execution report | `<project>/reports/REPORT-<YYYY-MM-DD>-<HHMMSS>-<mission_id>-<slug>.md` | Executor | Pilot; `tools/build-digest.sh` names the latest |
| Mini-prompt / RELAY block | a code block in the chat, never a file; the RELAY block also ends the report | Pilot / Executor | Executor / Pilot (the Owner pastes each one) |
| Handoff | `<project>/handoffs/HANDOFF-<YYYY-MM-DD-HHMMSS>-<slug>.md` | Pilot | next session; Executor (closing command) |
| Journal line | one line of `<project>/state/journal.md` | `tools/append-journal.sh` | `tools/build-state.sh`, `tools/build-digest.sh` |
| State sheet / digest | `<project>/state/STATE.md` / `<project>/state/DIGEST.md` | `tools/build-state.sh` / `tools/build-digest.sh` | Pilot (the digest at opening) |
| Pilot prompt | `<project>/state/PILOT-PROMPT.md` | `tools/project-bootstrap.sh` | Pilot, at opening |
| Birth certificate | comment block at the top of `<project>/.pre-commit-config.yaml` | `tools/project-bootstrap.sh` | `tools/resolve-vault.sh`, guardians |
| Mission register | `<project>/missions/MISSION-INDEX.md` | `tools/project-bootstrap.sh create`, then the Executor | `tools/build-digest.sh`, Executor |
| Folder index | `index.md` in each indexed folder | `tools/build-indexes.sh` | index guardians, searches |
| Vault identity | `VAULT-IDENTITY.md` at the Vault root | `tools/vault-identity.sh ensure` | tools that check which Vault they talk to |
| Working-root marker | `<workspace>/VAULT-ROOT.md` | `tools/write-marker.sh` | `tools/resolve-vault.sh`, agents |

## Mission

- **Template and name**: [Mission template](../../templates/mission-template.md), filled in with the [`mission-writing` skill](../../skills/mission-writing/SKILL.md) ([write a Mission](../how-to/write-a-mission.md)). File: `<project>/missions/MISSION-<YYYY-MM-DD-HHMMSS>-<NNN>-<slug>.md`, where `NNN` is the permanent three-digit identity. A correction keeps the number and adds `C01` to `C10`: `<project>/missions/MISSION-<YYYY-MM-DD-HHMMSS>-<NNN>-Cxx-<slug>.md`, with its own real timestamp ([versioning rule](../../rules/RULES-2026-08-17-211522-mission-versioning-and-generated-output.md)). The skill first files `<project>/missions/DRAFT-<slug>.md`, then renames it with the measured timestamp.
- **Front matter**: `type: mission`, `mission_id` (a quoted string, e.g. `"018"`), `status: AUTHORIZED`, `title`, `description`, `created_at` (ISO 8601 with offset), `timezone`, `scope`, `artifact_state`. A correction adds `correction: "Cxx"` and `supersedes:` (path of the replaced file); otherwise both keys are left out. `status` is frozen at creation: the execution state lives only in the register's `Statut` column.
- **Sections, in order**: Measured existing state (mandatory when the Scope creates a file), Context (mandatory), Objective, Scope (with an explicit out of scope), Preconditions, Sources, Applicable decisions, Constraints, Prior measurements (mandatory when a step creates, copies, installs, pins, wires or configures), Fan-out (optional), Steps, Gates, Validations, Exit contract, Resume contract, Doors, then the link section. **Who**: the Pilot writes it; the Executor reads it in full and applies it. The latest active version is complete on its own: the Executor never adds up earlier versions.

## Execution Note

- **Template and name**: [execution Note template](../../templates/execution-note-template.md); when to use it: [two work regimes](../../rules/RULES-2026-09-20-012259-two-work-regimes-light-note-and-full-mission.md). File: `<project>/missions/NOTE-<YYYY-MM-DD-HHMMSS>-<slug>.md`. A Note never gets a row in the Mission register: its trace is its journal line.
- **Front matter**: `type: note`, `title`, `description`, `created_at`, `timezone`, `regime: light`, `scope`. A mode-2 Note (written by the Executor from an Owner prompt) adds, after `scope:`, `origin: owner-prompt`, `mode: 2a` or `mode: 2b`, `received_at` (real time the prompt arrived, ISO 8601 with offset) and, for 2a, `prompt_sha256`.
- **Sections, exactly and in order**: Intent, Scope, Measure before, Gesture, Measure after, Journal line, then an optional link section. At most 4000 characters; a verbatim `prompt` block and an `owner_greenlight` block in the Intent are not counted. The Journal line is one line in a fenced block, starting `STATE:`, `OPEN:` or `CLOSE:`, at most 300 characters. **Who**: the Pilot, or the Executor as its first write in mode 2. `tools/check-work-regime.sh note <file>` must end with `REGIME-LIGHT-OK` (exit 0) before the gesture; a refusal ends with `REFUSED <id>[,<id>...]` (exit 1) and sends the gesture to a Mission.

## Execution report

- **Template and name**: [report template](../../templates/report-template.md). File: `<project>/reports/REPORT-<YYYY-MM-DD>-<HHMMSS>-<mission_id>-<slug>.md` ([report channel](../../decisions/DECISION-2026-08-21-000236-execution-report-channel.md), pattern amended by [Decision 145256](../../decisions/DECISION-2026-09-04-145256-amend-two-engraved-norms-and-amendment-rule.md)). The report-channel Decision names a `<project>/reports/` folder, the relay rule files mode-2 reports there, and `tools/build-digest.sh` looks there. (The [project structure standard](../../rules/RULES-2026-08-26-142800-project-structure-standard.md) describes `<project>/missions/` as holding Missions and their reports.)
- **Front matter**: `type: report`, `title`, `created_at`, `timezone`, `mission_id`, `role: executor`, `related_mission` (relative path of the Mission), `related_prompt` (title line of the mini-prompt), `status: FINAL`.
- **Sections**: 1. Gates · 2. Files created and modified · 3. Commits · 4. Impact on the installation · 5. Final state measured · 6. Deviations · 7. Final remeasurement, stop · RELAY block (filled in last) · link section. No `<…>` placeholder may remain; the SHA of the project commit that holds the report is given in the chat. **Who**: the Executor, staged in the same commit as the work it proves; in the chat it gives two lines, the path and the gates line. The Pilot reopens it only when the RELAY verdict or its « À trancher » rubric requires it.

## Mini-prompt and RELAY block

Both are fixed by the [relay rule](../../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md), the single source of their grammar, and travel as one copyable code block; the Owner is the only channel between the two windows ([read a relay](../how-to/read-a-relay.md)). The **mini-prompt** (Pilot to Executor) has five rubrics in order: the title line `Session Executor — Mission <NNN> (<description courte>)` (the form `Tu es l'Executor — …` is equivalent); `Position` (free); `Source à appliquer` (path of the Mission, to read and apply in full); `Interdits absolus` (no non-delegated git push, no model call, no deletion, move to `_trash/` only on the Mission's prescription, plus the Mission's own); `Sortie attendue` (end with the RELAY block). It never repeats the Mission. An `initiation` mini-prompt has no `Source à appliquer`: it carries the eight fields of the initiation order instead. In mode 2, rubric 3 becomes the Owner's prompt verbatim (2a) or `Fichiers à consommer`, one path per line (2b).

**RELAY block** (Executor to Pilot), at the end of every report and window:

```text
RELAY <NNN>
Rapport   : <chemin du fichier REPORT déposé>
Verdict   : <FAIT | PARTIEL | BLOQUÉ> + une ligne
Critères  : <n>/<total> PASS
Commits   : <dépôt> <hash> · <dépôt> <hash>
Poussées  : <dépôt> <avant>..<après> · <étiquette> | aucune
Résumé    : <cinq lignes>
À trancher: <une ligne, ou « rien »>
```

`Poussées` states what was actually pushed, measured with `git ls-remote`. `Résumé` is five lines at most, facts with figures, and lists every deviation. In mode 2 the first line is `RELAY NOTE-<YYYY-MM-DD-HHMMSS>` (the Note's timestamp).

## Handoff

- **Template, name, front matter**: [handoff template](../../templates/handoff-template.md). File: `<project>/handoffs/HANDOFF-<YYYY-MM-DD-HHMMSS>-<slug>.md`; the tools look for `HANDOFF-` followed by a four-digit year. Front matter: `type: handoff`, `title`, `created_at`, `timezone`, `status: active`.
- **Sections**: Objective, Current state, Done, Active decisions, Open points, Recommended next action, Constraints and prohibitions, Artifacts to read first, Executor closing command (mandatory: one `text` block with the five rubrics, naming this handoff by its relative path), link section. It is a dated handover, never a second current state.
- **Who**: the Pilot writes it at close ([session-close skill](../../skills/session-close/SKILL.md), [close a session](../how-to/close-a-session.md)); the next Pilot reads the handoff its digest names; the Executor runs its closing command. Where a project wires `tools/check-session-close.sh` (the bootstrap does not), a commit that brings in the newest handoff is refused unless the same commit carries a `<project>/state/DIGEST.md` naming it on its `Dernier handoff :` line and a journal `STATE:` line later than the handoff's `created_at`.

## Journal line

`<project>/state/journal.md` is append-only and never edited by hand. Only `tools/append-journal.sh <project path> "<text>"` writes it: it prefixes the timestamp, so a line reads `<YYYY-MM-DDTHH:MM:SS±HH:MM> <text>`, and it creates the file (a `# Journal — <name>` title and a link section) when missing. Text over 300 characters is refused with `REFUS append-journal.sh : ligne de <n> caracteres, plafond 300 (Decision 191407). Rien ecrit.` (exit 1). Lines that do not start with a date and time are ignored by the readers. Tags read by `tools/build-state.sh` (French forms are still recognised for history):

| Tag | Where on the line | Effect |
|---|---|---|
| `STATE:` (`ETAT:`) | anywhere | last occurrence becomes the current state |
| `NEXT:` (`PROCHAIN:`) | anywhere | last occurrence becomes the next action |
| `RESUME:` (`REPRISE:`) | on the last dated line only | shown as the resume note |
| `OPEN:` (`OUVERT:`) | right after the timestamp: `OPEN: <key> -- <text>` | opens or reopens a door |
| `CLOSE:` | right after the timestamp: `CLOSE: <key> -- <reference>` | closes that door |

A door key starts with `open-` or `frozen-` and uses lower-case letters, digits and hyphens; the ` -- ` separator is mandatory. For each key, its last occurrence decides. An `OPEN:` line without a conforming key is legacy: only counted.

```
bash <workspace>/second-brain/tools/append-journal.sh <workspace>/<project> "STATE: Mission 012 closed, 4/4 PASS"
```
_Not executed by the documentation check._

## STATE.md and DIGEST.md

Both are generated and never edited by hand. Each refuses to overwrite a file its script did not generate (no `generated_by:` line naming it): `STATE-NOT-GENERATED` or `DIGEST-NOT-GENERATED`, nothing written. Both copy at their head the seven-line contract of the [Pilot contract template](../../templates/pilot-contract-template.md) and fail if it does not hold exactly seven lines. The Executor runs them (at session close, or on a Mission's prescription).

- **STATE.md**, by `tools/build-state.sh [--replace-hand-written] <project path>`. Front matter: `type: state`, `title`, `description`, `status: GENERATED`, `generated_by`. Sections: `Contrat du Pilot`, `Références de session`, `État courant`, `Prochaine action`, `Portes ouvertes`, `Historique legacy`, `Documents récents` (the 15 most recently modified `.md` files of the project), `État des dépôts` (`git status -sb` of the Vault and the project), `Reprise`, link section. `--replace-hand-written` replaces a hand-written sheet only when Git holds it unchanged at HEAD. The common Pilot prompt reads the state sheet its PILOT-PROMPT names.
- **DIGEST.md**, by `tools/build-digest.sh <project path>`: capped at 8000 bytes, fail-closed (over the cap, `REFUS build-digest.sh : digest généré à <n> octets, plafond 8000 octets. DIGEST.md non écrit (fail-closed).`, exit 1). Success ends with `OK build-digest.sh : <path> écrit, <n> octets (plafond 8000).` Front matter: `type: digest`, `title`, `description`, `status: GENERATED`, `generated_by`. Sections: `Contrat du Pilot`, `En-tête` (generation time, `Dernière entrée journal`), `État des dépôts` (short HEAD and `origin/main`, ahead/behind, porcelain count), `Dernières lignes du journal` (last three, cut at 300 characters), `Portes ouvertes` (keys only), `Dernière Mission`, `Pointeurs` (`Dernier handoff`, `Dernier rapport`), link section. The Pilot reads it in full at opening ([reading list](../../skills/session-start/reading-list.md)); it is stale when the journal was modified after its `Dernière entrée journal`.

## PILOT-PROMPT.md

`<project>/state/PILOT-PROMPT.md` is written by `tools/project-bootstrap.sh` (create and adopt) when it is absent; an existing one is kept and its canary reused. `project-bootstrap.sh prompt <folder> [--state-path <relative path>]` regenerates it for an adopted project, keeping `project_id`, `canary`, `title` and the project path. There is no template for it in `templates/`: the script writes it; the common part it points to is the [common opening prompt](../../templates/session-opening-prompt-template.md).

- **Front matter**: `type: pilot-prompt`, `title`, `description`, `status: generated`, `project_id`, `canary` (`pp-` and 12 hexadecimal characters), `vault_id`, `mcp_server`, `vault_ref`, `state_path` (the state sheet, relative to the project, by default state/STATE.md), `language`, `generated_at`.
- **Body and readers**: a list (project path, Vault and commit, MCP server, canary, state sheet, language), a `## Ouverture Pilot` section of three steps, and a link section. The Pilot reads it at opening, returns the canary as proof of reading and compares the Vault commit; `prompt` reads its fields back.

## Birth certificate

The comment block at the top of `<project>/.pre-commit-config.yaml`, written by `tools/project-bootstrap.sh` (create and adopt; `adopt --git` changes `# vcs: none` to `# vcs: git`):

```yaml
# second-brain-birth-certificate: v1
# vault_id: <vault_id of the Vault>
# vault_origin: <remote URL or folder of the Vault clone>
# vault_ref: <Vault commit>
# vcs: <none | git>
# baseline: <.vault-baseline-YYYY-MM-DD-HHMMSS.tsv, at adoption only>
```

The first line is exact; keys are read only above the first non-comment line. Below the block, `repos:` holds one `repo: local` entry with four hooks (`vault-check-secrets`, `vault-check-indexes-fresh`, `vault-check-index-weight`, `vault-check-links`) that call the Vault's guardians by a relative path ([guardians and hooks](./guardians-and-hooks.md)). An optional `# exempt:` key lists path prefixes relative to the project, separated by spaces, each ending with `/`; `<project>/.vault-exempt` holds the same, one per line. Only the link, index-freshness and index-weight guardians honour them, never the secrets check. `tools/resolve-vault.sh` finds the certificate by walking up and refuses a Vault whose `vault_id` differs, naming both. This read-only check prints the Vault's path (exit 0) or a `REFUS : …` line on stderr (exit 1):

```
bash <workspace>/second-brain/tools/resolve-vault.sh <workspace>/<project>
```

## Mission register (MISSION-INDEX.md)

`<project>/missions/MISSION-INDEX.md` is a verbatim copy of the [register template](../../templates/mission-index-template.md), made by `tools/project-bootstrap.sh create`. Front matter: `type: index`, `title: "Mission register"`, `description`, `status: active`. One table, one row per Mission lineage: `| ID | Objective | Active version | Statut | Path | Report |`. Keep the `Statut` header in French: `tools/build-digest.sh` finds the column by that name and shows the last row whose ID is a number in backticks (a suffix such as `194-C01` is accepted). The Executor keeps it up to date ([role charter](../../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)); it copies no perishable measurement, and a Note never gets a row.

## index.md files

`tools/build-indexes.sh [-v|--verbose] [--only-missing] <root...>` (it runs `tools/build_indexes.py`) writes one `index.md` per folder under each root, listing the `.md` files of that folder. It skips `.git`, `.githooks`, `.claude`, `.codex`, `.agents`, `graphify-out`, `tools`, `patterns`, `node_modules`, `state`, `.venv`, `venv`, `__pycache__`, `skills-warehouse`, `_trash`, `web-package`. The repository-root guard refuses the workspace root. Front matter: `type: index`, `title: "Index — <folder>"`, `description`, `status: active`, and a `generated_by` line naming `tools/build-indexes.sh`. Under `## Contenu`, one locator line per file:

```
- `<identifier>` · <status> · <short title> · `<file name>`
```

The identifier comes from the file name (Mission or report number, else timestamp, else date, else the name); the status is the front matter `status`, else `type`; the title is cut at 80 characters; a superseded file gets ` — REMPLACÉ par <name>`. An index over 8000 bytes is split into archive files, `<folder>/index-archive-<start>-<end>.md` (numbered files) or `<folder>/index-archive-<YYYY-MM>.md` (other dated files). Each root gets a `superseded-files.txt` listing its superseded files when there are any (it is removed when there are none, except with `--only-missing`, which leaves an existing file as it is). A file without the `generated_by` line is never overwritten. The index guardians and searches read these files ([indexes and links tools](./tools-indexes-and-links.md)).

## VAULT-IDENTITY.md

At the Vault root, generated once by `tools/vault-identity.sh ensure` at installation, tracked by Git, never edited by hand and never regenerated once `status: generated`. The distributed repository carries only a skeleton (`status: template`, empty values). Front matter: `type: vault-identity`, `title`, `description`, `status: generated`, `vault_id` (`sb-` and hexadecimal characters), `vault_origin` (remote URL, or folder path without a remote), `workspace_label` (optional, set when the MCP server is installed), `created_at`. The MCP server is named `second-brain-vault-<workspace_label>`, or, when there is no label, `second-brain-vault-` followed by the first 8 characters of `vault_id` after its `sb-` prefix. Read by `tools/write-marker.sh`, `tools/project-bootstrap.sh` and `tools/resolve-vault.sh`. Read-only query:

```
bash <workspace>/second-brain/tools/vault-identity.sh get server_name <workspace>/second-brain
```

## VAULT-ROOT.md

`<workspace>/VAULT-ROOT.md` is written by `tools/write-marker.sh [--marker-only] <work-root> [vault-name]` from the [marker template](../../templates/vault-root-template.md): it fills the Vault's name (default `Brian`), relative path, identity and origin, and rewrites the relative links. Without `--marker-only` it also writes `<workspace>/CLAUDE.md` and `<workspace>/AGENTS.md`. Front matter: `type: marker`, `title`, `description`, `status: active`, and a `generated_by` line naming `tools/write-marker.sh`. Sections: Role contract, Location. The Location holds three lines whose French labels stay exact: `Chemin relatif du Vault depuis cette racine de travail : `, `Identité du Vault : ` and `Origine du Vault : `, each followed by a value in backticks. `tools/resolve-vault.sh` walks up to it when a project has no certificate and reads the first two; the repository-root guard treats its folder as a workspace root. Never edit it by hand: regenerate it.

## Link section (Liens)

Every document ends with a section headed exactly `## Liens`, one line per link: `` - `<type>` — [readable title](relative path) ``, and each link also appears in the sentence that states the relation ([linking standard](../../rules/RULES-2026-08-21-115658-document-linking-standard.md)). The six types: `applies`, `supersedes` (the target needs `superseded by`, same commit), `amends` (the target needs `amended by`), `source`, `prescribed by` (every template carries one), `see also`. A link into another repository is suffixed `(hors Vault)`. `tools/check-links.sh` (staged files, or `check-links.sh <project>` without Git) blocks a missing section (except under `skills/external/` and `skills-warehouse/`) and a relative `.md` link that does not resolve (`LIENS: cible introuvable: …`); a file with no internal link only gets a warning. Links inside code are ignored.

## Other templates

| Template | Becomes | Front matter | Sections | Who |
|---|---|---|---|---|
| [capture](../../templates/capture-template.md) | a capture in `knowledge/` (the example names it `CAPTURE-<timestamp>-<slug>`) | `type: capture`, `status: draft`, `knowledge_kind`, `certainty` | Context, Captured information, Level of certainty, Possible impact, Related artifacts, Limit | Pilot |
| [decision](../../templates/decision-template.md) | `<project>/decisions/DECISION-<YYYY-MM-DD-HHMMSS>-<slug>.md` | `type: decision`, `status: proposed`, `owner_gate: required` | Date, Status, Decision, Reason, Impact, Important alternatives, Human gate, Related artifacts; `ARBITRATED` only after an explicit human gate | Pilot |
| [proposal](../../templates/proposal-template.md) | `<project>/proposals/PROPOSAL-<YYYY-MM-DD-HHMMSS>-<slug>.md` | `type: proposal`, `status: proposed`, `owner_gate: required` | Status, Context, Proposal, Reason, Expected impact, Important alternatives, Associated links | Pilot |
| [initiation order](../../templates/initiation-order-template.md) | an order file for `project-bootstrap.sh --order <file>` | `type: template` | fields `Type`, `Mode`, `Nom`, `Emplacement`, `Vault + construction`, `Git`, `Objet`, `Autorisation Owner datée`, optional `Arbre sale` | Pilot fills, Owner dates, Executor consumes |
| [Pilot contract](../../templates/pilot-contract-template.md) | the head of STATE.md and DIGEST.md | `type: template` | seven lines between `CONTRACT:BEGIN` and `CONTRACT:END` | read by the two generators |
| [project registry](../../templates/project-registry-template.md) | [project registry](../../projects/PROJECT-REGISTRY.md) | `write_contract` executor-only | Active, Paused, Archived; columns `project_id`, `display_name`, `status`, `relative_path`, `vcs`, `conformity` | rows by `tools/project-bootstrap.sh` |
| [common opening prompt](../../templates/session-opening-prompt-template.md) | the Pilot's Project instructions | `type: template` | block between `PROMPT:BEGIN` and `PROMPT:END`; the bootstrap replaces `{{VAULT_SHORT_ID}}` | Owner pastes, Pilot follows |
| [current state](../../templates/current-state-template.md) | nothing: superseded on 2026-09-23 by the generated state sheet | `status: superseded` | kept as history only | nobody |

Every template also carries `title`, and the dated ones `created_at` and `timezone`; each ends with a link section. The [example project](../../templates/example-project-book-club/README.md) is a fictional book club that shows the seven-function skeleton; it is not in the registry.

## Liens

- `source` — [Mission template](../../templates/mission-template.md)
- `source` — [Execution Note template](../../templates/execution-note-template.md)
- `source` — [Report template](../../templates/report-template.md)
- `source` — [Handoff template](../../templates/handoff-template.md)
- `source` — [Mission register template](../../templates/mission-index-template.md)
- `source` — [Pilot contract template](../../templates/pilot-contract-template.md)
- `source` — [Common opening prompt template](../../templates/session-opening-prompt-template.md)
- `source` — [Working-root marker template](../../templates/vault-root-template.md)
- `source` — [Capture template](../../templates/capture-template.md)
- `source` — [Decision template](../../templates/decision-template.md)
- `source` — [Proposal template](../../templates/proposal-template.md)
- `source` — [Initiation order template](../../templates/initiation-order-template.md)
- `source` — [Project registry template](../../templates/project-registry-template.md)
- `source` — [Current state template (superseded)](../../templates/current-state-template.md)
- `source` — [Example project](../../templates/example-project-book-club/README.md)
- `source` — [Project registry](../../projects/PROJECT-REGISTRY.md)
- `source` — [Relay between roles through mini-prompts](../../rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md)
- `source` — [Standard for links between documents](../../rules/RULES-2026-08-21-115658-document-linking-standard.md)
- `source` — [Versioning of Missions and generated outputs](../../rules/RULES-2026-08-17-211522-mission-versioning-and-generated-output.md)
- `source` — [Two work regimes](../../rules/RULES-2026-09-20-012259-two-work-regimes-light-note-and-full-mission.md)
- `source` — [Project structure standard](../../rules/RULES-2026-08-26-142800-project-structure-standard.md)
- `source` — [Role charter and session determination](../../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)
- `source` — [Absolute repository paths and verified pushes](../../rules/RULES-2026-09-25-100419-absolute-repo-paths-and-verified-pushes.md)
- `source` — [Decision — Execution report channel](../../decisions/DECISION-2026-08-21-000236-execution-report-channel.md)
- `source` — [Decision — Report naming amended](../../decisions/DECISION-2026-09-04-145256-amend-two-engraved-norms-and-amendment-rule.md)
- `source` — [Session opening reading list](../../skills/session-start/reading-list.md)
- `source` — [session-close skill](../../skills/session-close/SKILL.md)
- `source` — [mission-writing skill](../../skills/mission-writing/SKILL.md)
- `source` — [Vault identity](../../VAULT-IDENTITY.md)
- `source` — [append-journal.sh](../../tools/append-journal.sh)
- `source` — [build-state.sh](../../tools/build-state.sh)
- `source` — [build-digest.sh](../../tools/build-digest.sh)
- `source` — [project-bootstrap.sh](../../tools/project-bootstrap.sh)
- `source` — [resolve-vault.sh](../../tools/resolve-vault.sh)
- `source` — [vault-identity.sh](../../tools/vault-identity.sh)
- `source` — [write-marker.sh](../../tools/write-marker.sh)
- `source` — [build-indexes.sh](../../tools/build-indexes.sh)
- `source` — [build_indexes.py](../../tools/build_indexes.py)
- `source` — [check-links.sh](../../tools/check-links.sh)
- `source` — [check-work-regime.sh](../../tools/check-work-regime.sh)
- `source` — [check-session-close.sh](../../tools/check-session-close.sh)
- `see also` — [Roles and permissions](./roles-and-permissions.md)
- `see also` — [Guardians and hooks](./guardians-and-hooks.md)
- `see also` — [State and journal tools](./tools-state-and-journal.md)
- `see also` — [Indexes and links tools](./tools-indexes-and-links.md)
- `see also` — [Write a Mission](../how-to/write-a-mission.md)
- `see also` — [Read a relay](../how-to/read-a-relay.md)
- `see also` — [Close a session](../how-to/close-a-session.md)
