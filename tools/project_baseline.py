#!/usr/bin/env python3
# Dated baseline and ratchet (Decision 2026-09-17-000545, A4) -- Python
# twin of tools/project-baseline.sh, read by the guardians written in Python
# (check_indexes_fresh.py, check_index_weight.py) and written by
# tools/project-bootstrap.sh at adoption (subcommand `write`).
#
# File format (one line per file existing at adoption):
#   # second-brain-baseline: v1
#   # created_at: <timestamp>
#   <sha256><TAB><relative path, separator />
#
# usage:
#   project_baseline.py write <project-root> <output-file>
#   project_baseline.py list <project-root>
#   project_baseline.py filter <project-root>   (stdin: paths; stdout: B|U|T|N<TAB>path)
#   project_baseline.py text <project-root>     (stdin: paths; stdout: +lines of text files)
#       (Mission 218, lot 6: one pass for the shell guardians, no process per file)
#   project_baseline.py amend <project-root> --paths <file> --by <who> --reason <why> [--ref <ref>]
#       (Mission 218: targeted, proved amendment; each path already in the
#       baseline, working-tree content equal to <ref>'s, one header line;
#       all or nothing -- the only way to change a baseline, never by hand)
#   project_baseline.py retire <project-root> --prefix <p> [--prefix <p>...] --by <who> --reason <why>
#       (Mission 219: entries removed, all or nothing; each prefix covers at
#       least one entry, none of them tracked by Git; one header line)
#
# Listing (Mission 219): at the top of a Git work tree, the files are those Git
# tracks plus the untracked ones it does not ignore; elsewhere, the folder walk.
#
# Standard library only.

import hashlib
import os
import sys
import time

CERT_HEADER = "# second-brain-birth-certificate: v1"
BASELINE_HEADER = "# second-brain-baseline: v1"
PRUNE_DIRS = {".git", "node_modules"}
PRUNE_PATHS = {".claude/skills", ".claude/agents", ".agents/skills"}


def sha256_file(path):
    # Fingerprint of the content without carriage returns: a rewrite of line
    # endings by Git (core.autocrlf) does not count as a modification.
    # Same computation as pb_sha256 in tools/project-baseline.sh.
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk.replace(b"\r", b""))
    return h.hexdigest()


def read_certificate(root):
    """Keys of the birth certificate, {} if there is none."""
    path = os.path.join(root, ".pre-commit-config.yaml")
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as f:
            lines = [l.rstrip("\r\n") for l in f]
    except OSError:
        return {}
    if CERT_HEADER not in lines:
        return {}
    cert = {}
    for line in lines:
        if not line.startswith("#"):
            break
        if line.startswith("# ") and ": " in line:
            key, value = line[2:].split(": ", 1)
            cert.setdefault(key, value)
    return cert


def parse_exempt(value):
    """Path prefixes of the certificate's `# exempt:` key (Mission 203).

    Grammar: prefixes relative to the project root, separated by spaces, each
    ending with `/`. Returns (valid prefixes, rejected tokens). A rejected token
    exempts nothing: an absolute path, a `..`, a backslash, a drive letter or a
    token without the final `/` is ignored -- the exemption only ever shrinks.
    Twin of bc_exempt in tools/resolve-vault.sh (same grammar, one source of
    truth in the tests).
    """
    valid, rejected = [], []
    for tok in (value or "").split():
        bad = (
            tok.startswith("/") or ".." in tok or "\\" in tok or ":" in tok
            or not tok.endswith("/") or tok == "/"
        )
        (rejected if bad else valid).append(tok)
    return valid, rejected


EXEMPT_FILE = ".vault-exempt"


