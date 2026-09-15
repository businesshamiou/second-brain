# Instructions pour les agents

Before any action: determine your role. Read [the role charter](./rules/RULES-2026-08-23-224706-role-charter-and-session-determination.md).

- Les fichiers du Vault sont la source de vérité. Lire les sources liées avant toute modification.
- La mémoire du modèle n'est jamais une source d'état ni d'hypothèse : ce qui n'a pas été lu dans un fichier au cours de la session n'est pas connu. Ne pas se poser la question de l'existence d'un fichier est une forme d'affirmation.
- Sans serveur MCP filesystem actif ni accès shell : demander les fichiers à l'Owner et ne rien produire de mémoire.
- Rédiger la prose en français. Utiliser un anglais idiomatique pour les identifiants machine, slugs, clés et noms de dossiers.
- Enregistrer explicitement toute décision structurante. Ne jamais transformer silencieusement une proposition en décision.
- Appliquer le [cycle de contexte V2](./rules/RULES-2026-08-17-111018-context-lifecycle-v2.md) de façon sélective : capturer seulement ce qui sera durablement utile et créer une proposal uniquement lorsqu'une option importante doit attendre un arbitrage.
- Appliquer la [règle de versionnement des Missions et outputs générés](./rules/RULES-2026-08-17-211522-mission-versioning-and-generated-output.md) lorsqu’un projet utilise des Missions ou une landing zone `generated/`.
- Maintenir le fichier `<projet>/current-state.md` lorsqu’un projet l’utilise ; le mettre à jour au lieu d’empiler des états successifs.
- Produire un handoff seulement lorsqu’une reprise fiable est réellement nécessaire.
- Conserver toute décision structurante au statut `PROPOSED` jusqu’à son arbitrage par human gate.
- Ne jamais écrire de secret, clé, token, mot de passe ou credential dans le Vault ou dans Git.
- Des hooks Git contrôlent les secrets et les motifs de contournement ; ils s’activent par `core.hooksPath` pointant sur `.githooks/`. Cette configuration est locale et non versionnée : la refaire après tout clone.
- Inspecter chaque fichier avant staging, stage fichier par fichier par chemin explicite (`git add -- <chemin>`), puis inspecter le diff staged du même chemin (`git diff --cached -- <chemin>`). Le staging en masse est banni sous toutes ses formes : `git add .` et `git add -A`, qui stagent un dossier ou un dépôt entier ; `git add -u`, qui stage toutes les modifications suivies ; `git commit -a`, qui stage et commite sans inspection. Motif : les gardiens ne contrôlent que les fichiers stagés — stager sans lire élargit silencieusement la surface qu'ils valident et fait passer pour vérifié ce que personne n'a lu.
- Remesurer l'état technique et les preuves au moment utile au lieu de recopier des valeurs périssables.
- Gestes réservés à l'Owner, jamais exécutés par un agent même autorisé : `push`, suppression définitive (substitut agent : déplacement vers `_trash/` à la racine de l'espace de travail, [Décision 110852](./decisions/DECISION-2026-08-29-110852-deletion-is-owner-gesture-trash-zone.md)). Exiger un human gate pour tout renommage structurant, partage sensible ou autre action sensible. Le push peut être délégué à une fenêtre Executor par une autorisation Owner verbatim et datée ([Décision 154553](./decisions/DECISION-2026-08-26-154553-delegated-push-exception-becomes-rule.md)) ; sans cette ligne exacte, l'Executor refuse.
- Maintenir la frontière entre le Vault et les projets externes : le Vault contient le transversal ; chaque projet conserve son contexte local.
- Ne jamais importer automatiquement dans le Vault le contexte métier, les décisions ou les artefacts propres à un projet.
- Toute amélioration transversale issue d’un projet doit être validée avant son intégration au Vault.
- Ne pas introduire dans le Vault les prompts, présentations, storyboards, supports ou outils dont le seul rôle est de fabriquer le workshop.
- Tout rapport d'exécution de l'Executor est un fichier dans le dossier `reports/` du projet en cours (Decision du 2026-08-21) ; en chat, deux lignes : chemin du rapport et ligne « gates ».
- L'ancien runbook d'installation du Vault est retiré de la distribution ; conservé, non supprimé, dans [`_trash/`](./_trash/runbook-vault-setup.md), à titre historique seulement — plus d'obligation de mise à jour.
- Tout document porte une section `## Liens` conforme au [standard de liens](./rules/RULES-2026-08-21-115658-document-linking-standard.md) ; le contrôle `tools/check-links.sh` tourne au pre-commit.
- Toute délégation à l'Executor suit la [règle du relais entre rôles par mini-prompts](./rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md) : mini-prompt à l'aller, bloc `RELAY` en fin de rapport au retour.
- Pour tout travail dans `skills-warehouse/` : lire d'abord [`skills-warehouse/AGENTS.md`](./skills-warehouse/AGENTS.md) — ce sous-dossier suit ses propres conventions, distinctes de celles ci-dessus (T02, Mission 168). Codex le charge automatiquement quand il est lancé dans ce sous-dossier ou plus bas ; cette ligne route Codex lancé à la racine et tout autre agent vers la même source.

## Liens

- `applies` — [Cycle de contexte V2](./rules/RULES-2026-08-17-111018-context-lifecycle-v2.md)
- `applies` — [Standard de liens entre documents](./rules/RULES-2026-08-21-115658-document-linking-standard.md)
- `applies` — [Relais entre rôles par mini-prompts à rubriques fixes](./rules/RULES-2026-08-23-124937-role-relay-mini-prompts.md)
- `applies` — [Décision — La suppression définitive est un geste Owner](./decisions/DECISION-2026-08-29-110852-deletion-is-owner-gesture-trash-zone.md)
