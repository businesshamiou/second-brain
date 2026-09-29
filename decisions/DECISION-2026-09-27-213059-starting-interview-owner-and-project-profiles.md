---
type: decision
title: "The starting interview: a living Owner profile under a fixed heading of USER.md, a project profile at creation and adoption, both read before a Mission and by the assistant"
description: "Engraves the Owner's order of 2026-09-27 (Mission 240, mode 2a): the method of the starting interview, adapted from the smb-onboard skill of Anthropic's Small Business plugin (Apache-2.0, commit da38ec1), read only, no file copied. « ## Profil de départ » in USER.md, written only by sb profile --order from a profile order the welcome Pilot files in <workspace>/_orders/; three optional fields of the initiation order and of --ask, written under « ## Profil du projet » of the project's README.md; the mission-writing skill, the assistant and build-state.sh read both. The installer and its nine questions are unchanged."
created_at: "2026-09-27T21:30:59-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
amends:
  - "../templates/accueil-pilot-prompt-template.md"
  - "../templates/initiation-order-template.md"
  - "./DECISION-2026-09-17-000545-project-initiation-birth-certificate-embedded-mcp-pilot-prompt.md"
---

# DECISION — THE STARTING INTERVIEW: OWNER PROFILE AND PROJECT PROFILE

## Date

2026-09-27

## Status

`ARBITRATED`

## Measured problem

1. Second Brain knew the Owner by the installer's answers only: one sentence of activity (question 5), a list of AI tools (question 6), one sentence of what matters (question 7), written once into `USER.md` and never asked again. Nothing recorded the Owner's current headaches or the rhythm at which they want their work reviewed.
2. A project was known by its folder name and, at best, the one-sentence `Objet` of its initiation order, copied into the Vault's project sheet. The Pilot writing a Mission, and the assistant, had nothing to read about what the project must achieve or what blocks it.
3. The welcome Pilot writes only initiation orders; the Pilot never writes a canonical file without an Executor. A profile therefore needs its own order, and a tool that writes one section and nothing else.

## Decision

1. **The method, adapted.** The starting interview reads the existing profile first, shows it, and asks only what changed; without a profile it asks one question at a time, at least three, with a single follow-up when an answer is vague; it shows the full profile before anything is written and never replaces one silently; the profile lives under a fixed heading everyone reads; an older profile with missing fields is asked for those fields only; it offers three to five first steps and a review rhythm, once. The procedure is the `starting-interview` skill (`skills/starting-interview/SKILL.md`); the page that is authoritative for the Owner is `docs/how-to/starting-interview.md`.
2. **The Owner profile.** A fixed section `## Profil de départ` in the installed Vault's `USER.md`, five named fields, one per line — `Ce que je fais` and `Ce qui compte pour moi` (the installer's questions 5 and 7, taken up as they are, never removed from the installation), `Trois casse-têtes du moment`, `Rythme de revue`, `Outils du quotidien` (taken from question 6 when it was answered) — and a line `Mis à jour le`. The installer is unchanged: the section is born at the first profile order, not at installation.
3. **Who writes it.** The welcome Pilot reads the section first (its opening, and the E9 line of the session-start matrix), runs the interview, shows the profile, and with the Owner's agreement writes a profile order (`templates/profile-order-template.md`) to `<workspace>/_orders/PROFILE-<YYYY-MM-DD-HHMMSS>.md`, path announced before — the only folder it writes in. An Executor applies it with the verb `sb profile --order <file>` (`tools/starting_profile.py`): only the section is rewritten, a field the order leaves out keeps its value, the order must carry the Owner's dated authorization, the distributed skeleton (`status: template`) is refused, and the order is moved to `<workspace>/_archive/orders/`, never deleted. `sb profile` alone shows the section and its missing fields.
4. **The update keeps it.** `second-brain update` keeps the participant's `USER.md` byte for byte and appends only what the skeleton adds and the participant lacks (Mission 230); a `## Profil de départ` the participant has is never duplicated nor replaced. `tests/test-update-user-profile-merge.sh` proves it.
5. **The project profile.** The initiation order carries three optional fields, in French like the others — `Résultat attendu`, `Blocage actuel`, `Rythme de revue` — read by `tools/project-bootstrap.sh --order` by their exact name; `sb new --ask` and `sb adopt --ask` ask them in the terminal, one at a time, Enter leaving one empty. The welcome Pilot (E9) and the Pilot of a project preparing an adoption (E8) ask them one at a time before proposing the order. At least one answer is written under a fixed section `## Profil du projet` of the project's `README.md`; none, nothing is written. `tools/build-state.sh` copies that section into the state sheet. A project without it stays conforming: neither `project-bootstrap.sh identity --check` nor `tools/check-project-conformity.sh` requires it.
6. **Why `README.md`.** It is a source file, written once at creation and never regenerated; it is already the project's identity and entry point (the project sheet's `entry_point`), part of the seven-function skeleton the conformity check requires, and the first file a human or an agent opens. The state files are generated (`<project>/state/STATE.md`, `<project>/state/DIGEST.md`, `<project>/state/PILOT-PROMPT.md`) or append-only (`<project>/state/journal.md`); the Vault's project sheet lives outside the project. At adoption, an existing `README.md` gains the section (an existing section is kept as it is); a folder without one gets a README carrying its title and the section.
7. **The transmission.** The `mission-writing` skill reads both sections before drafting a Mission and says so in one line of its procedure; the assistant reads both headings; its three forms are regenerated by their tools.
8. **The source, and what is left out.** The method comes from the skill `smb-onboard` of the Small Business plugin published by Anthropic under the Apache License 2.0, snapshot `small-business-da38ec1` (commit `da38ec1`), read only in the workspace's archive. Nothing of it is installed, copied or quoted at length: the skill, the tool and the pages are written here from the method, and the skill names its source. Left out: the connectors and their setup, the recipes run to prove value, the brand and output-format capture, the Cowork session memory, the voice profile, the welcome page.

