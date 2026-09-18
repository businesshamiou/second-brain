---
type: decision
title: "Decision — Verdicts of the memory/retrieval benchmark: native Vault KEEP, Mnemosyne REMOVE, OpenViking DEFER; FREEZE of the layer after removal, until after v1.0.0-stable"
created_at: "2026-09-06T11:38:50-04:00"
timezone: America/Montreal
status: active
description: "Owner arbitration of 2026-09-06 on the measurements of Mission 146 (report 112317): the native Vault answers 10/10 in 1.484 s and 6,455 bytes; Mnemosyne, as actually installed and fed in this AIOS, answers 0/10 in 18.989 s and 10,506 bytes, with a confident false positive and a present fact not surfaced — REMOVE, bearing on this measured deployment, not on the product in general; OpenViking DEFER for four measured causes, returns to LAB/NEXT outside the V1 critical path. After the removal of Mnemosyne (Mission 147): FREEZE of the memory/retrieval layer until after the v1.0.0-stable tag."
---

# DECISION — Verdicts of the memory/retrieval benchmark and FREEZE

## Context

The Decision of 2026-09-05 on the close of the memory/retrieval phase (204248) required a bounded benchmark and an explicit verdict per tool. Mission 146 ran it on 2026-09-06: frozen corpus (995 files, 16,161,948 bytes, vault 0c8ded8 + 3 untracked, the workshop (history, not distributed) bc34443), ten questions written before any installation, same counting rules. Report: REPORT-2026-09-06-112317-146-memory-retrieval-benchmark.md (outside the Vault, workshop repository).

**Measurements.** Native Vault: 10/10 correct, 15 calls, 6,455 bytes loaded, 1,484 ms — the most expensive question cost 3 calls and 580 bytes, against up to 233 greps before the index reform (audit 139 → Decision 124647 → Mission 140). Mnemosyne: 0/10, 10 calls, 10,506 bytes, 18,989 ms — 1.6× more bytes and 12.8× more time than the native Vault for zero answers; two aggravating fairness probes: a fact present in the bank (the push line 2c8acd4..765543e) not surfaced by the natural question, and a confident false positive (Mission 133 returned for "mission 135", score 0.800, entity match); structural cause: vectors 0, vec_type none, dense_score 0.0 everywhere — the bank was never vector-indexed. OpenViking: not runnable within the constraints — no CLI in the pip package (Rust binary absent by design), the "openviking-server init" form falsified on the spot, the default embedder that downloads outside the LAB and fails on a certificate, the Ollama server present without support for embeddings.

## Decision (Owner, chat, 2026-09-06)

1. **Native Vault: KEEP.** The mechanisms in place — digest, locator indexes, grep/tail, guardians — are the retrieval layer of V1.
2. **Mnemosyne: REMOVE.** The verdict bears on **its deployment as actually installed and measured in this AIOS** — bank fed from the journal only, never vector-indexed — not on a general claim about the product. The removal is clean and verifiable (Mission 147): wiring removed, artefacts moved, "experimented / rejected" note with the measurements.
3. **OpenViking: DEFER**, for measurable impossibility within the constraints (four causes above). It returns to LAB/NEXT and is no longer part of the V1 critical path.
4. **FREEZE.** After the removal of Mnemosyne, the memory/retrieval layer is frozen: no memory tool, vector base, graph memory or retrieval is tested or integrated **until after the v1.0.0-stable tag**. Any resumption is a NEXT/LAB decision, on measurement.

## Consequences

- Mission 147: removal of Mnemosyne — remember wiring of tools/append-journal.sh (set by Mission 122, fail-open), the project's environment and data files, operational references in the rules and skills (measured before removal), knowledge note with the benchmark figures. The workstation's MCP configuration (mnemosyne entry of Claude Desktop) is an Owner gesture, outside the Mission.
- The benchmark LAB is purged on Owner authorization of 2026-09-06, the evidence being copied into the committed report.
- The present Decision and 204248 enter the Vault with the vault commit of Mission 147 (manifest and decisions index included).

## Alternatives set aside

- Keep Mnemosyne "just in case": contrary to point 1 of 204248 (no dependency without measured value); the measurements are unambiguous.
- Repair the vector indexing before deciding: that would be a new work item in the stabilization phase; the door remains open in NEXT/LAB, after the tag.
- Run OpenViking by lifting the constraints (API key, downloads outside the LAB): refused by Owner arbitrations of 2026-09-05/06.

## Liens

- `prescribed by` — [Context cycle V2](../rules/RULES-2026-08-17-111018-context-lifecycle-v2.md)
- `applies` — [Decision — Close of the memory/retrieval phase](./DECISION-2026-09-05-204248-memory-retrieval-closure-benchmark-freeze.md)
- `applies` — [Decision — Evidence status and STOP control](./DECISION-2026-08-29-212009-evidence-status-and-stop-control.md)