def parse_exempt_file(root):
    """Prefixes of the project's versioned `.vault-exempt` (Mission 218).

    One prefix per line, so that a folder name may hold spaces -- the
    certificate's key separates its prefixes by spaces and cannot name
    "Adn Dev/". Same grammar otherwise (relative, ending with `/`, no `..`, no
    backslash, no colon); `#` starts a comment line. Read only when the root
    carries a birth certificate, like the key. Returns (valid, rejected)."""
    valid, rejected = [], []
    if not read_certificate(root):
        return valid, rejected
    try:
        with open(os.path.join(root, EXEMPT_FILE), "r", encoding="utf-8", errors="replace") as f:
            lines = [l.rstrip("\r\n") for l in f]
    except OSError:
        return valid, rejected
    for tok in lines:
        if not tok.strip() or tok.lstrip().startswith("#"):
            continue
        bad = (
            tok.startswith("/") or ".." in tok or "\\" in tok or ":" in tok
            or not tok.endswith("/") or tok == "/" or tok != tok.strip()
        )
        (rejected if bad else valid).append(tok)
    return valid, rejected


class Exempt:
    """Paths the three index/link guardians do not judge (never the secrets).

    Read from the birth certificate of `root` (key `# exempt:`) and, since
    Mission 218, from the project's versioned `.vault-exempt` (one prefix per
    line); no certificate: nothing exempt, behaviour unchanged.
    """

    def __init__(self, root):
        self.prefixes, self.rejected = parse_exempt(read_certificate(root).get("exempt", ""))
        more, bad = parse_exempt_file(root)
        self.prefixes += more
        self.rejected += bad
        for tok in self.rejected:
            sys.stderr.write("EXEMPT : entree ignoree (forme invalide) : %s\n" % tok)

    def covers_file(self, rel):
        return any(rel.startswith(p) for p in self.prefixes)

    def covers_dir(self, rel):
        return rel != "." and any((rel + "/").startswith(p) for p in self.prefixes)


def _is_link(path):
    if os.path.islink(path):
        return True
    isjunction = getattr(os.path, "isjunction", None)
    return bool(isjunction and isjunction(path))


