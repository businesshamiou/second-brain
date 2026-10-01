---
type: how-to
title: "The starting interview"
description: "How Second Brain comes to know you and each project: the Owner profile under « ## Profil de départ » of USER.md, kept alive by the welcome Pilot and applied by sb profile --order; the project profile under « ## Profil du projet » of the project's README.md, asked at creation and adoption. The page that is authoritative."
status: active
---

# THE STARTING INTERVIEW

Second Brain keeps two short profiles, each under a fixed heading that the Pilot, the skill that writes Missions, the assistant and the state sheet read by name ([Decision — the starting interview](../../decisions/DECISION-2026-09-27-213059-starting-interview-owner-and-project-profiles.md)). This page is the reference for both; the procedure the Pilot follows is the [starting-interview skill](../../skills/starting-interview/SKILL.md).

In the commands below, `<workspace>` is the absolute path of your workspace and the installed Second Brain is `<workspace>/second-brain`.

## The two profiles

**Your profile** lives in `<workspace>/second-brain/USER.md`, under `## Profil de départ`:

```text
## Profil de départ

- **Ce que je fais :** <one sentence>
- **Ce qui compte pour moi :** <what you want kept in mind>
- **Trois casse-têtes du moment :** <one> · <two> · <three>
- **Rythme de revue :** <for instance: every Monday morning>
- **Outils du quotidien :** <the tools of your day>
- **Mis à jour le :** <YYYY-MM-DD>
```

The first two fields take up the installer's questions 5 and 7 as they are, and the last one question 6 when you answered it. Since Mission 244 the installer writes them there itself, at installation (`tools/starting_profile.py owner-seed`): only the answers you gave — a question you skipped leaves its field absent, never a default in its place — so the welcome Pilot's first interview shows your profile and asks what changed, and only the missing fields one at a time.

**A project's profile** lives in the project's `README.md`, under `## Profil du projet`:

```text
## Profil du projet

- **Résultat attendu :** <what the project must achieve>
- **Blocage actuel :** <what blocks it now>
- **Rythme de revue :** <how often to review it>
- **Mis à jour le :** <YYYY-MM-DD>
```

The headings and field names stay in French whatever your language: tools find them by their exact text. A project without this section is not at fault — it stays conforming and its state sheet says « Aucun ».

## Steps

### Your profile, with the welcome Pilot (scenario E9, then E3)

1. Open a conversation in `SB - Accueil` (created once from the block `sb pilot-prompt --accueil` prints, anywhere in your workspace; if you created it before Mission 240, paste that block again once). At opening it reads `## Profil de départ` first.
2. **If the section exists**, it shows it and asks one question: what has changed? You answer only the difference. Fields that are missing are asked, and only those.
3. **If it does not**, it runs the interview: one question at a time, at least three, one follow-up at most when an answer is vague. What the installer already knows (your activity, what matters to you, your AI tools) is proposed for you to confirm.
4. It shows you the full profile — for a change, the old value next to the new one — and waits for your yes. Nothing is written on silence.
5. With your agreement it announces, then writes, the order `<workspace>/_orders/PROFILE-<YYYY-MM-DD-HHMMSS>.md` from the [profile order template](../../templates/profile-order-template.md), with your approving sentence and its date. This folder is the only place it writes.
6. It then offers, once, three to five first steps drawn from your headaches, and your review rhythm as the moment to come back.
7. In an Executor window opened in the workspace, paste the mini-prompt it gives you. The Executor runs:

   ```bash
   sb profile --order <workspace>/_orders/PROFILE-<YYYY-MM-DD-HHMMSS>.md
   ```

   _Not executed by the documentation check._

   Only the section `## Profil de départ` of `USER.md` is rewritten; a field the order leaves out keeps its value; the order moves to `<workspace>/_archive/orders/`. The Executor inspects the diff of `USER.md` and commits it alone — an update refuses a Second Brain with uncommitted changes.

`sb profile`, with no argument, prints the section and the fields it lacks, and writes nothing.

### A project's profile, at creation or adoption (scenarios E9, E8, E3)

- **With the welcome Pilot** (a new idea) or **the Pilot of a folder to adopt** (E8): before proposing the initiation order, it asks the three questions one at a time — expected result, current blocker, review rhythm — and puts your answers in the order's optional fields `Résultat attendu`, `Blocage actuel`, `Rythme de revue` ([initiation order template](../../templates/initiation-order-template.md)). The Executor runs `sb new --order <order>`.
- **In a terminal**, `--ask` asks them after the name, the location and Git; Enter leaves one empty:

  ```bash
  sb new <folder> "<Name>" --ask
  sb adopt --ask
  ```

  _Not executed by the documentation check._

At least one answer is written under `## Profil du projet` of the project's `README.md` (at adoption, an existing README gains the section and an existing section is kept as it is; a folder without README gets one carrying its title and the section). No answer: nothing is written. The next state sheet copies the section.

## What you should see

- `sb profile` ends with `OWNER-PROFILE PRESENT missing=<n>` or `OWNER-PROFILE ABSENT missing=5`, after a `MISSING …` line naming the fields to ask.
- `sb profile --order <file>` prints the section as written, `KEPT …` (the fields the order left as they were), `ARCHIVED <path>`, `OWNER-PROFILE-WRITTEN`, then ` M USER.md`.
- The report of `sb new` or `sb adopt` says `Profil du projet écrit sous « ## Profil du projet » : <README>` or `Profil du projet déjà présent, laissé tel quel : <README>`.
- The project's state sheet `state/STATE.md` has a section `## Profil du projet`, with the fields and their source, or « Aucun … (facultatif) ».

## Known errors

- **`REFUSED USER.md is the distributed skeleton (status: template)`**: you are in a laboratory Second Brain, whose `USER.md` is distributed to everyone; a profile is written in an installed one.
- **`REFUSED profile order without « Autorisation Owner datée » carrying a date`**: add your approving sentence with its `AAAA-MM-JJ` date to the order.
- **`REFUSED the archive already holds …`**: an order of the same name was already applied; nothing was written. Name the new order with the real time.

## Scripts used

- `tools/starting_profile.py` — the only writer of both sections: [project tools](../reference/tools-projects.md)
- `tools/project-bootstrap.sh` — the three fields of the order, `--ask`: [project tools](../reference/tools-projects.md)
- `tools/build-state.sh` — the section copied into the state sheet: [state and journal tools](../reference/tools-state-and-journal.md)

## Liens

- `source` — [Decision — The starting interview](../../decisions/DECISION-2026-09-27-213059-starting-interview-owner-and-project-profiles.md)
- `source` — [Skill: starting-interview](../../skills/starting-interview/SKILL.md)
- `source` — [Template: profile order](../../templates/profile-order-template.md)
- `source` — [Template: initiation order](../../templates/initiation-order-template.md)
- `source` — [Template: welcome Pilot](../../templates/accueil-pilot-prompt-template.md)
- `see also` — [Start something new](start-something-new.md)
- `see also` — [Create a project](create-a-project.md)
- `see also` — [Adopt an existing folder](adopt-a-project.md)
- `see also` — [Commands](../reference/commands.md)
