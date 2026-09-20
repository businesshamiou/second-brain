#!/usr/bin/env python3
# Index generator (Mission 080, rewritten in Python by Mission 140 to
# apply DECISION-2026-09-05-124647). Regenerates one index.md per eligible
# folder, under each root passed as argument. Generated only: never
# edit an index.md by hand.
#
# usage: build_indexes.py [-v|--verbose] [--only-missing] <racine...>
#
# --only-missing (Decision 2026-09-17-000545, A4 -- adoption of an existing
# folder): writes an index only in a folder that carries none
# (neither index.md nor archive); never rewrites, removes or splits an
# existing index, touches superseded-files.txt only if it is absent.
#
# Mission 172, audit defect 3: quiet by default (one summary line per
# invocation) since Mission 172; -v/--verbose restores the full per-file
# detail this file used to always print.
#
# SEMANTICS KEPT from tools/build-indexes.sh (read in full before the
# rewrite): walks the WORKTREE (never the staged tree -- it is the
# freshness guardian that reads the staged tree), same pruned folder names,
# depth-1 .md per folder excluding index.md, sort by path, marking
# "REMPLACE par" from the supersedes field, writing of superseded-files.txt
# per root (deleted if it would be empty, Mission 127), same index
# front-matter, same Liens section with relative path and suffix "(hors Vault)".
#
# WHAT CHANGES (DECISION-2026-09-05-124647):
#   point 1 -- an index line is a LOCATOR, never a description:
#              "- `<identifiant>` · <statut> · <titre court> · `<nom>`".
#              The front-matter description is no longer carried over: it lives
#              in the file pointed to.
#   point 4 -- if a folder's index exceeds WEIGHT_CAP bytes, it is
#              split: index.md keeps the N most recent entries,
#              index-archive.md carries the rest. N is COMPUTED here at each
#              generation, never set by hand.
#
# CHOICES DELEGATED BY MISSION 140 AND OWNER CLARIFICATION OF 2026-09-05, fixed
# here once and for all and documented:
#   1. Short title: TITLE_MAX = 80 characters, truncated with an ellipsis.
#   2. Archives NUMBERED on a STABLE key, never recomputed: an entry
#      never changes archive file.
#        - folders whose names carry a Mission number (missions/,
#          reports/, prompt-archive/): fixed slices of ARCHIVE_SLICE
#          numbers, file index-archive-<start>-<end>.md;
#        - other dated folders: by closed period, granularity
#          ARCHIVE_PERIOD, file index-archive-<YYYY-MM>.md.
#      Only the last slice grows; the earlier ones are frozen.
#   3. Slice size COMPUTED on the real data (Mission 140,
#      2026-09-05), the densest slice having to fit under WEIGHT_CAP:
#        slice 10 -> 16 archives, densest 2 768 B
#        slice 20 ->  9 archives, densest 4 685 B (missions/)
#                     7 archives, densest 6 306 B (reports/)
#        slice 25 ->  7 archives, densest 5 681 B / 7 029 B
#        slice 50 ->  4 archives, densest 10 403 B  EXCEEDS
#      Chosen: 20, the safest margin (21 % at worst) for a reasonable
#      number of archives. Period: the month (worst case measured 5 811 B,
#      captures/ 2026-08); the quarter and the week exceed on reports/.
#   4. Interpretation of point 4 of the Decision, recorded: the archives
#      form an EXHAUSTIVE and STABLE partition of all entries;
#      the live index is a VIEW of the N most recent entries (N computed
#      at each generation to fit under the cap), a deliberate duplicate
#      of the last archive. "Open/closed" cannot be derived from the
#      front-matter -- a Mission's status is frozen at AUTHORIZED by
#      the template's doctrine, and the notion makes no sense for reports/ or
#      decisions/; "the most recent" stands in for it, sorting by name being
#      chronological.

import os
import re
import sys

# Mission 203: the certificate's `# exempt:` prefixes (same reader as the guardians).
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import project_baseline  # noqa: E402

WEIGHT_CAP = 8000  # DECISION-2026-09-05-124647 point 3
TITLE_MAX = 80  # delegated choice 1
ARCHIVE_SLICE = 20  # delegated choice 3: slice of numbers, computed
ARCHIVE_PERIOD = "mois"  # delegated choice 3: granularity of dated folders
ARCHIVE_PREFIX = "index-archive-"

