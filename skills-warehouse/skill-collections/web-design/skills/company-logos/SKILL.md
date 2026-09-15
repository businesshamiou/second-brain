---
name: company-logos
description: "Use Iconify Simple Icons logos (64x64) instead of text logos."
license: MIT
compatibility: "Runtime-agnostic web design workflow; named framework or provider dependencies remain explicit when intrinsic."
metadata:
  upstream-repo: https://github.com/MengTo/Skills/tree/321c769739b823de5eb94eb3a52aa1974fe783a2/agent-skills/web-design/company-logos
  upstream-license-evidence: https://github.com/MengTo/Skills/blob/321c769739b823de5eb94eb3a52aa1974fe783a2/LICENSE
  upstream-commit: 321c769739b823de5eb94eb3a52aa1974fe783a2
  original-skill-sha256: 1fb7f4a753fbec72caa9c0d05bcc0ebeac84d21aed29dda2364f8060fd419ef9
  front-matter-normalization: license, compatibility, and provenance metadata added
---

# Company Logos Skill

## Use When
- A design needs recognizable brand marks without embedding custom SVG files or rendering company names as plain text.
- Logo rows, integrations grids, customer proof, partner lists, and tool badges need consistent icon treatment.

## Workflow
1. Use Iconify Simple Icons as the default source for brand logos.
2. Render each logo in a 64x64 visual box, then scale the inner SVG to the composition density.
3. Keep logos monochrome by default; use brand color only when the surrounding design needs recognition more than restraint.
4. Align logos to a shared baseline or center grid so rows feel intentional.
5. Add accessible labels when logos are interactive or communicate important proof.

## Guardrails
- Do not use typed company names as a replacement for logos unless no icon exists.
- Do not mix filled, outline, emoji, bitmap, and wordmark styles in one row.
- Do not hotlink random logo assets from search results.
