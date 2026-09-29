---
type: decision
title: "The assistant reads the documentation map first and runs on the lightest model admitted"
created_at: "2026-09-23T23:27:20-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
amends: "../assistant/ASSISTANT.md"
---

# DECISION — THE ASSISTANT READS THE DOCUMENTATION MAP FIRST AND RUNS ON THE LIGHTEST MODEL ADMITTED

## Date

2026-09-23

## Status

`ARBITRATED`

## Decision

1. **A documentation map.** [`docs/MAP.md`](../docs/MAP.md) holds one table from a kind of question to the documentation page that answers it, then to the file to open only if that page does not answer. The table sits between two markers, `<!-- doc-map:start -->` and `<!-- doc-map:end -->`.
2. **Embedded, read first.** Both generators ([generate-assistant.ps1](../tools/generate-assistant.ps1) and [sb_installer_helper.py](../tools/sb_installer_helper.py) `render-assistant`) append that block to the body of [the assistant's identity](../assistant/ASSISTANT.md), so the Claude Code subagent, the Codex skill and the web package's `web-package/<slug>/INSTRUCTIONS.md` all carry it and read it without a tool call. The search order of the identity starts with the page the map names; the index of the closest folder, then the wide search, follow only if that page does not answer. A clone without the map, or a map without its markers, is refused (fail-closed).
3. **The lightest model admitted.** The Claude Code subagent's front matter carries `model: haiku`, the lightest value the subagent format accepts (Claude Code documentation, "Subagents": `model` accepts `sonnet`, `opus`, `haiku`, a full model ID or `inherit`). The Codex skill carries no model field: none is documented for Codex skills. The web package runs on whatever model the person's Project uses.
4. **The tool-call cap stays at 8.** It is a ceiling, not a target: with the map embedded, the usual path becomes the page the map names, then its source.

## Reason

The Owner, 2026-09-23 22:43 (voice dictation, words as received; « Bryan » = Brian, « volt » = Vault): « je veux une documentation complète qui parle, je veux que le projet du volt parle de lui même, d'accord, donc l'agent Bryan, il devrait être aussi accessible d'une façon intelligente, à moindre coût. » ["I want a complete documentation that speaks, I want the Vault project to speak for itself, right, so the agent Bryan should also be reachable in a smart way, at the lowest cost."]

Reading of the Pilot, told to the Owner before the Mission was filed (Mission 222, Context): "Brian intelligent at the lowest cost" means Brian first reads a map of the documentation, then the one useful page; its subagent runs on the lightest model the format allows; the web package carries the same map. The documentation it points to was written and verified against the code by the same Mission (phase 2).

## Impact

- `docs/MAP.md` is a source of the generators: a new documentation page is added to the map in the same commit, or the assistant does not know it.
- The generated forms of an installation receive the map and the model field at the next generation (installation, update mode, or rename).
- The assistant's real behaviour (does it read the named page, how many calls, how well does it answer on `haiku`) is not measured without a model call: it stays a hypothesis until the acceptance scenarios S7 and S8 run with the model CLIs.

## Important alternatives

- **Map as a sixth web-package file.** Rejected: the package's five-file ceiling was decided by the Owner earlier (see the comment of `$Script:WebPackageKnowledgeFiles` in the generator); embedding the map in the instructions costs no file and no tool call.
- **Map read by a tool call, not embedded.** Rejected: one call more for every question, the opposite of "at the lowest cost".
- **Lower the cap to 6.** Not taken: the cap is a ceiling tested by `tests/test-assistant-tool-call-cap.ps1`; the map lowers the usual cost without lowering the ceiling.
- **`model: inherit`.** Rejected: it follows the main conversation's model, often the heaviest.

## Human gate

- Validation: granted
- Reference: the Owner's words above (2026-09-23 22:43), quoted in the Gates of Mission 222 (workshop history, not distributed)

## Related artifacts

- Source or artifact: `docs/MAP.md`, `assistant/ASSISTANT.md`, `tools/generate-assistant.ps1`, `tools/sb_installer_helper.py`, `tests/test-assistant-doc-map.ps1`

## Liens

- `prescribed by` — [Context cycle V2](../rules/RULES-2026-08-17-111018-context-lifecycle-v2.md)
- `source` — [Documentation map](../docs/MAP.md)
- `amends` — [Assistant identity](../assistant/ASSISTANT.md) (search order: the documentation map first)
- `source` — [PowerShell assistant generator](../tools/generate-assistant.ps1)
- `source` — [Python assistant generator](../tools/sb_installer_helper.py)
- `see also` — [The assistant (documentation)](../docs/explanation/assistant.md)
- `see also` — Mission 222 — overnight publication readiness and documentation (workshop history, not distributed) (hors Vault)
