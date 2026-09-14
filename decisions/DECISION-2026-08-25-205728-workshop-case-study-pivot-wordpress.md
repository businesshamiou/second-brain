---
type: decision
title: "Pivot du cas d'usage de l'atelier — abandon de « Une semaine sans écran », adoption du cas WordPress piloté par le Vault"
created_at: "2026-08-25T20:57:28-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
amends: "./DECISION-2026-08-23-124848-seven-arbitrations-2026-08-23.md"
rapatriated_from: "workshop-build/workshop-production/decisions/DECISION-2026-08-25-205728-workshop-case-study-pivot-wordpress.md"
---

# DÉCISION — PIVOT DU CAS D'USAGE DE L'ATELIER

## Date

2026-08-25

## Statut

`ARBITRATED`

Arbitré en séance par l'Owner le 2026-08-25, en session Pilot `plan · open`, sur brainstorming point par point.

## Décision

Six points arbitrés d'un bloc.

1. **Abandon.** Le cas d'étude « Une semaine sans écran / MiroShark » est abandonné comme cas d'usage de l'atelier. Il ne doit plus être proposé ni servir de fil rouge. Son sort matériel dans les dépôts (inventaire puis suppression éventuelle) reste un geste Executor sous human gate ; aucune suppression n'est autorisée par la présente Décision.

2. **Nouveau cas d'usage.** L'atelier construit un site WordPress — Elementor, thème Blocksy en version gratuite, NovaMira comme pont MCP entre l'assistant et WordPress — **piloté par la méthode du Vault**, avec un environnement de *staging* et une promotion explicite vers la production.

3. **Deux ressources distinctes, hiérarchisées.** Le Vault est le **produit** : c'est la ressource à laquelle l'audience aura accès et qu'elle réutilisera pour n'importe quel projet. L'atelier WordPress est la **preuve** que le Vault tient debout sur un travail réel. Les matériaux de l'atelier peuvent être inclus dans le paquet distribué, mais ils n'en sont pas le cœur. Toute conception ultérieure du contenu respecte cette hiérarchie.

4. **Audience et motif.** Environ 200 non-développeurs suivant les programmes de l'académie. Ils pratiquent déjà WordPress dans ces programmes et le vivent comme une difficulté. Le cas d'usage n'est donc pas un prérequis à enseigner mais une douleur existante à adresser.

5. **Format.** L'Owner construit seul ; la salle regarde. Séance enregistrée. Une fiche récapitulative reprenant les étapes, le contexte et le matériel est distribuée. Aucune construction en direct par les participants n'est prévue : la chaîne de dépendances (hébergement, domaine, DNS, greffons, Node.js, connecteur MCP) reste du côté de l'Owner.

6. **Durée.** Cible 3 h à 3 h 30, rythme habituel de l'académie.

## Raison

Le cas précédent ne satisfaisait pas deux critères devenus visibles à l'examen : il ne s'appuyait sur aucune douleur vécue par l'audience, et il ne fournissait pas de preuve que la méthode résiste à un travail réel et salissant.

Le cas WordPress les satisfait tous deux. Il part d'un échec que l'audience subit déjà, et il oppose à ce que fait couramment l'état de l'art — un prompt collé, un résultat attendu, une publication directe en production, aucune trace des décisions — les trois pièces que le Vault apporte : un environnement jetable avant la production, un corpus versionné où le plan, les décisions et les prompts sont des artefacts datés, et des gestes bornés et vérifiables plutôt qu'une commande unique.

La levée du format « l'Owner construit seul » supprime par ailleurs le risque principal identifié au brainstorming : la durée non maîtrisable des phases de génération, mesurée à environ dix minutes pour la conception et environ une heure pour la migration dans la source externe étudiée.

## Impact

- La porte `open-workshop-deliverable` change d'objet et reste ouverte.
- Le projet modèle démontable du lot E (`open-distribution-lot-e`) doit être réexaminé : le paquet distribuable et le matériel d'atelier partagent une partie de leur substance sans se confondre, le Vault restant le produit.
- La chaîne de démonstration prévue (ChatGPT + Codex en principal) entre en tension avec le nouveau cas, dont l'outillage naturel est un assistant de bureau connecté par MCP. **Point non arbitré**, à trancher séparément.
- L'ordre de travail arbitré au handoff du 2026-08-25 est amendé : la construction du Vault et son empaquetage passent devant la conception du contenu de l'atelier.
- Un découpage du déroulé en cinq blocs a été esquissé en séance ; il est **explicitement non retenu à ce stade**, ayant été construit avant que la hiérarchie du point 3 ne soit établie.

## Alternatives importantes

- **Conserver « Une semaine sans écran ».** Rejetée : aucune douleur d'audience, aucune preuve de robustesse de la méthode.
- **Reproduire le tutoriel externe tel quel.** Rejetée : c'est une démonstration de produit, non de méthode ; elle ne laisse aucune trace relisible et publie directement en production.
- **Faire construire les participants en direct.** Rejetée : chaîne de dépendances ingérable pour environ 200 non-développeurs en visioconférence.

## Human gate

- Validation : accordée
- Référence : arbitrage en séance de l'Owner, session Pilot du 2026-08-25 ; consigné au journal.

## Artefacts liés

- Source externe étudiée (à déposer) : étude de cas du tutoriel WordPress externe, `../knowledge-notes/`
- Ordre de travail amendé : `../handoffs/HANDOFF-2026-08-25-145859-pilot-session-close-purge-anglicization-content-plan.md` (supprimé)

## Liens

- `prescribed by` — [Cycle de contexte V2](../rules/RULES-2026-08-17-111018-context-lifecycle-v2.md)
- `amends` — Clôture de session Pilot 2026-08-25 (historique de l'atelier, non distribué)
- `amends` — [Décision — Sept arbitrages de session du 2026-08-23](./DECISION-2026-08-23-124848-seven-arbitrations-2026-08-23.md)
- `see also` — [Charte des rôles et détermination de session](../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)
