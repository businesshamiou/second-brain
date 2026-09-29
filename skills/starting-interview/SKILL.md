---
name: starting-interview
description: "Starting interview: show the profile, ask only what changed, one question at a time; sb profile."
license: "MIT"
metadata:
  vault-implements: "decisions/DECISION-2026-09-27-213059-starting-interview-owner-and-project-profiles.md"
  vault-validated: "2026-09-27T21:30:59-04:00"
---

The starting interview: how Second Brain comes to know the Owner and each project by more than one sentence. **Pilot surface** (the welcome Pilot `SB - Accueil`, and the Pilot of a project preparing an adoption): it asks, shows, and files an order; it never writes the profile itself. The Executor applies the order with a tool. Method adapted from the skill `smb-onboard` of Anthropic's Small Business plugin (Apache License 2.0, snapshot `da38ec1`), rewritten here; nothing of it is copied — see the Decision under Liens for the source and what was left out.

## 0. Which profile

| Profile | Where it lives | Fields (exact names) | Written by |
|---|---|---|---|
| Owner | `## Profil de départ` of the installed Vault's `USER.md` | `Ce que je fais` · `Ce qui compte pour moi` · `Trois casse-têtes du moment` · `Rythme de revue` · `Outils du quotidien` · then `Mis à jour le` | `sb profile --order <file>`, from a profile order |
| Project | `## Profil du projet` of the project's `README.md` | `Résultat attendu` · `Blocage actuel` · `Rythme de revue` · then `Mis à jour le` | `tools/project-bootstrap.sh`, from the initiation order or `--ask` |

The headings and field names are fixed: other skills and tools read them by name. Never rename one, never add a sixth Owner field.

## 1. Read first

Before any question, read the section. Owner: the heading `## Profil de départ` of `<Vault>/USER.md` (a search for the heading, not the whole file; with a shell, `sb profile` prints it and names the missing fields). Project: `## Profil du projet` of `<project>/README.md`.

- **Present and complete**: show it as it is, then ask one question: *what has changed?* Take only the fields the answer touches. Nothing changed: stop, nothing is filed.
- **Present, fields missing** (a field absent, empty, or `_(à remplir)_`): show it, then ask **only the missing fields**. Never re-interview.
- **Absent**: run the interview (§2). For the Owner, take what the installation already knows as the proposed answer of three fields — the section `## Activité` (question 5) for `Ce que je fais`, `Ce qui compte` (question 7) for `Ce qui compte pour moi`, `Outils IA` (question 6, when it was answered) for `Outils du quotidien` — and ask the Owner to confirm or correct each.

## 2. The interview

- **One question at a time.** Wait for the full answer before the next one. Never a list of questions in one message.
- **At least three questions.** For the Owner, when time is short, the three are the headaches, the review rhythm and the everyday tools (the other two come from the installation); never fewer. For a project, the three are its fields.
- **One follow-up at most** when an answer is vague ("things", "the usual"): ask once for an example; then take what was said.
- **The Owner's words.** Write the answers as said, shortened only to fit one line; the three headaches as three short items separated by `·`.

Owner questions, in the Owner's language: *what do you do, in one sentence?* · *what matters most to you in how we work?* · *what are your three biggest headaches right now — what eats your time or keeps you up?* · *how often do you want us to review where things stand — a day, a rhythm, or only when you ask?* · *which tools do you use every day?* Project questions: *what result do you expect from this project?* · *what is blocking it right now, if anything?* · *how often do you want to review it?*

## 3. Show, then file

1. **Show the full profile**, every field, as it will be written — and for an existing profile, the current value next to the proposed one for each field that changes. Wait for an explicit yes. Never write on silence, never replace a profile silently.
2. **Owner profile**: announce the path, then write the order from `templates/profile-order-template.md` to `<workspace>/_orders/PROFILE-<YYYY-MM-DD-HHMMSS>.md` (real time), with the Owner's approving sentence and its date in `Autorisation Owner datée`. Hand the Owner an Executor mini-prompt: « Tu es l'Executor. Applique l'ordre de profil <path> : sb profile --order <path>. »
3. **Project profile**: the three answers go into the initiation order you propose (its optional fields `Résultat attendu`, `Blocage actuel`, `Rythme de revue`, from `templates/initiation-order-template.md`), never into a separate file. An empty answer is left out.

## 4. Offer, once

After the profile is approved, offer **three to five first steps** drawn from the headaches — each one a concrete gesture with its command or its window (`sb new`, a first Mission, `sb adopt` for a folder that already exists) — and the **review rhythm** just recorded as the moment to come back (`sb status` in the project, or a Pilot session). Say it once; never repeat an offer the Owner declined in this session.

## What this skill does not do

Write `USER.md` or a `README.md` (the Executor's tools do) · connect tools, run recipes, capture a brand or a voice (left out of the method) · touch the installer or its nine questions · keep anything in a model's memory: the profile lives in the files above, nowhere else.

## Liens

- `prescribed by` — [Decision — The starting interview](../../decisions/DECISION-2026-09-27-213059-starting-interview-owner-and-project-profiles.md)
- `see also` — [Template — profile order](../../templates/profile-order-template.md)
- `see also` — [Template — initiation order](../../templates/initiation-order-template.md)
- `see also` — [Template — welcome Pilot](../../templates/accueil-pilot-prompt-template.md)
- `see also` — [The starting interview (how-to)](../../docs/how-to/starting-interview.md)
