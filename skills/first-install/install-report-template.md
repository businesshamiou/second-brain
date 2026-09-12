---
title: "Gabarit — Rapport d'installation du Vault sur un poste"
description: "Gabarit du rapport rendu par le skill first-install : identité du poste mesurée, réponses humaines de l'interrogatoire, table installé / manquant → installé / laissé (geste humain) avec preuve par ligne, total avant/après, gestes humains restants. Instancié par le skill, jamais édité comme source."
created_at: "2026-09-01T21:05:00-04:00"
timezone: America/Montreal
status: active
---

# RAPPORT D'INSTALLATION — <poste, YYYY-MM-DD>

## 1. Poste mesuré

| Mesure | Valeur |
|---|---|
| OS / shell | <`uname -s`, `$SHELL`> |
| Claude Code | <`claude --version`> |
| Git | <`git --version`> |
| Vault | <chemin mesuré, tête `git rev-parse --short HEAD`, `core.hooksPath`> |
| Racine de travail | <chemin du `VAULT-ROOT.md`> |
| Jonctions | <supportées : oui/non, méthode> |

## 2. Réponses humaines (interrogatoire `/to-questionnaire`)

- Chemin voulu du Vault : <réponse>
- Chemin des projets : <réponse>
- Dossier personnel des skills : <réponse ou défaut `%USERPROFILE%\.claude\skills`>
- Chemin du rapport : <réponse ou « conversation »>

## 3. Inventaire → installation

| # | Item (install-checklist.md) | Avant | Geste | Après | Preuve |
|---|---|---|---|---|---|
| 1 | <item> | installé / manquant | aucun / <commande> | installé / laissé (geste humain) | <chemin, `test -ef`, sortie> |

**Total** : <N> manquant avant → <M> manquant après ; <K> laissé (geste humain).

## 4. Skills chat — proposés, non installés

- <chemin mesuré du zip> — `laissé (geste humain)`

## 5. Gestes humains restants

1. <geste, avec la commande ou le chemin exact>

## 6. Preuve de non-écriture dans les dépôts

```
$ git -C <racine du Vault> status -sb        (avant)
$ git -C <racine du Vault> status -sb        (après, identique)
```

## Liens

- `see also` — [Skill first-install](./SKILL.md)
- `see also` — [Liste d'installation, une mesure par item](./install-checklist.md)