def _git_listing(root):
    """Mission 219, lot E: when <root> is the top of a Git work tree, the files
    Git tracks plus the untracked ones it does not ignore
    (`git ls-files -co --exclude-standard`), else None. A file that Git ignores
    and does not track (a `.env`, a `.venv/`) is then neither engraved in a
    baseline nor judged by a guardian in folder mode; a tracked file always is,
    ignored or not. Without Git, the walk below is unchanged."""
    import subprocess
    try:
        top = subprocess.run(["git", "-C", root, "rev-parse", "--show-toplevel"],
                             stdout=subprocess.PIPE, stderr=subprocess.DEVNULL).stdout
    except OSError:
        return None
    top = top.decode("utf-8", errors="surrogateescape").strip()
    if not top or os.path.normcase(os.path.realpath(top)) != os.path.normcase(os.path.realpath(root)):
        return None
    raw = subprocess.run(["git", "-C", root, "-c", "core.quotepath=off", "ls-files", "-co", "--exclude-standard", "-z"],
                         stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
    if raw.returncode != 0:
        return None
    return [p for p in raw.stdout.decode("utf-8", errors="surrogateescape").split("\0") if p]


def _git_listed_files(root, listed):
    """The Git listing, filtered like the walk: same pruned folders, no link,
    no path through a linked folder, only files that exist."""
    res, link_dirs = [], {}

    def through_link(rel_dir):
        if not rel_dir:
            return False
        if rel_dir not in link_dirs:
            parent = rel_dir.rsplit("/", 1)[0] if "/" in rel_dir else ""
            link_dirs[rel_dir] = through_link(parent) or _is_link(os.path.join(root, rel_dir))
        return link_dirs[rel_dir]

    for rel in listed:
        parts = rel.split("/")
        if any(p in PRUNE_DIRS for p in parts[:-1]):
            continue
        if any(rel.startswith(pp + "/") for pp in PRUNE_PATHS):
            continue
        rel_dir = "/".join(parts[:-1])
        full = os.path.join(root, rel)
        if through_link(rel_dir) or _is_link(full) or not os.path.isfile(full):
            continue
        res.append(rel)
    res.sort(key=lambda s: s.encode("utf-8", errors="surrogateescape"))
    return res


def list_files(root):
    res = []
    root = os.path.abspath(root)
    listed = _git_listing(root)
    if listed is not None:
        return _git_listed_files(root, listed)
    for dirpath, dirnames, filenames in os.walk(root, followlinks=False):
        rel_dir = os.path.relpath(dirpath, root).replace(os.sep, "/")
        rel_dir = "" if rel_dir == "." else rel_dir + "/"
        keep = []
        for d in dirnames:
            rel = rel_dir + d
            if d in PRUNE_DIRS or rel in PRUNE_PATHS or _is_link(os.path.join(dirpath, d)):
                continue
            keep.append(d)
        dirnames[:] = keep
        for fn in filenames:
            full = os.path.join(dirpath, fn)
            if _is_link(full):
                continue
            res.append(rel_dir + fn)
    res.sort(key=lambda s: s.encode("utf-8", errors="surrogateescape"))
    return res


class Baseline:
    def __init__(self, root):
        self.root = root
        self.name = ""
        self.entries = {}
        cert = read_certificate(root)
        self.name = cert.get("baseline", "")
        if not self.name:
            return
        path = os.path.join(root, self.name)
        try:
            with open(path, "r", encoding="utf-8", errors="surrogateescape") as f:
                for line in f:
                    line = line.rstrip("\r\n")
                    if not line or line.startswith("#") or "\t" not in line:
                        continue
                    digest, rel = line.split("\t", 1)
                    self.entries.setdefault(rel, digest)
        except OSError:
            self.entries = {}

    @property
    def active(self):
        return bool(self.entries)

    def is_baseline_file(self, rel):
        return bool(self.name) and rel == self.name

    def untouched(self, rel):
        want = self.entries.get(rel)
        if not want:
            return False
        full = os.path.join(self.root, rel)
        if not os.path.isfile(full):
            return False
        try:
            return sha256_file(full) == want
        except OSError:
            return False


def cmd_write(root, out):
    files = [p for p in list_files(root)]
    stamp = time.strftime("%Y-%m-%dT%H:%M:%S%z")
    lines = [BASELINE_HEADER, "# created_at: " + stamp]
    for rel in files:
        full = os.path.join(root, rel)
        if os.path.abspath(full) == os.path.abspath(out):
            continue
        lines.append(sha256_file(full) + "\t" + rel)
    with open(out, "w", encoding="utf-8", newline="\n", errors="surrogateescape") as f:
        f.write("\n".join(lines) + "\n")
    print(len(lines) - 2)
    return 0


PROGRESS_EVERY = 2000  # Mission 218: a progress line on stderr every N paths


def _stdin_paths():
    """Relative paths, one per line, on standard input (bytes, UTF-8)."""
    raw = sys.stdin.buffer.read().decode("utf-8", errors="surrogateescape")
    return [p for p in raw.replace("\r\n", "\n").split("\n") if p]


def _out(data):
    sys.stdout.buffer.write(data)


def cmd_filter(root):
    """Mission 218, lot 6: the baseline read ONCE for a whole list of paths.

    stdin: relative paths. stdout, in the same order, one line per path:
      B<TAB>path  the baseline file itself (names and fingerprints, never content)
      U<TAB>path  engraved and untouched: never judged
      T<TAB>path  engraved then touched: judged in full (the ratchet)
      N<TAB>path  not in the baseline: judged as usual
    Same verdict as pb_untouched/pb_touched of project-baseline.sh, path by path
    (same file, first entry per path, fingerprint without carriage returns),
    with no process per file: the shell guardians used to re-read the whole
    baseline with awk for each file, two or three times."""
    b = Baseline(root)
    paths = _stdin_paths()
    n = len(paths)
    chunks = []
    for i, p in enumerate(paths, 1):
        if b.name and p == b.name:
            tag = "B"
        elif p in b.entries:
            tag = "U" if b.untouched(p) else "T"
        else:
            tag = "N"
        chunks.append(tag + "\t" + p + "\n")
        if n >= PROGRESS_EVERY and i % PROGRESS_EVERY == 0:
            sys.stderr.write("progress: baseline %d/%d\n" % (i, n))
    _out("".join(chunks).encode("utf-8", errors="surrogateescape"))
    return 0


def cmd_text(root):
    """Mission 218, lot 6: the full content of text files, each line prefixed
    with `+`, in one process -- byte for byte what check-secrets.sh produced
    with `head | tr | cmp` then `sed 's/^/+/'` per file: a file whose first 8000
    bytes hold a NUL byte is binary and skipped; an empty file gives nothing; a
    last line without newline stays without newline (GNU sed)."""
    paths = _stdin_paths()
    n = len(paths)
    for i, p in enumerate(paths, 1):
        full = os.path.join(root, p)
        if os.path.isfile(full):
            try:
                with open(full, "rb") as f:
                    data = f.read()
            except OSError:
                data = b""
            if data and b"\x00" not in data[:8000]:
                ends = data.endswith(b"\n")
                lines = data.split(b"\n")
                if ends:
                    lines = lines[:-1]
                _out(b"\n".join(b"+" + l for l in lines) + (b"\n" if ends else b""))
        if n >= PROGRESS_EVERY and i % PROGRESS_EVERY == 0:
            sys.stderr.write("progress: content %d/%d\n" % (i, n))
    return 0


def _git_blobs(root, ref, paths):
    """Contents of <ref>:<path> for each path, in one `git cat-file --batch`."""
    import subprocess
    payload = "".join("%s:%s\n" % (ref, p) for p in paths).encode("utf-8", errors="surrogateescape")
    raw = subprocess.run(
        ["git", "-C", root, "cat-file", "--batch"], input=payload,
        stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
    ).stdout
    res, pos = {}, 0
    for p in paths:
        nl = raw.find(b"\n", pos)
        if nl == -1:
            res[p] = None
            continue
        header = raw[pos:nl]
        pos = nl + 1
        if header.endswith(b" missing") or len(header.split(b" ")) < 3:
            res[p] = None
            continue
        size = int(header.split(b" ")[2])
        res[p] = raw[pos:pos + size]
        pos += size + 1
    return res


def cmd_amend(root, ref, paths_file, by, reason):
    """Mission 218, lot 5: a targeted, proved amendment -- never an edit by hand.

    Each listed path must already be in the baseline (an amendment never widens
    it), and its working-tree content must equal its content at <ref> (same
    fingerprint, carriage returns removed): its entry then takes that
    fingerprint. One path that fails and nothing is written. The header
    receives one line: who, when, which reference (full SHA), how many paths,
    why. Writing goes through a temporary file replaced at once."""
    import subprocess
    root = os.path.abspath(root)
    name = read_certificate(root).get("baseline", "")
    if not name:
        sys.stderr.write("BASELINE-AMEND-REFUSED : no baseline named by the birth certificate of %s\n" % root)
        return 1
    base_path = os.path.join(root, name)
    try:
        with open(base_path, "r", encoding="utf-8", errors="surrogateescape", newline="") as f:
            lines = f.read().replace("\r\n", "\n").split("\n")
    except OSError:
        sys.stderr.write("BASELINE-AMEND-REFUSED : baseline unreadable: %s\n" % base_path)
        return 1
    if lines and lines[-1] == "":
        lines = lines[:-1]
    sha = subprocess.run(["git", "-C", root, "rev-parse", "--verify", ref + "^{commit}"],
                         stdout=subprocess.PIPE, stderr=subprocess.DEVNULL).stdout.decode().strip()
    if not sha:
        sys.stderr.write("BASELINE-AMEND-REFUSED : reference not found in the project's repository: %s\n" % ref)
        return 1
    with open(paths_file, "r", encoding="utf-8", errors="surrogateescape") as f:
        paths = [l.rstrip("\r\n") for l in f if l.strip()]
    if not paths:
        sys.stderr.write("BASELINE-AMEND-REFUSED : no path given\n")
        return 1
    index = {}
    for i, line in enumerate(lines):
        if line and not line.startswith("#") and "\t" in line:
            index.setdefault(line.split("\t", 1)[1], i)
    blobs = _git_blobs(root, sha, paths)
    errors, new = [], {}
    for p in paths:
        if p not in index:
            errors.append("%s : not in the baseline (an amendment never widens it)" % p)
            continue
        blob = blobs.get(p)
        if blob is None:
            errors.append("%s : absent from %s" % (p, sha[:12]))
            continue
        want = hashlib.sha256(blob.replace(b"\r", b"")).hexdigest()
        full = os.path.join(root, p)
        if not os.path.isfile(full):
            errors.append("%s : absent from the working tree" % p)
            continue
        if sha256_file(full) != want:
            errors.append("%s : working-tree content differs from %s" % (p, sha[:12]))
            continue
        new[p] = want
    if errors:
        for e in errors:
            sys.stderr.write("BASELINE-AMEND-REFUSED : %s\n" % e)
        sys.stderr.write("BASELINE-AMEND-REFUSED : %d refusal(s), nothing written\n" % len(errors))
        return 1
    changed = 0
    for p, digest in new.items():
        i = index[p]
        old = lines[i].split("\t", 1)[0]
        if old != digest:
            changed += 1
        lines[i] = digest + "\t" + p
    stamp = time.strftime("%Y-%m-%dT%H:%M:%S%z")
    header_end = 0
    while header_end < len(lines) and lines[header_end].startswith("#"):
        header_end += 1
    note = "# amended_at: %s by: %s ref: %s paths: %d reason: %s" % (
        stamp, by.replace("\n", " "), sha, len(new), reason.replace("\n", " "))
    lines.insert(header_end, note)
    tmp = base_path + ".amend-tmp"
    with open(tmp, "w", encoding="utf-8", newline="\n", errors="surrogateescape") as f:
        f.write("\n".join(lines) + "\n")
    os.replace(tmp, base_path)
    print("BASELINE-AMENDED : %d path(s) at %s (%d fingerprint(s) changed) in %s" % (len(new), sha, changed, name))
    return 0


def cmd_retire(root, prefixes, by, reason):
    """Mission 219, lot E: entries removed from a baseline, all or nothing --
    never by hand. A prefix ending in `/` covers every entry under it; any
    other prefix names one entry exactly. Every prefix must cover at least one
    entry, and no covered path may be tracked by Git (retire is for what Git
    does not version: a secret file, a virtual environment); one refusal and
    nothing is written. The header receives one line: who, when, which
    prefixes, how many entries, why. Retiring only ever widens what the
    guardians judge: a retired file that still exists is judged as new."""
    import subprocess
    root = os.path.abspath(root)
    name = read_certificate(root).get("baseline", "")
    if not name:
        sys.stderr.write("BASELINE-RETIRE-REFUSED : no baseline named by the birth certificate of %s\n" % root)
        return 1
    base_path = os.path.join(root, name)
    try:
        with open(base_path, "r", encoding="utf-8", errors="surrogateescape", newline="") as f:
            lines = f.read().replace("\r\n", "\n").split("\n")
    except OSError:
        sys.stderr.write("BASELINE-RETIRE-REFUSED : baseline unreadable: %s\n" % base_path)
        return 1
    if lines and lines[-1] == "":
        lines = lines[:-1]

    def covers(prefix, rel):
        return rel.startswith(prefix) if prefix.endswith("/") else rel == prefix

    entries = [(i, l.split("\t", 1)[1]) for i, l in enumerate(lines)
               if l and not l.startswith("#") and "\t" in l]
    errors, drop = [], set()
    for pf in prefixes:
        hit = [(i, rel) for i, rel in entries if covers(pf, rel)]
        if not hit:
            errors.append("%s : covers no entry of the baseline" % pf)
        drop.update(i for i, _ in hit)
    covered = sorted({lines[i].split("\t", 1)[1] for i in drop})
    in_git = subprocess.run(["git", "-C", root, "rev-parse", "--is-inside-work-tree"],
                            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL).returncode == 0
    for k in range(0, len(covered) if in_git else 0, 200):
        run = subprocess.run(["git", "--literal-pathspecs", "-C", root, "-c", "core.quotepath=off",
                              "ls-files", "-z", "--"] + covered[k:k + 200],
                             stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
        if run.returncode != 0:
            errors.append("git ls-files failed: tracked files not measurable")
            break
        for rel in sorted(p for p in run.stdout.decode("utf-8", errors="surrogateescape").split("\0") if p):
            errors.append("%s : tracked by Git (retire is for what Git does not version)" % rel)
    if errors:
        for e in errors:
            sys.stderr.write("BASELINE-RETIRE-REFUSED : %s\n" % e)
        sys.stderr.write("BASELINE-RETIRE-REFUSED : %d refusal(s), nothing written\n" % len(errors))
        return 1
    kept = [l for i, l in enumerate(lines) if i not in drop]
    stamp = time.strftime("%Y-%m-%dT%H:%M:%S%z")
    header_end = 0
    while header_end < len(kept) and kept[header_end].startswith("#"):
        header_end += 1
    note = "# retired_at: %s by: %s prefixes: %s entries: %d reason: %s" % (
        stamp, by.replace("\n", " "), "|".join(prefixes), len(drop), reason.replace("\n", " "))
    kept.insert(header_end, note)
    tmp = base_path + ".retire-tmp"
    with open(tmp, "w", encoding="utf-8", newline="\n", errors="surrogateescape") as f:
        f.write("\n".join(kept) + "\n")
    os.replace(tmp, base_path)
    _out(("BASELINE-RETIRED : %d entr%s under %s in %s\n" % (
        len(drop), "y" if len(drop) == 1 else "ies", "|".join(prefixes), name)).encode("utf-8", errors="surrogateescape"))
    return 0


def main(argv):
    if len(argv) >= 2 and argv[0] == "retire":
        prefixes, by, reason, rest = [], "", "", argv[2:]
        while rest:
            if rest[0] in ("--prefix", "--by", "--reason") and len(rest) >= 2:
                if rest[0] == "--prefix":
                    prefixes.append(rest[1])
                elif rest[0] == "--by":
                    by = rest[1]
                else:
                    reason = rest[1]
                rest = rest[2:]
            else:
                sys.stderr.write("usage: project_baseline.py retire <root> --prefix <p> [--prefix <p>...] --by <who> --reason <why>\n")
                return 2
        if not prefixes or not by or not reason:
            sys.stderr.write("BASELINE-RETIRE-REFUSED : --prefix, --by and --reason are required (what, who, why)\n")
            return 2
        return cmd_retire(argv[1], prefixes, by, reason)
    if len(argv) >= 3 and argv[0] == "write":
        return cmd_write(argv[1], argv[2])
    if len(argv) >= 2 and argv[0] == "amend":
        opts = {"--ref": "HEAD", "--paths": "", "--by": "", "--reason": ""}
        rest = argv[2:]
        while rest:
            if rest[0] in opts and len(rest) >= 2:
                opts[rest[0]] = rest[1]
                rest = rest[2:]
            else:
                sys.stderr.write("usage: project_baseline.py amend <root> --paths <file> --by <who> --reason <why> [--ref <ref>]\n")
                return 2
        if not opts["--paths"] or not opts["--by"] or not opts["--reason"]:
            sys.stderr.write("BASELINE-AMEND-REFUSED : --paths, --by and --reason are required (who, what, why)\n")
            return 2
        return cmd_amend(argv[1], opts["--ref"], opts["--paths"], opts["--by"], opts["--reason"])
    if len(argv) == 2 and argv[0] == "filter":
        return cmd_filter(argv[1])
    if len(argv) == 2 and argv[0] == "text":
        return cmd_text(argv[1])
    if len(argv) >= 2 and argv[0] == "list":
        # UTF-8 bytes, never the console code page (accented paths on Windows).
        _out("".join(rel + "\n" for rel in list_files(argv[1])).encode("utf-8", errors="surrogateescape"))
        return 0
    sys.stderr.write("usage: project_baseline.py write <racine> <sortie> | list <racine>\n")
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