# Bash block l.18: same pruned names, at any depth.
# `skills-warehouse` added (ticket 02, Mission 168, same reason and Owner
# arbitration as the fix already applied to tools/check_indexes_fresh.py,
# ticket 01 §16.3): this subtree does not follow the Vault's index convention
# (a single native index.md, skill-collections/index.md), never one per
# folder -- generating here would recreate there the ~155 phantom files
# deleted by hand during ticket 01, this time reproducibly.
# ".agents" added (ticket 06, Mission 168): same reason as ".claude" and
# ".codex" already present -- official location of Codex skills and
# sub-agents (T11), a folder machine-read by a third-party tool, never content
# of the documentary corpus indexed by this script.
# "_trash" added (Mission 175, step 7): the product's `_trash/` zone, content
# removed from distribution and frozen (Decision 110852) -- never browsed by
# the index-based search order (assistant/ASSISTANT.md), so never
# indexed, same reason as "state".
# "web-package" added (Mission 183-C01): package generated for a web Project,
# whose README announces every file to upload; an index.md generated
# here was one file too many there, announced nowhere (report 182).
PRUNE_NAMES = {
    ".git", ".githooks", ".claude", ".codex", ".agents", "graphify-out",
    "tools", "patterns", "node_modules", "state", ".venv", "venv",
    "__pycache__", "skills-warehouse", "_trash", "web-package",
}

ARCHIVE_RE = re.compile(r"^index-archive-.+\.md$")


def is_index_name(name):
    """Generated indexes never index themselves."""
    return name == "index.md" or bool(ARCHIVE_RE.match(name))


def read_text(path):
    # The worktree may carry CRLF (4 .md files of the vault, measured
    # Mission 142) where the staged tree gives LF: without this
    # normalisation, the front-matter opening line is "---\r", the
    # front-matter is not recognised, and the entry falls to "(sans titre)" /
    # "inconnu" -- a regression measured against the original awk, which read these
    # same files correctly.
    with open(path, "rb") as fh:
        raw = fh.read().decode("utf-8", errors="surrogateescape")
    return raw.replace("\r\n", "\n")


def write_text(path, text):
    with open(path, "wb") as fh:
        fh.write(text.encode("utf-8", errors="surrogateescape"))


# --- Bash block l.25-40: list_fields, same field grammar -------------------
FIELD_RE = {
    k: re.compile(r"^%s:[ \t\r\f\v]*(.*)$" % k)
    for k in ("title", "type", "status", "description")
}


def front_matter(text):
    """title/type/status/description, same quote handling as the original
    awk (removal of one leading and one trailing quote), no fallback
    value here -- defaults are applied by the caller."""
    out = {"title": "", "type": "", "status": "", "description": ""}
    lines = text.split("\n")
    infm = False
    for i, line in enumerate(lines):
        if i == 0:
            if line == "---":
                infm = True
            continue
        if infm and line == "---":
            infm = False
            continue
        if not infm:
            continue
        for key, rx in FIELD_RE.items():
            m = rx.match(line)
            if m:
                v = re.sub(r'^"|"$', "", m.group(1))
                out[key] = v
    return out


# --- Bash block l.46-68: extract_supersedes_raw ----------------------------
SUPERSEDES_RE = re.compile(r"^supersedes:[ \t\r\f\v]*(.*)$")
LIST_ITEM_RE = re.compile(r"^[ \t]+-[ \t]*(.*)$")
MD_NAME_RE = re.compile(r"([A-Za-z0-9._-]+\.md)")


def supersedes_values(text):
    """Values of the supersedes field: scalar or items of a YAML list."""
    vals = []
    lines = text.split("\n")
    infm = False
    insup = False
    for i, line in enumerate(lines):
        if i == 0:
            if line == "---":
                infm = True
            continue
        if infm and line == "---":
            infm = False
            insup = False
            continue
        if not infm:
            continue
        m = SUPERSEDES_RE.match(line)
        if m:
            insup = True
            if m.group(1) != "":
                vals.append(m.group(1))
            continue
        if insup:
            mi = LIST_ITEM_RE.match(line)
            if mi:
                vals.append(mi.group(1))
            else:
                insup = False
    return vals


