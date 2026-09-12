# Standard canonique de portabilité

> **Amendement de stockage actuel :** les règles de portabilité ci-dessous restent normatives. Les exemples d’originaux locaux sous `sources/originals/` sont historiques : les originaux complets sont désormais archivés hors Git, avec preuve légère sous `provenance/`. Voir [THIN_REPOSITORY_STANDARD.md](THIN_REPOSITORY_STANDARD.md).

La normalisation du front-matter et le double emballage sont régis par [PRODUCTION_STANDARD.md](PRODUCTION_STANDARD.md). Toute modification du corps lors du packaging exige une exception déclarée dans le rapport de validation.

Ce document est l’unique politique normative de portabilité de la bibliothèque. [INGESTION_STANDARD.md](INGESTION_STANDARD.md) est la norme complémentaire qui gouverne la détection, la résolution et l’entrée des sources. Les fichiers propres à un runtime, notamment `AGENTS.md`, `CLAUDE.md`, les métadonnées `agents/` et les éventuels `adapters/`, ne font que pointer vers ces normes ou traduire un mécanisme d’exécution. Ils ne définissent jamais une politique concurrente.

## 1. Portée

La distribution active sous `skill-collections/<collection>/skills/` doit fournir une version canonique de chaque Skill, compréhensible par tout runtime capable d’interpréter un `SKILL.md`. La classification et la propriété des collections sont régies par [COLLECTIONS_STANDARD.md](COLLECTIONS_STANDARD.md). Le dossier racine `skills/` reste l’instantané legacy jusqu’à une migration explicite. La portabilité vise notamment ChatGPT, Codex, Claude et Claude Code, sans supposer qu’ils exposent les mêmes outils.

Un Skill canonique sépare quatre niveaux :

1. **Intention** — le résultat recherché et les limites de la tâche.
2. **Workflow** — les décisions et étapes logiques qui produisent ce résultat.
3. **Capabilities** — les capacités nécessaires ou optionnelles : fichiers, shell, Git, web, navigateur, API, exécution de code, délégation, interaction humaine.
4. **Runtime** — la façon dont un environnement particulier fournit ces capacités.

Le cœur canonique décrit principalement intention, workflow et capabilities. Le runtime choisit l’implémentation disponible.

## 2. LLM et runtime agnosticism

- Nommer une capacité plutôt qu’un outil propriétaire : « utiliser la capacité de recherche web disponible », « déléguer à un agent isolé si le runtime le permet », « afficher ou ouvrir le fichier si cette capacité existe ».
- Référencer un autre Skill par son nom canonique et son workflow. Le runtime peut l’invoquer nativement; sinon l’agent lit son `SKILL.md` et l’applique directement.
- Ne pas imposer de syntaxe d’invocation propre à un runtime dans le workflow canonique.
- Ne pas supposer la présence de sous-agents, tâches en arrière-plan, navigateur, shell, système de fichiers, MCP, API ou exécution de code.
- Une métadonnée runtime optionnelle est acceptable seulement si elle est isolée, ignorée sans danger par les autres runtimes et non requise pour comprendre ou exécuter le workflow.

## 3. Dégradation gracieuse

Pour chaque capacité optionnelle :

1. utiliser la meilleure capacité réellement disponible;
2. utiliser un équivalent documenté;
3. exécuter séquentiellement ou localement lorsque le résultat reste fidèle;
4. sinon signaler précisément la limitation et produire la meilleure sortie partielle honnête.

Exemples :

- Sans délégation, exécuter les travaux indépendants séquentiellement en préservant leur isolation logique.
- Sans accès web, limiter la recherche aux sources locales et ne pas prétendre avoir vérifié des faits externes actuels.
- Sans écriture de fichiers, retourner le contenu complet à enregistrer et signaler qu’il n’a pas été persisté.
- Sans capacité d’ouverture graphique, fournir le chemin ou l’URL à ouvrir manuellement.

Une capacité essentielle à la nature de la tâche peut rester obligatoire. Le Skill doit alors la nommer clairement et échouer avec une limitation explicite plutôt que simuler le résultat.

## 4. Dépendances essentielles et accidentelles

Une dépendance est **essentielle** lorsque le fournisseur, protocole, produit ou environnement est l’objet même du Skill. Un Skill qui configure les hooks Claude Code peut légitimement utiliser `.claude/` et le format `PreToolUse`. Cette dépendance est conservée, classée `INTRINSIC-PROVIDER-DEPENDENCY` et visible dans le registre et le rapport de compatibilité.

Une dépendance est **accidentelle** lorsque le même résultat peut être décrit par une capacité générique. Une recherche générique ne doit pas exiger un outil de tâche particulier; une revue indépendante ne doit pas exiger des sous-agents si deux passes séquentielles isolées conservent le workflow.

La normalisation analyse la fonction de chaque instruction. Les remplacements textuels globaux de noms de fournisseurs sont interdits.

## 5. Adapters de runtime

Créer `adapters/` uniquement lorsqu’une différence d’exécution réelle et maintenable doit être documentée.

