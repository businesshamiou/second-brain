#!/usr/bin/env python3
# MCP server of the Vault (Decision 2026-09-17-000545, A6): gives the Pilot
# bounded disk access, versioned with the Vault, with no dependency outside the
# Python standard library (launched by `uv run --no-project`).
#
# stdio transport, JSON-RPC 2.0, one message per line. Standard output is
# reserved for JSON-RPC messages; any log goes to standard error.
#
# usage:
#   uv run --no-project tools/vault-mcp.py --allow <folder> [--allow <folder>...] [--vault <root>]
#
# Bounds:
#   - every path is resolved (realpath) before comparison; it must lie
#     under an allowed folder, itself resolved;
#   - a symbolic link or a junction that leaves the perimeter is therefore refused;
#   - a `tools/call` refusal is a RESULT carrying `isError: true`
#     whose text names the requested path AND the allowed folders,
#     never an exception nor a server stop; only protocol
#     defects (unknown method or tool, unreadable JSON) remain
#     JSON-RPC errors.
#   - `list_allowed_directories` also returns the Vault commit: the Pilot
#     compares it with the one in its project prompt (pinning by commit).

import argparse
import datetime
import difflib
import fnmatch
import json
import os
import re
import subprocess
import sys

# Fixed name: the fallback for a Vault with no generated identity (the distributed
# repository carries a skeleton, `status: template`, with empty values).
SERVER_NAME = "second-brain-vault"
DEFAULT_PROTOCOL = "2025-06-18"
ACCESS_DENIED = -32001
INVALID_PARAMS = -32602
METHOD_NOT_FOUND = -32601
INTERNAL_ERROR = -32603


def log(message):
    sys.stderr.write("[vault-mcp] " + message + "\n")
    sys.stderr.flush()


class ToolError(Exception):
    def __init__(self, code, message):
        Exception.__init__(self, message)
        self.code = code
        self.message = message


def norm(path):
    return os.path.normcase(os.path.realpath(path))


# Accents folded to their letter by `normalize_label`: the same table as
# `vid_label_normalize` in tools/vault-identity.sh (Latin-1 letters, ae, oe, ss).
_LABEL_FOLD = {}
for _letters, _plain in (("àáâãäå", "a"), ("æ", "ae"), ("ç", "c"), ("èéêë", "e"), ("ìíîï", "i"), ("ñ", "n"),
                         ("òóôõö", "o"), ("œ", "oe"), ("ùúûü", "u"), ("ýÿ", "y"), ("ß", "ss")):
    for _letter in _letters:
        _LABEL_FOLD[_letter] = _plain


def normalize_label(text):
    """The workspace label in kebab case, the twin of `vid_label_normalize` (shell).

    Lower-cased, accents folded (Latin-1 letters, ae, oe, ss), every run of characters
    that is not a-z or 0-9 becomes ONE hyphen, no hyphen at either end: `Workspaces` ->
    `workspaces`, `Mon Espace (2)` -> `mon-espace-2`, `ÉTÉ` -> `ete`. Both implementations
    are played on the same cases (tests/test-install-vault-mcp-workspace-label.sh).
    """
    folded = "".join(_LABEL_FOLD.get(c, c) for c in text.lower())
    return re.sub("[^a-z0-9]+", "-", folded).strip("-")


def server_name(vault_root):
    """Name this server announces: derived from THIS Vault's identity file.

    Same rule as `vid_server_name` in tools/vault-identity.sh (Decision 162812 A,
    Mission 206, which amends 152251 C): `second-brain-vault-<workspace_label>` when the
    front matter of VAULT-IDENTITY.md, at the root of the Vault, carries a label (posed
    by the installer from the workspace folder, normalised here as there); otherwise
    `second-brain-vault-` followed by the first 8 characters of `vault_id`, after its
    `sb-` prefix (Mission 205; the identity is what the system checks, the label is what
    the Owner reads). The desktop application keeps ONE server per announced name: two
    Vaults announcing the same fixed name were one server (Mission 205). CRLF line
    endings are tolerated (Windows clone with autocrlf), like `vid_get`. A missing file,
    no front matter or an empty `vault_id` (the skeleton of the distributed repository):
    the fixed name, silently -- standard output is reserved for JSON-RPC.
    """
    try:
        with open(os.path.join(vault_root, "VAULT-IDENTITY.md"), "r", encoding="utf-8", errors="replace", newline="") as f:
            text = f.read()
    except OSError:
        return SERVER_NAME
    lines = text.replace(chr(13), "").split(chr(10))
    if lines[0] != "---":
        return SERVER_NAME
    found = {}
    for line in lines[1:]:
        if line == "---":
            break
        i = line.find(":")
        key = line[:i] if i > 0 else ""
        if key in ("vault_id", "workspace_label") and key not in found:
            value = line[i + 1:].strip()
            if len(value) >= 2 and value[0] == '"' and value[-1] == '"':
                value = value[1:-1]
            found[key] = value
    vault_id = found.get("vault_id", "")
    short = (vault_id[3:] if vault_id.startswith("sb-") else vault_id)[:8]
    if not short:
        return SERVER_NAME
    label = normalize_label(found.get("workspace_label", ""))
    return "%s-%s" % (SERVER_NAME, label or short)


