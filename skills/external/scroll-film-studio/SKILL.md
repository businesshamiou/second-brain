---
name: scroll-film-studio
description: "Create a cinematic scroll-driven website from a continuous generated film, with frame extraction, seam and motion gates, canvas scrubbing, responsive finishing, and visual verification."
license: "NOASSERTION"
metadata:
  upstream-repo: "archive locale Super website skill v2.zip, SHA-256 c818f30350afd90e9bce1b6ef180d4b85d6a4f2e5a3fd599045d65b7a8086ff7"
  upstream-license-evidence: "Aucun fichier de licence applicable et aucun champ license dans le SKILL.md source n'ont ete trouves. Les licences presentes dans package-lock.json concernent les dependances et ne prouvent pas la licence du Skill lui-meme."
  vault-source: "affiliate-pro-skills-full.zip"
  vault-source-sha256: "8d4a56240ccb587b4b70fec27f76329444ec254d3dce8b64e4fd912bb1588acb"
  vault-body-sha256: "7323283491fa638efb93168aa3f73890a038b163dac2a91933078f42c58f077e"
  vault-entered: "2026-09-01"
---

# Scroll Film Studio

Build a polished website around one continuous cinematic camera move. The film is pre-rendered, extracted into frames, and scrubbed on a canvas so scroll controls time without live video seeking.

This workflow is independent of any LLM or hosting runtime. Provider-specific scripts are optional adapters; the core requirements are pinned-frame image/video generation, local media tooling, a browser for verification, and user authorization for paid or external actions.

## 1. Establish the brief

Confirm:

- the brand, audience, offer, and desired outcome;
- whether the page uses an existing film or requires generation;
- the visual world, palette, typography, and one-sentence camera vector;
- the chapters/keyframes and the final payoff;
- desktop only or a native portrait/mobile film;
- local delivery or an explicitly authorized deployment target.

Treat the camera vector as a structural constraint. Every clip prompt must describe the journey from its start pin to its end pin and must not reverse direction unless a deliberate reversal is declared in the storyboard.

## 2. Choose a production lane

### Existing film

Inspect the opening, closing, continuity, duration, frame rate, resolution, and aspect ratio. Trim unrelated or static opening frames before extraction. Continue at assembly and finishing.

### Generated film

Read `references/playbook.md` before spending. Select an available engine only after verifying that its current API/schema honors both start and end pins. If a one-junction preflight shows that the engine merely reinterprets the pinned start, use the documented single-take fallback or select another engine.

Before generation, disclose the provider, expected calls, current quoted cost, data transferred, and reroll headroom. Obtain explicit approval. Never rely on the dated provider prices or model names in reference material without checking them at execution time.

## 3. Create the storyboard

Represent the film as ordered keyframes plus one motion prompt per transition. For N keyframes, require exactly N−1 clips. Every motion prompt must name the destination and preserve the declared direction.

Run `scripts/vector-check.py` before generation. It is provider-neutral and catches conflicting or missing motion vectors.

## 4. Generate and gate the chain

The chaining law is universal:

1. generate or supply the opening keyframe;
2. pin each clip to its intended far-end keyframe;
3. extract the literal last rendered frame;
4. use that exact file as the next clip's start pin;
5. verify the first junction before generating the rest;
6. resume from completed artifacts after interruptions.

`scripts/chain-step.sh` is an optional Higgsfield adapter. `scripts/kie-chain.py` is an optional Kie adapter. Neither provider is mandatory. Never run either adapter until credentials, cost, account-owned upload paths, and external data transfer are authorized.

Use `scripts/continuity-gate.sh` to locate suspicious motion and inspect flagged frames visually. Similarity scores are evidence, not an automatic substitute for judging a cut, teleport, freeze, or grade change.

## 5. Assemble the film and frames

Use `scripts/assemble.sh` or an equivalent FFmpeg pipeline to:

- remove the duplicate first frame from clips after the first;
- encode a compatible master with variable-frame-rate handling where appropriate;
- extract every frame at the native cadence;
- sample the final-frame seam color;
- record the exact frame count used by the scrub engine.

Do not reduce motion cadence by silently dropping frames. If payload is too large, reduce image width or quality with measured visual review.

## 6. Build and finish the page

Read `references/engine.md` for the canvas scrub engine and `references/finishing.md` for layout, chrome, mobile, and handoff details.

Required qualities:

- decoded-frame buffering rather than synchronous decode during paint;
- bounded memory and closed image bitmaps when variants switch;
- deterministic scroll-to-frame mapping with smoothing;
- `prefers-reduced-motion` fallback;
- readable chrome over both bright and dark footage;
- a mobile film composed for portrait when mobile is in scope;
- page copy that sells the offer instead of narrating the camera mechanic.

Run `scripts/copy-gate.js` on visitor-facing HTML. Use `scripts/shot.js` or `scripts/verify.js` for deterministic screenshots and jank checks after installing their declared local dependency. The `--no-sandbox` browser mode must remain opt-in and limited to an environment where the user accepts the security tradeoff.

## 7. Validate and deliver

Do not claim completion until:

- vector, junction, and continuity checks pass or every flagged exception is inspected and documented;
- the frame count matches the generated frame set;
- representative top, middle, chapter, seam, and final positions render correctly;
- desktop and mobile viewports pass when in scope;
- reduced-motion behavior works;
- no secrets, account paths, intermediate generations, or oversized source assets are included unintentionally;
- every requested deliverable exists at the reported path.

Deployment is separate and opt-in. Publish only to an account and destination the user explicitly selected.
