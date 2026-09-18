#!/usr/bin/env python3
# Index freshness guardrail (Mission 089), rewritten in Python by
# Mission 137-B: same verdict, same messages, same return codes as
# tools/check-indexes-fresh.sh, in a single process. Never regenerates, never
# modifies anything; reads the format that tools/build-indexes.sh produces
# (Mission 080), does not redefine it -- same list of pruned folders, same
# field grammar. Refusal is the default position.
#
# Three fixed Git calls (Owner arbitration of 2026-09-04, option 2), never one
# per entry or per file: git diff --cached (staged set), git ls-files
# (contents of the folders in the staged tree), git cat-file --batch (all
# contents in one pass). The semantics of the old Bash are kept: everything
# is read in the STAGED TREE, never in the worktree.
#
# Output: index gaps go to stdout, the MISSION-INDEX.md cap
# to stderr, as in the original Bash. Written in binary (UTF-8, LF)
# so as not to suffer Python's CRLF translation under Windows.

import os
import re
import subprocess
import sys

# --- Output: strict LF, UTF-8, never any line-ending translation ----------


def out(line):
    sys.stdout.buffer.write((line + "\n").encode("utf-8"))


def err(line):
    sys.stderr.buffer.write((line + "\n").encode("utf-8"))


# --- Bash block l.13-16: Git guard ------------------------------------------
# The Bash does `git rev-parse --show-toplevel`. Here the root is found by
# climbing up to a .git: same result, no extra process.
# REPO_ROOT appears in no message: its form (Windows or POSIX) has
# no effect on the output.
def find_repo_root():
    d = os.path.abspath(os.getcwd())
    while True:
        if os.path.exists(os.path.join(d, ".git")):
            return d
        parent = os.path.dirname(d)
        if parent == d:
            return None
        d = parent


# Folder mode (Decision 2026-09-17-000545, A4 -- vcs: none): an argument
# names the root of a project without Git; the three Git calls are then
# replaced by a read of the disk (all files of the project, all
# .md counted as added). Without argument: behaviour unchanged.
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import project_baseline  # noqa: E402

DIR_MODE = len(sys.argv) > 1
if DIR_MODE:
    REPO_ROOT = os.path.abspath(sys.argv[1])
    if not os.path.isdir(REPO_ROOT):
        err("REFUS : dossier de projet introuvable : %s" % sys.argv[1])
        sys.exit(1)
else:
    REPO_ROOT = find_repo_root()
    if REPO_ROOT is None:
        err("REFUS : hors d'un depot Git : gardien non executable.")
        sys.exit(1)

# The Bash does `cd "$REPO_ROOT"` (l.261) before inspecting the folders.
os.chdir(REPO_ROOT)

# --- Bash block l.20: pruned folders ----------------------------------------
# `skills-warehouse` added (Mission 168, Owner arbitration 2026-09-11, option
# b): subtree adopted as is (tracked files only, T24), with its
# own standards (AGENTS.md, CLAUDE.md, *_STANDARD.md) and without the
# Vault index convention -- it has only ever carried a single native
# index.md (skill-collections/index.md), not one per folder. Outside the perimeter of
# this guardian, as tools/ or state/ already are for other reasons.
# ".agents" added (ticket 06, Mission 168): same reason as ".claude" and
# ".codex" already present -- official location of the Codex skills and
# subagents (T11), a folder machine-read by a third-party tool, never content
# of the documentary corpus indexed by this script.
# "_trash" added (Mission 175, step 7): the product's _trash/ zone, content
# withdrawn from distribution and frozen (Decision 110852) -- never navigated by
# the search order by index (assistant/ASSISTANT.md), hence never
# indexed, same reason as "state".
# "web-package" added (Mission 183-C01), same list as
# tools/build_indexes.py: package generated for a web Project, never indexed.
PRUNE_NAMES = set(
    ".git .githooks .claude .codex .agents graphify-out tools patterns "
    "node_modules state .venv venv __pycache__ skills-warehouse _trash "
    "web-package".split()
)

