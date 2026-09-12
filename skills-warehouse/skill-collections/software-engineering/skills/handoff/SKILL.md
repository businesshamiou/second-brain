---
name: "handoff"
description: "Compact the current conversation into a handoff document for another agent to pick up."
license: "MIT"
metadata:
  claude-code-argument-hint: "What will the next session be used for?"
  claude-code-disable-model-invocation: "true"
  upstream-license-evidence: "https://github.com/mattpocock/skills/blob/6654f6b60cd9d5be8b54c6fafe44346dabeb3b76/LICENSE"
  upstream-repo: "https://github.com/mattpocock/skills/tree/6654f6b60cd9d5be8b54c6fafe44346dabeb3b76"
---

Write a handoff document summarising the current conversation so a fresh agent can continue the work. When filesystem access is available, save it to the operating system's temporary directory, not the current workspace. If the runtime cannot write files, return the complete handoff document in the response and state that it still needs to be saved or passed to the destination agent.

Include a "suggested skills" section naming the relevant Skills and why the next agent should apply them. Do not prescribe a runtime-specific invocation syntax.

Do not duplicate content already captured in other artifacts (specs, plans, ADRs, issues, commits, diffs). Reference them by path or URL instead.

Redact any sensitive information, such as API keys, passwords, or personally identifiable information.

If the user passed arguments, treat them as a description of what the next session will focus on and tailor the doc accordingly.
