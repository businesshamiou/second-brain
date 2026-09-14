---
type: decision
title: "Consolidation du 2026-08-25 soir — standard de projet, dévoilement progressif, droits d'écriture du Pilot, protocole du mot exact, skills V1, plan en huit chantiers"
description: "Grave les arbitrages du brainstorm du 25 août au soir : les cinq questions de l'arborescence projet (7 fonctions, workspace, YAGNI, exclusions, allowlist MCP), le dévoilement progressif des index, le protocole d'autorisation par mot exact, la liste des skills V1 et l'ordre des chantiers."
created_at: "2026-08-25T23:23:41-04:00"
timezone: America/Montreal
status: arbitrated
owner_gate: granted
rapatriated_from: "workshop-build/workshop-production/decisions/DECISION-2026-08-25-232341-evening-consolidation-project-standard-and-plan.md"
---

# DÉCISION — CONSOLIDATION DU 2026-08-25 SOIR

## Date

2026-08-25

## Statut

`ARBITRATED`

Arbitré en séance par l'Owner, point par point au fil du brainstorm du 2026-08-25 au soir, puis validé globalement (« je suis d'accord avec tes propositions, vas-y »). Chaque section indique son mode d'arbitrage lorsque celui-ci fut global plutôt qu'individuel.

## Décision

### 1. Standard de projet — les cinq questions du 2026-08-24 sont fermées

**1.1 Le minimum vital d'un projet est défini par sept fonctions, pas par des dossiers** : identité (« quel est ce projet ? »), règles métier (« quelles lois s'appliquent ici et seulement ici ? »), mémoire d'état (« où en est-on ? »), exécution (« qu'a-t-on fait faire ? »), arbitrage (« qu'a-t-on décidé ? »), matière (« qu'a-t-on appris ? »), passation (« comment on reprend ? »).

**1.2 Frontière Vault/projet**, test gravé : *« Cette règle aurait-elle du sens dans un autre projet ? »* Oui → Vault. Non → dossier `rules/` du projet. Le Vault reste distribuable ; les règles métier restent chez elles.

