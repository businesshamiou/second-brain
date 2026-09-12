---
name: excalidraw-automate
description: "Create, modify, explain, or review ExcalidrawAutomate scripts for Obsidian Excalidraw. Use for drawing creation, selected-element edits, custom data, dialogs, side panels, exports, or automation."
license: "AGPL-3.0-only"
metadata:
  upstream-repo: "https://github.com/zsviczian/obsidian-excalidraw-plugin/tree/052dfe3c12fbc66c8142368f6393673d7f5aecf6"
  upstream-license-evidence: "https://github.com/zsviczian/obsidian-excalidraw-plugin/blob/052dfe3c12fbc66c8142368f6393673d7f5aecf6/LICENSE"
  vault-source: "affiliate-pro-skills-full.zip"
  vault-source-sha256: "8d4a56240ccb587b4b70fec27f76329444ec254d3dce8b64e4fd912bb1588acb"
  vault-body-sha256: "311fb7d18ed73f0e340343ba35880845581813c8b90e978bbb80c5b870d7ddb6"
  vault-entered: "2026-09-01"
---

# ExcalidrawAutomate

Build safe, maintainable scripts against the ExcalidrawAutomate API exposed by the Obsidian Excalidraw plugin.

## Intrinsic environment

This Skill requires:

- Obsidian;
- the Excalidraw plugin for Obsidian;
- the plugin's ExcalidrawAutomate script environment and `ea` API.

Those product dependencies are intrinsic to the task. The instructions do not depend on a particular language model, agent protocol, shell, or orchestration runtime.

Do not claim that a script was executed or visually verified unless it actually ran in the user's compatible Obsidian environment.

## Required reading

Read [references/SECURITY.md](references/SECURITY.md) before adapting or running any example.

Then load only the references needed for the request:

- [references/api-usage-index.md](references/api-usage-index.md) for task-to-API routing and examples;
- [references/excalidraw-lib-functions.md](references/excalidraw-lib-functions.md) for Excalidraw library helpers;
- [references/startup-scripts.md](references/startup-scripts.md) for startup, autostart, event, and side-panel lifecycles;
- [references/type-definitions.md](references/type-definitions.md) when signatures, optional fields, or return types are ambiguous;
- `references/scripts/` for focused examples after locating the relevant API.

The references are snapshots from upstream commit `052dfe3c12fbc66c8142368f6393673d7f5aecf6`. Reconcile them with the user's installed plugin version when behavior or signatures differ.

## Workflow

### 1. Establish the execution context

Determine:

- whether the user wants a new script, an edit, an explanation, or a review;
- the current drawing, selected elements, vault paths, and files that may change;
- the installed Excalidraw plugin version when compatibility matters;
- whether network access, credentials, startup registration, or destructive changes are requested.

Ask for approval before any external transfer, credential use, autostart registration, bulk vault mutation, overwrite, or deletion that was not already explicit.

### 2. Find the narrowest applicable API

Search `references/api-usage-index.md` first. Open a focused example next. Consult the large type-definition reference only for unresolved details.

Prefer the `ea` wrapper API when it exposes the needed operation. Use `window.ExcalidrawLib` only for capabilities that are not available through `ea`, and guard their availability.

### 3. Plan a bounded transaction

State which drawing elements, files, or plugin registrations the script will read and change. For risky operations, provide a preview, dry-run mode, backup, or explicit target list before committing changes.

Keep paths vault-relative when the API expects vault paths. Validate that required files and active views exist before mutation.

### 4. Implement with the workbench model

Treat scene elements returned by the view as immutable snapshots. Use the ExcalidrawAutomate workbench for edits:

```js
ea.clear();
const ids = ea.getViewSelectedElements().map((element) => element.id);
if (ids.length === 0) {
  new Notice("Select at least one element.");
  return;
}

ea.copyViewElementsToEAforEditing(ids);
for (const element of ea.getElements()) {
  // Mutate only the workbench copy.
}
await ea.addElementsToView();
```

Use the exact selection or identifiers intended by the user. Avoid whole-scene or whole-vault operations when a narrower operation is possible.

### 5. Persist through supported APIs

Use the relevant ExcalidrawAutomate method instead of editing plugin internals. Common patterns include:

- `ea.addElementsToView()` to commit workbench changes;
- `ea.addAppendUpdateCustomData()` for element custom data;
- `ea.create()` or view-specific APIs for drawing creation and updates;
- `ea.getViewSelectedElements()` for explicit selection scope;
- `ea.openFileInNewOrAdjacentLeaf()` for supported drawing navigation.

Await asynchronous operations. Handle missing views, cancelled dialogs, empty selections, unavailable APIs, invalid paths, and partial failures.

### 6. Verify and hand off

Check syntax and reason through the failure paths without executing untrusted examples. When an Obsidian test environment is available, verify on a disposable drawing or backup and report exactly what was tested.

Deliver:

- the complete script or a focused patch;
- prerequisites and the target plugin version if known;
- installation and invocation steps inside Obsidian;
- affected files/elements and safety assumptions;
- a short manual verification checklist.

## API invariants

### Element identity and immutability

- Do not mutate elements returned directly by the live view.
- Copy targeted elements into the workbench, change the copies, then commit.
- Preserve IDs and relationships unless replacement is intentional.
- Re-read the scene after a commit when later logic depends on the new state.

### Styles

- `ea.style` supplies defaults for newly created elements.
- Modify existing workbench elements directly when changing their current style.
- Avoid global style changes unless the user asks for them.

### Custom data

Use the supported custom-data API so plugin metadata remains compatible. Namespaced keys reduce collisions with other scripts.

### Dialogs and cancellation

Use the plugin's dialog helpers as instances according to their documented API. Treat dismissal as a normal result and do not continue with guessed values.

### Startup scripts, side panels, and events

Registration changes are persistent behavior, not ordinary one-shot edits. Follow [references/startup-scripts.md](references/startup-scripts.md), avoid duplicate handlers, and provide teardown or unregister behavior. Never register autostart behavior without explicit user intent.

### Version checks

Distinguish the Obsidian version, Excalidraw plugin version, script bundle version, and Excalidraw library version. Compare the version that actually governs the API in question.

### Export

Choose SVG, PNG, or scene export based on the requested output. Make embedding, theme, padding, scale, and linked-file behavior explicit. Do not upload or publish exports unless requested.

## Example policy

Examples under `references/scripts/` are learning material, not trusted executable dependencies. Extract the smallest relevant pattern, review it against [references/SECURITY.md](references/SECURITY.md), adapt it to the current plugin version, and explain any sensitive behavior.

Do not reproduce source-maintenance or publishing steps unless the user explicitly asks to contribute to the upstream repository; that is a separate repository workflow, not part of operating ExcalidrawAutomate.
