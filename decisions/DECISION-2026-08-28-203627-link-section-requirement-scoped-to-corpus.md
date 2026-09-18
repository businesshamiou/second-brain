---
type: decision
title: "Scoping of the links standard — the mandatory ## Liens section applies to the Vault's corpus, not to the adopted material of skills/external/"
description: "Engraves the Owner's arbitration X: the obligation of a ## Liens section in the links standard is bounded to the Vault's documentary corpus and does not apply to the files of vault/skills/external/, adopted operational material whose bodies stay verbatim; the check of link resolution stays global, including in external/. check-links.sh is adjusted accordingly, proofs by canaries."
created_at: "2026-08-28T20:36:27-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
amends: "../rules/RULES-2026-08-21-115658-document-linking-standard.md"
---

# DECISION — THE ## LIENS SECTION IS BOUNDED TO THE CORPUS, NOT TO THE ADOPTED MATERIAL

## Date

2026-08-28

## Status

`ARBITRATED`

## Decision

**1. Bounding of the rule.** The obligation of a `## Liens` section engraved by the links standard (`RULES-2026-08-21-115658`) applies to the **Vault's documentary corpus** — rules, decisions, missions, reports, captures, handoffs, proposals, knowledge notes, templates and native skills. It does **not** apply to the files of `vault/skills/external/`: adopted operational material, body verbatim guaranteed by fingerprints (`DECISION-171209`), which does not take part in the corpus's citation graph.

**2. What stays global.** The check of **resolution** of relative links remains over the whole repository, `skills/external/` included: a broken link there remains a refusal. Only the requirement that the section be present is bounded.

**3. Execution.** `tools/check-links.sh` is adjusted to apply this bounding — same pattern as its already arbitrated bounding on code blocks — with proof by canaries in both directions: a corpus document without `## Liens` stays refused; a file of `external/` without the section passes; a broken link in `external/` stays refused.

**4. Boundary of the decision.** The day an adopted skill is promoted by complete rewrite (body included) out of `external/`, it joins the corpus and the full obligation applies to it.

## Reason

Owner's arbitration X, 2026-08-28, on real measurement: 54 upstream files without a `## Liens` section, zero broken targets (report 084+083). The alternative — adding sections in the bodies — would have destroyed the body-verbatim guarantee and its 28 fingerprints engraved that very day, for sections with no purpose: these files cite nothing from the corpus. The rule is legitimate; its perimeter simply did not cover a type of material that did not exist when it was written. This is the case anticipated and reserved for the Owner by `DECISION-160213` §6, now measured.

## Impact

- `RULES-2026-08-21-115658` receives the reciprocal `amended by` link (same commit as this engraving).
- `tools/check-links.sh` modified, diff limited to the bounding, canaries recorded.
- The commit of the 97 files of `skills/external/` (pending since Mission 082) becomes possible without a workaround or an artificial section.
- The door `open-guardrail-wiring-arbitration` is not touched; the case "narrowing check-links" already queued (exclusion of code blocks) is distinct and remains.

## Human gate

- Validation: granted
- Reference: « je tranche : X » ["I decide: X"], Owner, 2026-08-28, after presentation of the two routes and of the mechanical conflict of L with the body-verbatim guarantee.

## Linked artefacts

- Source measurement: (workshop history, not distributed) (54 section refusals, 0 broken targets — outside the repository).
- Body-verbatim doctrine: (workshop history, not distributed) (hors dépôt).
- Execution Mission: (workshop history, not distributed) (hors dépôt).

## Liens

- `amends` — [Standard for links between documents](../rules/RULES-2026-08-21-115658-document-linking-standard.md)
- `applies` — Decision — Adoption by V1 envelope rewrite (workshop history, not distributed) (hors Vault)
- `see also` — Report — guardian fix and 083 chain (workshop history, not distributed) (hors Vault)
