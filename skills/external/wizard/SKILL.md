---
name: wizard
description: "Generate an interactive Bash wizard for steps only a human can perform. Use for infrastructure, credentials, third-party dashboards, migrations, or cutovers; not for actions the agent can do itself."
license: "MIT"
metadata:
  upstream-repo: "https://github.com/mattpocock/skills/tree/6654f6b60cd9d5be8b54c6fafe44346dabeb3b76"
  upstream-license-evidence: "https://github.com/mattpocock/skills/blob/6654f6b60cd9d5be8b54c6fafe44346dabeb3b76/LICENSE"
  vault-source: "affiliate-pro-skills-full.zip"
  vault-source-sha256: "8d4a56240ccb587b4b70fec27f76329444ec254d3dce8b64e4fd912bb1588acb"
  vault-body-sha256: "b8411869483f53a768b1c4bcfe5d2cbdb39966f044b474e9b8fc7acf4b147018"
  vault-entered: "2026-09-01"
---

# Wizard

A **wizard** is a bash script that walks a human, step by step, through a manual procedure that's tedious to do by hand and tedious to re-explain to an AI every time. It opens each URL when the operating system supports that capability, says exactly what to click and copy, captures the values, writes them where they belong (`.env`, a configured secret store, or another explicit destination), confirms at every stage, and shows how many stages are left. It might configure third-party services, run a one-off migration, or move the project from one state to another.

The delightful UX is already solved by [template.sh](template.sh): stage-by-stage progress, confirmation gates, cross-platform URL opening with a manual fallback, hidden secret entry, idempotent `.env` upserts, optional GitHub Actions secret/variable helpers, and a closing summary. **Your job is only to scope the procedure and author its stages.** The library above the `STAGES` marker is identical in every wizard; that consistency is the point: never hand-edit it.

A wizard is ephemeral by default: built for one run, saved to a scratch or `scripts/` path, deleted when the job's done. Commit it only when the user wants a repeatable setup path that should live in the repo.

## Process

### 1. Scope the procedure

Work out every manual step the human must take and every value that gets captured along the way. Read the repo first, don't ask cold:

- For setup: `.env`, `.env.example`, `.env.*`, `README`, `docker-compose*`, framework config, and the repository's CI configuration. Identify the actual CI provider and every referenced secret or variable; do not assume GitHub Actions.
- For a migration or transition: the current state, the target state, and the irreversible actions between them.

Then show the user the ordered list of stages and the values each produces, and confirm: they may add, drop, or reorder.

**Done when:** every stage is named in order, and for each captured value you know (a) where the human gets it, (b) where it is written (`.env`, the configured CI secret store, both, another destination, or nowhere), and (c) whether it is secret or public.

### 2. Map each stage's journey

For each stage, write the precise path a human follows: which URL to open, what to do there, where a value is shown, which variable it fills: e.g. "Dashboard → Developers → API keys → Reveal test key → copy". Where you don't actually know the current UI or the exact command, say so and ask the user or check the docs: never invent steps that may not exist.

**Done when:** every stage traces to concrete instructions a stranger could follow.

### 3. Author the wizard

Copy `template.sh` to the target path. Replace the example stage with one `stage` per step, in dependency order. Use the portable library helpers: `stage`, `say`/`step`, `open_url`, `ask`/`ask_secret`, `write_env`, and `pause`/`confirm`. Use `set_github_secret` or `set_github_var` only when GitHub Actions is the configured CI provider. For another provider, author the documented provider command when it is available or give the human an explicit manual step; do not rename a GitHub helper as if it were generic. Set `TOTAL_STAGES` to the number of stages you wrote.

Hold the bar the template sets: open the URL before asking for its value, use `ask_secret` for anything secret, `write_env` every locally persisted value, write to a CI secret store only when the project actually uses it, and `confirm` before any irreversible action. Each `stage` clears the screen so only the current step is visible: keep a stage to one focused task so nothing the human needs scrolls away. Don't touch the library above the marker.

### 4. Verify and hand off

- `bash -n <script>`; run `shellcheck` if available.
- `chmod +x <script>`.
- Don't run it end-to-end yourself: it may open browsers and blocks on human input. Trace it statically instead: every value from step 1 is captured and lands where step 1 said, and every CI secret name exactly matches the configured CI references.
- Tell the user how to run it. If it's a repeatable setup path, commit it and link it from the README so the next person runs the script instead of asking an AI.
