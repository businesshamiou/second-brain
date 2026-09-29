---
type: decision
title: "Language — recorded once in USER.md, rendered in each Pilot prompt, and a fixed sentence in the common prompt so that a Pilot speaks the Owner's language from its first line"
description: "Engraves the Owner arbitration of 2026-09-23 (D-B), as amended at 00:48: the installer writes language: in the front matter of USER.md; project-bootstrap.sh reads it and renders language: plus one sentence in each project's Pilot prompt, which the Executor regenerates; the common prompt carries one fixed, neutral sentence, never rendered per project; without a recorded language, the language of the Owner's messages, never English by default. No manual re-paste is asked of the Owner."
created_at: "2026-09-23T01:24:59-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
amends:
  - "../templates/session-opening-prompt-template.md"
---

# DECISION — LANGUAGE: RECORDED ONCE, RENDERED PER PROJECT, A FIXED SENTENCE IN THE COMMON PROMPT

## Date

2026-09-23

## Status

`ARBITRATED`

## Measured problem

On 2026-09-22 a Pilot session answered the Owner in English. `AGENTS.md` said "speak to the participant in the language of USER.md", but `USER.md` carried no language field — the installer wrote the answer only as a line of prose in its body — and `AGENTS.md` is not in the Pilot's opening chain. The common prompt, the only text a Pilot reads before any file, said nothing about language; the same evening the file channel fell silent, and a Pilot without files had nothing to go by. The project instruction files that `tools/project-bootstrap.sh` renders said "write in French" whatever the installation language.

## Decision

1. **Recorded once.** The installer writes `language: fr`, `en` or `es` in the front matter of `USER.md`; the skeleton carries the key, empty.
2. **Rendered per project.** `tools/project-bootstrap.sh` reads that key at the root of its Vault — failing it, the language its caller passes explicitly — and renders `language:` and one sentence, taken from the `i18n/` catalogue of that language, in each project's generated Pilot prompt (`<projet>/state/PILOT-PROMPT.md`). The Executor regenerates the Pilot prompts of existing projects (`tools/project-bootstrap.sh prompt`); the project instruction files it renders at birth say the same language.
3. **A fixed sentence in the common prompt**, neutral, never rendered per project, so the pasted text stays identical from one project to the next: "Speak to the Owner in the language they write in, from your first line; the PILOT-PROMPT names the language of the files you deposit." It acts before any reading, including when the file channel does not answer.
4. **What the language governs.** Agents speak to the Owner, and write the files they deposit **in a project**, in that language. Machine identifiers — file names, keys, commands, the journal labels `STATE:`, `OPEN:`, `CLOSE:` — stay in English. The Vault's own corpus stays in English (Decision "Corpus language: English, the participant keeps their language").
5. **Without a recorded language:** the language of the Owner's messages. Never English by default in silence.
6. **No re-paste.** No manual gesture is asked of the Owner: existing projects receive the language through their regenerated Pilot prompt; the fixed sentence holds for the Pilot windows opened with the common prompt from now on.

Owner's choices, verbatim: « USER.md → prompt + PILOT-PROMPT (Recommandé) » ["USER.md → prompt + PILOT-PROMPT (Recommended)"]; amended at 00:48: « j'utilise l'IA pour faire tes traitements, corriger tout ça automatiquement […] ne me demande pas ce genre de chose Quand tu me dis qu'on a des instructions et cetera, non, ça va être fait par un exécuteur lui-même. » ["I use the AI to do your processing, correct all that automatically […] don't ask me that kind of thing; when you tell me we have instructions and so on, no, it will be done by an executor itself."]

## Reason

The language must act before any file is read, and must not depend on a file the Pilot may never reach. A fixed sentence in the common prompt covers the first line and the silent channel; the recorded language in the Pilot prompt covers the files. Rendering a per-project line in the common prompt would have forced a re-paste in every existing Pilot window, which the Owner refused.

## Impact

- `USER.md` skeleton, `tools/sb_installer_helper.py`, `tools/questionnaire.ps1`: the `language:` key.
- `tools/project-bootstrap.sh`: reads the key, renders it in the Pilot prompt and in the project instruction files.
- `templates/session-opening-prompt-template.md`: the fixed sentence, and no new placeholder.
- `i18n/catalog.fr.json`, `catalog.en.json`, `catalog.es.json`: the Pilot prompt's language sentence.
- `AGENTS.md`, `CLAUDE.md`: the language line names the key and its default.

## Important alternatives

- A language line rendered per project inside the common prompt: rejected at 00:48, it requires a manual re-paste in every window.
- Default to English when nothing is recorded: rejected, it is exactly the measured defect.
- Translate the Vault's corpus: rejected, the corpus stays in English.

## Human gate

- Validation: granted
- Reference: Owner, Pilot session of 2026-09-23 at 00:4x (multiple-choice question) and 00:48 (amendment), quoted under "Decision"; recorded in Mission 218 (workshop history, not distributed).

## Linked artefacts

- Mission 218 and its entry audit (workshop history, not distributed).
- Decision "Corpus language: English, the participant keeps their language" (workshop history, not distributed).

## Liens

- `amends` — [Template — minimal opening prompt](../templates/session-opening-prompt-template.md)
- `see also` — [Decision — State sheet, one name, generated](./DECISION-2026-09-23-012458-state-sheet-one-name-generated-state-path.md)
- `see also` — [Decision — Project initiation and adoption, birth certificate](./DECISION-2026-09-17-000545-project-initiation-birth-certificate-embedded-mcp-pilot-prompt.md)
- `prescribed by` — [Context lifecycle V2](../rules/RULES-2026-08-17-111018-context-lifecycle-v2.md)
- `amended by` — [Decision — The Owner's go-ahead quoted in the Note; a local language file](./DECISION-2026-09-23-105507-owner-greenlight-in-note-and-local-language-file.md) (point 4: USER.local.yaml read before USER.md)