Owner's order, verbatim (Mission 240, prompt of 2026-09-27, mode 2a, execution Note 212000 of the workshop): « Une Décision dans decisions/ grave la méthode, la mention de la source Apache-2.0 avec son commit da38ec1, et ce qu'on a écarté. »

## Reason

A profile written once at installation ages the day after; a profile asked again from scratch at every session wears the Owner out. Reading first and asking only the difference keeps it alive at the cost of one question. Routing the write through an order keeps the charter whole: the Pilot proposes and files only in `_orders/`, the Owner dates, the Executor applies with a tool that can touch one section and nothing else. The project profile lives where every reader already looks — the README — so no new file, no new guardian and no new requirement on existing projects are needed.

## Impact

- New: `skills/starting-interview/SKILL.md`, `tools/starting_profile.py`, `templates/profile-order-template.md`, `docs/how-to/starting-interview.md`, the verb `profile` in `tools/sb/verbs.json` (help in the three catalogues, the plugin, `docs/reference/commands.md` and `docs/COMMANDS-CARD.md` regenerated).
- Amended: `templates/accueil-pilot-prompt-template.md` (the block now reads the profile first and may file a profile order — the Owner pastes it again once), `templates/initiation-order-template.md` (three optional fields), `tools/project-bootstrap.sh` (the three fields, `--ask`, the README section), `tools/build-state.sh` (the section copied), `skills/session-start/SKILL.md` (E3, E8, E9), `skills/mission-writing/SKILL.md`, `assistant/ASSISTANT.md`.
- Unchanged: `install.ps1`, `install.sh`, `tools/questionnaire.ps1` and the nine questions; the update script behind `second-brain update`, named here in words (its profile merge already keeps the section).
- Tests: `tests/test-starting-profile.sh`; `tests/test-update-user-profile-merge.sh` extended.

## Important alternatives

- Writing the section at installation: rejected, the installer and its questions are out of reach of this order.
- A section in the distributed `USER.md` skeleton: rejected, the installer rewrites that file whole, so a fresh installation would lack it while an updated one would carry an empty copy; the section is born, for everyone, at the first profile order.
- Letting the welcome Pilot write `USER.md` through the MCP server: rejected, the Pilot writes only its own new artefacts, never a canonical file.
- A separate profile file at the root of the project: rejected, a new root file every reader would have to learn, where the README is already read.
- Installing or copying the Small Business skill: rejected by the order; the connectors, recipes and memory it relies on do not exist here.

## Human gate

- Validation: granted
- Reference: the Owner's order of Mission 240 (2026-09-27, mode 2a), quoted under "Decision"; the go-ahead on criterion `R3-doctrine` is the order's own words, quoted in the Note (to be ratified, report of Mission 240).

## Linked artefacts

- Mission 240, its Note and its report (workshop history, not distributed).

## Liens

- `see also` — [The starting-interview skill](../skills/starting-interview/SKILL.md)
- `see also` — [Template — profile order](../templates/profile-order-template.md)
- `amends` — [Template — welcome Pilot](../templates/accueil-pilot-prompt-template.md)
- `amends` — [Template — initiation order](../templates/initiation-order-template.md)
- `amends` — [Decision — Project initiation and adoption, birth certificate](./DECISION-2026-09-17-000545-project-initiation-birth-certificate-embedded-mcp-pilot-prompt.md)
- `see also` — [Decision — Two relay modes](./DECISION-2026-09-23-012500-two-relay-modes-owner-prompt-traced-by-note.md)
- `see also` — [Rule — The sb command surface](../rules/RULES-2026-09-26-200933-sb-command-surface.md)
