---
title: "Template — Report of the Vault's installation on a machine"
description: "Template of the report returned by the first-install skill: measured identity of the machine, human answers of the questioning, installed / missing → installed / left (human gesture) table with proof per line, before/after total, remaining human gestures. Instantiated by the skill, never edited as a source."
created_at: "2026-09-01T21:05:00-04:00"
timezone: America/Montreal
status: active
---

# INSTALLATION REPORT — <machine, YYYY-MM-DD>

## 1. Machine measured

| Measurement | Value |
|---|---|
| OS / shell | <`uname -s`, `$SHELL`> |
| Claude Code | <`claude --version`> |
| Git | <`git --version`> |
| Vault | <measured path, head `git rev-parse --short HEAD`, `core.hooksPath`> |
| Work root | <path of the `VAULT-ROOT.md`> |
| Junctions | <supported: yes/no, method> |

## 2. Human answers (questioning `/to-questionnaire`)

- Desired path of the Vault: <answer>
- Path of the projects: <answer>
- Personal skills folder: <answer or default `%USERPROFILE%\.claude\skills`>
- Path of the report: <answer or "conversation">

## 3. Inventory → installation

| # | Item (install-checklist.md) | Before | Gesture | After | Proof |
|---|---|---|---|---|---|
| 1 | <item> | installed / missing | none / <command> | installed / left (human gesture) | <path, `test -ef`, output> |

**Total**: <N> missing before → <M> missing after; <K> left (human gesture).

## 4. Chat skills — proposed, not installed

- <measured path of the zip> — `laissé (geste humain)`

## 5. Remaining human gestures

1. <gesture, with the exact command or path>

## 6. Proof of no writing in the repositories

```
$ git -C <racine du Vault> status -sb        (before)
$ git -C <racine du Vault> status -sb        (after, identical)
```

## Liens

- `see also` — [first-install skill](./SKILL.md)
- `see also` — [Installation checklist, one measurement per item](./install-checklist.md)
