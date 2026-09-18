---
type: decision
title: "Semantics of the status field — Mission front matter and registry"
description: "Freezes the status of the Mission front matter at the creation authorization; MISSION-INDEX.md becomes the only source of the execution state."
created_at: 2026-08-20T01:57:48-04:00
timezone: America/Montreal
status: ARBITRATED
scope: mission-status-semantics
owner_gate: granted
---

# DECISION — SEMANTICS OF THE STATUS FIELD: MISSION FRONT MATTER AND REGISTRY

## Context

The [Mission versioning rule](../rules/RULES-2026-08-17-211522-mission-versioning-and-generated-output.md) requires that a Mission and its correction declare at least `mission_id`, `correction`, `supersedes` and `status`, but nowhere defines the values `status` may take, when it is filled in, or who updates it. No Mission template exists to fix this usage.

A measurement on 2026-08-20 of the 18 active Mission files of the registry (missions/MISSION-INDEX.md (hors Vault) of (workshop history, not distributed)) established that this gap produced divergent usage: `status` carries sometimes an authorization value (`AUTHORIZED`), sometimes an execution value (`COMPLETED`), depending on the file.

## Decision

**D1 — Frozen authorization.** The `status` field of a Mission's front matter expresses the authorization granted at the time of its creation. It is written once and never touched again afterwards, including when the Mission progresses or ends.

**D2 — The registry is authoritative.** missions/MISSION-INDEX.md (hors Vault) is the only source of a Mission's execution state. No other location is authoritative on this point.

**D3 — Registry vocabulary.** The registry's « Statut » column takes one of these four values: `AUTHORIZED`, `IN_PROGRESS`, `COMPLETED`, `ABANDONED`. The Executor updates it at the end of each Mission.

**D4 — Deprecated for reading.** The front-matter `status` is deprecated for reading: no one relies on it to know a Mission's execution state. Its only remaining function is to document, after the fact, which authorization allowed the file to be opened.

**D5 — No rework of the stock.** The 18 existing Mission files are not modified in light of this Decision. No realignment Mission, no `Cxx` correction is opened for this reason alone.

## Existing state — seven COMPLETED files

Seven active Missions carry `COMPLETED` in their front matter: `001-C01`, `002-C01`, `003`, `006`, `007-C01`, `008`, `004-C02`. Their `created_at` values cover a continuous three-hour window, from 2026-08-17T21:10:23-04:00 to 2026-08-18T00:19:00-04:00.

This window is bracketed on both sides by Missions carrying `AUTHORIZED`: before, `005-C01` at 2026-08-17T21:01:00-04:00, the oldest of the 18; after, `011` at 2026-08-19T10:19:20-04:00, the first file created after the window — that is, about 34 hours with no Mission opened. No other file of the active stock carries `COMPLETED`.

This shape — one continuous block, bracketed, with no recurrence before or after — is that of interrupted maintenance, not that of a convention in force that was later abandoned. These seven files remain intact under D5; they have no normative value for the present Decision.

## Human gate

Owner arbitration given in a steering session, on the measurement of 2026-08-20.

## Liens

- `applies` — missions/MISSION-INDEX.md (workshop history, not distributed) (hors Vault)
