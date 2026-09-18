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


def _is_link(path):
    if os.path.islink(path):
        return True
    isjunction = getattr(os.path, "isjunction", None)
    return bool(isjunction and isjunction(path))


def list_files(root):
    res = []
    root = os.path.abspath(root)
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


def main(argv):
    if len(argv) >= 3 and argv[0] == "write":
        return cmd_write(argv[1], argv[2])
    if len(argv) >= 2 and argv[0] == "list":
        for rel in list_files(argv[1]):
            print(rel)
        return 0
    sys.stderr.write("usage: project_baseline.py write <racine> <sortie> | list <racine>\n")
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
