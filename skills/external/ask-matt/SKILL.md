---
name: "ask-matt"
description: "Ask which skill or flow fits your situation. A router over the skills in this repo."
license: "MIT"
metadata:
  upstream-repo: "github.com/mattpocock/skills"
  upstream-version: "1.2.3"
  vault-source: "affiliate-pro-skills-full.zip"
  vault-source-sha256: "8d4a56240ccb587b4b70fec27f76329444ec254d3dce8b64e4fd912bb1588acb"
  vault-body-sha256: "a1f7c6463974f97048f51ad6e255f0d29eb09dd7a5f5c9b5a1edef7f29a6ac86"
  vault-entered: "2026-09-01"
  claude-code-disable-model-invocation: "true"
---

# Ask Matt

You don't remember every skill, so ask.

Skill names below are canonical identifiers, not runtime-specific commands. Invoke them through the runtime's available Skill mechanism; when no such mechanism exists, read the named sibling `SKILL.md` and follow it directly.

A **flow** is a path through the skills. Most paths run along one **main flow**, and two **on-ramps** merge onto it. Everything else is standalone, or a vocabulary layer that runs underneath.

## The main flow: idea → ship

The route most work travels. You have an idea and want it built.

1. **`grill-with-docs`** sharpens the idea by interview. Start here whenever you are **working in a working directory**: it's stateful, retaining what it learns in `CONTEXT.md` and ADRs. (No working directory? Use `grill-me` instead, covered under Standalone. Both run the same `grilling` primitive; `grill-with-docs` is the one that leaves a paper trail, which makes it the better of the two whenever a repo is there to leave it in.)
2. **Branch: can you settle every question in conversation?** If a question needs a runnable answer (state, business logic, a UI you have to see), detour through a prototype, bridged by **`handoff`** in both directions (a prototype lives in its own directory, which is exactly what `handoff` is for; see Phase boundaries):
   - use **`handoff`** to capture the outgoing context, then open a fresh session against that file,
   - use **`prototype`** to answer the question with throwaway code,
   - use **`handoff`** again to bring back what you learned, and reference it from the original idea thread.
3. **Branch: is this a multi-session build?**
   - **Yes** → **`to-spec`** (turn the thread into a spec), then **`to-tickets`** to split it into tracer-bullet tickets, each declaring its **blocking edges**. On a local tracker that's one file per ticket under `.scratch/<feature>/issues/`, worked blockers-first by hand; on a real tracker the edges become native blocking links, so any ticket whose blockers are done can be grabbed. Apply **`implement`** per ticket and start a fresh context between tickets when the runtime supports it. Otherwise use the ticket plus a handoff summary as the context boundary. Each ticket is self-contained, so the last one's context is disposable.
   - **No** → apply **`implement`** right here, in the same context window.

   Either way, **`implement`** builds each issue by driving **`tdd`** internally (one red-green slice at a time), then closes out by applying **`code-review`**, a two-axis review (Standards + Spec) of the diff, before committing. Reach for **`tdd`** on its own when you just want to build a concrete behaviour test-first without a full spec, and **`code-review`** on its own whenever you want to review a branch or PR against a fixed point.

### Context hygiene

Keep steps 1–3 in **one unbroken context window** (do not summarize or discard it until after `to-tickets`) so the grilling, spec, and tickets all build on the same thinking. Each `implement` then starts fresh, working from the ticket.

