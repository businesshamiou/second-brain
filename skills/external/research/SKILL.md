---
name: research
description: "Research a question using high-trust primary sources and capture cited findings in Markdown. Use for topic research, documentation or API facts, and reading legwork separated from the main task."
license: "MIT"
metadata:
  upstream-repo: "https://github.com/mattpocock/skills/tree/6654f6b60cd9d5be8b54c6fafe44346dabeb3b76"
  upstream-license-evidence: "https://github.com/mattpocock/skills/blob/6654f6b60cd9d5be8b54c6fafe44346dabeb3b76/LICENSE"
  vault-source: "affiliate-pro-skills-full.zip"
  vault-source-sha256: "8d4a56240ccb587b4b70fec27f76329444ec254d3dce8b64e4fd912bb1588acb"
  vault-body-sha256: "3d62db42fa43265bd56ed750c1324b8b0d859f26d0793e126dff81d164ab3a27"
  vault-entered: "2026-09-01"
---

Research in an isolated delegated agent when the runtime supports delegation; this keeps the reading context separate and may run concurrently with the main task. Otherwise execute the same workflow sequentially in the current agent. Delegation is an optimization, not a prerequisite.

Use the runtime's available web, documentation, repository, or local-file capabilities. Prefer live primary sources when the question depends on current facts. If live access is unavailable, use only sources already present locally, label the limitation, and do not imply that current external facts were verified.

Its job:

1. Investigate the question against **primary sources** (official docs, source code, specs, first-party APIs), not a secondary write-up of them. Follow every claim back to the source that owns it.
2. Write the findings to a single Markdown file, citing each claim's source.
3. Save it where the workspace already keeps such notes; match the existing convention. If no writable filesystem is available, return the complete Markdown in the response and state that it could not be saved.