# Mission 140: index.md and its frozen archives never index themselves
# (same rule as tools/build_indexes.py).
ARCHIVE_RE = re.compile(r"^index-archive-.+\.md$")


def is_index_name(name):
    return name == "index.md" or bool(ARCHIVE_RE.match(name))


# --- Bash block l.22-35: is_pruned_dir --------------------------------------
def is_pruned_dir(d):
    if d == ".":
        return False
    return any(comp in PRUNE_NAMES for comp in d.split("/"))


# --- Bash block l.78-79: MISSION-INDEX.md cap -----------------------------
# Path relative to the root of the CURRENT REPOSITORY (the one committing -- a project
# created by tools/project-bootstrap.sh, whose register lives at the root of
# its own missions/ folder, never under a workshop subfolder:
# "workshop-production/" was a workshop path left hard-coded (Mission
# 174, audit; Mission 175, step 2), with no effect on a real project since
# that subfolder never exists there -- the cap therefore never triggered
# outside the Owner's workshop. Measured in the same report: this repository
# (second-brain) itself carries no missions/ folder at its root, so
# this change alters the severity of no real content of this repository.
MISSION_INDEX_LINE_CAP_BASELINE = 122
MISSION_INDEX_PATH = "missions/MISSION-INDEX.md"

FAIL = 0


# --- Bash block l.113-119: report_gap (stdout) ------------------------------
def report_gap(dossier, ecart, index_path):
    global FAIL
    out("INDEX-FRESHNESS [%s]" % dossier)
    out("  Ecart    : %s" % ecart)
    out(
        "  Consigne : bash tools/build-indexes.sh <racine> ; git add %s ; "
        "relire git diff --cached" % index_path
    )
    FAIL = 1


# --- Git calls (three, fixed) ----------------------------------------------
# Single call point: every external command of the guardian goes through here. It is
# invoked exactly three times, never in a loop (see GIT_CALLS).
GIT_CALLS = []


def git_out(args, payload=None):
    GIT_CALLS.append(" ".join(["git"] + args))
    return subprocess.run(["git"] + args, input=payload, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL).stdout


def decode(b):
    return b.decode("utf-8", errors="surrogateescape")


# Baseline (Decision 000545, A4): files engraved at adoption.
BASELINE = project_baseline.Baseline(REPO_ROOT)

if DIR_MODE:
    TRACKED = project_baseline.list_files(REPO_ROOT)
    diff_raw = "\n".join("A\t" + p for p in TRACKED if p.endswith(".md"))
else:
    # Call 1 -- Bash block l.259: staged set.
    diff_raw = decode(
        git_out(
            [
                "diff",
                "--cached",
                "--name-status",
                "-M",
                "--diff-filter=ACDMR",
                "--",
                "*.md",
            ]
        )
    )

    # Call 2 -- Bash block l.128: files present in the staged tree.
    lsfiles_raw = git_out(["ls-files", "-z"])
    TRACKED = [decode(p) for p in lsfiles_raw.split(b"\x00") if p]

# An addition or modification of an engraved, untouched file does not count
# as a change of the commit (ratchet: only what is touched is judged).
if BASELINE.active:
    kept = []
    for line in diff_raw.split("\n"):
        fields = line.split("\t")
        if len(fields) == 2 and fields[0][:1] in ("A", "M") and BASELINE.untouched(fields[1]):
            continue
        kept.append(line)
    diff_raw = "\n".join(kept)


# --- Bash block l.236-259: folders touched by a staged .md ----------------
DIRS = []
for line in diff_raw.split("\n"):
    if not line:
        continue
    fields = line.split("\t")
    st = fields[0]
    if not st:
        continue
    # R*/C* carry two paths; the others a single one (l.240-243).
    paths = fields[1:3] if st[:1] in ("R", "C") else fields[1:2]
    for p in paths:
        if not p:
            continue
        if not p.endswith(".md"):
            continue
        fn = p.rsplit("/", 1)[-1]
        if is_index_name(fn):
            continue
        d = p.rsplit("/", 1)[0] if "/" in p else "."
        if is_pruned_dir(d):
            continue
        if d not in DIRS:
            DIRS.append(d)

