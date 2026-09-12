# Whiteboard prompt system

## 1. Find the visual claim

For each excerpt, finish this sentence privately: “The viewer must understand that ___.” That answer is the visual claim. Do not draw every noun in the sentence. Draw the relationship that proves the claim.

Examples:

| Spoken idea | Weak direction | Strong visual claim |
|---|---|---|
| The model can see images | Robot beside a photo | Image card enters the model's eye, then becomes usable design decisions |
| Cheap sites decorate a business | Random website mockup | Storefront covered in ornaments while the customer stands still |
| Expensive sites move visitors forward | Fancy laptop | Visitor follows a guided path from problem to clear CTA |
| One-million-token context | Huge number floating | Many project inputs enter one long memory ribbon without being dropped |

## 2. Choose a visual mode

Use the selection matrix in `visual-grammar.md`. The mode is a compositional decision, not a decorative tag.

## 3. Build the scene direction

Write one compact paragraph that names:

1. the main objects;
2. their position from left to right or center outward;
3. the action or relationship;
4. the mascot's role;
5. the exact labels that must appear.

Example:

> Three-stage left-to-right journey. On the left, a visitor is stuck behind a gray wall labeled “PROBLEM.” In the center, the orange mascot opens a pink gate labeled “WEBSITE.” On the right, the visitor reaches a bright yellow destination flag labeled “NEXT STEP.” Use one continuous curved arrow through all three stages.

## 4. Write the final prompt

Use this structure for every frame:

```text
Create one polished 16:9 whiteboard storyboard illustration.

MESSAGE
The viewer must immediately understand: [visual claim].

COMPOSITION
[Concrete scene direction with positions, scale, action, arrows, and mascot role.]

TEXT
Main handwritten title at the top: “[TITLE]”.
Include only these additional short labels: “[LABEL 1]”, “[LABEL 2]”.
Do not add any other words, pseudo-text, captions, or watermarks.

VISUAL LANGUAGE
Clean white paper canvas; loose black felt-marker outlines with slight human wobble; pale yellow highlights and numbered circles; restrained pink arrows and emphasis marks; faint cool-gray shadows; subtle paper texture; generous editorial spacing. Preserve the supplied orange low-poly mascot's blocky silhouette and proportions. Make the idea readable at thumbnail size.

AVOID
Photorealism, dark backgrounds, glossy UI, generic corporate vector style, dense diagrams, tiny text, decorative clutter, duplicate characters, broken arrows, random icons, and extra limbs.
```

Do not shorten the `VISUAL LANGUAGE` section during batch generation. Consistency comes from repeating constraints and attaching the same references.

## 5. Control text

Image models are strongest when text is scarce.

- Title: 2–7 words.
- Labels: 0–5 labels, preferably 1–3 words each.
- Never place the spoken script inside the image.
- Spell required text exactly and quote it in the prompt.
- When a concept needs more explanation, express it with objects and arrows.

## 6. Use the mascot intentionally

Assign one role per frame:

- **Actor:** performs the transformation.
- **Guide:** points toward the reading path.
- **Witness:** reacts to the result and adds emotion.
- **Obstacle:** represents the limiting behavior or old way.
- **Scale cue:** makes an abstract system feel large or small.

Vary pose and role while preserving identity. Avoid placing the mascot motionless in the same lower corner in every frame.

## 7. Keep a batch coherent

Before generation, compare adjacent prompts. Vary the metaphor and staging, not the style. Avoid repeating the same laptop, staircase, split-screen, or floating cards more than twice in ten frames.

Generate a sample containing people, arrows, labels, and the mascot. It exposes style and legibility failures better than a simple title card.
