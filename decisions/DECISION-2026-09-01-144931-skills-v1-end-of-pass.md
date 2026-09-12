---
type: decision
title: "Fin de passe skills V1 — liste à six skills plus un hook, principe commande, arbitrages session-start / session-close / first-install, recherche scindée en trois, ordre de fabrication, péremption par sources"
description: "Grave l'ensemble des arbitrages de la passe skills V1 rendus entre le 2026-08-30 et le 2026-09-01 : liste finale (session-start, session-close, écriture-de-mission, project-bootstrap, first-install, recherche interne ; executor-preflight devient un hook), principe commande (l'Owner lance, jamais de canal agent → agent), les points arbitrés de session-start (six), session-close (quatre) et first-install (quatre), la scission de la recherche (interne fabriquée, web couverte par le skill research de la bibliothèque, images sans skill), le maintien du nom to-questionnaire après investigation, l'ordre de fabrication commençant par session-start et finissant par first-install, et le mécanisme de péremption par sources (vault-implements + vault-validated croisés avec superseded-files.txt et les amended by). Amende DECISION-2026-08-25-232341 §5.1."
created_at: "2026-09-01T14:49:31-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
amends: "./DECISION-2026-08-25-232341-evening-consolidation-project-standard-and-plan.md"
rapatriated_from: "workshop-build/workshop-production/decisions/DECISION-2026-09-01-144931-skills-v1-end-of-pass.md"
---

# DÉCISION — FIN DE PASSE SKILLS V1

## Date

2026-09-01 (arbitrages rendus du 2026-08-30 au 2026-09-01)

## Statut

`ARBITRATED` — mots exacts de l'Owner, fenêtre Pilot : « hook », « ok » (session-start), « ok » (session-close), « je valide » (commande), puis ce jour « fi-ok », « garder », « c-ok », « péremption-implements », et la scission de la recherche dictée en toutes lettres.

## Décision

**1. Liste V1 : six skills et un hook.** Les skills fabriqués par le Vault sont `session-start`, `session-close`, `écriture-de-mission` (nouveau, ajouté par cette Décision), `project-bootstrap`, `first-install`, `recherche-interne`. `executor-preflight` n'est pas un skill : c'est un hook `PreToolUse` posé par le bootstrap, plus le filtre pre-commit, plus trois lignes dans `session-start` (arbitrage « hook »). Cette liste amende `DECISION-2026-08-25-232341` §5.1 (qui disait six skills dont un `executor-preflight` et un skill de recherche non spécifié).

**2. Principe `commande`, commun à tous.** Le Pilot prépare sur disque ; l'Owner lance une commande fixe dans Claude Code ; l'Executor finit seul et rend un RELAY. Jamais de canal agent → agent : l'Owner reste l'unique pont entre fenêtres.

**3. `session-start`, six points (arbitrés le 2026-08-31).** Complète le prompt d'ouverture, ne le remplace pas · le hook est le déclencheur côté Executor, automatique seulement une fois posé par le bootstrap · un seul skill, bascule mécanique selon la surface (shell disponible ?) · canari d'ouverture = `rev:` de `.pre-commit-config.yaml` comparé à la tête du Vault + présence du hook + présence des scripts gardiens · NOT-READY = arrêt (Executor : aucun geste ; Pilot : aucun dépôt) · la liste de lecture par rôle vit dans un fichier du Vault, chaîne `amended by` suivie.

**4. `session-close`, quatre points (arbitrés le 2026-08-31).** Déclenché par l'Owner (« wrap ») · deux surfaces · refuse de clore avec des trous (portes sans ligne, résidus non arbitrés, RELAY non consommé) · la tenue de `MISSION-INDEX.md` fait partie de sa spec.

