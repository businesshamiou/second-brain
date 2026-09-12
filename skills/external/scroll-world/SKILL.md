---
name: scroll-world
description: "Build a landing page where scrolling scrubs a camera flight through a branded world. Use for diorama journeys, multi-scene worlds, scroll cinematics, or portable canvas/video experiences."
license: "MIT"
metadata:
  upstream-repo: "https://github.com/oso95/scroll-world/tree/71cc36d3bb150248ae36a2c552f9cbf88802a79c"
  upstream-license-evidence: "https://github.com/oso95/scroll-world/blob/71cc36d3bb150248ae36a2c552f9cbf88802a79c/LICENSE"
  vault-source: "affiliate-pro-skills-full.zip"
  vault-source-sha256: "8d4a56240ccb587b4b70fec27f76329444ec254d3dce8b64e4fd912bb1588acb"
  vault-body-sha256: "31c07274f237acc8063b0472b5aeb7478913c757aeecec8bbdca1b73e5bdd4e3"
  vault-entered: "2026-09-01"
---

# Scroll World

Create a landing page where scroll position drives a pre-rendered camera journey through multiple connected scenes. The invariant is visual continuity: every junction begins from the literal rendered endpoint of the preceding clip.

The Skill is LLM- and runtime-agnostic. It needs only capabilities appropriate to the chosen workflow: image generation, a video engine that can pin start and end frames, local file operations, and media inspection. Provider examples in `references/pipeline.md` are optional adapters, not mandatory defaults.

## 1. Define the world

Ask only for information that cannot be inferred safely:

- subject, audience, brand name, palette, tone, and art direction;
- ordered journey of roughly 5–7 scenes;
- camera personality: expressive fly-through, continuous walkthrough, or locked isometric glide;
- desktop only or a separately composed portrait/mobile chain;
- destination format and whether deployment is in scope.

For each scene, capture the visual subject, eyebrow, headline, short body, and optional tags. Reuse one style preamble verbatim across every generation. Read `references/prompts.md` for the intake and prompt grammar.

## 2. Select capabilities and approve cost

Inspect available image and video capabilities without assuming a provider. The video engine must support start-image conditioning for every clip and end-image conditioning wherever a connector must land on an exact target. If it cannot demonstrate both, use a single-take fallback or select another engine; do not promise seamless chaining.

Before any paid or external generation:

1. state the selected provider/capability and why it fits;
2. verify its current schema, model availability, pricing, balance, and content rules;
3. calculate the image and clip count, including mobile and reroll headroom;
4. obtain explicit approval for the spend and external data transfer;
5. run one still and one junction preflight before the full batch.

Never treat dated prices in a reference as current. Never mix image or video models mid-chain without testing the first cross-model seam and obtaining approval.

## 3. Generate cohesive stills

Create one still per scene with the same style preamble, palette, lighting, angle rules, and aspect ratio. Review the full set before generating video. Regenerate outliers rather than allowing style drift to compound.

Optional background knockout is available in `references/knockout.py`. Preserve full-bleed stills when transparency would damage the art direction. Stills also serve as posters and loading fallbacks.

## 4. Build the seamless chain

Read `references/pipeline.md` before rendering. The non-negotiable rules are:

- use one camera grammar and one video model for the chain when possible;
- extract the literal last frame of each rendered clip;
- use that frame as the next clip's start image;
- pin connectors to both their real start and intended end frame;
- render a cheap preflight junction before committing the batch;
- resume from completed files instead of regenerating them;
- keep audio off unless the user explicitly requests it.

Parallel rendering is optional. A sequential workflow is always valid and is required whenever the next clip depends on the previous clip's rendered endpoint.

## 5. Assemble and integrate

Use FFmpeg or an equivalent media capability to normalize clips, remove duplicate junction frames, and encode compatible desktop/mobile variants. Wire the result with `references/scrub-engine.js` and `references/index-template.html`; both are framework-independent resources that may be adapted to the target project.

Do not scrub by repeatedly seeking a large video when a decoded frame sequence or preloaded clip chain is more reliable for the target. Respect `prefers-reduced-motion`, provide posters/fallbacks, cap memory, and avoid mobile center-crop unless the user explicitly accepts it as a stopgap.

## 6. Validate

Do not declare completion until all applicable checks pass:

- exact frame continuity at every junction, with side-by-side inspection where metrics are ambiguous;
- no unintended cuts, teleports, freezes, grade changes, or direction reversals inside clips;
- desktop and mobile behavior at representative viewports;
- reduced-motion and loading fallback behavior;
- frame count, payload size, and scroll mapping;
- readable page copy and accessible controls;
- current output files present at the reported paths.

Deployment is a separate opt-in action. Never publish, buy credits, install a provider tool, or transmit private brand assets without authorization.