# --- Mission 161: union with every indexed folder of the staged tree ----------
# The loop above only keeps a folder that received a non-index .md
# in the current commit. A folder the commit does not touch was therefore
# never checked: blind spot measured in report 160 -- five indexes left in the
# old format for four days, and decisions/index.md grown to 16 495
# bytes, 206 % of the ceiling, without any guardian seeing it. Every folder of
# the staged tree carrying an index.md is now checked, whether the commit
# touches it or not.
# No Git call added (arbitration of 2026-09-04, three fixed calls):
# TRACKED comes from the `git ls-files` already read at call 2. The grammar is not
# touched -- neither ENTRY_RE, nor check_dir, nor PRUNE_NAMES.
for p in TRACKED:
    if p.rsplit("/", 1)[-1] != "index.md":
        continue
    d = p.rsplit("/", 1)[0] if "/" in p else "."
    if is_pruned_dir(d):
        continue
    if d not in DIRS:
        DIRS.append(d)


# --- Bash block l.128-136: depth-1 .md of a folder, sorted ----------
# Byte sort: identical to the `sort` of the context, measured on 2026-09-05 on
# the 154 real names of missions/.
def disk_files_of(d):
    prefix = "" if d == "." else d + "/"
    res = []
    for f in TRACKED:
        if not f.startswith(prefix):
            continue
        rel = f[len(prefix):]
        if "/" in rel or is_index_name(rel) or not rel.endswith(".md"):
            continue
        res.append(rel)
    res.sort(key=lambda s: s.encode("utf-8", errors="surrogateescape"))
    return res


# --- Call 3: all contents of the staged tree, in one pass -------------
# Replaces the `git show ":$path"` and `git cat-file -e ":$path"` that the Bash
# launched per file (l.143, l.149, l.177, l.82, l.85).
def batch_read(specs):
    if not specs:
        return {}
    if DIR_MODE:
        res = {}
        for spec in specs:
            try:
                with open(os.path.join(REPO_ROOT, spec[1:]), "rb") as f:
                    res[spec] = f.read()
            except OSError:
                res[spec] = None
        return res
    payload = ("\n".join(specs) + "\n").encode("utf-8", errors="surrogateescape")
    raw = git_out(["cat-file", "--batch"], payload)
    res = {}
    pos = 0
    for spec in specs:
        nl = raw.find(b"\n", pos)
        if nl == -1:
            break
        header = raw[pos:nl]
        pos = nl + 1
        if header.endswith(b" missing"):
            res[spec] = None
            continue
        size = int(header.split(b" ")[2])
        res[spec] = raw[pos:pos + size]
        pos += size + 1  # the content is followed by a \n added by cat-file
    return res


DISK = {d: disk_files_of(d) for d in DIRS}


# Ratchet: a folder whose index and every .md are engraved and untouched
# is not checked -- it is as it was at adoption.
def dir_untouched(d):
    prefix = "" if d == "." else d + "/"
    names = ["index.md"] + DISK[d]
    return all(BASELINE.untouched(prefix + n) for n in names)


if BASELINE.active:
    DIRS = [d for d in DIRS if not dir_untouched(d)]

# Mission 140: frozen archives of a folder, present in the staged tree.
ARCHIVES = {}
for d in DIRS:
    prefix_d = "" if d == "." else d + "/"
    found = []
    for f in TRACKED:
        if not f.startswith(prefix_d):
            continue
        rel = f[len(prefix_d):]
        if "/" not in rel and ARCHIVE_RE.match(rel):
            found.append(f)
    ARCHIVES[d] = sorted(found, key=lambda s: s.encode("utf-8", errors="surrogateescape"))

