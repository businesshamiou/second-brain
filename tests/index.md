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

Ce fichier est tenu à la main : `tools/build-indexes.sh` n'indexe que les documents Markdown à front matter, et un test est un script. L'inventaire complet reste le dossier lui-même ; l'enchaînement par système est [`.github/workflows/ci.yml`](../.github/workflows/ci.yml), seule source de vérité de ce qui tourne où.

## Contenu

Chaque test rend un verdict fermé — `PASS`, `FAIL`, ou `SKIP (cause, plateforme)` — et porte son propre témoin négatif : la même mesure, sur un cas fabriqué pour échouer. Un test sans témoin ne prouve pas qu'il sait échouer.

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