**1.3 Les fonctions vivent à la racine du projet** — aucun sous-dossier de travail intermédiaire. Les sous-dossiers supplémentaires naissent au fil du besoin réel, jamais par anticipation (principe YAGNI), selon les normes de nomenclature et les règles de l'art de l'industrie logicielle. Squelette de référence :

    <projet>/
    ├── README.md      (identité, point d'entrée)
    ├── rules/         (règles métier du projet)
    ├── state/         (journal + fiche générée)
    ├── missions/      (Missions ET leurs rapports — même lignée)
    ├── decisions/     (arbitrages rendus)
    ├── proposals/     (options en attente — séparées : une option n'est pas un arbitrage)
    ├── knowledge/     (matière : captures, études, notes — fusion de captures/ et knowledge-notes/)
    └── handoffs/      (passation)

**1.4 Exclusions du standard** : `prompt-archive/` (aboli par A7), `audits/` (un audit est une exécution, son rapport va dans `missions/` avec les autres), `generated/` (naît au besoin, hors minimum).

**1.5 Clause du grand-père** : (historique de l'atelier, non distribué) reste tel quel — aucune restructuration, aucune migration. Coût connu (liens relatifs, cf. Missions 052-055) pour gain nul. Sa non-conformité a valeur pédagogique d'avant/après. Seule règle applicable : plus aucun dépôt dans ses dossiers morts.

**1.6 Le workspace `workshops` est le conteneur de tout le chantier.** L'organisation du workspace (branches d'activité de l'utilisateur, sous-dossiers par domaine) est **libre et personnelle**, collectée par l'interrogatoire de première installation ; le registre v1 la supporte déjà (chemins relatifs au parent du Vault). Le standard ne porte que sur l'intérieur d'un projet.

**1.7 Le premier-né du standard est `wordpress-workshop`** (nom arbitré) : premier projet créé par le bootstrap conforme, banc d'essai du registre v2, objet montré à l'atelier, candidat projet modèle du paquet distribuable.

### 2. Dévoilement progressif (progressive disclosure)

**2.1** Tout document porte un champ `description` en front-matter : une à deux phrases, **écrites par l'auteur du document au moment du dépôt** — jamais générées par un modèle tiers (leçon de l'audit externe : la couche produite par LLM est la moins fiable et exige un contrôle qualité permanent).

**2.2** Les `index.md` de dossier, toujours générés par script et jamais écrits à la main, s'enrichissent mécaniquement de trois champs recopiés depuis les en-têtes : `status`, `description`, relation de supersession. La génération est strictement déterministe.

**2.3** Règle de descente, gravée : on s'arrête à l'index quand la question porte sur l'existence, le statut, ou ce qui est en vigueur ; on descend au fichier quand il faut le texte exact d'une règle, quand on va s'appuyer dessus pour une Mission ou une Decision, ou au moindre doute sur la ligne d'index.

**2.4** La présence et la forme du champ `description` sont exigées par le garde-fou pre-commit — validation préventive à l'écriture, pas contrôle réactif après coup.

**2.5** Toute partition d'archive (« dossier par an ») est une **condition de réveil**, pas une action : le chantier s'ouvre quand un dossier dépasse environ 100 fichiers. Aucun chiffre d'économie de lecture n'est revendiqué publiquement sans mesure propre.

### 3. Droits d'écriture du Pilot — étage 2 de la charte, enfin défini

**3.1** Allowlist par la configuration du serveur MCP, **grain gros — par dossier** : le Pilot peut créer dans les dossiers d'artefacts (`missions/`, `decisions/`, `proposals/`, `knowledge/`, `handoffs/` et leurs équivalents actuels) ; il ne touche jamais `rules/`, `state/`, `templates/`, `tools/`, les index générés ni les fichiers racine.

**3.2** Principes importés de l'audit du système aîné : **fail closed** (configuration absente = refus bruyant, jamais de repli silencieux) ; le modèle de menace reste **anti-accident, pas anti-évasion**. La distinction créer/modifier dans un dossier autorisé reste couverte par l'étage 3 (muraille pre-commit, inspection du diff).

**3.3** La réalisation technique (montages, options du serveur) doit être **mesurée, pas supposée** — Mission dédiée. (Arbitrage global.)

### 4. Protocole du mot exact (autorisation aux gates)

**4.1** Toute demande de porte adressée à l'Owner se termine par un snippet où **le Pilot propose lui-même les mots attendus** et leur effet — par exemple : « réponds `je valide` pour déposer tel quel, `je tranche : b` pour l'option b ». L'Owner copie le mot ; tout substitut ou formulation libre vaut discussion, pas autorisation.

**4.2** Clause de réalisme, gravée à la demande de l'Owner : on ne mécanise pas tout ; une petite erreur d'un côté ou de l'autre se rattrape au geste suivant. Le protocole vise la certitude des gates importants, pas le contrôle total.

**4.3** Origine : incident mesuré du système aîné (le mot « continue » servant deux autorisations différentes la même nuit) et faute de session du 2026-08-24 (« vas-y » oral pris pour un arbitrage).

### 5. Skills V1 — liste fermée et ordre

**5.1** Six skills : `session-start` (geste zéro : identité et racine avant toute lecture ; canari des garde-fous : hooks vivants, chemins de hooks, empreintes des fichiers de politique ; chargement de l'index du registre ; vérification de conformité du projet ; annonce du rôle) · `session-close` (le miroir manquant des deux systèmes : journal, fiche régénérée, revue des portes avec leurs `CLOSE:`, handoff si reprise) · `executor-preflight` (extension du préflight existant : geste zéro + refus de la forme `git add .`/`-A`) · `project-bootstrap` (arborescence des 7 fonctions + fiche registre + ligne d'index) · `first-install` (l'interrogatoire : questions de contexte → fiche USER → marqueur nom+contrat → journal → premiers index) · skill de recherche (enveloppe de `find-in-vault.sh`, dernier).

**5.2** Deux mécaniques pures hors skills : filtre de la forme `git add` au pre-commit ; canari si mieux placé dans le préflight.

**5.3** Ordre impératif, justifié par l'avertissement du système aîné (ne pas bâtir sur des contrats non figés) : le nettoyage normatif (chantier 2) gèle la charte **avant** la construction des skills.

**5.4** Non importé, décision explicite : le moteur de politique complet du système aîné (`policy.yaml`, régimes, identité de dépôt). YAGNI — le trio lanceur d'identité + allowlist MCP + muraille pre-commit couvre les trous réels. Conservé comme référence de conception.

### 6. Liens et pointeurs — règle générale

Une cible hors dépôt ou inexistante **se cite, ne se lie pas** : l'information se garde en mention texte, le pointeur mort se supprime. (Généralise l'arbitrage des six références pré-Vault du RELAY 055.)

### 7. Plan en huit chantiers

0. Audit 057 — **fait** (rapport `214618`). 1. Gravure de synthèse — **ce document**. 2. Nettoyage normatif sur pièces du rapport 057 : charte §3, quatre couples contredits, résidus PROMPT, outillage du garde-fou. 3. Registre v2 (contrat de structure : bootstrap, session-start, allowlist MCP) et 3-bis Skills V1. 4. Naissance de `wordpress-workshop`. 5. Empaquetage du Vault (interrogatoire, fiche USER, paquet, notice). 6. Contenu de l'atelier, construit dans `wordpress-workshop`. 7. Skill de recherche. Logique : on nettoie, on standardise, on fait naître l'exemple, on emballe, on prouve.

## Raison

Cinq occurrences en une journée du patron « une règle survit à l'abandon de son motif » ont montré que la doctrine seule dérive ; l'audit du système aîné a confirmé empiriquement que ce qui est mécanisé tient (zéro violation sur les gestes bloqués par hook) et que ce qui est doctrinal se viole (trois épisodes documentés). La présente consolidation transforme le brainstorm du soir en textes gravés avant que la session ne se ferme — précisément pour ne pas rejouer le patron qu'elle combat.

## Impact

- Le standard de projet est arbitré ; le registre v2 a son cahier des charges ; la porte `frozen-project-tree-standard` a trouvé son réveil et sa réponse (ligne `CLOSE:` à écrire par la prochaine fenêtre Executor, avec les clés de portes associées).
- Le gabarit de Mission recevra quatre amendements (section Préconditions ; comptes relatifs obligatoires ; section Portes avec `CLOSE:` ; contrat de reprise en cas d'arrêt partiel) — chantier 2, arbitrage global acquis.
- Les relations d'amendement envers `DECISION-2026-08-23-124848` (point 7 : le projet modèle du lot E n'est plus « Une semaine sans écran ») et la charte §3 seront typées réciproquement par la Mission du chantier 2 — non liées ici, conformément au point 6 et aux deux refus du garde-fou documentés au rapport 057.

## Alternatives importantes

- Restructurer `workshop-production` au standard : rejetée (coût des liens, gain nul, valeur pédagogique de l'écart).
- Grain fin par fichier pour les droits du Pilot : rejeté (non natif au serveur, se périme à chaque fichier, n'arrête pas mieux l'accident).
- Import du moteur de politique du système aîné : rejeté, YAGNI (référence conservée).

## Human gate

- Validation : accordée
- Référence : arbitrages successifs en séance du 2026-08-25 soir, puis validation globale finale de l'Owner ; consigné au journal par la prochaine fenêtre Executor.

## Artefacts liés

- Rapport de l'audit 057 : `../reports/REPORT-2026-08-25-214618-057-executor-stale-rule-survivorship-audit.md`
- Pivot du cas d'usage : `./DECISION-2026-08-25-205728-workshop-case-study-pivot-wordpress.md`
- Position d'ouverture libérée : `./DECISION-2026-08-25-213150-session-opening-directory-freed.md`
- Handoff des cinq questions (2026-08-24) : `../handoffs/HANDOFF-2026-08-24-115651-pilot-session-close-graphify-eradication-and-tree-question.md` (supprimé)
- Audits externes servant de sources (à verser en knowledge-notes, chantier en file) : audit du dévoilement progressif de la base YouTube ; audit des contraintes de rôles du système aîné (2026-08-26-030356).

## Liens

- `amended by` — Décision — §2.4 cesse d'affirmer un garde-fou qui n'existe pas (historique de l'atelier, non distribué)
- `amended by` — [Décision — Prise de conscience du Vault par un projet, en trois étages](./DECISION-2026-08-31-210731-project-vault-awareness-three-tiers.md)
- `amended by` — [Décision — Fin de passe skills V1](./DECISION-2026-09-01-144931-skills-v1-end-of-pass.md)
- `prescribed by` — [Cycle de contexte V2](../rules/RULES-2026-08-17-111018-context-lifecycle-v2.md)
- `applies` — [Décision — Pivot du cas d'usage de l'atelier](./DECISION-2026-08-25-205728-workshop-case-study-pivot-wordpress.md)
- `applies` — [Décision — Répertoire d'ouverture libéré](./DECISION-2026-08-25-213150-session-opening-directory-freed.md)
- `see also` — Rapport d'exécution — Mission 057 (historique de l'atelier, non distribué)
- `see also` — Leçons de la session du 2026-08-25 (historique de l'atelier, non distribué)
- `amends` — Décision — Modèle opératoire minimal des projets (historique de l'atelier, non distribué) (noyau minimal remplacé — Mission 065)
- `amends` — Décision — Arbitrage de la cartographie de normalisation et héritage projet (historique de l'atelier, non distribué) (§5, architecture projet standard remplacée — Mission 065)