specs = []
for d in DIRS:
    if not DISK[d]:
        continue
    specs.append(":" + ("index.md" if d == "." else d + "/index.md"))
    for arch in ARCHIVES[d]:
        specs.append(":" + arch)
    prefix = "" if d == "." else d + "/"
    for fn in DISK[d]:
        fpath = prefix + fn
        if fpath.startswith("./"):  # l.176
            fpath = fpath[2:]
        specs.append(":" + fpath)
specs.append(":" + MISSION_INDEX_PATH)
BLOBS = batch_read(specs)


def staged_text(path):
    b = BLOBS.get(":" + path)
    if b is None:
        return None
    # `$(git show ...)` strips the trailing newlines (l.149, l.177, l.85).
    return decode(b).rstrip("\n")


# --- Bash block l.39-48: fm_status_desc, same grammar as build-indexes ---
def fm_status_desc(text):
    infm = False
    status = ""
    description = ""
    lines = text.split("\n")
    for i, line in enumerate(lines):
        if i == 0:
            if line == "---":
                infm = True
                continue
        if infm and line == "---":
            infm = False
        if infm and line.startswith("status:"):
            v = re.sub(r"^status:[ \t\r\f\v]*", "", line)
            v = re.sub(r'^"|"$', "", v)
            status = v
        if infm and line.startswith("description:"):
            v = re.sub(r"^description:[ \t\r\f\v]*", "", line)
            v = re.sub(r'^"|"$', "", v)
            description = v
    return status, description


# --- Bash block l.50-58: fm_type -------------------------------------------
def fm_type(text):
    infm = False
    ty = ""
    lines = text.split("\n")
    for i, line in enumerate(lines):
        if i == 0:
            if line == "---":
                infm = True
                continue
        if infm and line == "---":
            infm = False
        if infm and line.startswith("type:"):
            v = re.sub(r"^type:[ \t\r\f\v]*", "", line)
            v = re.sub(r'^"|"$', "", v)
            ty = v
    return ty if ty else "inconnu"


# --- Bash block l.60-66: contenu_section -----------------------------------
def contenu_section(text):
    on = False
    res = []
    for line in text.split("\n"):
        if re.match(r"^## Contenu[ \t\r\f\v]*$", line):
            on = True
            continue
        if line.startswith("## "):
            on = False
        if on:
            res.append(line)
    return res


# --- Mission 140: line format as a locator -------------------------
# "- `<identifiant>` · <statut> · <titre court> · `<nom de fichier>`"
# followed, where applicable, by " — REMPLACÉ par <nom>". The status never contains
# a "·"; the title may contain some, hence the greedy group.
ENTRY_RE = re.compile(r"^- `[^`]*` · ([^·]*?) · .* · `([^`]*)`$")
MARK = " — REMPLACÉ par "


def parse_entry(line):
    """Return (file name, status) for an entry line, otherwise None."""
    if MARK in line:
        line = line.split(MARK, 1)[0]
    m = ENTRY_RE.match(line)
    if not m:
        return None
    return m.group(2), m.group(1)


# --- Bash block l.155: comm -13 on two sorted lists ---------------------
def comm_13(disk, index_names):
    i = j = 0
    only_second = []
    while i < len(disk) and j < len(index_names):
        a = disk[i].encode("utf-8", errors="surrogateescape")
        b = index_names[j].encode("utf-8", errors="surrogateescape")
        if a == b:
            i += 1
            j += 1
        elif a < b:
            i += 1
        else:
            only_second.append(index_names[j])
            j += 1
    only_second.extend(index_names[j:])
    return only_second