**5. `first-install`, quatre points (arbitrés « fi-ok » le 2026-09-01).** Executor seul · réutilise le skill `to-questionnaire` de la bibliothèque pour son interrogatoire · rejouable sans écraser (sur un poste déjà installé, il complète) · propose les skills chat sans jamais les déclarer installés — l'installation chat est un geste Owner constaté. Il se fabrique **en dernier** : installer tout exige d'avoir vu tout.

**6. Recherche : trois objets, un seul fabriqué.** (a) **Recherche interne au Vault** : skill V1 `recherche-interne`, une discipline et pas un moteur — index et champs `description` d'abord (dévoilement progressif), puis `grep`/glob exacts sur le corpus, jamais d'affirmation sans chemin mesuré ; deux surfaces ; conforme à la conclusion de l'étude Mnemosyne (câbler l'existant plutôt qu'outiller du neuf). (b) **Recherche web** : couverte par le skill `research` de la bibliothèque externe (mesuré au catalogue v3, case UD, invocation `/research` ou automatique — « high-trust primary sources », sortie Markdown citée) ; rien à fabriquer ; si l'Owner fournit une meilleure source, elle passera par le circuit d'adoption ordinaire. (c) **Recherche d'images** : aucun skill, les règles en place suffisent.

**7. `to-questionnaire` garde son nom (arbitrage « garder », après investigation).** Mesuré : le nom vient de l'amont `github.com/mattpocock/skills` (front-matter `upstream-repo`, version 1.2.3), et « questionnaire » est un mot anglais à part entière — le nommage English est respecté. Le renommer romprait l'appariement par nom du cycle update-ou-rejet à chaque paquet du warehouse, la jonction, le catalogue et le manifeste, pour corriger un défaut qui n'existe pas.

**8. Ordre de fabrication (arbitrage « c-ok »).** L'étude préalable est faite (recherche des règles d'or de fraîcheur documentaire, ce jour, consignée en Raison). Puis : `session-start` → `session-close` → `écriture-de-mission` → `project-bootstrap` (mode adopter) → `recherche-interne` → `first-install`. Un skill à la fois, entièrement spécifié avant lancement, règle anti-chevauchement à la création (232341, inchangées). Conséquence assumée : l'adoption du projet `skills-warehouse` attend `project-bootstrap`.

**9. Péremption par sources (arbitrage « péremption-implements »).** Chaque skill fabriqué par le Vault porte dans `metadata` : `vault-implements` (chemins des Décisions et règles qu'il incarne, chaîne séparée par virgules — `metadata` n'accepte que des paires chaîne → chaîne) et `vault-validated` (date de dernière validation). Un skill est **réputé périmé** dès qu'une de ses sources figure dans `superseded-files.txt` ou reçoit une ligne `amended by` postérieure à son `vault-validated`. Contrôle manuel à chaque fin de passe pour commencer ; gardien mécanique candidat (croisement de fichiers existants, aucun outil neuf) — trajectoire doctrine → règle → mécanisme. Les skills externes adoptés ne portent pas `vault-implements` : leur péremption est celle du cycle update-ou-rejet.

## Raison

La passe V1 était arbitrée aux deux tiers depuis le 2026-08-31 (handoff §3) ; restaient first-install, la recherche, l'ordre et la péremption. Les verdicts de ce jour ferment la passe.

L'ajout d'`écriture-de-mission` à la liste s'appuie sur une preuve mesurée : trois contradictions internes de Missions en trois jours (090, 108 ×2), gravées avec leurs règles par `DECISION-2026-09-01-115547` — le skill n'a plus qu'à incarner des règles déjà écrites, c'est le rendement le plus sûr du chantier.

La scission de la recherche vient d'une mesure : le catalogue v3 montre que la recherche web est déjà servie par un skill adopté (`research`), et l'étude Mnemosyne (2026-08-30) avait conclu que câbler les mécanismes existants vaut mieux que du nouvel outillage — la recherche interne est donc une discipline sur les index existants, pas un moteur.

