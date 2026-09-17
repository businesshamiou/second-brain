#!/usr/bin/env python3
# Ligne de base datee et cliquet (Decision 2026-09-17-000545, A4) -- jumeau
# Python de tools/project-baseline.sh, lu par les gardiens ecrits en Python
# (check_indexes_fresh.py, check_index_weight.py) et ecrit par
# tools/project-bootstrap.sh a l'adoption (sous-commande `write`).
#
# Format du fichier (une ligne par fichier existant a l'adoption) :
#   # second-brain-baseline: v1
#   # created_at: <horodatage>
#   <sha256><TAB><chemin relatif, separateur />
#
# usage :
#   project_baseline.py write <racine-projet> <fichier-sortie>
#   project_baseline.py list <racine-projet>
#
# Bibliotheque standard seulement.

import hashlib
import os
import sys
import time

CERT_HEADER = "# second-brain-birth-certificate: v1"
BASELINE_HEADER = "# second-brain-baseline: v1"
PRUNE_DIRS = {".git", "node_modules"}
PRUNE_PATHS = {".claude/skills", ".claude/agents", ".agents/skills"}


def sha256_file(path):
    # Empreinte du contenu sans retours chariot : une reecriture des fins de
    # ligne par Git (core.autocrlf) ne compte pas comme une modification.
    # Meme calcul que pb_sha256 dans tools/project-baseline.sh.
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk.replace(b"\r", b""))
    return h.hexdigest()


def read_certificate(root):
    """Cles de l'acte de naissance, {} s'il n'y en a pas."""
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
