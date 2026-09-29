---
type: template
title: "Template — profile order"
description: "The order that carries the Owner's starting profile, approved in the starting interview: written by the welcome Pilot in <workspace>/_orders/, dated by the Owner, applied by an Executor with sb profile --order, which rewrites only the « ## Profil de départ » section of USER.md."
status: active
---

# TEMPLATE — PROFILE ORDER

The profile order is the only way the Owner's starting profile reaches `USER.md` (Mission 240, [Decision — the starting interview](../decisions/DECISION-2026-09-27-213059-starting-interview-owner-and-project-profiles.md)). The welcome Pilot runs the interview ([the starting-interview skill](../skills/starting-interview/SKILL.md)), shows the Owner the full profile, and, once the Owner agrees to its exact content, writes this order to `<workspace>/_orders/PROFILE-<YYYY-MM-DD-HHMMSS>.md` (real time, path announced before writing) — the one folder it writes in. An Executor applies it with `sb profile --order <file>`: the tool rewrites the section « ## Profil de départ » of the installed Vault's `USER.md` and nothing else, then moves the order to `<workspace>/_archive/orders/`. The Pilot never writes `USER.md` itself.

The block below keeps its French labels as they are: the five field names, the date line of the section and `Autorisation Owner datée` [dated Owner authorization] are read by `tools/starting_profile.py`, which finds each one by its exact name followed by a colon — the same grammar as the [initiation order](./initiation-order-template.md).

<!-- ORDER:BEGIN -->
Session Executor — profil de départ

Position : free; establish your awareness of position.

Ordre de profil
- Ce que je fais : <one sentence — the installer's question 5, taken up as it is>
- Ce qui compte pour moi : <the installer's question 7, taken up as it is>
- Trois casse-têtes du moment : <headache 1> · <headache 2> · <headache 3>
- Rythme de revue : <for instance: every Monday morning; or only when I ask>
- Outils du quotidien : <the installer's question 6 when it was answered, completed by the Owner>
- Autorisation Owner datée : <the Owner's sentence approving this profile, verbatim, AAAA-MM-JJ>

Interdits absolus : no model call, no deletion, no push; writing bounded to the « ## Profil de départ » section of USER.md and to the move of this order into _archive/orders/.

Sortie attendue : the output of sb profile --order, the diff of USER.md, then a commit of USER.md alone.
<!-- ORDER:END -->

## Fields

| Field | Effect |
|---|---|
| `Ce que je fais` [what I do] | the activity, in one sentence |
| `Ce qui compte pour moi` [what matters to me] | what the Owner wants kept in mind |
| `Trois casse-têtes du moment` [the three biggest headaches right now] | three short items, separated by `·` |
| `Rythme de revue` [review rhythm] | when the Owner wants a review (a day, a frequency, or "only when I ask") |
| `Outils du quotidien` [everyday tools] | the tools of the Owner's day, by name |
| `Autorisation Owner datée` [dated Owner authorization] | the Owner's approval of the profile shown, verbatim, with `AAAA-MM-JJ` (year-month-day); without a date, refusal |

A field left out, or holding `-` or a placeholder in angle brackets, keeps the value `USER.md` already has: an older profile completed by the interview only needs the fields that were missing. An order without any of the five fields is refused. The section also carries a line `Mis à jour le` [updated on], written by the tool with the day it applies the order.

## Liens

- `see also` — [Template — initiation order](./initiation-order-template.md)
- `see also` — [Template — welcome Pilot](./accueil-pilot-prompt-template.md)
- `see also` — [The starting-interview skill](../skills/starting-interview/SKILL.md)
- `prescribed by` — [Decision — The starting interview](../decisions/DECISION-2026-09-27-213059-starting-interview-owner-and-project-profiles.md)
