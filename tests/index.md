---
type: index
title: "Tests du Vault"
description: "Scénarios de vérification du comportement du système."
created_at: 2026-08-19T11:53:06-04:00
timezone: America/Montreal
status: active
---

# Tests du Vault

Scénarios de vérification du comportement du système.

Ce fichier est tenu à la main : `tools/build-indexes.sh` n'indexe que les documents Markdown à front matter, et un test est un script. L'inventaire complet reste le dossier lui-même ; l'enchaînement par système est [`suite.tsv`](./suite.tsv), seule source de vérité de ce qui tourne où, joué à l'identique en local et en CI par [`run-suite.sh`](./run-suite.sh) (et [`run-suite.ps1`](./run-suite.ps1) sous Windows) — `bash tests/run-suite.sh` joue toute la suite. [`.github/workflows/ci.yml`](../.github/workflows/ci.yml) n'appelle plus que ce lanceur, après l'action partagée [`setup-test-env`](../.github/actions/setup-test-env/action.yml) (uv, Python et pre-commit, en cache).

## Contenu

Chaque test rend un verdict fermé — `PASS`, `FAIL`, ou `SKIP (cause, plateforme)` — et porte son propre témoin négatif : la même mesure, sur un cas fabriqué pour échouer. Un test sans témoin ne prouve pas qu'il sait échouer.

### Banc de test réutilisable — Mission 188

Chaque fichier porte en tête son oracle et son témoin négatif.

- T1 `test-suite-manifest-matches-ci.sh` (U) — `suite.tsv` = la suite de `ci.yml` à `42f74e6a` (108 triplets).
- T2 `test-run-suite-reports-red.sh` (W / U / M) — le lanceur joue tout, compte, nomme les rouges.
- T3 `test-setup-test-env-offline.sh` (U, CI) — l'environnement en cache répond hors réseau.
- T4 `test-reference-clone-equivalence.sh` (U) — le clone de référence installe la même chose.

### Portes fermées par la Mission 186 (v0.1.5)

Six mesures : la source unique du relais Pilot↔Executor (DECISION-2026-09-17-201623) synchronisée dans tout le corpus distribué, plus le bloc « Instructions du Projet » rendu prêt à coller et le parcours d'installation retravaillé. U = Ubuntu, W = Windows, M = macOS.

| # | Fichier | Ce qu'il prouve | Témoin négatif | Systèmes |
|---|---|---|---|---|
| T1 | `test-no-push-formula.sh` | zéro occurrence, dans le corpus distribué, des quatre formulations de l'ancienne formule de push imposée (« j'ordonne le push », « verbatim »/« à l'identique » associés à push, « aucun push » sans « non délégué ») | un fichier par motif, jamais écrit dans ce dépôt → chacun détecté et nommé | U |
| T2 | `test-relay-single-source.sh` | la grammaire du bloc RELAY (rubriques exactes) n'apparaît que dans `RULES-2026-08-23-124937` ; les pièces qui en parlent y renvoient nommément (« 124937 ») sans la redire | une copie de skill qui redit la grammaire → détectée et nommée | U |
| T3 | `test-common-prompt-no-relay.sh` | le bloc `PROMPT:BEGIN/END` du prompt Pilot commun ne porte plus le mot RELAY, et garde la phrase d'exclusivité du serveur MCP | RELAY réinjecté dans une copie jetable du gabarit → échec | U |
| T4 | `test-project-bootstrap-instructions-block.sh` | le bloc « Instructions du Projet » rendu par `tools/project-bootstrap.sh` porte le tronc commun complet, prêt à coller (chemin natif, `vault_id`, canari identique à `state/PILOT-PROMPT.md`), en français et dans les trois langues du questionnaire | gabarit privé de `<!-- PROMPT:BEGIN -->` → échec propre, sans rendu partiel | W / U / M |
| T5 | `test-install-doc-participant-path.sh` | README.md et INSTALL.md portent, dans l'ordre, les quatre étapes du parcours participant (installer, serveur MCP, ouvrir le Pilot, adopter) et une FAQ des quatre leçons de l'acceptation 184 | copie de README.md privée d'une section puis d'une entrée FAQ → échec | U |
| T6 | `test-i18n-parity.sh` | les catalogues `i18n/catalog.{fr,en,es}.json` déclarent exactement le même ensemble de clefs, dont les nouvelles clefs `projectBootstrap.consume.instructions*` | une clef retirée d'une copie jetable d'un catalogue → détectée et nommée | U |

