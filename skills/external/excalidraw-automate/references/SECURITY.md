# Security boundary

The files in `references/scripts/` are upstream examples for study. They are not reviewed dependencies and must never be executed blindly.

## Default-deny behaviors

Unless the user explicitly requests the behavior and approves its concrete scope, generated or adapted scripts must not:

- delete, overwrite, rename, or bulk-modify vault files;
- register startup, autostart, event, or persistent side-panel behavior;
- send drawing, vault, or user data over the network;
- load executable code from a CDN or another remote location;
- evaluate strings as code through `eval`, `new Function`, or an equivalent mechanism;
- read, print, transmit, or persist API keys and other secrets;
- install packages, change plugin settings, or publish artifacts;
- operate on the entire vault or scene when an explicit target set is available.

The script runs only in the user's Obsidian Excalidraw environment. Do not execute reference scripts in the current shell or treat Markdown code blocks as verified code.

## Known sensitive examples

Review these areas especially carefully:

- `ExcaliMath.md` demonstrates dynamic expression evaluation with `new Function`;
- `Image Occlusion.md` includes file and folder deletion plus binary writes;
- `Auto Layout.md` can load a library from a public CDN;
- `ExcaliAI.md` includes external AI providers and credential handling;
- startup examples register persistent behavior and event handlers;
- several examples create or modify vault files.

Their presence is documentation, not authorization to use those behaviors.

## Safe adaptation checklist

1. Identify the exact drawing, selection, and vault paths involved.
2. Explain every write, network request, credential access, and persistent registration.
3. Validate paths and expected target counts before mutation.
4. Prefer a preview or dry run. Back up affected data before destructive or bulk changes.
5. Prefer recoverable trash semantics over permanent deletion when the available API supports it.
6. Keep secrets in the user's approved secret or plugin-setting mechanism; never hard-code or echo them.
7. Pin and verify remote dependencies when external loading is explicitly approved.
8. Provide teardown for handlers, views, and startup registrations.
9. Test on a disposable drawing or vault copy before production use.
10. Report what was actually verified and what still requires an Obsidian runtime test.

Third-party services, samples, and APIs can change after the archived upstream commit. Revalidate current behavior, terms, and compatibility before use.
