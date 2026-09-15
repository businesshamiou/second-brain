---
type: decision
title: "Balayage d'existence avant toute recommandation de création ; la mémoire n'est jamais source d'hypothèse ; rubrique « Existant mesuré » au gabarit de Mission"
description: "Décision arbitrée le 2026-09-04 après un angle mort mesuré : le Pilot a recommandé de créer un fichier d'entrée qui existait déjà, et l'Owner a arbitré « go » avant qu'aucun contrôle ne joue. Trois points : toute recommandation de création porte, dans la même réponse, un balayage d'existence ; la règle « la mémoire n'est jamais une source d'état » s'étend aux hypothèses sur ce qui existe ; le gabarit de Mission reçoit une rubrique obligatoire « Existant mesuré », avec gardien, pour toute Mission qui crée un fichier."
created_at: "2026-09-04T12:14:43-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
scope: pilot-recommendations, memory-doctrine, mission-template
---

# DÉCISION — BALAYAGE D'EXISTENCE, MÉMOIRE ET HYPOTHÈSES, RUBRIQUE « EXISTANT MESURÉ »

## Date

2026-09-04

## Statut

`ARBITRATED`

Arbitrage Owner en clair, session Pilot du 2026-09-04 (nuit), gate « grave », après analyse d'un angle mort mesuré dans la même session.

## Fait déclencheur

Interrogé sur la manière dont une session de chat atteint le Vault, le Pilot a recommandé de créer un fichier d'entrée unique à la racine du Vault. L'Owner a arbitré « go ». La règle de lecture des gabarits a ensuite conduit le Pilot à lister la racine du Vault : `CLAUDE.md` s'y trouvait, portant déjà la ligne d'entrée exacte (« avant toute action, détermine ton rôle, lis la charte »), aux côtés de `AGENTS.md`, `README.md`, `INSTALL.md`, `USER.md` et `index.md`. La recommandation était un doublon. Un seul appel de listage, avant la recommandation, l'aurait évitée.

Le même tour a montré que le mécanisme cherché existait aussi : `VAULT-ROOT.md` à la racine du workspace, généré par `tools/write-marker.sh`, porte le chemin relatif du Vault ; la racine du workspace se demande au serveur MCP. Aucun chemin n'a besoin d'être figé hors dépôt.

## Décision

1. **Balayage d'existence avant toute recommandation de création.** Toute réponse du Pilot qui recommande de créer un fichier, un outil, un skill ou un mécanisme porte, dans la même réponse et avant la recommandation, le résultat d'un balayage : le dossier de destination listé, et la fonction visée cherchée dans les index du Vault ou par `tools/find-in-vault.sh`. Sans balayage montré, la recommandation n'est pas émise et aucun arbitrage n'est demandé. Le coût est d'un à deux appels ; le coût de l'omission est un arbitrage Owner rendu sur une base fausse.

2. **La mémoire n'est jamais une source d'hypothèse.** La règle existante — la mémoire du modèle n'est jamais une source d'état — se lisait comme une interdiction de *citer* la mémoire. Elle s'étend explicitement à l'usage tacite : la représentation qu'un agent se fait du contenu du Vault, héritée de sessions passées ou d'un résumé, ne fonde ni une recommandation, ni une conception, ni la décision de ne pas vérifier. Ne pas se poser la question de l'existence d'un fichier est une forme d'affirmation.

3. **Rubrique « Existant mesuré » au gabarit de Mission.** Toute Mission dont le Périmètre comporte la création d'un fichier porte une rubrique « Existant mesuré » : commande de listage ou de recherche jouée, sortie, et conclusion explicite (« aucun fichier ne remplit cette fonction » ou « le fichier X la remplit partiellement, la Mission l'amende au lieu de créer »). Un gardien refuse au commit une Mission qui crée sans cette rubrique remplie. La détection de la création se fait sur la présence, dans le Périmètre, d'un chemin absent du dépôt.

## Raison

- Les sept gardiens, le contrat de sortie des rapports et le challenge avant émission portent tous sur des **artefacts commités**. La prose de chat du Pilot n'a aucun contrôle — or c'est exactement le support sur lequel l'Owner arbitre. Le seul artefact non gardé du système est celui qui déclenche toutes les décisions.
- Le challenge avant émission, institué la même nuit, a bien trouvé le doublon — mais en aval de l'arbitrage, et par effet secondaire d'une autre règle. Un contrôle qui ne joue qu'après la décision de l'Owner protège l'exécution, pas la décision.
- La doctrine « mesurer avant d'affirmer » portait sur les états vérifiables. Un design proposé n'est pas un état ; il échappait donc à la règle tout en engageant davantage.

## Impact

- Le gabarit `templates/mission-template.md` reçoit la rubrique ; les Missions existantes ne sont pas rétroactivement amendées.
- Un gardien reste à écrire ; tant qu'il n'existe pas, le point 3 est doctrinal — donc, par le constat répété de ce projet, sujet à dérive. Il rejoint la file de la Mission 132 « contrat gardiens ».
- Les points 1 et 2 ne sont mécanisables par aucun gardien : rien ne lit le chat. Ils sont assumés comme doctrinaux et consignés à la checklist du skill `écriture-de-mission`.
- Premier cas d'application : la Mission qui ajoute à `CLAUDE.md` et `AGENTS.md` les deux règles universelles aujourd'hui hors dépôt (mémoire jamais source d'état ; sans MCP, demander les fichiers et ne rien produire), au lieu de créer un fichier d'entrée nouveau.

## Alternatives importantes

- Un gardien qui analyserait les réponses du Pilot : rejeté, rien ne lit le chat ; la contrainte serait doctrinale sous un déguisement mécanique.
- Élargir le challenge avant émission à toute recommandation : rejeté comme unique remède — il se joue après l'arbitrage de l'Owner ; il reste utile en aval, il ne remplace pas le balayage en amont.
- Ne rien graver et consigner la faute à la checklist : rejeté, le motif est structurel et non un lapsus isolé.

## Human gate

- Validation : accordée
- Référence : ordre Owner en clair, session Pilot du 2026-09-04 (nuit), gate « grave »

## Artefacts liés

- Proposal source : aucune
- Décision amendée dans son esprit (mémoire, hypothèses) : `./DECISION-2026-09-03-140714-pilot-context-budget-mission-size-cap.md`
- Fait déclencheur consigné en fautes Pilot : (historique de l'atelier, non distribué) (hors Vault)

## Liens

- `prescribed by` — [Cycle de contexte V2](../rules/RULES-2026-08-17-111018-context-lifecycle-v2.md)
- `see also` — [Charte des rôles et détermination de session](../rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md)
- `see also` — [Décision — Budget de contexte du Pilot](./DECISION-2026-09-03-140714-pilot-context-budget-mission-size-cap.md)
- `see also` — [Décision — Une fenêtre MCP, un workspace ; skills exposés en entier](./DECISION-2026-09-03-230604-one-mcp-window-per-workspace-skills-fully-exposed.md)
- `see also` — [Décision — Statuts d'évidence et contrôle des STOP](./DECISION-2026-08-29-212009-evidence-status-and-stop-control.md)
- `see also` — [Liste de lecture d'ouverture de session, par rôle](../skills/session-start/reading-list.md)