def vault_commit(vault_root):
    git_dir = os.path.join(vault_root, ".git")
    try:
        with open(os.path.join(git_dir, "HEAD"), "r", encoding="utf-8") as f:
            head = f.read().strip()
        if not head.startswith("ref: "):
            return head
        ref = head[5:]
        ref_file = os.path.join(git_dir, *ref.split("/"))
        if os.path.isfile(ref_file):
            with open(ref_file, "r", encoding="utf-8") as f:
                return f.read().strip()
        packed = os.path.join(git_dir, "packed-refs")
        if os.path.isfile(packed):
            with open(packed, "r", encoding="utf-8") as f:
                for line in f:
                    parts = line.strip().split(" ")
                    if len(parts) == 2 and parts[1] == ref:
                        return parts[0]
    except OSError:
        pass
    try:
        out = subprocess.run(
            ["git", "-C", vault_root, "rev-parse", "HEAD"],
            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, check=False,
        ).stdout.decode("utf-8", "replace").strip()
        return out or "unknown"
    except OSError:
        return "unknown"


class Sandbox:
    def __init__(self, allowed, vault_root):
        self.allowed_display = [os.path.abspath(a) for a in allowed]
        self.allowed = [norm(a) for a in allowed]
        self.vault_root = os.path.abspath(vault_root)
        self.server_name = server_name(self.vault_root)

    def inside(self, resolved):
        for root in self.allowed:
            if resolved == root:
                return True
            try:
                if os.path.commonpath([resolved, root]) == root:
                    return True
            except ValueError:
                continue
        return False

    def check(self, path):
        """Path, existing or not; resolved, within the perimeter, otherwise refusal."""
        if not isinstance(path, str) or not path:
            raise ToolError(INVALID_PARAMS, "chemin manquant")
        full = os.path.abspath(os.path.expanduser(path))
        if os.path.lexists(full):
            resolved = norm(full)
        else:
            parent = os.path.dirname(full)
            resolved = os.path.join(norm(parent), os.path.normcase(os.path.basename(full)))
        if not self.inside(resolved):
            # The text carries the TWO facts the Pilot needs in order to
            # correct without guessing: what it asked for, and where it is
            # allowed to read or write (door 3 of capture
            # 2026-09-17-144137: the application showed only
            # « Tool execution failed », with neither path nor reason).
            raise ToolError(ACCESS_DENIED, "accès refusé : %s est hors des dossiers autorisés.\nDossiers autorisés :\n%s" % (
                path, "\n".join("- " + d for d in self.allowed_display)))
        return full


def text_result(text):
    return {"content": [{"type": "text", "text": text}]}


def read_text(path):
    with open(path, "r", encoding="utf-8", errors="replace", newline="") as f:
        return f.read()


def tool_list_allowed(sb, args):
    lines = ["Allowed directories:"] + sb.allowed_display
    lines.append("Vault: " + sb.vault_root)
    lines.append("Vault commit: " + vault_commit(sb.vault_root))
    return text_result("\n".join(lines))


def tool_list_directory(sb, args):
    path = sb.check(args.get("path"))
    if not os.path.isdir(path):
        raise ToolError(INVALID_PARAMS, "pas un dossier : %s" % args.get("path"))
    out = []
    for name in sorted(os.listdir(path)):
        kind = "[DIR]" if os.path.isdir(os.path.join(path, name)) else "[FILE]"
        out.append("%s %s" % (kind, name))
    return text_result("\n".join(out))


def tool_read_text_file(sb, args):
    path = sb.check(args.get("path"))
    if not os.path.isfile(path):
        raise ToolError(INVALID_PARAMS, "fichier introuvable : %s" % args.get("path"))
    text = read_text(path)
    head = args.get("head")
    tail = args.get("tail")
    if head:
        text = "".join(text.splitlines(True)[: int(head)])
    elif tail:
        text = "".join(text.splitlines(True)[-int(tail):])
    return text_result(text)


