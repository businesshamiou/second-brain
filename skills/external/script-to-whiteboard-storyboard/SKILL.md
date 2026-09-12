---
name: script-to-whiteboard-storyboard
description: "Turn a script, article, lesson, or outline into a consistent whiteboard storyboard with one visual per idea. Use for visual metaphors, explainer flows, mascots, prompts, manifests, or review pages."
license: "NOASSERTION"
metadata:
  upstream-repo: "https://github.com/Samin12/script-to-whiteboard-storyboard/tree/c4927de34c710771e9bf5bf86d700aa223261d9d"
  upstream-license-evidence: "Aucun fichier LICENSE applicable et aucun champ license dans le SKILL.md amont n'ont ete trouves."
  vault-source: "affiliate-pro-skills-full.zip"
  vault-source-sha256: "8d4a56240ccb587b4b70fec27f76329444ec254d3dce8b64e4fd912bb1588acb"
  vault-body-sha256: "b063cc244fef6489c464fd68bdd41f3d226ae15bc5703f7ad4d9ce4ec2933220"
  vault-entered: "2026-09-01"
---

# Script to Whiteboard Storyboard

Convert prose into a complete visual storyboard while preserving the author's meaning. The workflow is independent of any particular LLM or image provider.

## Workflow

1. Read the complete input before segmenting it.
2. Locate supplied style and mascot references. If none are supplied, use `assets/style-reference.png` and `assets/mascot-reference.png`.
3. Segment the script into atomic visual beats using `references/prompt-system.md`.
4. Classify each beat with one mode from `references/visual-grammar.md`.
5. Write a concrete direction and a self-contained generation prompt for every beat.
6. Create `storyboard.json` using `references/manifest-schema.md`.
7. Validate the manifest with `scripts/validate-storyboard.mjs`.
8. If image files were requested, generate one representative sample and obtain approval before a paid or large batch unless the user explicitly approved the full batch.
9. Generate the remaining images with an available image-generation capability or a user-selected provider adapter.
10. Build `review.html` with `scripts/build-review.mjs`, run `references/qa-checklist.md`, and present the review through an available file or browser preview.

Do not stop at prompts when the user requested images. Do not claim completion until every requested file exists and the review artifact can be opened.

## Segment the script

Create a beat whenever the speaker introduces a distinct claim, example, contrast, step, list item, transformation, or call to action. Keep exact excerpts; never silently rewrite the source.

Prefer one strong idea per frame. A beat is usually 8–30 spoken words, but meaning outranks word count. Give every beat:

- a stable sequential ID such as `S001`;
- the exact script excerpt;
- a short on-image title, usually 2–7 words;
- one visual mode;
- a concrete scene direction;
- only essential labels;
- a complete generation prompt.

## Direct the image

Load `references/prompt-system.md` and `references/visual-grammar.md` before authoring prompts. Translate abstract ideas into visible relationships such as movement, hierarchy, choice, obstacle, transformation, comparison, cause and effect, or destination.

Keep each frame readable at thumbnail size:

- one dominant focal idea and one obvious reading direction;
- no more than five major nodes;
- short, intentional labels only;
- arrows attached to exact causes and outcomes;
- generous white space;
- a mascot used as an actor, guide, witness, or scale cue rather than decoration.

Use exact quoted wording only for the title and essential labels. Require no other text in the generated image. Repeat the complete visual language in every prompt instead of relying on conversational memory.

## Generate safely

Before sending source text or reference images to an external service, confirm that the user permits that transfer when the material may be confidential. Before any paid batch, show the provider, model or capability, expected number of images, current quoted cost when available, and a resumable output location.

Choose generation in this order:

1. an available native image-generation capability that accepts the prompt and references;
2. a provider or API already selected and authorized by the user;
3. prompt-only handoff when no generation capability is available.

`scripts/generate-images.mjs` is an optional Higgsfield adapter, not a runtime requirement. It supports `--dry-run`, skips existing non-empty images, and can resume an interrupted batch. The validator and review builder are provider-neutral.

```bash
node scripts/validate-storyboard.mjs --manifest /absolute/path/storyboard.json
node scripts/generate-images.mjs --manifest /absolute/path/storyboard.json --output /absolute/path/images --style-ref /absolute/path/style.png --mascot-ref /absolute/path/mascot.png --concurrency 4
node scripts/build-review.mjs --manifest /absolute/path/storyboard.json --images /absolute/path/images --output /absolute/path/review.html
```

Preferred output:

```text
project/
├── storyboard.json
├── images/
│   ├── S001.png
│   └── S002.png
├── prompts/
│   ├── S001.txt
│   └── S002.txt
└── review.html
```

Never embed credentials, account paths, or private source material in the Skill or its outputs.
