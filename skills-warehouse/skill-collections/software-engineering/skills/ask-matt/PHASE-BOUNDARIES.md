# Phase boundaries

A **phase** is a chunk of work inside a session: the grilling, the implementation, the QA. The definition is fuzzy on purpose: a phase ends when you think *"ok, we're done with that"*.

The **phase boundary** is the gap between two phases, and it is the only place this decision belongs. Mid-phase there is no decision to make: continue, or delegate the remaining work when the runtime supports isolated agents. Summarizing mid-phase makes the agent lose the thread.

## The five options

| Option       | What it does                                                    |
| ------------ | --------------------------------------------------------------- |
| **Continue** | Stay in the session. No context switch at all.                    |
| **Fresh context** | Start a new context from nothing when the current one is disposable. |
| **Handoff** | Write a portable Markdown file and seed a session anywhere with it. |
| **Delegation** | Send the task to an isolated agent context when supported. |
| **Context summary** | Compress or summarize this context for a fresh session. |

## The tree

Work top to bottom at the boundary. The first **yes** wins.

**1. Can you continue in this session?** Two things make the answer yes: the next phase needs this phase as a **primary source**, or you have enough [smart zone](https://www.aihero.dev/ai-coding-dictionary/smart-zone) left (~150k tokens) for the next phase to fit. Grilling → implementation is the standard yes: the implementation wants the reasoning verbatim, not a summary of it. Continue costs nothing and loses nothing, so rule it out before anything else.

**2. Is the context irrelevant to what comes next?** Is everything in this session disposable? If so, start a **fresh context** using the runtime's new-session or clear capability. If the runtime cannot do that in place, begin a separate session manually. Keep the old session resumable when the runtime supports it.

The cost of getting this wrong is one-way. Clear a *relevant* context and you lose the **why** behind what you built, and no amount of reading the diff back gets it returned.

**3. Do you need to hand off?** Apply the `handoff` Skill only when you are:

- moving to a **different runtime or agent harness**,
- moving to a **new directory** or repo,
- sending the work to a **colleague**,
- or forking a side task you found **mid-phase** without derailing what you're doing.

That list is the whole clause. What a handoff buys is **portability**: a file that travels. If nothing is travelling, you don't need it.

**4. Can the task be done AFK?** Is it scoped tightly enough to run without steering? If isolated agent delegation exists, delegate it and leave this session untouched. Otherwise execute it sequentially here or use a handoff to a separate session; do not invent a background capability.

**5. Otherwise, summarize the context.** Relevant context, same runtime, same directory, and you need to stay in the loop: use the runtime's compaction or summarization capability with an instruction describing the next phase. If unavailable, create a handoff document and continue from it in a fresh session.

Context summarization is the **default, not the first reach**. It sits at the bottom because the four questions above it are cheaper or more precise. The failure mode when people start here is a fresh session that is confidently wrong about a decision the summary flattened.

## Primary and secondary sources

Every move except **Continue** turns a **primary source** into a **secondary source**: the session as it happened, replaced by a summary of it. The trade is always the same shape:

| Source                            | Information | Noise | Room to move |
| --------------------------------- | ----------- | ----- | ------------ |
| Primary (Continue)                | Full        | Lots  | Little       |
| Secondary (context summary or handoff) | Lossy | Less | Lots |

This is why question 1 comes first. You only pay the lossiness when staying costs more than it saves.

## These are judgement calls

The questions are not objective: each has taste in it, and the same boundary can go two ways on two days. The value is in asking them **in order**, at the boundary rather than in the middle of the work.
