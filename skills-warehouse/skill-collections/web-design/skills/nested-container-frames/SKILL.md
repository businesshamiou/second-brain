---
name: nested-container-frames
description: "Create a container-in-container layout system using nested frames. Use an outer centered container with visible vertical boundary lines and corner markers. Inside, place inner containers inset..."
license: MIT
compatibility: "Runtime-agnostic web design workflow; named framework or provider dependencies remain explicit when intrinsic."
metadata:
  upstream-repo: https://github.com/MengTo/Skills/tree/321c769739b823de5eb94eb3a52aa1974fe783a2/agent-skills/web-design/nested-container-frames
  upstream-license-evidence: https://github.com/MengTo/Skills/blob/321c769739b823de5eb94eb3a52aa1974fe783a2/LICENSE
  upstream-commit: 321c769739b823de5eb94eb3a52aa1974fe783a2
  original-skill-sha256: 63ee2b26954de4d4ac833afd80010c188aa6d6effd4f22a9b7c115f39d343a2f
  front-matter-normalization: description shortened to 200 characters
---

# Nested Container Frames Skill

## Use When
- A layout needs a container-in-container system with visible outer bounds, inset inner frames, and layered page structure.

## Workflow
1. Define an outer centered container that controls the global page width.
2. Add visible vertical boundary lines and small corner markers to establish the frame.
3. Place inner containers inset from the outer edges using consistent padding.
4. Give each inner level its own background, border, radius, and spacing rhythm.
5. Use the frame hierarchy to separate hero, feature, proof, and CTA modules without adding heavy cards.

## Guardrails
- Do not nest cards inside cards until the layout feels boxed in.
- Do not let frame lines overpower content readability.
