---
type: decision
title: "Liens sortants vers un autre dépôt — marqués, contrôlés seulement quand le dépôt cible est présent sur disque"
description: "(historique de l'atelier, non distribué)"
created_at: "2026-09-02T00:50:41-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
rapatriated_from: "workshop-build/workshop-production/decisions/DECISION-2026-09-02-005041-cross-repo-links-checked-only-when-target-repo-present.md"
---

# DÉCISION — LIENS SORTANTS VERS UN AUTRE DÉPÔT

## Date

2026-09-02

## Statut

`ARBITRATED` — mot exact « exempter », Owner, 2026-09-02, fenêtre Pilot, après recommandation unique.

## Décision

1. **Définition.** Un lien est *sortant* quand sa cible résolue sort de la racine du dépôt courant (chemin relatif qui traverse `..` au-delà de la racine, ou chemin vers un dépôt frère). Exemples : les lignes `amended by` que le Vault porte vers (historique de l'atelier, non distribué) (placement 205904 : la réciproque vit dans le dépôt du document amendé), les lignes `prescribed by` qu'un projet porte vers `vault/rules/`.
2. **Marquage.** Tout lien sortant porte, après le lien, la mention `(hors Vault)` quand la cible est le Vault, `(hors dépôt)` sinon. La mention est pour le lecteur ; le gardien décide par le chemin, pas par la mention.
3. **Contrôle.** `check-links.sh` traite un lien sortant ainsi : si le **dépôt cible est présent** sur disque (sa racine existe) → la cible est vérifiée comme un lien ordinaire, absente = refus ; si le **dépôt cible est absent** → avertissement nommant le lien, **pas de refus**. Les liens internes au dépôt ne changent pas : absents = refus.
4. **Portée.** La règle vaut dans le corpus de travail (les deux dépôts côte à côte : tout est vérifié comme avant) et dans un paquet autonome (le Vault seul : les 22 liens sortants sont avertis, le paquet est propre). Elle ne couvre pas les liens vers des fichiers `INTERNE` du même dépôt (registre, historique d'installation) : ceux-là restent des liens internes, morts par verdict dans le paquet, consignés au rapport de construction — l'Owner en a tranché le verdict, pas le lien.
5. **Erratum (Mission 127, 2026-09-02).** Le chiffre « 22 » ci-dessus (et aux autres occurrences de ce document) était un instantané du rapport 117 ; le compte réel est mesuré à chaque construction du paquet (86 avertissements mesurés au rapport 118, croissance normale du corpus) et n'est pas normatif — aucune des occurrences précédentes n'est réécrite.

## Raison

Le principe de placement (205904) impose au Vault de porter des liens vers les Décisions du projet qui l'amendent. Un paquet autonome ne contient pas le projet : ces liens y sont morts **par construction**, pas par erreur. Le rapport 117 les a comptés pour la première fois sur un objet réel : 22, tous structurels. Un gardien qui refuserait le paquet pour cela refuserait une propriété voulue ; un gardien qui ignorerait tout lien sortant perdrait le contrôle dans le corpus de travail. La règle retient les deux : contrôle plein quand la cible peut exister, avertissement quand elle ne le peut pas.

## Impact

- `RULES-2026-08-21-115658-document-linking-standard.md` amendée (réciproque posée dans le Vault, Mission 118) ; `DECISION-2026-08-28-203627` (section Liens scoped au corpus) inchangée, compatible.
- `tools/check-links.sh` modifié par la Mission 118 selon le patron 107 : canaris dans un dépôt jetable (sortant vers dépôt absent → averti ; sortant vers dépôt présent, cible absente → refus ; interne absent → refus), test ajouté sous `tests/`, cycle de ré-épingle en fin de Mission.
- `build-package.sh` : le contrôle de liens sur l'arbre extrait devient partie de la vérification (117 l'a fait à la main) ; résultat attendu après cette Décision : 0 refus, 22 avertissements, 12 liens internes vers fichiers `INTERNE` consignés.
- Coût : une Mission ; aucun changement pour les auteurs, qui marquent déjà « (hors Vault) ».

## Alternatives importantes

- **Laisser les 22 morts et le consigner** : rejetée — le gardien livré refuserait le paquet livré ; on ne distribue pas un contrôle qui échoue sur ce qu'il accompagne.
- **Retirer les `amended by` sortants du Vault** : rejetée — contraire au placement 205904 et à la traçabilité des amendements.
- **Exempter par la mention plutôt que par le chemin** : rejetée — une mention oubliée ou fausse tromperait le gardien ; le chemin ne ment pas.

## Human gate

- Validation : accordée — « exempter », Owner, 2026-09-02.
- Référence : fenêtre Pilot, revue des dettes de fin de session.

## Artefacts liés

- Source : `../reports/REPORT-2026-09-02-002016-117-manifest-verdicts-and-package-rebuild.md` (35 liens, dont 22 sortants)
- Exécution : Mission 118 (gardien, test, réciproque)

## Liens

- `prescribed by` — [Gabarit de décision](../../../vault/templates/decision-template.md) (hors Vault)
- `amends` — [Standard de liaison des documents](../../../vault/rules/RULES-2026-08-21-115658-document-linking-standard.md) (hors Vault)
- `see also` — [Décision — L'amendement vit dans le dépôt du document amendé](../../../vault/decisions/DECISION-2026-08-28-205904-amendment-lives-in-amended-repo.md) (hors Vault)
- `see also` — Décision — Le code n'est jamais une norme (historique de l'atelier, non distribué)
