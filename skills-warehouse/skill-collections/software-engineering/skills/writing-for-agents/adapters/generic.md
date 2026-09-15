# Generic runtime adapter

Use this adapter when a runtime can interpret `SKILL.md` but has no documented invocation-policy metadata.

- Keep `name` and `description` in YAML frontmatter.
- Treat the description as the discovery pointer when the runtime indexes Skills.
- For explicit-only intent, document that intent in the package or UI. Do not invent a frontmatter flag.
- If the runtime cannot prevent automatic selection, report the limitation; the Skill workflow remains usable when selected manually.
- Refer to other Skills by canonical name and apply their workflow directly when the runtime has no Skill invocation API.