### Portes fermées par la Mission 185-C01 (v0.1.4)

Douze mesures, une par défaut relevé pendant l'acceptation humaine du 2026-09-17. W = Windows, U = Ubuntu, M = macOS.

| # | Fichier | Ce qu'il prouve | Témoin négatif | Systèmes |
|---|---|---|---|---|
| T1 | `test-bootstrap-stale-temp-clone.ps1` / `.sh` | un dossier temporaire déjà cloné est amené à `--ref` | `--ref` inexistant ; origine différente → refus, rien d'installé | W / U / M |
| T2 | `test-install-vault-origin.sh` | `vault_origin`, marqueur et acte du premier projet portent l'origine réelle | source sans remote → repli sur le chemin, dit au participant | W / U / M |
| T3 | `test-install-leaves-vault-clean.sh` | le Vault installé est rendu au porcelain vide | installation interrompue → porcelain non vide, vu par la même mesure | W / U / M |
| T4 | `test-project-bootstrap-git-identity.sh` | tout dépôt créé ou repris porte une identité d'auteur | identité locale retirée → commit refusé, « Author identity unknown » | W / U / M |
| T5 | `test-project-bootstrap-adopt-git-no-question.sh` | `--git` vaut réponse : aucune question, l'entrée standard n'est pas lue | sans `--git` ni `--vcs` → la question est posée et sa réponse appliquée | W / U / M |
| T6 | `test-vault-mcp-refusal-message.py` | un refus MCP est un résultat `isError` nommant le chemin et le périmètre | chemin dedans → pas d'`isError`, contenu rendu | W / U / M |
| T7 | `test-project-bootstrap-native-paths.ps1` / `.sh` | sous Windows, les chemins rendus sont natifs (`C:\…`) | sous Unix, le chemin POSIX revient rigoureusement inchangé | W / U / M |
| T8 | `test-project-bootstrap-adopt-plan.sh` | le plan d'adoption ne parle que de l'existant | un fichier existant mal rangé est toujours proposé au déplacement | W / U / M |
| T9 | `test-common-prompt-exclusivity.sh` | le prompt Pilot commun dit que `second-brain-vault` est le seul outil de fichiers | copie du gabarit sans la phrase → échec | U |
| T10 | `test-install-doc-windows-invocation.sh` | `INSTALL.md` et `README.md` portent l'invocation Windows exacte | copie sans ces lignes → échec | U |
| T11 | `test-catalog-key-parity.sh` / `.ps1` | parité fr/en/es, et présence des clefs neuves | une clef retirée d'un catalogue → échec | U |
| T12 | suites de la Mission 184 | les 106 cas et les onze lignes d'acceptation gardent leur verdict | — (c'est la règle « ne rien casser ») | W / U / M |

### Familles antérieures

- **Installation de bout en bout** — `test-install-e2e.ps1` / `.sh`, `test-bootstrap-no-git.ps1`, `test-install-standard-user.ps1`, `test-prerequisites-e2e.ps1`.
- **Initiation et adoption de projet** — `test-project-initiation.sh`, `test-project-bootstrap-path-validation.sh`, `test-project-structure-standard-conformity.ps1`.
- **Serveur MCP embarqué** — `test-vault-mcp.sh` (serveur, injection sur profil simulé, contenance).
- **Gardiens** — `test-githooks-run-on-commit.sh`, `test-guardian-offline-commit.sh`, `test-guardian-path-special-chars.sh`, `test-guardian-secret-refusal.sh`, `test-exec-bit-bare-scripts.sh`.
- **Questionnaire et assistant** — `test-questionnaire-*.ps1`, `test-assistant-*.ps1`.
- **Portabilité et vocabulaire** — `test-participant-shell-portability.sh`, `test-nominal-flow-no-atelier-vocabulary.ps1` / `.sh`, `test-distributed-documents-no-atelier-vocabulary.ps1` / `.sh`.

## Liens

- `see also` — [Garde-fous et niveaux de preuve](../rules/RULES-2026-08-19-210803-guardrails-and-evidence-levels.md)
- `prescribed by` — [Standard de liens entre documents](../rules/RULES-2026-08-21-115658-document-linking-standard.md)
