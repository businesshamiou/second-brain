# Claude Code adapter

Claude Code can preserve explicit-only invocation with this optional `SKILL.md` frontmatter extension:

```yaml
disable-model-invocation: true
```

Omit that field for model-discoverable Skills. Keep the workflow body capability-oriented: the flag controls discovery, not how the work is performed. Runtime commands such as slash invocation belong to user documentation, not to the canonical workflow.