def tool_read_multiple_files(sb, args):
    paths = args.get("paths")
    if not isinstance(paths, list) or not paths:
        raise ToolError(INVALID_PARAMS, "paths doit etre une liste non vide")
    checked = [sb.check(p) for p in paths]
    parts = []
    for original, path in zip(paths, checked):
        try:
            parts.append("%s:\n%s" % (original, read_text(path)))
        except OSError as exc:
            parts.append("%s: Error - %s" % (original, exc.strerror or exc))
    return text_result("\n---\n".join(parts))


def tool_write_file(sb, args):
    path = sb.check(args.get("path"))
    content = args.get("content")
    if not isinstance(content, str):
        raise ToolError(INVALID_PARAMS, "content manquant")
    with open(path, "w", encoding="utf-8", newline="") as f:
        f.write(content)
    return text_result("Successfully wrote to %s" % args.get("path"))


def tool_edit_file(sb, args):
    path = sb.check(args.get("path"))
    edits = args.get("edits")
    if not isinstance(edits, list) or not edits:
        raise ToolError(INVALID_PARAMS, "edits doit etre une liste non vide")
    original = read_text(path)
    text = original
    for edit in edits:
        old = edit.get("oldText")
        new = edit.get("newText", "")
        if not isinstance(old, str) or old not in text:
            raise ToolError(INVALID_PARAMS, "texte introuvable dans %s" % args.get("path"))
        text = text.replace(old, new, 1)
    diff = "".join(difflib.unified_diff(
        original.splitlines(True), text.splitlines(True),
        fromfile=args.get("path"), tofile=args.get("path"),
    ))
    if not args.get("dryRun"):
        with open(path, "w", encoding="utf-8", newline="") as f:
            f.write(text)
    return text_result(diff or "(aucun changement)")


def tool_create_directory(sb, args):
    path = sb.check(args.get("path"))
    os.makedirs(path, exist_ok=True)
    return text_result("Successfully created directory %s" % args.get("path"))


def tool_search_files(sb, args):
    root = sb.check(args.get("path"))
    pattern = args.get("pattern")
    if not isinstance(pattern, str) or not pattern:
        raise ToolError(INVALID_PARAMS, "pattern manquant")
    has_glob = any(c in pattern for c in "*?[")
    needle = pattern.lower()
    found = []
    for dirpath, dirnames, filenames in os.walk(root, followlinks=False):
        kept = []
        for d in dirnames:
            full = os.path.join(dirpath, d)
            if d == ".git" or not sb.inside(norm(full)):
                continue
            kept.append(d)
        dirnames[:] = kept
        for name in dirnames + filenames:
            ok = fnmatch.fnmatch(name.lower(), needle) if has_glob else needle in name.lower()
            if ok:
                found.append(os.path.join(dirpath, name))
        if len(found) >= 500:
            break
    return text_result("\n".join(found) if found else "No matches found")


def tool_get_file_info(sb, args):
    path = sb.check(args.get("path"))
    if not os.path.lexists(path):
        raise ToolError(INVALID_PARAMS, "introuvable : %s" % args.get("path"))
    st = os.stat(path)
    info = [
        "size: %d" % st.st_size,
        "modified: %s" % datetime.datetime.fromtimestamp(st.st_mtime).isoformat(),
        "created: %s" % datetime.datetime.fromtimestamp(st.st_ctime).isoformat(),
        "isDirectory: %s" % str(os.path.isdir(path)).lower(),
        "isFile: %s" % str(os.path.isfile(path)).lower(),
    ]
    return text_result("\n".join(info))


def tool_move_file(sb, args):
    src = sb.check(args.get("source"))
    dst = sb.check(args.get("destination"))
    if not os.path.lexists(src):
        raise ToolError(INVALID_PARAMS, "source introuvable : %s" % args.get("source"))
    if os.path.lexists(dst):
        raise ToolError(INVALID_PARAMS, "destination existante : %s" % args.get("destination"))
    os.rename(src, dst)
    return text_result("Successfully moved %s to %s" % (args.get("source"), args.get("destination")))


def schema(props, required):
    return {"type": "object", "properties": props, "required": required}