# --- Bash block l.121-232: check_dir ---------------------------------------
def check_dir(d):
    prefix = "" if d == "." else d + "/"

    disk_files = DISK[d]
    if not disk_files:  # l.138: not an indexed folder
        return

    index_path = "index.md" if d == "." else d + "/index.md"

    index_content = staged_text(index_path)
    if index_content is None:  # l.143-146
        report_gap(
            d,
            "dossier indexe sans index.md (%s absent de l'arbre stage)" % index_path,
            index_path,
        )
        return

    # Mission 140: a folder's index may be split into a live index
    # and frozen archives (DECISION-2026-09-05-124647 point 4). The set
    # of names is read over the union of both -- the live one alone is a
    # partial view, and would wrongly refuse any archived entry.
    contenu = contenu_section(index_content)
    for arch_path in ARCHIVES.get(d, []):
        arch_text = staged_text(arch_path)
        if arch_text is not None:
            contenu = contenu + contenu_section(arch_text)

    index_entries = {}  # file name -> status carried by the index
    for line in contenu:
        parsed = parse_entry(line)
        if parsed:
            index_entries[parsed[0]] = parsed[1]
    index_names = sorted(
        index_entries, key=lambda s: s.encode("utf-8", errors="surrogateescape")
    )

    # l.153-163: extra entries.
    for fn in comm_13(disk_files, index_names):
        if not fn:
            continue
        report_gap(
            d,
            "entree en trop dans l'index : %s (absent du dossier apres le commit)" % fn,
            index_path,
        )

    # l.165-231: missing entry, then status/description desync.
    for fn in disk_files:
        if not fn:
            continue

        if fn not in index_names:  # l.170-173
            report_gap(d, "entree manquante dans l'index : %s" % fn, index_path)
            continue

        fpath = (prefix + fn)
        if fpath.startswith("./"):
            fpath = fpath[2:]
        fm_content = staged_text(fpath)
        if fm_content is None:
            fm_content = ""
        st, _ = fm_status_desc(fm_content)
        ty = fm_type(fm_content)

        # Mission 140: the line is a locator, the status is a field
        # in its own right; the description has disappeared from indexes (DECISION
        # 124647 point 1), so its comparison disappears too.
        expected = st if st else ty
        found = index_entries.get(fn)
        if found != expected:
            if st:
                report_gap(
                    d,
                    'status desynchronise pour %s (fichier: "%s")' % (fn, st),
                    index_path,
                )
            else:
                report_gap(
                    d,
                    "status desynchronise pour %s (fichier: aucun status)" % fn,
                    index_path,
                )


# --- Bash block l.81-109: 300-character cap (stderr) --------------------
def check_mission_index_line_cap():
    global FAIL
    content = staged_text(MISSION_INDEX_PATH)
    if content is None:  # l.82: git cat-file -e ... || return 0
        return

    line_no = 0
    for line in content.split("\n"):
        line_no += 1
        # l.89-92: pattern "| `NNN` |" at the start of a line.
        m = re.match(r"^\| `([0-9]+)`.*", line)
        if not m:
            continue
        nnn = int(m.group(1))
        if nnn <= MISSION_INDEX_LINE_CAP_BASELINE:  # l.97
            continue
        # l.99: `wc -m` counts characters, not bytes, and the newline
        # is not counted (printf '%s').
        length = len(line)
        if length > 300:
            err("INDEX-LINE-CAP [%s]" % MISSION_INDEX_PATH)
            err("  Ligne    : %d (Mission %d)" % (line_no, nnn))
            err(
                "  Longueur : %d caracteres > 300 (Decision 191407)" % length
            )
            FAIL = 1


# --- Bash block l.263-273: execution order -------------------------------
for d in DIRS:
    check_dir(d)

# l.271-273: cap only if MISSION-INDEX.md is staged in this commit.
staged_now = set()
for line in diff_raw.split("\n"):
    if not line:
        continue
    fields = line.split("\t")
    if not fields[0]:
        continue
    if fields[0][:1] in ("A", "C", "M", "R"):
        staged_now.update(p for p in fields[1:3] if p)
if MISSION_INDEX_PATH in staged_now and not BASELINE.untouched(MISSION_INDEX_PATH):
    check_mission_index_line_cap()

# --- Bash block l.275 -------------------------------------------------------
sys.stdout.buffer.flush()
sys.stderr.buffer.flush()
sys.exit(FAIL)
