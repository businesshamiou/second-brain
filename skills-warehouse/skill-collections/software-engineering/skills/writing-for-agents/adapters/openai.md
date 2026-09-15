# OpenAI and Codex adapter

OpenAI/Codex packaging can preserve explicit-only invocation in `agents/openai.yaml`:

```yaml
policy:
  allow_implicit_invocation: false
```

Omit the policy for normal model discovery. Keep UI metadata such as `display_name` and `short_description` aligned with `SKILL.md`, but do not make the canonical workflow depend on `agents/openai.yaml` being loaded. Other runtimes may safely ignore this adapter metadata.

