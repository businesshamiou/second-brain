---
type: decision
title: "Décisions de périmètre — Obsidian hors du premier workshop, recherche par contenu construite en propre"
created_at: "2026-08-23T12:49:17-04:00"
timezone: America/Montreal
status: ARBITRATED
owner_gate: required
---

# DÉCISION — Décisions de périmètre du 2026-08-23

## Date

2026-08-23

## Statut

`ARBITRATED`

Arbitrage : session Owner/Pilot du 2026-08-23.

## Décision

Adoption des deux décisions de périmètre apparues en séance le 2026-08-23, consignées dans la proposal des sept arbitrages et de l'ordre des lots révisé (historique de l'atelier, non distribué), §4.

1. **Obsidian hors du premier workshop.** Obsidian est écarté du workshop et du paquet distribué : l'audience visée est non développeuse, et l'ajout d'un logiciel à installer contredit la promesse de légèreté du système. Constat associé : les skills de recherche examinés (kepano/obsidian-skills, gmickel/obsidian-skill, le skill Obsidian de hermes-agent, un serveur MCP de recherche par ripgrep) ne dépendent pas d'Obsidian dans leur mécanisme — ils cherchent dans des fichiers Markdown en clair ; la stratégie est réutilisable sans l'outil. Écarté : intégrer Obsidian au premier workshop. Obsidian reste un sujet possible pour un second workshop bâti sur celui-ci.

2. **Recherche par contenu construite en propre.** Le Vault se dote de sa propre recherche : un script qui cherche dans le contenu et renvoie les lignes trouvées, pas les fichiers (chemin, numéro de ligne, ligne), et un skill mince qui traduit la question en arguments du script et présente le résultat sans rien lire d'autre. Convention de nommage : nom anglais tiré de ce que le skill produit. Les skills tiers examinés servent de références de conception et ne sont pas importés dans le Vault, conformément à la règle existante. Écarté : dépendre d'un outil ou d'un skill tiers importé pour la recherche par contenu.

## Raison

Obsidian : l'audience non développeuse et la promesse de légèreté priment sur les capacités de recherche d'Obsidian, d'autant que ces capacités sont atteignables sans l'outil (skills tiers examinés cherchent en Markdown clair, sans dépendance mécanique à Obsidian).

Recherche par contenu : retrouver un seul mot dans le corpus a coûté, en séance, la lecture d'une capture entière, faute de recherche par contenu côté chat. Côté Executor le besoin est déjà couvert nativement ; construire un script mince et un skill dans le Vault referme cet écart sans dépendance externe.

## Impact

Le paquet de distribution (lot E) n'installe pas Obsidian. Le lot A (Mission 027, objectif D) construit `tools/find-in-vault.sh` et le skill de recherche associé. Aucun skill tiers n'est importé dans `vault/`.

## Alternatives importantes

- Intégrer Obsidian au premier workshop pour sa recherche native : rejeté, coût d'installation contraire à la promesse de légèreté pour une audience non développeuse.
- Importer un skill tiers de recherche Obsidian tel quel : rejeté, contraire à la règle existante sur les skills tiers ; sert de référence de conception seulement.

## Human gate

- Validation : accordée
- Référence : arbitrage de l'Owner en session le 2026-08-23, formalisé par la Mission 028.

## Artefacts liés

- Proposal source : (historique de l'atelier, non distribué)

## Liens

- `source` — Proposal sept arbitrages et ordre des lots révisé (historique de l'atelier, non distribué) (hors Vault)
- `see also` — [Décision — Sept arbitrages de session du 2026-08-23](./DECISION-2026-08-23-124848-seven-arbitrations-2026-08-23.md)
- `see also` — Mission 027 — Lot A (historique de l'atelier, non distribué) (hors Vault)
