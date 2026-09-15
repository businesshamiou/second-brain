---
type: capture
title: "<titre concis>"
created_at: "YYYY-MM-DDTHH:MM:SS±HH:MM"
timezone: America/Montreal
status: draft
knowledge_kind: "<fact | observation | learning | open-question>"
certainty: "<confirmed | observed | inferred | uncertain>"
---

# CAPTURE — <titre>

Cette capture conserve une connaissance durable utile. Elle documente un fait, une observation, un apprentissage ou une question ouverte, mais ne constitue ni une proposal ni une décision.

## Contexte

<Pourquoi cette information mérite-t-elle de survivre à la session ?>

## Information capturée

<Fait, observation, apprentissage ou question ouverte.>

## Niveau de certitude

<Indiquer le niveau retenu et la preuve ou la source disponible.>

## Impact éventuel

<Conséquence possible, ou « Aucun impact identifié ».>

## Artefacts liés

- Source ou artefact : `<chemin relatif>`

## Limite

Cette capture ne doit pas être requalifiée silencieusement. Si une option doit attendre un arbitrage, créer une `PROPOSAL`; si un choix est arbitré, créer un artefact `DECISION` distinct avec le statut et le human gate appropriés.

## Liens

- `prescribed by` — [Cycle de contexte V2](../rules/RULES-2026-08-17-111018-context-lifecycle-v2.md)
- (à compléter : type — titre — chemin relatif, voir le standard de liens)
