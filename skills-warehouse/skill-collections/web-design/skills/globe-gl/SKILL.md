---
name: globe-gl
description: "Use when implementing globe.gl (Globe.GL) for 3D globe data visualization with WebGL/ThreeJS, including setup, data layers (points, arcs, polygons, labels), and integration patterns in plain HTML..."
license: MIT
compatibility: "Runtime-agnostic web design workflow; named framework or provider dependencies remain explicit when intrinsic."
metadata:
  upstream-repo: https://github.com/MengTo/Skills/tree/321c769739b823de5eb94eb3a52aa1974fe783a2/agent-skills/web-design/globe-gl
  upstream-license-evidence: https://github.com/MengTo/Skills/blob/321c769739b823de5eb94eb3a52aa1974fe783a2/LICENSE
  upstream-commit: 321c769739b823de5eb94eb3a52aa1974fe783a2
  original-skill-sha256: ddcc800b5130be8e2818e11f6e28abe6c366c5f73588d614b7aef98e04c0ea23
  front-matter-normalization: description shortened to 200 characters
---

# Globe.GL Skill

## Workflow
1. Confirm environment (plain HTML, framework, React bindings) and the data layers needed.
2. Provide a minimal quick-start snippet plus the layer-specific fields.
3. Add interactions or extra layers only if requested.
4. Call out container sizing and performance considerations.

## Quick start (ESM)
```html
<script type="module">
  import Globe from 'globe.gl';

  const myGlobe = new Globe(document.getElementById('globe'))
    .globeImageUrl(myImageUrl)
    .pointsData(myData);
</script>
```

## Quick start (script tag)
```html
<script src="//cdn.jsdelivr.net/npm/globe.gl"></script>
<script>
  const myGlobe = new Globe(document.getElementById('globe'))
    .globeImageUrl(myImageUrl)
    .pointsData(myData);
</script>
```

## Common layers to mention
- Points
- Arcs
- Polygons
- Paths
- Heatmaps and hex bins
- Labels or HTML elements
- 3D objects and custom layers

## Practical tips
- Size the container with CSS; the globe fills its parent element.
- Reduce point count or size for performance on mobile.
- Use a darker globe texture for neon-style data overlays.

## Questions to ask when specs are missing
- Which layers do you need (points, arcs, polygons, labels)?
- What should the globe size be on desktop vs mobile?
- Do you want drag/rotate interactions or a static globe?
- Is this plain HTML, React (`react-globe.gl`), or another framework?