# --- Bash block l.85 and l.127-135: worktree walk --------------------------
def walk_dirs(root_abs):
    """Folders under the root, pruning identical to the Bash find -prune.

    Mission 203 (report 202, A7): pruning is decided on the folder names BELOW
    the root, never on the absolute path of the root. The old test looked at
    every component of the absolute path, so a project living under a folder
    named `tools`, `state` or `skills-warehouse` was pruned whole -- zero
    folders indexed, the guardian's own hint a dead end. Names in PRUNE_NAMES
    are still pruned at any depth below the root; the certificate's
    `# exempt:` prefixes (paths of third parties that must stay
    byte-identical) are pruned too. A root without certificate: unchanged.
    """
    exempt = project_baseline.Exempt(root_abs)
    for dirpath, dirnames, _ in os.walk(root_abs):
        rel = os.path.relpath(dirpath, root_abs).replace("\\", "/")
        rel = "" if rel == "." else rel + "/"
        dirnames[:] = [
            d for d in dirnames
            if d not in PRUNE_NAMES and not exempt.covers_dir(rel + d)
        ]
        yield dirpath


def md_files_of(dirpath):
    """Depth-1 .md, excluding generated indexes, sorted by bytes like sort."""
    try:
        names = os.listdir(dirpath)
    except OSError:
        return []
    res = [
        n for n in names
        if n.endswith(".md")
        and not is_index_name(n)
        and os.path.isfile(os.path.join(dirpath, n))
    ]
    res.sort(key=lambda s: s.encode("utf-8", errors="surrogateescape"))
    return res


def short_title(title):
    """Short title, delegated choice 1. Truncation on the length in characters."""
    t = title if title else "(sans titre)"
    if len(t) > TITLE_MAX:
        t = t[: TITLE_MAX - 1].rstrip() + "…"
    return t


def identifier(name, fields):
    """Identifier of the entry (DECISION point 1: number, timestamp or name).
    Derived from the file name, never typed in: Mission or report number
    when the name carries one (140, 137-B), otherwise the timestamp, otherwise the name
    without extension."""
    # Variant of a lineage: short, typed suffix only (132-A, 137-B,
    # 002-C01, 128-bis). A slug word following the number is not one:
    # without this restriction, 133-vault-entry-chain would give "133-vault"
    # (measured Mission 140, 2026-09-05, on the 157 real entries).
    m = re.match(
        r"^(?:MISSION|REPORT|PROMPT)-\d{4}-\d{2}-\d{2}-\d{6}-"
        r"(\d+(?:-(?:[A-Z]{1,2}|C\d+|bis|ter))?)(?:-|$)",
        name,
    )
    if m:
        return m.group(1)
    m = re.match(r"^[A-Z-]+-(\d{4}-\d{2}-\d{2}-\d{6})-", name)
    if m:
        return m.group(1)
    m = re.match(r"^[A-Z-]+-(\d{4}-\d{2}-\d{2})-", name)
    if m:
        return m.group(1)
    return name[:-3] if name.endswith(".md") else name


def entry_line(name, fields, superseded_by):
    """Index line as a locator (DECISION point 1).
    Exact form: "- `<id>` · <statut> · <titre court> · `<nom>`", followed
    by " — REMPLACE par <nom>" when the file is superseded."""
    ident = identifier(name, fields)
    status = fields["status"] if fields["status"] else (
        fields["type"] if fields["type"] else "inconnu"
    )
    line = "- `%s` · %s · %s · `%s`" % (
        ident, status, short_title(fields["title"]), name
    )
    if name in superseded_by:
        line += " — REMPLACÉ par %s" % superseded_by[name]
    return line


# --- STABLE archive key (Owner clarification 2026-09-05) -------------------
NUM_RE = re.compile(r"^[A-Z-]+-\d{4}-\d{2}-\d{2}-\d{6}-(\d+)")
DATE_RE = re.compile(r"^[A-Z-]+-(\d{4})-(\d{2})-\d{2}-")


