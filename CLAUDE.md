Before any action: determine your role. Read [the role charter](./rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md).

Files in this repository are written in English. Speak to the participant in the language that the `language:` field of USER.md records — without one, the language they write in, never English by default — and write the files you deposit in a project in that same language. When `USER.local.yaml` exists at the root of this repository (one line `language: <fr|en|es>`, local, never versioned nor distributed), the language it records is read before that field (Decisions 012459 and 105507).

The model's memory is never a source of state or of hypothesis: what has not been read in a file during the session is not known.
Without an active filesystem MCP server: ask the Owner for the files and produce nothing from memory.

A message that starts with `sb ` is a Second Brain command ([rule](./rules/RULES-2026-09-26-200933-sb-command-surface.md)): run `sb <verb>` (or `bash tools/sb/bin/sb <verb>` from this repository), then apply its card in [the command reference](./docs/reference/commands.md); without a shell, apply the card of a verb the reference marks « Pilot: yes », and answer that any other verb needs an Executor window.

For any work in `skills-warehouse/`: first read [`skills-warehouse/CLAUDE.md`](./skills-warehouse/CLAUDE.md) and [`skills-warehouse/AGENTS.md`](./skills-warehouse/AGENTS.md) — this subfolder follows its own conventions (T02, Mission 168).

## Liens

- `see also` — [Role charter and session determination](./rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)
- `see also` — [Rule — The sb command surface](./rules/RULES-2026-09-26-200933-sb-command-surface.md)
