---
name: sb
description: "Second Brain commands: a message starting with `sb ` (sb help, sb status, sb open…) is one. Run `sb <verb>` in the shell, then apply its card."
disable-model-invocation: true
license: "MIT"
metadata:
  vault-implements: "rules/RULES-2026-09-26-200933-sb-command-surface.md"
  vault-validated: "2026-09-26T20:09:33-04:00"
---

The single router of the `sb` command for agents that load skills (Codex: `$sb <verb>`; Claude Code: `/sb <verb>`, next to the plugin's `/sb:<verb>`). One skill for all the verbs, because the list of skills Codex loads first is capped at 8,000 characters ([rule on the sb command surface](../../rules/RULES-2026-09-26-200933-sb-command-surface.md) §8).

## When it applies

A message whose first word is `sb`, followed by a verb: `sb help`, `sb status`, `sb open`, `sb run 236`… The verbs, by group: sessions `open close handoff status help`; projects `new adopt list pilot-prompt`; work `mission run relay push search`; maintenance `doctor clean update install uninstall add-skill`; Owner only `publish`. A former phrasing (« ouvre la session », « écris la Mission », « wrap »…) leads to the same verb; `sb help <verb>` lists them.

## What you do

1. **Run it.** In the shell: `sb <verb> <arguments>`. If `sb` is not on the `PATH`, run `bash <Vault>/tools/sb/bin/sb <verb> <arguments>`, the Vault being the folder the `VAULT-ROOT.md` marker names, found walking up from the current folder.
2. **Show its output as it is.** Exit code 3 means wrong place: say where the verb runs (the output names it) and stop. Exit code 2: an unknown verb or a wrong argument; show `sb help`. Exit code 1: the underlying tool refused; report its message, never work around it. Exit code 4: an Owner-only verb.
3. **Apply the card** of the verb: the section `### sb <verb>` of [the command reference](../../docs/reference/commands.md), line « Card ». A verb of nature *tool* is done once its output is shown; a verb of nature *agent* (`close`, `handoff`, `mission`, `run`) or *tool+agent* (`open`, `search`) continues with the skill its card names.

## Without a shell

You are the Pilot, or any agent with no shell. Apply the card of a verb marked « Pilot: yes » (`help`, `status`, `list`, `pilot-prompt`, `mission`, `relay`) by reading the files it names. For any other verb, answer: « this verb needs a shell: type it in an Executor window », and stop.

## What this skill never does

It adds no rule of its own: `sb` measures and relays, the role charter still decides who does what. No push unless the Owner delegated it in this window, no deletion, no model call.

## Liens

- `applies` — [Rule — The sb command surface](../../rules/RULES-2026-09-26-200933-sb-command-surface.md)
- `see also` — [Commands](../../docs/reference/commands.md)
- `see also` — [Command card](../../docs/COMMANDS-CARD.md)
