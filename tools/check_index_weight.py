#!/usr/bin/env python3
# Gardien de poids des index (Mission 140, DECISION-2026-09-05-124647
# point 3) : refuse un commit dont un index stage depasse WEIGHT_CAP octets,
# ou dont une ligne d'entree du registre des Missions depasse LINE_CAP
# caracteres (DECISION-2026-09-02-191407, mecanisee ici sur le registre).
# Lecture seule : ne corrige jamais, se contente de refuser et de lister.
# Le refus est la position par defaut.
#
# Fichiers controles, dans l'arbre STAGE (jamais le worktree) : tout
# index.md, tout index-archive-*.md, et missions/MISSION-INDEX.md. Un seul
# appel Git, jamais un par fichier.

import re
import subprocess
import sys

WEIGHT_CAP = 8000  # DECISION-2026-09-05-124647 point 3
LINE_CAP = 300  # DECISION-2026-09-02-191407
# Chemin relatif a la racine du DEPOT COURANT (celui qui commite), pas un
# chemin d'atelier en dur : meme defaut, meme correction que
# tools/check_indexes_fresh.py (Mission 175, etape 2) -- residu non traite
# alors dans ce fichier jumeau, trouve par la Mission 177. Sans ce
# changement, la butee de 300 caracteres par ligne ne se declenchait jamais
# sur un projet reel (missions/MISSION-INDEX.md, pas
# workshop-production/missions/MISSION-INDEX.md). Aucun dossier missions/ a
# la racine de second-brain lui-meme : la severite ne change pour aucun
# contenu reel de ce depot.
MISSION_INDEX_PATH = "missions/MISSION-INDEX.md"

# Non retroactif, meme discipline que la butee existante de
# check_indexes_fresh.py : seules les lignes de Mission au-dela de cette
# baseline sont verifiees.
MISSION_INDEX_LINE_CAP_BASELINE = 122

ARCHIVE_RE = re.compile(r"(?:^|/)index-archive-.+\.md$")
INDEX_RE = re.compile(r"(?:^|/)index\.md$")
ENTRY_NUM_RE = re.compile(r"^\| `([0-9]+)`")

FAIL = 0


def err(line):
    sys.stderr.buffer.write((line + "\n").encode("utf-8"))


def report(path, ecart, consigne):
    global FAIL
    err("INDEX-WEIGHT [%s]" % path)
    err("  Ecart    : %s" % ecart)
    err("  Consigne : %s" % consigne)
    FAIL = 1


def git_out(args, payload=None):
    return subprocess.run(
        ["git"] + args, input=payload, stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
    ).stdout


def main():
    global FAIL

    # Appel Git 1 : les fichiers stages de ce commit.
    raw = git_out(
        ["diff", "--cached", "--name-only", "--diff-filter=ACMR"]
    ).decode("utf-8", errors="surrogateescape")
    staged = [p for p in raw.split("\n") if p]

    targets = [
        p for p in staged
        if INDEX_RE.search(p) or ARCHIVE_RE.search(p) or p == MISSION_INDEX_PATH
    ]
    if not targets:
        return 0

    # Appel Git 2 : leur contenu depuis l'arbre stage, en une passe.
    payload = ("\n".join(":" + p for p in targets) + "\n").encode(
        "utf-8", errors="surrogateescape"
    )
    out = git_out(["cat-file", "--batch"], payload)

    pos = 0
    for path in targets:
        nl = out.find(b"\n", pos)
        if nl == -1:
            break
        header = out[pos:nl]
        pos = nl + 1
        if header.endswith(b" missing"):
            continue
        size = int(header.split(b" ")[2])
        blob = out[pos:pos + size]
        pos += size + 1

        # Mission 163 : exemption de la Mission 161 RETIREE. Le point 2 de la
        # DECISION-2026-09-05-124647 est livre -- le registre des Missions est
        # passe a quatre colonnes -- donc le plafond du point 3, qui vise
        # "genere ou registre", lui redevient applicable sans exception. Le
        # registre vivant est scinde par tranches ; les archives portent un nom
        # distinct de celui des archives generees. La butee LINE_CAP reste
        # appliquee au registre seul, plus bas.
        if size > WEIGHT_CAP:
            report(
                path,
                "index de %d octets > %d (DECISION-2026-09-05-124647)" % (size, WEIGHT_CAP),
                "alleger l'index : ligne en localisateur, ou scission "
                "vivant/archive par bash tools/build-indexes.sh <racine>",
            )

        if path != MISSION_INDEX_PATH:
            continue

        text = blob.decode("utf-8", errors="surrogateescape")
        line_no = 0
        for line in text.split("\n"):
            line_no += 1
            m = ENTRY_NUM_RE.match(line)
            if not m:
                continue
            nnn = int(m.group(1))
            if nnn <= MISSION_INDEX_LINE_CAP_BASELINE:
                continue
            if len(line) > LINE_CAP:
                report(
                    path,
                    "ligne %d (Mission %d) de %d caracteres > %d "
                    "(DECISION-2026-09-02-191407)" % (line_no, nnn, len(line), LINE_CAP),
                    "reduire la ligne du registre a un statut d'execution, "
                    "sans recit",
                )

    sys.stderr.buffer.flush()
    return FAIL


if __name__ == "__main__":
    sys.exit(main())
