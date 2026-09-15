# Skill mechanics

The skill-specific branch of [`writing-for-agents`](SKILL.md): what changes when the document is a skill (frontmatter, the invocation choice, and router skills). Everything else about writing it is the universal reference in `SKILL.md`.

## Invocation

Two intent-level choices trade the two loads. Their exact metadata is runtime-specific, so keep the intent canonical here and use the relevant adapter only when packaging for a runtime:

- A **model-discoverable** Skill exposes a discriminating `description` so a runtime that indexes Skills can select it automatically and other workflows can reference it. The human can still invoke it explicitly. The description is the Skill's top-level context pointer: permanent context load in exchange for discoverability.
- An **explicit-only** Skill is intended to run only when a human selects it. It spends cognitive load instead of automatic-discovery load. Keep its description short and human-facing, and express the explicit-only policy using the runtime's supported metadata.

Pick model discovery only when the agent must reach the Skill on its own or another workflow must select it. If it only ever fires by hand, prefer explicit-only invocation. When the runtime cannot enforce the chosen mode, preserve the workflow, state the limitation in packaging metadata, and never invent an unsupported flag.

For exact mappings, read only the relevant adapter:

- [Generic runtimes](adapters/generic.md)
- [Claude Code](adapters/claude.md)
- [OpenAI/Codex packaging](adapters/openai.md)

Shared reference that two explicit-only Skills both need should live in neither. Put it in a plain reference file that both can reach without one Skill having to invoke the other.

## Splitting by invocation

The invocation cut of splitting (the sequence cut lives in `SKILL.md`): split off a model-discoverable Skill when you have a distinct leading word that should trigger it on its own, or another workflow must reach it. You pay context load for the new discoverable description, so that independent reach has to be worth it.

## Router skills

When explicit-only Skills multiply past what you can remember, that piled-up cognitive load is cured by a **router Skill**: one explicit-only Skill that names the others and when to reach for each, so the human has one Skill to remember instead of many. A runtime may let the router invoke them directly, merely recommend them, or provide no Skill invocation API. Write the router in terms of applying the named workflow and let the runtime adapter decide the mechanism.