def archive_key(name):
    """Archive key of an entry: fixed by the file name, never
    recomputed from one generation to the next. Returns (sort_key, suffix) or None
    if the entry has no stable key (it then stays in the live index)."""
    m = NUM_RE.match(name)
    if m:
        n = int(m.group(1))
        start = (n // ARCHIVE_SLICE) * ARCHIVE_SLICE
        end = start + ARCHIVE_SLICE - 1
        return ((0, start), "%d-%d" % (start, end))
    m = DATE_RE.match(name)
    if m:
        y, mo = m.group(1), m.group(2)
        if ARCHIVE_PERIOD == "mois":
            return ((1, "%s-%s" % (y, mo)), "%s-%s" % (y, mo))
        q = (int(mo) - 1) // 3 + 1
        return ((1, "%s-T%d" % (y, q)), "%s-T%d" % (y, q))
    return None


# --- Bash block l.152-185: rendering an index ------------------------------
def render(title, entries, rel_std, hors_suffix, archive_note=""):
    parts = [
        "---",
        "type: index",
        'title: "Index — %s"' % title,
        'description: "Index généré automatiquement par tools/build-indexes.sh."',
        "status: active",
        "generated_by: tools/build-indexes.sh",
        "---",
        "",
        "# Index — %s" % title,
        "",
        "Index généré automatiquement. Ne pas éditer à la main : régénérer via "
        "`tools/build-indexes.sh`.",
        "",
    ]
    if archive_note:
        parts += [archive_note, ""]
    parts += ["## Contenu", ""]
    parts += entries
    parts += ["", "## Liens", ""]
    if rel_std:
        parts.append(
            "- `prescribed by` — [Standard de liens entre documents](%s)%s"
            % (rel_std, hors_suffix)
        )
    return "\n".join(parts) + "\n"


def main(argv):
    # Mission 172, audit defect 3: this used to write one stderr line per
    # regenerated index.md/archive unconditionally -- across the 3 calls a
    # nominal install makes (Save-ClonePendingChanges x2, project-bootstrap.sh
    # x1), that dumped the full list three times over, with no per-step
    # result line to make sense of it. Default is now one summary line per
    # invocation; -v/--verbose restores the full per-file detail this file
    # used to always print (kept byte-identical when passed, so a
    # troubleshooting session loses nothing).
    verbose = False
    only_missing = False
    roots = []
    for arg in argv:
        if arg in ("-v", "--verbose"):
            verbose = True
        elif arg == "--only-missing":
            only_missing = True
        else:
            roots.append(arg)
    argv = roots

    if not argv:
        sys.stderr.write("usage: build_indexes.py [-v|--verbose] <racine...>\n")
        return 1

    live_count = 0
    archive_count = 0

    def emit(message):
        if verbose:
            sys.stderr.write(message)

    script_dir = os.path.dirname(os.path.abspath(__file__))
    vault_root = os.path.abspath(os.path.join(script_dir, ".."))
    std_link_target = os.path.join(
        vault_root, "rules", "RULES-2026-08-21-115658-document-linking-standard.md"
    )

    for root in argv:
        if not os.path.isdir(root):
            continue
        root_abs = os.path.abspath(root)

        # Map of supersessions, scoped to this root (Bash block l.88-96).
        superseded_by = {}
        all_md = []
        for dirpath in walk_dirs(root_abs):
            for name in md_files_of(dirpath):
                all_md.append(os.path.join(dirpath, name))
        for path in all_md:
            try:
                text = read_text(path)
            except OSError:
                continue
            for raw in supersedes_values(text):
                m = MD_NAME_RE.search(raw)
                if m:
                    superseded_by[m.group(1)] = os.path.basename(path)

        # superseded-files.txt of the root (Bash block l.110-125).
        listed = sorted(
            (
                os.path.relpath(p, root_abs).replace("\\", "/")
                for p in all_md
                if os.path.basename(p) in superseded_by
            ),
            key=lambda s: s.encode("utf-8", errors="surrogateescape"),
        )
        sup_file = os.path.join(root_abs, "superseded-files.txt")
        if only_missing and os.path.exists(sup_file):
            pass
        elif listed:
            write_text(sup_file, "\n".join(listed) + "\n")
        elif os.path.exists(sup_file):
            os.remove(sup_file)

        for dirpath in walk_dirs(root_abs):
            names = md_files_of(dirpath)
            if not names:
                continue

            title = os.path.basename(dirpath)
            rel_std = os.path.relpath(std_link_target, dirpath).replace("\\", "/")
            if not rel_std.startswith(("../", "./")):
                rel_std = "./" + rel_std
            hors = ""
            if not (dirpath == vault_root or dirpath.startswith(vault_root + os.sep)):
                hors = " (hors Vault)"

            entries = []
            for name in names:
                try:
                    fields = front_matter(read_text(os.path.join(dirpath, name)))
                except OSError:
                    continue
                entries.append(entry_line(name, fields, superseded_by))

            index_path = os.path.join(dirpath, "index.md")

            # Existing archives of this folder, to remove those that are
            # no longer produced (no content deletion: the file
            # exists only if it carries entries).
            existing_archives = {
                n for n in os.listdir(dirpath) if ARCHIVE_RE.match(n)
            }
            if only_missing and (os.path.exists(index_path) or existing_archives):
                continue

            whole = render(title, entries, rel_std, hors)
            if len(whole.encode("utf-8", errors="surrogateescape")) <= WEIGHT_CAP:
                write_text(index_path, whole)
                for stale in existing_archives:
                    os.remove(os.path.join(dirpath, stale))
                live_count += 1
                emit(index_path + "\n")
                continue

            # --- Split (DECISION point 4, Owner clarification 2026-09-05) ---
            # Archives: EXHAUSTIVE and STABLE partition by frozen key.
            buckets = {}
            no_key = []
            for name, line in zip(names, entries):
                key = archive_key(name)
                if key is None:
                    no_key.append(line)
                else:
                    buckets.setdefault(key, []).append(line)

            produced = set()
            for (sort_key, suffix) in sorted(buckets, key=lambda k: k[0]):
                lines = buckets[(sort_key, suffix)]
                arch_name = "%s%s.md" % (ARCHIVE_PREFIX, suffix)
                arch_note = (
                    "Archive figée : les entrées de cette tranche n'en changent "
                    "jamais. L'index courant est [`index.md`](./index.md) "
                    "(DECISION-2026-09-05-124647, point 4)."
                )
                arch = render(
                    "%s — archive %s" % (title, suffix), lines, rel_std, hors, arch_note
                )
                arch_path = os.path.join(dirpath, arch_name)
                write_text(arch_path, arch)
                produced.add(arch_name)
                size = len(arch.encode("utf-8", errors="surrogateescape"))
                flag = "" if size <= WEIGHT_CAP else "  DEPASSE LE PLAFOND"
                archive_count += 1
                emit("%s (%d o)%s\n" % (arch_path, size, flag))

            for stale in existing_archives - produced:
                os.remove(os.path.join(dirpath, stale))

            # Live index: view of the N most recent entries, N computed.
            arch_list = ", ".join(
                "[`%s%s.md`](./%s%s.md)" % (ARCHIVE_PREFIX, s, ARCHIVE_PREFIX, s)
                for (_, s) in sorted(buckets, key=lambda k: k[0])
            )
            note = (
                "Index vivant : les entrées les plus récentes. La totalité est "
                "répartie en archives figées — %s." % arch_list
            )
            n = len(entries)
            while n > 0:
                cand = render(title, entries[len(entries) - n:], rel_std, hors, note)
                if len(cand.encode("utf-8", errors="surrogateescape")) <= WEIGHT_CAP:
                    break
                n -= 1
            live = render(title, entries[len(entries) - n:], rel_std, hors, note)
            write_text(index_path, live)
            live_count += 1
            emit("%s (vivant, N=%d)\n" % (index_path, n))

    # Mission 173 step 7 (Q17): silent by default, full stop -- even the
    # one-line summary Mission 172 kept is noise once the installer prints
    # its own named step-per-line journal; -v/--verbose still restores
    # every per-file line AND this summary, unchanged.
    if verbose:
        sys.stderr.write(
            "build_indexes.py: %d index(es) regenerated (%d archived) across %d root(s)\n"
            % (live_count, archive_count, len(argv))
        )

    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
