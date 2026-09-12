---
name: "handoff"
description: "Compact the current conversation into a handoff document for another agent to pick up."
license: "MIT"
metadata:
  upstream-repo: "github.com/mattpocock/skills"
  upstream-version: "1.2.3"
  vault-source: "affiliate-pro-skills-full.zip"
  vault-source-sha256: "8d4a56240ccb587b4b70fec27f76329444ec254d3dce8b64e4fd912bb1588acb"
  vault-body-sha256: "d377e9ef678123ab9a63ffc785068f6efe740fa29fa0545e2e3d614035b9f7d7"
  vault-entered: "2026-09-01"
  claude-code-argument-hint: "What will the next session be used for?"
  claude-code-disable-model-invocation: "true"
---

Write a handoff document summarising the current conversation so a fresh agent can continue the work. When filesystem access is available, save it to the operating system's temporary directory, not the current workspace. If the runtime cannot write files, return the complete handoff document in the response and state that it still needs to be saved or passed to the destination agent.

Include a "suggested skills" section naming the relevant Skills and why the next agent should apply them. Do not prescribe a runtime-specific invocation syntax.

Do not duplicate content already captured in other artifacts (specs, plans, ADRs, issues, commits, diffs). Reference them by path or URL instead.

Redact any sensitive information, such as API keys, passwords, or personally identifiable information.

If the user passed arguments, treat them as a description of what the next session will focus on and tailor the doc accordingly.
