---
type: decision
title: "Une fenêtre MCP, un workspace ; skills exposés en entier"
description: "Décision arbitrée le 2026-09-03 (ordre Owner, session Pilot) : un seul serveur MCP filesystem configuré une fois au niveau de l'application Desktop, racine = le workspace entier, fenêtre unique de toute session de chat vers les fichiers ; l'installation comprend ce MCP et les skills exposés au chat ; par défaut la liste entière des skills du projet est exposée à la session de chat, sous une HYPOTHÈSE de coût à mesurer avant toute réduction ; la liste des skills à installer se dérive de l'index des skills du Vault, jamais écrite à la main."
created_at: "2026-09-03T23:06:04-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
scope: mcp-filesystem, workspace-root, skills-exposure, installation
---

# DÉCISION — UNE FENÊTRE MCP, UN WORKSPACE ; SKILLS EXPOSÉS EN ENTIER

## Date

2026-09-03

## Statut

`ARBITRATED`

Arbitrage Owner donné en clair dans la session Pilot du 2026-09-03 (soir), avant la rédaction de la Mission 132-A. Aucune proposal source : la Décision vient directement de l'Owner.

## Décision

1. **Un seul serveur MCP filesystem par workspace.** Il est configuré une fois, au niveau de l'application Desktop, et sa racine est le workspace entier. Il est la fenêtre unique par laquelle toute session de chat, de tout projet, touche des fichiers. Aucun serveur MCP filesystem par projet ; un projet nouveau est un dossier du workspace, joignable sans reconfiguration. L'état actuel n'est pas affirmé par cette Décision, il est à mesurer : nom du serveur (`workshops` attendu), racine déclarée égale au workspace (par l'outil qui liste les répertoires autorisés), et fichier de configuration réellement lu par Desktop (même méthode que la Mission 128-bis pour le serveur Mnemosyne).

2. **L'installation comprend le MCP et les skills.** Le runbook d'installation (INSTALL.md), le skill first-install et le skill project-bootstrap disent explicitement, chacun à sa place : installer et configurer ce serveur MCP dans le fichier que Desktop lit ; installer les skills exposés aux sessions de chat. Une installation qui laisse une session de chat sans fenêtre fichiers ou sans skills est incomplète.

3. **Skills : liste entière exposée par défaut.** La session de chat reçoit la liste ENTIÈRE des skills du projet, pour savoir ce qui existe. HYPOTHÈSE à mesurer avant toute réduction : un skill exposé ne coûte dans le préfixe fixe de conversation que son nom et sa description, le corps ne se chargeant qu'à l'appel ; la mesure est « octets par skill × nombre de skills ». Si l'impact mesuré est négatif, le repli est nommé d'avance : un digest des skills généré, plafonné, fail-closed (nom, description, chemin de chaque skill), et seule la liste principale installée.

4. **La liste des skills à installer est dérivée, jamais écrite à la main.** Elle se dérive de l'index des skills du Vault, de façon déterministe, à partir du champ `description` de chaque skill. Registry v2 porte cette dérivation comme contrat de structure.

## Raison

- Deux serveurs MCP filesystem pour deux projets, c'est deux configurations à tenir, deux racines à mesurer et une reconfiguration à chaque projet nouveau — le contraire d'un système distribué à deux cents non-développeurs.
- Une session de chat qui ignore quels skills existent ne peut pas les invoquer : l'exposition entière est la condition de l'usage. La réduction est une optimisation, elle vient après la mesure, pas avant (Décision 140714 : le plafond attend la mesure).
- Une liste de skills écrite à la main dérive ; une liste dérivée d'un index généré ne peut pas diverger de la source.

## Impact

- La Mission 132-A « session-start : installation et conformité » prend cette Décision en Décisions applicables et ajoute à son volet mesure : point 1 (nom, racine déclarée, fichier lu) et point 3 (coût par skill × nombre).
- INSTALL.md et les skills first-install et project-bootstrap seront amendés par Mission, après mesure ; cette Décision n'édite aucun fichier existant.
- Registry v2 reçoit un contrat de plus : la dérivation de la liste des skills depuis l'index.
- Le point 3 est une HYPOTHÈSE : tant qu'elle n'est pas mesurée, la liste entière est la règle et le repli reste inactif.

## Alternatives importantes

- Un serveur MCP filesystem par projet, racine = le projet : rejeté (reconfiguration à chaque projet, racines multiples à mesurer, périmètre d'écriture Pilot éclaté).
- N'exposer au chat qu'une liste réduite de skills choisis à la main : rejeté par défaut, conservé comme repli du point 3 sous forme de digest généré, seulement si la mesure le justifie.
- Laisser l'installation des skills hors du runbook, à la charge de chaque participant : rejeté (installation incomplète par construction).

## Human gate

- Validation : accordée
- Référence : ordre Owner en clair, session Pilot du 2026-09-03 (soir), « Ordre Owner — Décision à graver avant la 132-A »

## Artefacts liés

- Proposal source : aucune
- Charte des rôles, §2 « Écriture — bornée » et §5 étage 2 (périmètre Pilot appliqué par la configuration du serveur MCP) : `vault/rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md`
- Rapport 131, contrat des gardiens rencontrés : (historique de l'atelier, non distribué)

## Liens

- `prescribed by` — [Cycle de contexte V2](../rules/RULES-2026-08-17-111018-context-lifecycle-v2.md)
- `see also` — [Charte des rôles et détermination de session](../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)
- `see also` — [Décision — Budget de contexte du Pilot](./DECISION-2026-09-03-140714-pilot-context-budget-mission-size-cap.md)
- `see also` — [Liste de lecture d'ouverture de session, par rôle](../skills/session-start/reading-list.md)
- `see also` — Rapport 131 — alignement du protocole d'ouverture Pilot (historique de l'atelier, non distribué) (hors Vault)