La péremption par sources fond la recommandation du Pilot avec les règles d'or du terrain, recherchées ce jour sur demande de l'Owner : lier chaque document à ses sources dans un manifeste que la machine lit ; dater la dernière validation dans le document lui-même et l'imposer en CI ; mettre à jour dans le même geste que le changement, avec revue périodique et responsable nommé. Le Vault possède déjà les deux stocks machine-lisibles nécessaires (`superseded-files.txt`, lignes `amended by`) : le futur gardien est un croisement, pas un outil.

## Impact

- `DECISION-2026-08-25-232341` §5.1 est amendée (réciproque `amended by` posée par la Mission d'exécution).
- La fabrication peut commencer : première spec = `session-start`, un skill à la fois.
- Le gabarit des skills fabriqués gagne deux champs `metadata` (`vault-implements`, `vault-validated`) — à poser dans la spec du premier skill, pas rétroactivement sur les 40 externes.
- La revue de péremption entre dans la clôture de chaque passe skills ; `session-close` (point 4) n'en hérite pas — c'est un contrôle de passe, pas de session.
- L'installation chat (file point 2) et l'adoption du warehouse (point 4) restent ouvertes, inchangées par cette Décision.
- Une investigation de nommage est close : `to-questionnaire`, consignée au point 7, aucun trou ni lien mort créé.

## Alternatives importantes

- **Fabriquer `écriture-de-mission` en premier** (preuve mesurée la plus forte) : écartée par l'Owner (« on commence par le commencement ») — `session-start` ouvre chaque session, son absence coûte à chaque fenêtre ; l'écriture de Mission vient troisième.
- **Un moteur de recherche interne** (retrieval, embeddings) : écarté, contre la conclusion de l'étude Mnemosyne et sans besoin mesuré.
- **Renommer `to-questionnaire`** : écarté après investigation (point 7).
- **Péremption calendaire** (revue à date fixe sans lien aux sources) : écartée — elle fait relire ce qui n'a pas bougé et manque ce qui a bougé entre deux dates ; la revue périodique reste comme filet, pas comme mécanisme principal.

## Human gate

- Validation : accordée — verdicts nommés au Statut, Owner, 2026-08-31 et 2026-09-01.
- Référence : fenêtre Pilot du 2026-09-01 (table d'arbitrage en une passe, un verdict par rubrique) ; handoff `HANDOFF-2026-09-01-004859` §3 pour les arbitrages du 2026-08-31.

## Artefacts liés

- Source : `../handoffs/HANDOFF-2026-09-01-004859-session-close-skills-rework-library-pending-106.md` (§3, arbitrages des deux tiers)
- Source : `../knowledge-notes/KNOWLEDGE-NOTE-2026-09-01-110501-skills-library-v3-catalog.md` (mesure du skill `research`, entrée `to-questionnaire`)
- Source : `../knowledge-notes/KNOWLEDGE-NOTE-2026-08-30-211552-mnemosyne-retrieval-vs-vault-reel.md` (câbler l'existant plutôt qu'outiller)
- Exécution : Mission à venir (réciproque sur 232341, spec `session-start`)

## Liens

- `prescribed by` — [Gabarit de décision](../../../vault/templates/decision-template.md) (hors Vault)
- `amends` — [Décision — Consolidation du soir, standard projet et plan](./DECISION-2026-08-25-232341-evening-consolidation-project-standard-and-plan.md)
- `applies` — [Décision — Prise de conscience du Vault par un projet, trois étages](./DECISION-2026-08-31-210731-project-vault-awareness-three-tiers.md)
- `applies` — [Décision — Cohérence interne des Missions](./DECISION-2026-09-01-115547-mission-context-coherence-and-least-powerful-reading.md)
- `see also` — Décision — Critère de score retiré, adoption par nom (historique de l'atelier, non distribué)
- `see also` — Catalogue v3 des 40 skills externes (historique de l'atelier, non distribué)
