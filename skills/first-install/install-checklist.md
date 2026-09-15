---
title: "Liste d'installation, une mesure par item"
description: "Source unique de l'inventaire joué par le skill first-install : chaque item d'installation du Vault sur un poste, avec la mesure qui dit installé ou manquant et le geste qui l'installe sans écraser. C'est ce fichier qu'on amende quand un item nouveau apparaît — le corps du skill ne bouge pas. Chaîne amended by suivie par le skill."
created_at: "2026-09-01T21:05:00-04:00"
timezone: America/Montreal
status: active
---

# LISTE D'INSTALLATION

Jouée par le skill `first-install` (§2 inventaire, §3 installation). Une ligne = un item, sa mesure, le geste s'il manque. Un item installé n'est jamais retouché.

| # | Item | Mesure (installé si…) | Geste si manquant | Réponse |
|---|---|---|---|---|
| 1 | Racine de travail marquée | `VAULT-ROOT.md` trouvé en remontant depuis le Vault, ligne « Chemin relatif du Vault » lisible | `tools/write-marker.sh` du Vault (geste Executor sur prescription) | machine |
| 2 | Vault cloné | `.git` présent à la racine du Vault (trouvée par le marqueur), `git -C <racine du Vault> status -sb` répond | clone par l'humain (URL et emplacement = réponses de l'interrogatoire) | humaine (chemin) |
| 3 | `core.hooksPath` du Vault | `git -C <racine du Vault> config core.hooksPath` = `.githooks` | `git -C <racine du Vault> config core.hooksPath .githooks` | machine |
| 4 | Outils des gardiens | `command -v bash git sha256sum` tous présents | installation par l'humain (Git for Windows fournit les trois) | machine → humaine |
| 5 | `pre-commit` | `command -v pre-commit` présent | installation par l'humain (`pipx`/`uv tool install pre-commit`) ; sans lui, les projets gardent le hook natif seulement | machine → humaine |
| 6 | Support des jonctions | Windows : `fsutil` présent et une jonction d'essai lisible ; autres : `ln -s` | aucun (capacité du poste, signalée) | machine |
| 7 | Dossier personnel des skills | `%USERPROFILE%\.claude\skills\` existe | `mkdir` | machine |
| 8 | Jonctions des skills du Vault | pour chaque `skills/<nom>/SKILL.md` du Vault (hors `external/`) : jonction du même nom, `test -ef` IDENTIQUE — **troisième état (Mission 125)** : jonction du même nom **présente mais `test -ef` FAUX** (elle cible un autre Vault installé sur ce poste) = ni installé ni manquant, **STOP et demander à l'Owner** ; ne jamais réécrire une jonction existante, quel que soit son état | `mklink /J` (ou `ln -s`) vers `skills/<nom>` du Vault, jamais sur une jonction existante | machine |
| 9 | Jonctions de la bibliothèque externe | pour chaque `skills/external/<nom>/SKILL.md` du Vault : jonction du même nom, `test -ef` IDENTIQUE — même troisième état qu'à l'item 8 (jonction existante, cible différente) : **STOP et demander à l'Owner**, jamais de réécriture | idem vers `skills/external/<nom>` du Vault | machine |
| 10 | Jonctions étrangères | jonction du dossier personnel sans cible dans le Vault | aucun geste : signalée, laissée (elle n'appartient pas au Vault) | machine |
| 11 | Étage machine — Claude Code | `~/.claude/CLAUDE.md` existe et mentionne `VAULT-ROOT` | créer le fichier minimal (DECISION-210731 point 1) ; s'il existe sans la mention : signalé, non modifié | machine |
| 12 | Étage machine — Codex | `~/.codex/AGENTS.md` existe (taille > 0) et mentionne `VAULT-ROOT` | absent, ou présent à 0 octet : créer le fichier minimal (DECISION-210731 point 1) ; présent avec un contenu non vide sans la mention : signalé, non modifié | machine |
| 13 | Racine MCP filesystem (surface Pilot) | configuration du client chat lisible et pointant la racine de travail | geste humain (paramètres du client), chemin proposé | machine → humaine |
| 14 | Projets enregistrés : `pre-commit install` | pour chaque `relative_path` du registre : `.git/hooks/pre-commit` posé par pre-commit, ou `core.hooksPath` natif présent — **précision (Mission 125)** : `projects/PROJECT-REGISTRY.md` est `INTERNE` au manifeste (contenu propre à ce poste, jamais distribué) ; **absent sur un clone neuf, ce n'est pas un manque** — 0 projet enregistré, rien à faire ici ; le registre est créé depuis `templates/project-registry-template.md` (`DISTRIBUABLE`) par `project-bootstrap.sh` au premier projet, pas par `first-install` | `pre-commit install` dans le projet, si l'item 5 est installé et le registre présent | machine |
| 15 | Skills chat (claude.ai) | jamais mesurable depuis le poste | liste des zips avec chemin mesuré, `laissé (geste humain)` | humaine |
| 16 | Rapport d'installation | fichier déposé au chemin nommé par l'Owner | `install-report-template.md` rempli | humaine (chemin) |

## Liens

- `see also` — [Skill first-install](./SKILL.md)
- `see also` — [Gabarit du rapport d'installation](./install-report-template.md)
- `applies` — Décision — Prise de conscience du Vault par un projet, trois étages (historique de l'atelier, non distribué) (hors Vault)
