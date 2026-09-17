#!/usr/bin/env python3
# Reparation des liens casses d'un projet adopte (Decision 2026-09-17-000545,
# A4) : rend un PLAN, n'applique rien. L'application (--apply) n'a lieu que
# sous une Mission nommee (--mission <fichier MISSION-...>), jamais seule.
#
# Un lien casse est un lien Markdown relatif (./ ou ../) vers un .md absent,
# hors bloc de code et hors code en ligne -- la regle de tools/check-links.sh.
# Une reparation est proposee seulement si le projet porte un et un seul
# fichier du meme nom ; sinon le lien est rendu sans proposition.
#
# usage: propose_link_repairs.py <projet> [--apply --mission <fichier>]
# Bibliotheque standard seulement.

import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import project_baseline  # noqa: E402

LINK_RE = re.compile(r"\]\((\.{1,2}/[^)]*)\)")
INLINE_CODE_RE = re.compile(r"(`+)(.+?)\1")


def out(line):
    sys.stdout.buffer.write((line + "\n").encode("utf-8"))


def broken_links(root, files):
    for rel in files:
        if not rel.endswith(".md"):
            continue
        full = os.path.join(root, rel)
        try:
            with open(full, "r", encoding="utf-8", errors="replace") as f:
                lines = f.read().split("\n")
        except OSError:
            continue
        in_fence = False
        for no, line in enumerate(lines, 1):
            stripped = line.lstrip()
            if stripped.startswith("```") or stripped.startswith("~~~"):
                in_fence = not in_fence
                continue
            if in_fence:
                continue
            scan = INLINE_CODE_RE.sub(" ", line)
            for target in LINK_RE.findall(scan):
                if not target.endswith(".md"):
                    continue
                resolved = os.path.normpath(os.path.join(os.path.dirname(full), target))
                if not os.path.isfile(resolved):
                    yield rel, no, target


def main(argv):
    if not argv:
        sys.stderr.write("usage: propose_link_repairs.py <projet> [--apply --mission <fichier>]\n")
        return 1
    root = os.path.abspath(argv[0])
    apply = "--apply" in argv
    mission = ""
    if "--mission" in argv:
        i = argv.index("--mission")
        mission = argv[i + 1] if i + 1 < len(argv) else ""
    if not os.path.isdir(root):
        sys.stderr.write("REFUS : dossier de projet introuvable : %s\n" % argv[0])
        return 1
    if apply:
        ok = False
        if mission and os.path.isfile(mission) and os.path.basename(mission).startswith("MISSION-"):
            with open(mission, "r", encoding="utf-8", errors="replace") as f:
                ok = "type: mission" in f.read()
        if not ok:
            sys.stderr.write("REFUS : --apply est reserve a une Mission (--mission <fichier MISSION-...> de type mission)\n")
            return 1

    files = project_baseline.list_files(root)
    by_name = {}
    for rel in files:
        by_name.setdefault(os.path.basename(rel), []).append(rel)

    total = proposed = applied = 0
    for rel, no, target in list(broken_links(root, files)):
        total += 1
        candidates = by_name.get(os.path.basename(target), [])
        if len(candidates) != 1:
            out("SANS-PROPOSITION %s:%d: %s (%d candidat(s))" % (rel, no, target, len(candidates)))
            continue
        src_dir = os.path.dirname(os.path.join(root, rel))
        new = os.path.relpath(os.path.join(root, candidates[0]), src_dir).replace(os.sep, "/")
        if not new.startswith("../"):
            new = "./" + new
        proposed += 1
        out("PROPOSE %s:%d: %s -> %s" % (rel, no, target, new))
        if apply:
            full = os.path.join(root, rel)
            with open(full, "r", encoding="utf-8", newline="") as f:
                lines = f.read().split("\n")
            old_link = "](%s)" % target
            if old_link in lines[no - 1]:
                lines[no - 1] = lines[no - 1].replace(old_link, "](%s)" % new, 1)
                with open(full, "w", encoding="utf-8", newline="") as f:
                    f.write("\n".join(lines))
                applied += 1
                out("APPLIQUE %s:%d" % (rel, no))
    out("PLAN: %d lien(s) cassé(s), %d réparation(s) proposée(s), %d appliquée(s)" % (total, proposed, applied))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