The limit on this is the **[smart zone](https://www.aihero.dev/ai-coding-dictionary/smart-zone)**: the usable context within which the model still reasons sharply. Its size varies by runtime and model; do not assume a fixed token count. If the session approaches its practical limit before `to-tickets`, use the runtime's context summarization capability at the nearest phase boundary. If none exists, create a `handoff` document and continue from that secondary source.

## On-ramps

A starting situation that generates work, then merges onto the main flow.

- **Bugs and requests piling up** → **`triage`**. It moves issues through triage roles and produces agent-ready issues, which **`implement`** later picks up.

  Triage is only for issues **you didn't create**: bug reports, incoming feature requests, anything that arrives raw. Tickets that `to-tickets` produced are already agent-ready, so **don't triage them**.

- **Something's broken** → **`diagnosing-bugs`**. For the hard ones: the bug that resists a first glance, the intermittent flake, the regression that crept in between two known-good states. It refuses to theorise until it has a **tight feedback loop** (one command that already goes red on *this* bug), then fixes with a regression test. Its post-mortem hands off to **`improve-codebase-architecture`** when the real finding is that there's no good seam to lock the bug down.

- **A huge, foggy effort: a greenfield project or a huge feature build, too big for one session** → **`wayfinder`**, the most cognitively demanding flow here. When the way from here to the destination isn't visible yet, it charts a **shared map** of **decision tickets** on the issue tracker and resolves them one at a time, producing **decisions, not deliverables**, until the fog is pushed back and the way is clear. Where **`grill-with-docs`** sharpens an idea you can hold in one session, wayfinder is for the idea you can't, and it's slower and denser, so save it for exactly that, never a well-scoped feature.

  When the map clears, **it hands off, it doesn't build**: merge onto the main flow at **`to-spec`**, which collapses the map's linked decisions into a buildable plan, then `to-tickets` and `implement` as usual. Looping the map straight into `implement` skips that collapse and throws the linked detail away, so go straight to `implement` only when the effort turned out genuinely small.

## Codebase health

Not feature work, just upkeep.

- **`improve-codebase-architecture`** runs whenever you have a spare moment to keep the codebase good for agents to operate in. It surfaces **deepening opportunities**; picking one _generates an idea_ you can take into the main flow at `grill-with-docs`. It's the survey that finds the candidates; **`codebase-design`** (below) is the bench you design the chosen one on.

## Vocabulary underneath

Two model-invoked references that run *beneath* the other skills, each the single source of truth for its vocabulary. Reach for them directly when the **words**, not the process, are the problem; or let the skills above pull them in.

- **`domain-modeling`**: sharpen the project's *domain* language: challenge a fuzzy term, resolve an overloaded word ("account" doing three jobs), record a hard-to-reverse decision as an ADR. It's the active discipline `grill-with-docs` drives to keep `CONTEXT.md` a clean glossary.
- **`codebase-design`** is the deep-module vocabulary (module, interface, depth, seam, adapter, leverage, locality) for designing a module's *shape*: a lot of behaviour behind a small interface at a clean seam. `tdd` and `improve-codebase-architecture` both speak it.

## Phase boundaries

A **phase** is a chunk of work inside a session: the grilling, the implementation, the QA. At the **boundary** between two of them you have five options, and picking between them is the fuzziest decision in this whole map:

- **Continue**: stay put. Costs nothing, loses nothing.
- **Fresh context**: start a new context when nothing here matters to what's next. Use the runtime's clear/new-session capability, or simply begin a new session.
- **`handoff`** writes a portable markdown file. Narrow: only for a **new runtime**, a **new directory**, a **colleague**, or forking a side task **mid-phase**. What it buys is portability.
- **Delegated context**: send a tightly-scoped task to an isolated agent when delegation exists; otherwise execute the task sequentially here.
- **Context summary**: use the runtime's compaction or summarization capability to seed a fresh session. If unavailable, create a `handoff` document. This is the **default**, at the bottom of the tree rather than the first reach.

Read [PHASE-BOUNDARIES.md](PHASE-BOUNDARIES.md) for the ordered tree: the five questions, the reasoning behind each branch, and why the primary-source cost makes **Continue** the one to rule out first. Make the decision **at** a boundary; mid-phase, continue or delegate the remaining work when supported.

## Standalone

Off the main flow entirely.

- **`grill-me`**: the same relentless interview as `grill-with-docs`, but **stateless**: it saves nothing locally and builds no `CONTEXT.md`. Reach for it when you are **not working in a working directory**. If you are in a working directory, use `grill-with-docs` instead: it runs the same interview and leaves a paper trail.
- **`grilling`** is the interview primitive itself: rounds, the frontier, facts are the agent's job and decisions are yours. `grill-me` and `grill-with-docs` are the two named ways in, and `triage`, `wayfinder`, and `improve-codebase-architecture` all run it internally. Reach for it directly only when you want the interview with no wrapper around it.
- **`resolving-merge-conflicts`** works an in-progress merge or rebase conflict hunk by hunk, resolving by **intent** traced to each side's primary source rather than by picking lines, then finishes the operation. It never runs `--abort`.
- **`prototype`** is a small, throwaway program that answers one design question: does this state model feel right, or what should this UI look like. Throwaway is a constraint on how the code is written, not a promise to destroy it: the answer folds into the real code, and the prototype itself is kept as a **primary source** on a `prototype/<name>` branch out of main, pointed at from the implementation issue.
- **`research`** investigates a question against **primary sources** and leaves a cited Markdown file. It uses background delegation when supported and otherwise runs sequentially. Its output feeds `grill-with-docs`; research informs the thinking rather than replacing it.
- **`to-questionnaire`** comes in when the blocking knowledge is in **someone else's** head. It interviews you about the **send** and writes a questionnaire aimed at the gap. What comes back is material for `grill-with-docs` or `to-spec`.
- **`wizard`** is for steps only a **human** can take: provisioning infrastructure, setting up credentials or CI secrets, clicking through a third-party dashboard, or running a migration. It generates an interactive bash script with fallbacks when browser-opening or provider CLIs are unavailable.
- **`wait-what`** is the corrective for a message that didn't land. It re-pitches what the agent just said with the missing context, in plain English, using the `CONTEXT.md` vocabulary. `grill-with-docs` is the upfront cure.
- **`teach`**: learn a concept over multiple sessions, using the current directory as a stateful workspace.
- **`writing-for-agents`** is the reference for writing documents agents consume: skills, repository agent instructions, and pointed-at docs.

## Precondition

**`setup-matt-pocock-skills`**: apply before your first engineering flow to configure the issue tracker, triage labels, and doc layout the other skills assume. Custom issue trackers also work.
