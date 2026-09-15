# SkillSpector security evidence

SkillSpector is the mandatory static security gate for incoming Skills and new collection releases. Its pinned upstream identity is recorded in `tools/skillspector-lock.json`; the executable is installed outside this repository.

The gate is fail-closed. A scanner failure, timeout, incomplete analysis, or HIGH/CRITICAL finding is `OPEN — SKILLSPECTOR SECURITY REVIEW`. Only an explicit Owner decision with an evidence-bound SkillSpector baseline suppression or remediation can resolve that state. No finding is suppressed automatically.

## Current audit records

- `software-engineering-current.json` is the compact native recursive scan of all 29 canonical engineering Skills. All 29 are `OPEN` because the static scanner reported incomplete analysis and/or HIGH findings; it found 20 findings in total. This report must be refreshed after any canonical change.
- `software-engineering-delivery-2026-09-07-v1.json` is the static scan of the immutable collection ZIP. It reported score 100 (`CRITICAL`), 12 findings, and incomplete analysis; it is evidence for review, not a release approval.
- `web-design` and `visual-content` still require a bounded batch security run. Their immutable ZIP inventory and byte identity are already checked by `tools/validate-warehouse.py`; that structural validation is not a substitute for the pending SkillSpector security gate.

All recorded scans use `--no-llm`. Optional semantic analysis may add evidence but cannot replace the reproducible static gate.
