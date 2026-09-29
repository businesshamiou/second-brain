#!/usr/bin/env python3
# Repository-root guard (Mission 226): the one place that decides whether a
# Vault tool may write under a target folder. Imported by the Python tools
# (build_indexes.py, propose_link_repairs.py) and run by the Bash tools
# (append-journal.sh, build-state.sh, build-digest.sh, set-release-version.sh,
# vault-identity.sh ensure, project-bootstrap.sh) before anything is written.
#
# Why: on 2026-09-21 (Mission 210) the index builder ran with "." from the
# workspace root -- a folder that holds several repositories without being one
# -- and rewrote about 2,400 index files in sibling folders, six of them
# without Git. On 2026-09-25 the same command was typed again from the same
# folder. The Owner asked for a mechanical guard in the tools.
#
# Default mode -- a target is ADMITTED when, walking up from it (from its
# nearest existing ancestor when it does not exist yet), a `.git` (folder, or
# file for a worktree) or a birth certificate (the header of a project's
# .pre-commit-config.yaml, whatever its `vcs:` key; it is how a project without
# Git is recognised) is found BEFORE any workspace root. In both modes a target
# that exists and is not a folder is refused. Otherwise it is REFUSED when:
#   - it is, or lies below nothing but, a workspace root: a folder that carries
#     VAULT-ROOT.md, or that holds two or more Git repositories without being
#     inside one -- the walk stops there, so a `.git` higher up (a dotfiles
#     repository in the profile) never admits the whole workspace;
#   - the walk reaches the filesystem root without finding either.
#
# The system temporary folder (Mission 231) is never a workspace root, however
# many repositories other work has left in it: a target below it whose walk
# reaches it without meeting a repository, a certificate or a workspace root
# is a throwaway folder, and is ADMITTED. The temporary folder itself is
# REFUSED, in both modes. A workspace root below it is judged as anywhere
# else. The system temporary folder is the one Python's tempfile names; it is
# not taken for one when it is the home folder, a filesystem root, or carries
# VAULT-ROOT.md (a TMPDIR pointing to a workspace stays a workspace root).
# Mission 234: the declared temporary folder (SB_TMP, tools/lib/tmp.sh) and each
# of its use sub-folders (tests, tools, m<NNN>...) are temporary folders in the
# same sense, and so is the platform's own (TEMP, TMP, LOCALAPPDATA\Temp):
# tests/run-suite.sh points TMPDIR at SB_TMP/tests, which then holds many
# throwaway repositories side by side without being a workspace root.
#
# --new-project mode (project-bootstrap.sh create/adopt, whose target is a
# project folder that is often in no repository yet): the target is refused
# only when it is itself a workspace root (VAULT-ROOT.md, or two or more
# repositories inside it); the bootstrap's own checks do the rest.
#
# There is no switch that turns the guard off, and no environment variable.
#
# usage: repo_root_guard.py [--new-project] <path>
# Exit 0: admitted, nothing printed. Exit 2: refused, one line on stderr
# starting with REPO-ROOT-REFUSED, naming the path received and the root
# expected (in --new-project mode, an example of the project folder expected).
# Exit 1: usage error.

import os
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import project_baseline  # noqa: E402  (sibling module: read_certificate)

MARKER = "VAULT-ROOT.md"


def _child_repositories(d):
    """Number of direct child folders of d that are Git repositories."""
    try:
        names = os.listdir(d)
    except OSError:
        return 0
    n = 0
    for name in names:
        child = os.path.join(d, name)
        if os.path.isdir(child) and os.path.exists(os.path.join(child, ".git")):
            n += 1
    return n


def workspace_reason(d):
    """Why d is a workspace root, in words; '' when it is not one."""
    if os.path.exists(os.path.join(d, ".git")):
        return ""
    if os.path.isfile(os.path.join(d, MARKER)):
        return "it carries %s" % MARKER
    n = _child_repositories(d)
    if n >= 2:
        return "it holds %d Git repositories without being one" % n
    return ""