- `SKILL.md` demeure la source canonique.
- Un adapter contient uniquement la traduction runtime d’une capacité ou d’une métadonnée.
- Un adapter ne duplique pas le workflow et ne devient pas requis pour les runtimes génériques.
- Aucun fichier vide ou adapter mécanique n’est créé.
- Les métadonnées existantes comme `agents/openai.yaml` sont des adapters optionnels de packaging; le workflow ne doit pas dépendre de leur chargement.
- Les extensions de frontmatter comme `disable-model-invocation` peuvent être conservées pour préserver une politique d’invocation lorsqu’elles sont ignorées sans danger ailleurs. Leur sémantique doit être documentée dans un adapter pertinent.

## 6. Scripts et ressources

- Inspecter tous les scripts, templates, références et assets utilisés par le Skill.
- Éliminer les SDK, chemins, clés et commandes fournisseur hardcodés lorsqu’ils sont accidentels.
- Conserver une intégration fournisseur lorsqu’elle correspond à une branche explicitement choisie ou à l’objet du Skill; la nommer honnêtement.
- Fournir un fallback manuel ou local lorsque cela conserve le résultat.
- Ne jamais remplacer aveuglément un SDK fournisseur par un autre.
- Valider la syntaxe des scripts modifiés avec l’outil approprié lorsqu’il est disponible; sinon effectuer une inspection statique et documenter la limite.

## 7. Provenance et originaux

- Toute source est traitée par lecture et copie; elle n’est jamais modifiée.
- Avant de normaliser un Skill, copier son dossier original complet sous `sources/originals/<source>/<skill>/` et vérifier les hashes.
- `sources/originals/` est une archive locale : elle n’est jamais un ensemble de Skills actifs et n’entre jamais dans le ZIP maître.
- Le registre conserve source, version ou commit, hash original de `SKILL.md`, hash canonique, fichiers modifiés, raison et classification.
- Une nouvelle version n’écrase jamais automatiquement une version existante en cas d’ambiguïté; utiliser `OPEN — VERSION CONFLICT`.

## 8. Place dans le pipeline permanent d’ingestion

Toute nouvelle source suit obligatoirement le pipeline complet défini dans `INGESTION_STANDARD.md` :

INGEST → RESOLVE SOURCES → INSPECT → IDENTIFY SKILLS → SECURITY CHECK → FILTER → CLASSIFY COLLECTION → DEDUPLICATE WAREHOUSE-WIDE → PORTABILITY AUDIT → LLM-AGNOSTIC NORMALIZATION → LICENSE AUDIT → PRESERVE ORIGINAL → INTEGRATE INTO COLLECTION → UPDATE COLLECTION RECORDS → PACKAGE COLLECTION → VALIDATE → GENERATE SHA-256

La présente norme régit les étapes `PORTABILITY AUDIT` et `LLM-AGNOSTIC NORMALIZATION` ainsi que les critères de portabilité vérifiés lors de `VALIDATE`. Aucun fichier ne passe directement d’une source ou de `intake/` à une collection active avant ces étapes. Les dossiers deprecated, obsolete, experimental, WIP ou in-progress ne sont pas actifs.

## 9. Classifications d’audit

- `UNIVERSAL` — déjà LLM et runtime agnostique.
- `MINOR-PORTABILITY-FIX` — correction locale sans changement substantiel du workflow.
- `RUNTIME-COUPLED` — dépendance accidentelle structurante nécessitant une refactorisation.
- `INTRINSIC-PROVIDER-DEPENDENCY` — dépendance légitime car le fournisseur est l’objet du Skill.
- `OPEN` — décision humaine requise avant activation ou écrasement.

## 10. Critères d’acceptation

Un Skill peut être `ACTIVE` seulement si :

1. son intention et son résultat attendu sont clairs;
2. son workflow original utile est préservé;
3. ses dépendances runtime accidentelles sont supprimées ou isolées;
4. ses dépendances essentielles sont explicites;
5. ses ressources locales existent et leurs chemins sont valides;
6. ses capacités optionnelles ont un fallback raisonnable;
7. sa provenance et, s’il a été modifié, son original sont conservés;
8. il ne crée aucun doublon ou écrasement ambigu;
9. son frontmatter, sa structure et ses scripts sont valides.

## 11. Validation

Un résultat `PASS` couvre simultanément structure, intégrité, provenance, déduplication et portabilité.

La validation vérifie au minimum :

- un `SKILL.md` valide par Skill actif;
- les références locales et l’autonomie des dossiers;
- l’unicité des noms canoniques;
- les hashes actifs et originaux;
- la cohérence du registre, de l’index, du manifest et du rapport de compatibilité;
- l’absence de dépendance runtime accidentelle non documentée;
- l’exclusion de `sources/originals/`, `intake/`, autres collections, dossiers `releases/`, clones, caches et ZIP récursifs du ZIP de collection;
- l’ouverture et le contenu exact de tous les ZIP.

Le rapport multi-runtime est une analyse statique. Il ne doit jamais être présenté comme un test d’exécution réel dans un runtime non exécuté.
