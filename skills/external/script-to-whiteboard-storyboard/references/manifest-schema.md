# Storyboard manifest

Store the plan as UTF-8 JSON:

```json
{
  "projectTitle": "Example tutorial",
  "source": "/absolute/path/script.txt",
  "style": {
    "aspectRatio": "16:9",
    "model": "gpt_image_2"
  },
  "beats": [
    {
      "id": "S001",
      "script": "The exact spoken excerpt.",
      "title": "THE CLEAR IDEA",
      "visualMode": "flow-3",
      "visualClaim": "The viewer understands the causal relationship.",
      "direction": "Three large nodes arranged left to right...",
      "labels": ["INPUT", "CHANGE", "RESULT"],
      "prompt": "Create one polished 16:9 whiteboard storyboard illustration..."
    }
  ]
}
```

Rules:

- IDs must be unique and sort in narrative order.
- `script` must preserve the source wording.
- `title`, `visualMode`, `visualClaim`, `direction`, and `prompt` are required.
- `labels` may be empty but must be an array.
- Image filenames use the beat ID exactly: `S001.png`.
