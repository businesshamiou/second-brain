---
type: decision
title: "Amendement de DECISION-171209 — la bibliothèque de skills passe à la forme standard Agent Skills (six champs, provenance sous metadata) ; remplacement par le paquet du skills-warehouse"
description: "Grave l'arbitrage Owner du 2026-08-31 : l'enveloppe V1 à clés plates (type, title, created_at, status, metadata-upstream-*) est abandonnée parce qu'elle est hors de la spécification Agent Skills — le téléverseur de claude.ai la refuse en erreur dure, seuls name, description, license, compatibility, allowed-tools et metadata sont admis. La bibliothèque vault/skills/external/ est remplacée par la sortie du projet skills-warehouse (paquet affiliate-pro-skills-full.zip), en forme standard ; les skills de la bibliothèque actuelle absents du paquet sont conservés et convertis à la même forme ; les doublons sont comptés et soumis ; rien n'est supprimé, l'ancienne bibliothèque part en _trash/ avec empreinte. Cycle update-ou-rejet et corps verbatim sous empreinte restent en vigueur."
created_at: "2026-08-31T23:18:41-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
amends: "./DECISION-2026-08-28-171209-skills-adoption-by-v1-envelope-rewrite.md"
rapatriated_from: "workshop-build/workshop-production/decisions/DECISION-2026-08-31-231841-skills-library-standard-form-warehouse.md"
---

# DÉCISION — FORME STANDARD DE LA BIBLIOTHÈQUE DE SKILLS ET REMPLACEMENT PAR LE PAQUET DU WAREHOUSE

## Date

2026-08-31

## Statut

`ARBITRATED`

## Fait mesuré

Doc officielle Claude Code (« Extend Claude with skills », lue le 2026-08-31) : tout champ d'en-tête hors des six autorisés (`name`, `description`, `license`, `compatibility`, `allowed-tools`, `metadata`) provoque un refus en erreur dure au téléversement dans claude.ai. Notre enveloppe V1 (DECISION-171209 §2 : `type`, `title`, `created_at`, `timezone`, `status`, clés plates `metadata-upstream-*`) est donc hors spécification ; les extensions Claude Code de l'amont (`argument-hint`, `disable-model-invocation`) le sont aussi. La knowledge-note 152952 l'avait établi le 2026-08-27 : `metadata` est l'unique point d'extension du standard. Les clés plates avaient été choisies pour contourner un gardien qui ne lisait pas le YAML imbriqué (Mission 083) — le code n'est jamais une norme (DECISION-193624).

## Décision

**1. Forme standard, seule forme admise dans `vault/skills/`.** Un `SKILL.md` de la bibliothèque porte au plus les six champs de la spécification. Toute information propre au Vault (provenance, empreinte du corps, version amont, date d'entrée, extensions d'un outil) vit **sous `metadata:`**, en paires chaîne → chaîne. Le §2 de DECISION-171209 est remplacé sur ce point ; ses autres principes tiennent : corps verbatim prouvé par empreinte SHA-256, adoption par arbitrage Owner nominatif (DECISION-210726), cycle update-ou-rejet.

**2. Source de la bibliothèque : le projet `skills-warehouse`.** Sa sortie (paquet `affiliate-pro-skills-full.zip`, chemin donné par l'Owner le 2026-08-31, hors workspace) devient la source de `vault/skills/external/`. Le sens de circulation est warehouse → Vault, jamais l'inverse. Le nom du paquet est libre ; c'est son contenu qui est mesuré.

**3. Remplacement, pas fusion.** La bibliothèque actuelle (30 skills, enveloppes V1) est déplacée intégralement vers `_trash/` avec empreinte, jamais supprimée (DECISION-110852). La nouvelle bibliothèque est construite à partir du paquet.

**4. Ce que le paquet ne contient pas est conservé et converti.** Un skill présent dans la bibliothèque actuelle et absent du paquet est déclaré au rapport, puis réinstallé à partir de l'ancienne copie **converti à la forme standard** (corps intact, en-tête réduit aux six champs, provenance sous `metadata:`). Rien ne se perd, tout a la même forme.

**5. Doublons.** Un nom apparaît une fois dans la bibliothèque, une fois dans le catalogue, une fois dans le manifeste. Un doublon **interne au paquet** (même nom, deux dossiers ou deux `SKILL.md`) est un STOP : compté, listé, soumis à l'Owner — l'Executor ne choisit pas.

**6. Non-conformité du paquet.** Un `SKILL.md` du paquet portant un champ hors des six n'est pas installé tel quel : il est listé au rapport avec le champ fautif. Le paquet est censé être standard ; s'il ne l'est pas, c'est le warehouse qu'il faut corriger, pas le Vault qui doit s'adapter.

**7. Gardiens.** Si un gardien refuse un bloc `metadata:` imbriqué, c'est un STOP avec verbatim : le gardien sera corrigé par une Mission dédiée (lecture du gardien, push, ré-épingle), jamais contourné ni modifié dans la Mission d'installation.

## Raison

Arbitrage Owner du 2026-08-31 : « on va installer tous les skills des deux côtés ; côté Vault, refaire l'installation à partir du nouveau paquet ; enlever tous les autres skills et installer les nouveaux ; si un skill n'existe pas dans le paquet, le déclarer, le sauvegarder et l'adapter à la même structure, pour une forme standard ». Le choix de la forme standard n'est pas esthétique : c'est la seule qui passe sur les trois surfaces (Claude Code, claude.ai, autres agents), donc la seule compatible avec un Vault distribuable à tout LLM.

## Impact

- 171209 reçoit `amended by` (réciproque, même commit).
- Mission 106 : remplacement, conversion des orphelins, provenance, manifeste, catalogue v2, jonctions, contrôle par listage Claude Code.
- Catalogue 151755 : remplacé par un catalogue v2 (`superseded by`), l'ancien reste comme histoire.
- Gardien de réciprocité / obsolescence : à vérifier sur YAML imbriqué ; correctif éventuel = Mission dédiée.
- Téléversement dans claude.ai : devient possible directement depuis la bibliothèque (zip du dossier).

## Alternatives importantes

- Garder l'enveloppe V1 et produire des zips « nettoyés » à part pour le chat : écartée — deux formes du même skill, divergence garantie.
- Fusionner paquet et bibliothèque actuelle skill par skill : écartée par l'Owner — remplacement, le warehouse est la source.
- Supprimer l'ancienne bibliothèque : interdit (110852) ; `_trash/` avec empreinte.

## Human gate

- Validation : accordée
- Référence : messages Owner du 2026-08-31 cités en Raison.

## Liens

- `amends` — [Décision — Adoption par réécriture d'enveloppe V1](./DECISION-2026-08-28-171209-skills-adoption-by-v1-envelope-rewrite.md)
- `see also` — Décision — Le critère de score est supprimé, l'adoption est un arbitrage Owner par nom (historique de l'atelier, non distribué)
- `see also` — [Décision — La bibliothèque de skills externes entre dans le Vault](./DECISION-2026-08-28-160213-skills-library-into-vault-amendment.md)
- `see also` — Recherche — spécification Agent Skills et cycle de vie (historique de l'atelier, non distribué)
