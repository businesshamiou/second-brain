---
type: decision
title: "Décision — Legacy déjà préparé : sauvegarde froide vérifiée, branche legacy poussée ; le chantier ne se rouvre pas, la migration part de cet acquis"
created_at: "2026-09-06T11:45:21-04:00"
timezone: America/Montreal
status: active
description: "Amendement Owner du 2026-09-06 (fichier amendement-owner-legacy-deja-prepare.txt, en chat) : la préparation du Legacy est terminée et validée — sauvegarde froide vérifiée, branche legacy créée et poussée sur le dépôt distant du Vault. Conséquences : aucune nouvelle préparation, sauvegarde ni audit général du Legacy ; la Mission de migration (143) part de cet état acquis et ne joue que le cutover du plan V1 ; le chantier Legacy ne se rouvre que sur divergence nouvelle et mesurée. Amende la séquence 3 de la PROPOSAL 165829 sur ces points ; l'extraction ciblée des données Owner selon le manifeste arbitré reste due, depuis la branche legacy."
---

# DÉCISION — Legacy déjà préparé, migration depuis l'acquis

## Contexte

La PROPOSAL de fermeture V1 (165829, 2026-09-05, acceptée) prescrivait à la séquence 3 : préservation du Legacy (tag, zéro écriture), inventaire READ-ONLY par Claude Code sous autorisation dédiée, arbitrage Owner du manifeste d'extraction, puis Mission 143. L'Owner a réalisé la préparation de son côté et l'a validée le 2026-09-06.

## Décision (Owner, 2026-09-06, verbatim du fichier transmis)

État acquis : sauvegarde froide vérifiée ; branche legacy créée et poussée sur le dépôt distant businesshamiou/vault ; le Legacy est sécurisé et prêt pour la future bascule.

1. **Ne refaire ni préparation, ni sauvegarde, ni audit du Legacy.** Ces étapes de la séquence V1 sont acquises et sortent du plan.
2. **La phase de migration (Mission 143) part de cet état acquis** et ne réalise que les opérations de cutover nécessaires, conformément au plan V1.
3. **Le chantier Legacy ne se rouvre pas**, sauf si une divergence nouvelle et **mesurée** l'exige.
4. Le plan de clôture V1 se poursuit à partir de l'état actuel.

## Conséquences

- La Mission 143 remplace ses étapes de préservation et d'inventaire par une **précondition de mesure** : la branche legacy existe sur le distant (`git ls-remote`), son HEAD est collé, et le clone STABLE se fait sur main — la branche legacy n'est jamais fusionnée ni modifiée.
- L'extraction ciblée des données Owner (manifeste de la PROPOSAL 165829, arbitrage Owner requis) reste due ; sa source est la branche legacy poussée, pas un nouvel audit.
- Fait d'architecture consigné, à mesurer en précondition de la 143 : l'ancien contenu vit comme **branche du même dépôt distant** que le nouveau Vault, pas comme dépôt séparé.
- La PROPOSAL 165829 n'est pas réécrite (elle reste le plan accepté) ; la présente Décision l'amende sur les points 1–2 et prévaut en cas d'écart.

## Alternatives écartées

- Rejouer l'inventaire par prudence : contraire à l'ordre Owner et au principe « pas de précipitation, mais pas de re-travail » ; la sauvegarde froide et la branche poussée sont l'assurance mesurable.
- Graver seulement en chat : un ordre non gravé perd contre un plan commité au fil des sessions — mesuré plusieurs fois dans ce projet.

## Annotation du 2026-09-07

Fait mesuré (rapport 148 §5) : `<depot-prive>-works\vault` (Legacy) pousse vers `businesshamiou/vault.git`, `workshops\vault` (NEXT) vers `businesshamiou/ai-context-vault.git` — deux distants distincts, pas « le même dépôt distant ». La Décision 125156 amende ce point : la cible finale confirmée reste `businesshamiou/vault` (`main` moderne + branche `legacy`), atteinte depuis deux dépôts aujourd'hui séparés.

## Liens

- `prescribed by` — [Cycle de contexte V2](../rules/RULES-2026-08-17-111018-context-lifecycle-v2.md)
- `see also` — PROPOSAL — Fermeture de la V1 (historique de l'atelier, non distribué) (hors Vault)
- `applies` — [Décision — Statut de preuve et contrôle du STOP](./DECISION-2026-08-29-212009-evidence-status-and-stop-control.md)
- `amended by` — [Décision — Sept arbitrages sur les dépendances machine avant cutover](./DECISION-2026-09-07-125156-cutover-dependencies-seven-arbitrations.md)
