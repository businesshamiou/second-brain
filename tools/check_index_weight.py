#!/usr/bin/env python3
# Index-weight guardian (Mission 140, DECISION-2026-09-05-124647
# point 3): refuses a commit in which a staged index exceeds WEIGHT_CAP bytes,
# or in which an entry line of the Mission register exceeds LINE_CAP
# characters (DECISION-2026-09-02-191407, mechanised here on the register).
# Read-only: never fixes, only refuses and lists.
# Refusal is the default position.
#
# Files checked, in the STAGED tree (never the worktree): every
# index.md, every index-archive-*.md, and missions/MISSION-INDEX.md. A single
# Git call, never one per file.

import os
import re
import subprocess
import sys

# Folder mode and baseline (Decision 2026-09-17-000545, A4): same
# library as tools/check_indexes_fresh.py.
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import project_baseline  # noqa: E402

WEIGHT_CAP = 8000  # DECISION-2026-09-05-124647 point 3
LINE_CAP = 300  # DECISION-2026-09-02-191407
# Path relative to the root of the CURRENT REPOSITORY (the one committing), not a
# hard-coded workshop path: same defect, same fix as
# tools/check_indexes_fresh.py (Mission 175, step 2) -- residue not handled
# at the time in this twin file, found by Mission 177. Without this
# change, the 300-characters-per-line stop never triggered
# on a real project (missions/MISSION-INDEX.md, not
# workshop-production/missions/MISSION-INDEX.md). No missions/ folder at
# the root of second-brain itself: the severity changes for no
# real content of this repository.
MISSION_INDEX_PATH = "missions/MISSION-INDEX.md"

# Not retroactive, same discipline as the existing stop of
# check_indexes_fresh.py: only the Mission lines beyond this
# baseline are checked.
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


def dir_mode_batch(root, targets):
    # Same shape as the output of `git cat-file --batch`, read from disk.
    out = b""
    for path in targets:
        try:
            with open(os.path.join(root, path), "rb") as f:
                blob = f.read()
        except OSError:
            out += (":" + path + " missing\n").encode("utf-8", errors="surrogateescape")
            continue
        out += b"x blob %d\n" % len(blob) + blob + b"\n"
    return out


def main():
    global FAIL

    if len(sys.argv) > 1:
        # Folder mode (vcs: none): all the project's files.
        root = os.path.abspath(sys.argv[1])
        if not os.path.isdir(root):
            err("REFUS : dossier de projet introuvable : %s" % sys.argv[1])
            return 1
        staged = project_baseline.list_files(root)
        top = root
    else:
        root = None
        # Git call 1: the staged files of this commit.
        raw = git_out(
            ["diff", "--cached", "--name-only", "--diff-filter=ACMR"]
        ).decode("utf-8", errors="surrogateescape")
        staged = [p for p in raw.split("\n") if p]
        top = os.getcwd()

    # Baseline: an index engraved at adoption and not touched is not judged.
    baseline = project_baseline.Baseline(top)
    # Mission 203: the certificate's `# exempt:` prefixes are outside this
    # guardian's perimeter (same key, same grammar as the link and freshness
    # guardians). No key: nothing exempt.
    exempt = project_baseline.Exempt(top)

    targets = [
        p for p in staged
        if (INDEX_RE.search(p) or ARCHIVE_RE.search(p) or p == MISSION_INDEX_PATH)
        and not baseline.untouched(p)
        and not exempt.covers_file(p)
    ]
    if not targets:
        return 0

    if root:
        out = dir_mode_batch(root, targets)
    else:
        # Git call 2: their content from the staged tree, in one pass.
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

        # Mission 163: Mission 161's exemption REMOVED. Point 2 of
        # DECISION-2026-09-05-124647 is delivered -- the Mission register has
        # moved to four columns -- so the cap of point 3, which targets
        # "genere ou registre" ["generated or register"], applies to it again without exception. The
        # live register is split into slices; the archives carry a name
        # distinct from that of the generated archives. The LINE_CAP stop remains
        # applied to the register only, further down.
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