STR = {"type": "string"}
TOOLS = [
    ("list_allowed_directories", "Liste les dossiers autorisés et rend le commit du Vault.", schema({}, []), tool_list_allowed),
    ("list_directory", "Liste un dossier.", schema({"path": STR}, ["path"]), tool_list_directory),
    ("read_text_file", "Lit un fichier texte (head ou tail optionnels).",
     schema({"path": STR, "head": {"type": "number"}, "tail": {"type": "number"}}, ["path"]), tool_read_text_file),
    ("read_multiple_files", "Lit plusieurs fichiers texte.",
     schema({"paths": {"type": "array", "items": STR}}, ["paths"]), tool_read_multiple_files),
    ("write_file", "Écrit un fichier (le remplace s'il existe).",
     schema({"path": STR, "content": STR}, ["path", "content"]), tool_write_file),
    ("edit_file", "Remplace des passages exacts d'un fichier ; dryRun rend le diff sans écrire.",
     schema({"path": STR, "edits": {"type": "array", "items": schema({"oldText": STR, "newText": STR}, ["oldText", "newText"])},
             "dryRun": {"type": "boolean"}}, ["path", "edits"]), tool_edit_file),
    ("create_directory", "Crée un dossier (et ses parents).", schema({"path": STR}, ["path"]), tool_create_directory),
    ("search_files", "Cherche des noms de fichiers ou dossiers (motif glob ou sous-chaîne).",
     schema({"path": STR, "pattern": STR}, ["path", "pattern"]), tool_search_files),
    ("get_file_info", "Rend la taille et les dates d'un fichier ou dossier.", schema({"path": STR}, ["path"]), tool_get_file_info),
    ("move_file", "Déplace ou renomme un fichier ou dossier (destination absente).",
     schema({"source": STR, "destination": STR}, ["source", "destination"]), tool_move_file),
]
TOOL_BY_NAME = {name: fn for (name, _, _, fn) in TOOLS}


def handle(sb, msg):
    method = msg.get("method")
    params = msg.get("params") or {}
    if method == "initialize":
        return {
            "protocolVersion": params.get("protocolVersion") or DEFAULT_PROTOCOL,
            "capabilities": {"tools": {"listChanged": False}},
            "serverInfo": {"name": sb.server_name, "version": vault_commit(sb.vault_root)[:12]},
        }
    if method == "ping":
        return {}
    if method == "tools/list":
        return {"tools": [
            {"name": name, "description": desc, "inputSchema": sch}
            for (name, desc, sch, _) in TOOLS
        ]}
    if method == "tools/call":
        name = params.get("name")
        fn = TOOL_BY_NAME.get(name)
        if fn is None:
            # Unknown tool: a PROTOCOL defect, not an execution one -- it
            # remains a JSON-RPC error.
            raise ToolError(METHOD_NOT_FOUND, "outil inconnu : %s" % name)
        try:
            return fn(sb, params.get("arguments") or {})
        except ToolError as exc:
            # A tool EXECUTION failure is returned as a RESULT carrying
            # isError, never as a JSON-RPC error (door 3 of
            # capture 2026-09-17-144137): measured on the Owner's machine,
            # the desktop application folds the JSON-RPC error into
            # « <error>Tool execution failed</error> » and the text -- the
            # requested path, the allowed folders -- never reaches the
            # Pilot. The content of a result, by contrast, is passed to it as is.
            # This is also what the MCP specification prescribes for
            # tool errors.
            return {"content": [{"type": "text", "text": exc.message}], "isError": True}
    raise ToolError(METHOD_NOT_FOUND, "méthode inconnue : %s" % method)


def send(obj):
    data = json.dumps(obj, ensure_ascii=False) + "\n"
    sys.stdout.buffer.write(data.encode("utf-8"))
    sys.stdout.buffer.flush()


def main(argv):
    if hasattr(sys.stderr, "reconfigure"):
        sys.stderr.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(prog="vault-mcp.py")
    parser.add_argument("--allow", action="append", default=[], required=True)
    parser.add_argument("--vault", default=os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
    args = parser.parse_args(argv)
    for a in args.allow:
        if not os.path.isdir(a):
            log("dossier autorisé introuvable : %s" % a)
            return 2
    sb = Sandbox(args.allow, args.vault)
    log("prêt ; serveur %s ; dossiers autorisés : %s" % (sb.server_name, ", ".join(sb.allowed_display)))
    for raw in sys.stdin.buffer:
        line = raw.decode("utf-8", "replace").strip()
        if not line:
            continue
        try:
            msg = json.loads(line)
        except ValueError:
            send({"jsonrpc": "2.0", "id": None, "error": {"code": -32700, "message": "JSON illisible"}})
            continue
        if not isinstance(msg, dict):
            continue
        msg_id = msg.get("id")
        is_request = "id" in msg
        try:
            result = handle(sb, msg) if msg.get("method") != "notifications/initialized" else None
            if is_request:
                send({"jsonrpc": "2.0", "id": msg_id, "result": result if result is not None else {}})
        except ToolError as exc:
            if is_request:
                send({"jsonrpc": "2.0", "id": msg_id, "error": {"code": exc.code, "message": exc.message}})
        except Exception as exc:  # noqa: BLE001 -- never a server stop
            log("erreur interne : %r" % (exc,))
            if is_request:
                send({"jsonrpc": "2.0", "id": msg_id, "error": {"code": INTERNAL_ERROR, "message": "erreur interne : %s" % exc}})
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