def is_workspace_root(d):
    """A folder that carries the workspace marker, or holds two or more Git
    repositories without being one itself."""
    if os.path.exists(os.path.join(d, ".git")):
        return False
    return os.path.isfile(os.path.join(d, MARKER)) or _child_repositories(d) >= 2


def _same(a, b):
    return os.path.normcase(os.path.realpath(a)) == os.path.normcase(os.path.realpath(b))


def _usable_temp(d):
    """d when it is a usable temporary folder: an existing folder that is not
    the home folder, a filesystem root, nor carries the marker."""
    if not d:
        return None
    d = os.path.abspath(d)
    if not os.path.isdir(d) or os.path.dirname(d) == d:
        return None
    if _same(d, os.path.expanduser("~")) or os.path.isfile(os.path.join(d, MARKER)):
        return None
    return d


def system_temp():
    """The system temporary folder, or None when there is no usable one, or
    when it is the home folder, a filesystem root, or carries the marker."""
    try:
        return _usable_temp(tempfile.gettempdir())
    except (OSError, IOError):
        return None


def temp_folders():
    """Every temporary folder (Mission 234): the one Python names, the
    platform's own, the declared SB_TMP and each of its direct sub-folders."""
    found = []
    candidates = [system_temp(), os.environ.get("TEMP"), os.environ.get("TMP")]
    local = os.environ.get("LOCALAPPDATA")
    if local:
        candidates.append(os.path.join(local, "Temp"))
    sb = _usable_temp(os.environ.get("SB_TMP"))
    if sb:
        candidates.append(sb)
        try:
            names = os.listdir(sb)
        except OSError:
            names = []
        for name in names:
            candidates.append(os.path.join(sb, name))
    for c in candidates:
        c = _usable_temp(c)
        if c and not any(_same(c, f) for f in found):
            found.append(c)
    return found


def _nearest_existing(path):
    d = path
    while not os.path.exists(d):
        parent = os.path.dirname(d)
        if parent == d:
            return d
        d = parent
    return d


def check(target, new_project=False):
    """None when the target is admitted; otherwise the refusal message."""
    received = target
    path = os.path.abspath(target)
    expected = ("the root of a Git repository, or a folder inside one, or a project "
                "with a birth certificate, below the workspace root")
    if os.path.exists(path) and not os.path.isdir(path):
        return "REPO-ROOT-REFUSED: %s (%s) is not a folder; expected %s. Nothing written." % (received, path, expected)

    temps = temp_folders()
    if any(_same(path, t) for t in temps):
        return ("REPO-ROOT-REFUSED: %s (%s) is the system temporary folder, not a repository; a throwaway "
                "folder below it is admitted, e.g. %s. Nothing written."
                % (received, path, os.path.join(path, "<throwaway>")))

    if new_project:
        if os.path.isdir(path) and is_workspace_root(path):
            return ("REPO-ROOT-REFUSED: %s (%s) is a workspace root (%s); a project is created in its own "
                    "folder below it, e.g. %s. Nothing written."
                    % (received, path, workspace_reason(path), os.path.join(path, "<project>")))
        return None

    d = _nearest_existing(path)
    while True:
        if os.path.exists(os.path.join(d, ".git")):
            return None
        if project_baseline.read_certificate(d):
            return None
        if any(_same(d, t) for t in temps):
            return None
        if is_workspace_root(d):
            return ("REPO-ROOT-REFUSED: %s (%s) is not inside a repository: %s is a workspace root "
                    "(%s). Expected %s, for example %s. Nothing written."
                    % (received, path, d, workspace_reason(d), expected, os.path.join(d, "<repository>")))
        parent = os.path.dirname(d)
        if parent == d:
            return ("REPO-ROOT-REFUSED: %s (%s) is in no Git repository and carries no birth certificate; "
                    "expected %s. Nothing written." % (received, path, expected))
        d = parent


def main(argv):
    new_project = False
    args = []
    for a in argv:
        if a == "--new-project":
            new_project = True
        else:
            args.append(a)
    if len(args) != 1:
        sys.stderr.write("usage: repo_root_guard.py [--new-project] <path>\n")
        return 1
    message = check(args[0], new_project=new_project)
    if message:
        sys.stderr.write(message + "\n")
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
