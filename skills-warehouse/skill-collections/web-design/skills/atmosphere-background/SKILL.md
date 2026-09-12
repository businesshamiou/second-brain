---
name: atmosphere-background
description: "Create a dark atmospheric background with drifting vertical light folds, screen-blended glow, and a concentrated luminous corner or lower-edge bloom."
license: MIT
compatibility: "Runtime-agnostic web design workflow; named framework or provider dependencies remain explicit when intrinsic."
metadata:
  upstream-repo: https://github.com/MengTo/Skills/tree/321c769739b823de5eb94eb3a52aa1974fe783a2/agent-skills/web-design/atmosphere-background
  upstream-license-evidence: https://github.com/MengTo/Skills/blob/321c769739b823de5eb94eb3a52aa1974fe783a2/LICENSE
  upstream-commit: 321c769739b823de5eb94eb3a52aa1974fe783a2
  original-skill-sha256: 62f5457d154df9226d1dd8b79eaded920b1982c47f8b7ba99db16ceda13fbb3a
  front-matter-normalization: license, compatibility, and provenance metadata added
---

# Atmosphere Background Skill

## Use When
- Create a dark atmospheric background with drifting vertical light folds, screen-blended glow, and a concentrated luminous corner or lower-edge bloom.

## Workflow

## Scope
- Apply this only to the immersive background layer, not to the full page layout, typography, or unrelated WebGL/particle systems.
- Use it when the design needs a moody atmospheric backdrop with fluid light curtains or folds instead of geometric grids, blobs, or literal illustrations.

## Visual target
- Create a deep near-black background with soft vertical light folds drifting across the frame like illuminated fabric, fog sheets, or light curtains.
- Build the glow from multiple overlapping vertical bands so the background feels layered and spatial rather than flat.
- Let brightness accumulate more strongly toward one area, especially the lower right or lower edge, so the scene has a cinematic focal glow instead of uniform brightness.
- Keep the palette restrained: dark navy or charcoal base, then derive the glow from the design's primary color or strongest accent color. If no clear brand color exists, a cool cyan-blue atmosphere is acceptable.

## Implementation guidance
- Prefer canvas or shader-driven rendering for this effect instead of static CSS gradients when motion is required.
- Use multiple tall overlapping bands or folds with slow sine-wave drift so the structure reads as moving atmospheric light rather than hard columns.
- Use screen or additive-style blending so the overlapping folds brighten naturally where they cross.
- Shape each fold with vertical gradients that fade at the top and intensify toward the bottom or focal corner.
- Add a subtle radial glow overlay near the focal edge or corner to reinforce depth and the main luminous area.
- Motion should stay slow and meditative: gentle drift, slight intensity modulation, no noisy flicker or rapid pulsing.

## Tuning knobs
- Fold count: add or reduce the number of vertical folds depending on how dense the atmosphere should feel.
- Drift: control horizontal sway amplitude and speed to keep motion calm.
- Brightness focus: place the strongest glow near a corner, edge, or lower quadrant instead of spreading it evenly across the whole frame.
- Color: tint the folds with the active design accent while preserving a dark, premium base.
- Softness: adjust overlap width, gradient falloff, and post-glow strength so the background feels luminous but not washed out.

## Avoid
- Flat multi-stop gradients with no layered fold structure.
- Loud rainbow color transitions or bright full-frame glow that competes with foreground content.
- Hardcoded cyan if the design clearly uses another primary color.
- Fast turbulence, noisy particle motion, or obvious repeating patterns that break the calm atmospheric look.
