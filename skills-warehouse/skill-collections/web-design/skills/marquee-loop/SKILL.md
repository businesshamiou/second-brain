---
name: marquee-loop
description: "Apply seamless infinite marquee loops using duplicated items."
license: MIT
compatibility: "Runtime-agnostic web design workflow; named framework or provider dependencies remain explicit when intrinsic."
metadata:
  upstream-repo: https://github.com/MengTo/Skills/tree/321c769739b823de5eb94eb3a52aa1974fe783a2/agent-skills/web-design/marquee-loop
  upstream-license-evidence: https://github.com/MengTo/Skills/blob/321c769739b823de5eb94eb3a52aa1974fe783a2/LICENSE
  upstream-commit: 321c769739b823de5eb94eb3a52aa1974fe783a2
  original-skill-sha256: 851e6883dbfa4786d56c343f0216f98a5fb692d6083e51e5402569f7bc9961f6
  front-matter-normalization: license, compatibility, and provenance metadata added
---

# Marquee Skill

## Use When
- A design needs a seamless infinite loop for logos, testimonials, screenshots, tags, or short feature chips.

## Workflow
1. Duplicate the item sequence so the end and beginning match perfectly.
2. Animate the track with a linear transform from 0 to -50%.
3. Keep item widths stable to prevent jumps during the loop.
4. Mask or fade the edges when the marquee enters or exits a section.
5. Pause or slow the marquee on hover only when interaction is useful.
6. Respect prefers-reduced-motion with a static wrap or very slow movement.

## Guardrails
- Do not animate unique content that users must read carefully.
- Do not use large CPU-heavy shadows or filters on every moving item.
