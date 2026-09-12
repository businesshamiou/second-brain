---
name: "implement"
description: "Implement a piece of work based on a spec or set of tickets."
license: "MIT"
metadata:
  upstream-repo: "https://github.com/mattpocock/skills/tree/6654f6b60cd9d5be8b54c6fafe44346dabeb3b76"
  upstream-license-evidence: "https://github.com/mattpocock/skills/blob/6654f6b60cd9d5be8b54c6fafe44346dabeb3b76/LICENSE"
  vault-source: "affiliate-pro-skills-full.zip"
  vault-source-sha256: "8d4a56240ccb587b4b70fec27f76329444ec254d3dce8b64e4fd912bb1588acb"
  vault-body-sha256: "f69bbb615704e905107fe58e488fd25d943a4aadf91362cddfc7e02e28cd42af"
  vault-entered: "2026-09-01"
  claude-code-disable-model-invocation: "true"
---

Implement the work described by the user in the spec or tickets.

Apply the `tdd` skill where possible, at pre-agreed seams. Use the runtime's Skill mechanism when available; otherwise follow its `SKILL.md` directly.

Run typechecking regularly, single test files regularly, and the full test suite once at the end.

Once done, apply the `code-review` skill to review the work. Use the runtime's skill mechanism when available; otherwise follow that Skill's `SKILL.md` directly.

Commit your work to the current branch.
