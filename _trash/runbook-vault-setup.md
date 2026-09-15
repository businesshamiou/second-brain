---
type: knowledge
title: "Runbook d'installation du Vault — V1"
description: "Mode d'emploi ordonné pour installer et vérifier le Vault et son outillage ; registre vivant mis à jour par toute Mission qui touche à l'installation."
created_at: 2026-08-21T10:51:17-04:00
timezone: America/Montreal
status: active
---

# RUNBOOK D'INSTALLATION DU VAULT — V1

Mode d'emploi ordonné pour installer et vérifier le Vault et son outillage. Complète le [README](../README.md) (pourquoi/quoi) par le comment. Chaque ligne de fait porte `[VERIFIED]` (mesurée par l'Executor au moment de l'écriture, commande à l'appui) ou `[DECLARED — source]` (reprise d'un document cité). Une ligne `DECLARED` devient `VERIFIED` quand une Mission ultérieure la mesure. Voir les [deux principes de vérification](../knowledge/verification-and-evidence.md) : *measure, don't copy*.

**Obligation de mise à jour** : toute Mission qui installe, met à jour, configure ou retire un composant met ce runbook à jour **dans le même commit** ([Decision](../decisions/DECISION-2026-08-21-105117-vault-installation-runbook.md)). Le rapport d'exécution de cette Mission porte une section « Impact sur l'installation ».

## 1. Prérequis

- [VERIFIED] OS : Windows, `cmd /c ver` → `Microsoft Windows [version 10.0.26200.9168]` (Windows 11 Pro).
- [VERIFIED] Git : `git --version` → `git version 2.55.0.windows.2`.
- [VERIFIED] Python : la commande nue `python` sur ce poste ne résout **pas** vers un interpréteur (`python --version` renvoie le message de l'alias Microsoft Store « Python was not found »). Un interpréteur réel existe : `python3.12.exe` → `Python 3.12.13`.
- [VERIFIED] `uv` : `uv --version` → `uv 0.11.28 (ebf0f43d7 2026-07-07 x86_64-pc-windows-msvc)`. C'est le gestionnaire utilisé pour installer Graphify (§4).
- [VERIFIED] Node.js : `node --version` → `v24.18.0`. Non requis par le Vault lui-même ; présent sur le poste.
- [VERIFIED] Claude Code (CLI) : `claude --version` → `2.1.238 (Claude Code)`. C'est la session Executor.
- [DECLARED — `CAPTURE-2026-08-19-013315`] Claude Desktop est utilisé par le Pilot, installé via Microsoft Store (virtualisation MSIX — voir §5).

## 2. Dépôts

- `vault` (ce dépôt) : transversal — `decisions/`, `knowledge/`, `rules/`, `templates/`, `skills/`, `handoffs/`, `tests/`, `graphify-out/` (supprimé, Mission 040), `AGENTS.md`, `README.md`. [VERIFIED] `git remote -v` → origin distant configuré (fetch + push). Branche : `main`.
- (historique de l'atelier, non distribué) (dépôt frère, (historique de l'atelier, non distribué) depuis `vault`) : missions, prompts, rapports, audits, captures, proposals, handoffs, registre (MISSION-INDEX.md). [VERIFIED] `git remote -v` → origin distant configuré (fetch + push). Branche : `main`.
- [DECLARED — `CAPTURE-2026-08-19-013315`] Relation frère : les deux dépôts sont clonés côte à côte, (historique de l'atelier, non distribué) accessible depuis `vault` via (historique de l'atelier, non distribué) et réciproquement.
- Les sessions Executor s'ouvrent **uniquement dans `vault`** (§6).

## 3. Git

- [VERIFIED] `git config core.hooksPath` → `.githooks`. Cette configuration est **locale, non versionnée** : à refaire après tout clone (`git config core.hooksPath .githooks`) — [DECLARED — `AGENTS.md:12`].
- [VERIFIED] Contenu de `.githooks/` : `commit-msg`, `pre-commit`, `pre-push` (tous exécutables). `post-commit` et `post-checkout` (écrits par Graphify) ont disparu avec le retrait de Graphify (Mission 040, §4) : plus aucune reconstruction déclenchée après un commit ou un changement de branche.
  - `pre-commit`, `pre-push`, `commit-msg` : garde-fous (contrôle de secrets — voir `tools/check-secrets.sh`, qui refuse par défaut si `rules/patterns/secret-patterns.txt` est introuvable ; contrôle de liens — voir `tools/check-links.sh`, appelé juste après dans `pre-commit`, qui bloque tout `.md` stagé sans section `## Liens` ou avec un lien relatif cassé, et avertit sans bloquer en l'absence de lien interne — [Standard de liens entre documents](../rules/RULES-2026-08-21-115658-document-linking-standard.md)). Les deux contrôles sont précédés par la muraille de préflight (`tools/session-preflight.sh`, §10), qui refuse tout commit si son tampon est absent, `ready: false` ou périmé.
  - [VERIFIED] Gardien de fraîcheur des index (Mission 089) : `tools/check-indexes-fresh.sh`, invoqué dans `pre-commit` après le gardien de réciprocité et avant `tools/check-links.sh`. Ne régénère jamais : refuse tout commit dont un `.md` stagé (ajout, modification, renommage, suppression) laisse l'`index.md` de son dossier périmé (entrée manquante ou en trop, `status`/`description` désynchronisés), en lisant le format produit par `tools/build-indexes.sh` sans le redéfinir. Canaris mesurés : ajout non régénéré → refus une ligne ; régénération puis staging → silence, worktree identique après retrait du canari ; suppression stagée non régénérée → refus (« entrée en trop ») ; état réel du corpus au moment de l'écriture → silence (aucun index périmé).
  - Ne jamais modifier un hook écrit par l'outil [DECLARED — `AGENTS.md:17`] ; un rôle ne modifie pas son propre garde-fou.
- [VERIFIED] `.gitattributes` (Mission 062) → `* text=auto` et `*.sh text eol=lf`, normalisation des fins de ligne dans les deux dépôts. Remplace l'ancienne entrée `graphify-out/graph.json merge=graphify` (merge driver dédié au graphe généré), sans objet depuis le retrait de Graphify (Mission 040, §4).

## 4. Graphify — retiré

- [VERIFIED] Graphify est retiré du rôle « graphe du Vault » par la [Décision du 2026-08-23](../decisions/DECISION-2026-08-23-184200-graphify-graph-role-withdrawal.md), gestes exécutés par la Mission 040 : hooks Git (`post-commit`, `post-checkout`), merge driver `.gitattributes`, rappel automatique aux appels d'outils, sections d'instruction (`AGENTS.md`, `CLAUDE.md`), `graphify-out/` (supprimé, Mission 040), `.graphifyignore` (supprimé, Mission 040) (deux dépôts), paquet `graphifyy` (`uv tool uninstall`), variable `GEMINI_API_KEY` (`.env.example`) retirés ou désinstallés. Ce paragraphe ne décrit plus une installation active ; il ne subsiste que comme repère historique.
- Le système de navigation qui a remplacé Graphify (fiche d'état générée, index générés par dossier, recherche par contenu, liens écrits) reste décrit aux §8 et §10 — inchangé par ce retrait.
- Trace complète (argumentaire, mesures, verdict) conservée dans l'étude de cas Graphify (historique de l'atelier, non distribué), matériau du workshop non retiré par cette Mission.

## 5. Serveur MCP « workshops »

- [VERIFIED] Bloc de configuration lu dans le fichier de config de Claude Desktop (emplacement ci-dessous), **sans valeur sensible** :
  ```json
  "workshops": {
    "command": "mcp-server-filesystem",
    "args": ["<chemin absolu vers la racine du workspace>"]
  }
  ```
  Dossier exposé : la racine du workspace contenant `vault` et (historique de l'atelier, non distribué) (chemin absolu, propre à la machine — voir l'annexe historique).
- [DECLARED — `HANDOFF-2026-08-20-231741-pilot-session-closure-decision-status-mcp.md:120-125`] Emplacement réel du fichier de configuration (l'installation Microsoft Store de Claude Desktop virtualise le chemin classique) : %LOCALAPPDATA%\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Roaming\Claude\claude_desktop_config.json. [VERIFIED] ce chemin exact existe sur ce poste (fichier trouvé et lu).
- [DECLARED — `CAPTURE-2026-08-19-013315`] Usage : le Pilot lit ses sources directement via ce serveur (lecture/écriture de fichiers). Le Pilot **ne lance jamais de commande Git** — voir §6.
- [DECLARED — `decisions/DECISION-2026-08-19-233650-graphify-integrations-amendment.md`, D5] La mise en service d'un serveur MCP Graphify (`graphify-mcp.exe`, présent mais non configuré ci-dessus) reste hors périmètre : à décider par une Mission distincte.

## 6. Rôles et sessions

- [DECLARED — `CAPTURE-2026-08-19-013315:64-74`] **Pilot** (Chat Advisor) : brainstorm, arbitrage, architecture, cadrage, rédaction des Missions et Prompts, review, passations. Accès MCP « workshops » en lecture/écriture de fichiers. Ne touche jamais le filesystem par une commande Git et ne lance pas de commande shell. Session : Claude Desktop.
- [DECLARED — `CAPTURE-2026-08-19-013315`] **Executor** : filesystem, Git, exécution, tests, mesures, preuves. Ne décide jamais l'architecture. Seul rôle à committer. Session : Claude Code, ouverte **dans `vault/`** uniquement.
- [DECLARED — `AGENTS.md:15`] **Owner** : seul rôle habilité à pousser (`git push`) et à accorder les human gates (secrets, mises à jour de version système, tout ce qui sort du périmètre autorisé d'une Mission).
- [DECLARED — `decisions/DECISION-2026-08-21-000236-execution-report-channel.md`] Missions et Prompts : (historique de l'atelier, non distribué). Rapports d'exécution : (historique de l'atelier, non distribué), un fichier par Mission, stagé avec le travail qu'il prouve. Audits, captures, proposals, handoffs, decisions : voir les dossiers correspondants dans les deux dépôts.

## 7. Vérification de bon fonctionnement

Une commande et son résultat attendu, par composant :

| Composant | Commande | Résultat attendu |
|---|---|---|
| Git | `git status -sb` | branche courante, aucune divergence inattendue |
| Hooks | `git config core.hooksPath` puis lister `.githooks/` | `.githooks` ; `commit-msg`, `pre-commit`, `pre-push` seulement (§3) |
| Muraille de préflight | `bash tools/session-preflight.sh` | `READY` ; tampon `.claude/.preflight_stamp.json` écrit avec `"ready": true` |
| MCP « workshops » | lecture d'un fichier connu du Vault depuis le Pilot | contenu retourné sans erreur |
| Contrôle de liens | `bash tools/check-links.sh` sur un `.md` stagé sans section `## Liens` | `exit 1`, message `LIENS: section manquante: <fichier>` |

## 8. Outillage d'état, journal, index et recherche (Missions 027 et 029)

Cinq scripts créés en Mission 027, deux modifiés en Mission 029, plus trois gabarits. Tous dans `tools/` (scripts) et `templates/` (gabarits) ; aucun n'appelle de modèle.

- [VERIFIED] `tools/append-journal.sh <chemin-projet> "<texte>"` : ajoute une ligne horodatée en fin de `<projet>/state/journal.md`, création du fichier et du dossier si absents. N'ouvre jamais le journal en lecture. Convention de tags reconnue en préfixe du texte, ratifiée par la [Decision du 2026-08-23 14:35](../decisions/DECISION-2026-08-23-143542-pilot-contract-superseded-marking-and-journal-tags-ratification.md) : `ETAT:` et `PROCHAIN:` (dernière occurrence retenue), `OUVERT:` (toutes les occurrences listées), `REPRISE:` (reconnue seulement en dernière ligne du journal). Une ligne sans tag reconnu n'alimente aucune rubrique de la fiche d'état.
- [VERIFIED] `tools/build-state.sh <chemin-projet>` : régénère `<projet>/state/STATE.md` à partir du journal, de l'état Git des deux dépôts et du listing des documents récents (mtime, 15 derniers). Fiche générée, jamais éditée à la main. Depuis Mission 029, la fiche s'ouvre par le **contrat du Pilot** (sept lignes), recopié tel quel depuis `templates/pilot-contract-template.md` (repères `CONTRACT:BEGIN`/`CONTRACT:END`), sous la ligne d'en-tête « fichier généré ». Plafond arbitré : sept lignes exactement — le script échoue (`exit 1`, message explicite, fiche non écrite) si le gabarit s'en écarte. Mesuré sur (historique de l'atelier, non distribué) : ~2,5–2,8 s par exécution, idempotent (deux exécutions consécutives sans événement entre les deux produisent un `md5sum` identique).
- [VERIFIED] `tools/build-indexes.sh <racine...>` : régénère un `index.md` par dossier éligible sous chaque racine passée en argument (élagage `.git`, `tools`, `state`, `graphify-out`, etc. — voir `PRUNE_NAMES` dans le script). Depuis Mission 029, lit aussi le champ front-matter `supersedes` de tout le corpus de la racine traitée (valeur scalaire ou liste YAML indentée, tolérant les deux formats rencontrés dans le corpus) et : (a) suffixe `— REMPLACÉ par <fichier>` l'entrée de chaque fichier cité, dans l'`index.md` de son dossier ; (b) écrit `<racine>/superseded-files.txt`, une liste plate (chemin relatif à la racine, un par ligne) des fichiers remplacés sous cette racine — emplacement choisi par l'Executor, documenté dans le rapport de la Mission 029 (historique de l'atelier, non distribué). Mesuré : ~3 s sur la racine Vault, ~8 s sur (historique de l'atelier, non distribué) (165 fichiers `.md`), sous le seuil de dix secondes.
- [VERIFIED] `tools/find-in-vault.sh [--root <dir>] [--limit N] [--frontmatter-only] <motif>` : recherche par contenu, renvoie les lignes trouvées (jamais les fichiers), format `chemin:ligne:texte`. Racine par défaut : répertoire courant de l'appelant, **pas** un chemin fixe vers le Vault — défaut non corrigé, resté `OPEN` depuis Mission 027 (hors périmètre de Mission 029). Depuis Mission 029, suffixe `[REMPLACÉ]` toute ligne dont le fichier source figure dans un `superseded-files.txt` trouvé sous la racine de recherche (recherche récursive, pas seulement à la racine stricte, pour rester correct malgré le défaut de racine ci-dessus) ; absence de liste tolérée, sans erreur ; la ligne est toujours renvoyée, jamais filtrée. La marque n'est fraîche qu'à la dernière génération des index par `tools/build-indexes.sh` : un `supersedes` ajouté après coup n'apparaît qu'après régénération.
- [VERIFIED] `tools/write-marker.sh` : écrit `VAULT-ROOT.md` à la racine de travail depuis `templates/vault-root-template.md` — fichier marqueur remonté, retrouvé en remontant les dossiers parents (même principe que la détection d'un dépôt Git par `.git`). Non versionné (racine de travail, hors des deux dépôts).
- [VERIFIED] `templates/pilot-contract-template.md` : source unique des sept lignes du contrat du Pilot, recopiées telles quelles par `tools/build-state.sh`. Repères `CONTRACT:BEGIN`/`CONTRACT:END` délimitent le bloc extrait ; le plafond de sept lignes y est contrôlé, pas rédigé dans un script.
- [VERIFIED] `templates/session-opening-prompt-template.md` : prompt de réouverture minimal (rôle, chemin de la fiche d'état, emplacement des blocs RELAY) — aucune règle de comportement, elle vit dans la fiche d'état via le contrat ci-dessus.
- [VERIFIED] `templates/vault-root-template.md` : gabarit du fichier marqueur écrit par `tools/write-marker.sh`.

## 10. Préflight de session, lanceur d'identité et muraille pre-commit (Mission 039)

- [VERIFIED] `tools/session-preflight.sh` : vérifie sans rien modifier — charte des rôles présente, pointeurs `AGENTS.md`/`CLAUDE.md` des deux dépôts, `.claude/settings.json` présent et JSON valide, rôle par sonde de capacité, outils attendus exécutables (`git`, `bash`, `tools/build-state.sh`, `tools/build-indexes.sh`, `tools/check-links.sh`), âge de `.claude/hooks.log` s'il existe (silence > 72h signalé). Sortie `READY` ou `NOT-READY: <n> issue(s)` ; écrit le tampon local `.claude/.preflight_stamp.json` (non versionné, exclu par `.gitignore`). Bug réel rencontré et corrigé en route : la validation JSON priorise désormais `node`, car `python3` sur ce poste peut n'être qu'un alias-stub Windows Store sans interpréteur réel (faussait un `NOT-READY` sur un `.claude/settings.json` en réalité valide).
- [VERIFIED] Câblé au hook `SessionStart` (`tools/session-start-role.sh`) : silence si `READY` (les quatre lignes de rôle inchangées), une ligne `Preflight NOT-READY: <n> issue(s), see .claude/.preflight_stamp.json` sinon.
- [VERIFIED] `tools/start-executor.sh` : lanceur d'identité V1 minimal — pose `VAULT_AGENT=executor` et `VAULT_ROOT`, affiche un rappel d'une ligne (rôle et interdits), lance `claude` depuis la racine du Vault. Aucune table d'agents, aucun clone-vitre.
- [VERIFIED] Muraille pre-commit : les deux dépôts (`.githooks/pre-commit` à la racine du Vault, (historique de l'atelier, non distribué)) refusent tout commit si le tampon (`.claude/.preflight_stamp.json` à la racine du Vault, référencé par chemin relatif depuis (historique de l'atelier, non distribué)) est absent, `ready: false`, ou vieux de plus de 24h. Message de refus à remède unique : `bash tools/session-preflight.sh`, aucune variable de contournement. Refus et passage prouvés par le feu dans les deux dépôts.

## 11. Documentation, licences tierces et frontière produit (Mission 168, ticket 09)

- [VERIFIED] Documents racine réécrits pour ce dépôt distribué (`second-brain`, plus « Vault » comme seul synonyme interne) : `README.md` (résumé anglais en tête, sections prérequis — dont l'abonnement payant à au moins un agent IA —, ligne d'installation, ce qui est installé et où, reprise et mise à jour, désinstallation, questions fréquentes, licence) et `INSTALL.md` (même ligne d'installation, installation par archive toujours refusée). La ligne d'installation documentée est un clone du dépôt public suivi de l'appel de `install.ps1`/`install.sh` avec `-Source`/`--source` : ces deux scripts n'ont pas de mode « auto-clone » propre (mesuré dans leur code, ticket 09) — **Git doit déjà être présent sur le poste pour cette toute première étape**, avant même que l'installeur ne puisse envisager de l'installer lui-même pour le reste du parcours. Résidu corrigé en passant : `INSTALL.md` citait encore `tools/build-package.sh`, un outil `INTERNE` de fabrication du Vault jamais recréé dans `second-brain` (noté au rapport de la Mission 168, tickets 01-02) ; la mention est retirée.
- [VERIFIED] `CONTEXT.md` (racine) : glossaire des quinze termes du produit, validé en T18 de la Mission 168, au format du skill `domain-modeling`.
- [VERIFIED] `rules/RULES-2026-09-11-190000-project-second-brain-boundary.md` : règle courte, écrite comme règle du produit (elle ne nomme jamais l'atelier de fabrication) — un projet utilise Second Brain, le fait évoluer seulement dans `second-brain` lui-même par Mission, n'y écrit jamais directement.
- [VERIFIED] `THIRD-PARTY-LICENSES.md` (racine) : généré par `tools/generate-third-party-licenses.sh` depuis le fichier de licences propre à chaque collection du warehouse (sous `skill-collections/`) ; régénère-le après tout changement du warehouse (`bash tools/generate-third-party-licenses.sh`), jamais à la main. `tools/generate-third-party-licenses.sh --check` refuse si le fichier committé est périmé. `tests/test-third-party-licenses.sh` couvre les trois invariants : chaque skill adopté (121 mesurés) porte une ligne, deux régénérations successives produisent une sortie identique, et le fichier committé n'est pas périmé.

## Liens

- `prescribed by` — [Runbook d'installation du Vault — registre vivant](../decisions/DECISION-2026-08-21-105117-vault-installation-runbook.md)
- `see also` — [Standard de liens entre documents](../rules/RULES-2026-08-21-115658-document-linking-standard.md)
- `see also` — Annexe historique — installation du Vault sur le workspace « workshops » (profil Owner, non distribué)
