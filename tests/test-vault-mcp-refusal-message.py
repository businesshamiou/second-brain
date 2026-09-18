#!/usr/bin/env python3
# T6 (Mission 185-C01, door 3 of capture 2026-09-17-144137): a refusal
# by the Vault's MCP server is READABLE in the desktop application.
#
# Defect measured on the Owner's machine: a read outside the perimeter through
# `second-brain-vault` was displayed as « <error>Tool execution failed</error> »,
# with neither path nor reason. Cause read in the code: the failure came up as
# a JSON-RPC error, which the application folds into that single sentence. The
# MCP specification reserves the JSON-RPC error for protocol defects and
# requires that a tool EXECUTION failure be a result carrying
# `isError: true` -- it is that content that the application displays as is.
#
# Oracle (PASS expected): `tools/call read_text_file` on a path outside the
# perimeter returns a RESULT with `isError: true`, whose text contains the
# requested path AND the list of authorized folders; the same for a link that
# escapes the perimeter.
# Negative control (in this same file): the same call on a path
# INSIDE does not carry `isError` and returns the file's content.
#
# Nothing leaves a temporary folder (prefix m185); no network call,
# no model call.
#
# usage: uv run --no-project tests/test-vault-mcp-refusal-message.py
# Exit 0: all cases PASS (or named SKIP). Exit 1 otherwise.

import io
import json
import os
import shutil
import subprocess
import sys
import tempfile

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SERVER = os.path.join(REPO_ROOT, "tools", "vault-mcp.py")

FAILURES = []
PASSES = 0
SKIPS = 0


def ok(name):
    global PASSES
    PASSES += 1
    print("  PASS - " + name)


def ko(name, detail=""):
    FAILURES.append(name)
    print("  FAIL - " + name + ((" :: " + detail) if detail else ""))


def skip(cause, name):
    global SKIPS
    SKIPS += 1
    print("  SKIP (%s) - %s" % (cause, name))


def check(condition, name, detail=""):
    if condition:
        ok(name)
    else:
        ko(name, detail)


def uv_exe():
    """uv, on the PATH or at the two locations the runners use."""
    found = shutil.which("uv")
    if found:
        return found
    for base in (os.environ.get("RUNNER_TEMP", ""), os.path.expanduser("~")):
        if not base:
            continue
        for rel in ("uv-bin", os.path.join(".local", "bin"), os.path.join(".cargo", "bin")):
            for name in ("uv", "uv.exe"):
                candidate = os.path.join(base, rel, name)
                if os.path.isfile(candidate):
                    return candidate
    return None


def play(requests, allowed):
    """Sends the requests to the server, returns the list of JSON messages."""
    args = [UV, "run", "--no-project", SERVER, "--vault", REPO_ROOT]
    for a in allowed:
        args += ["--allow", a]
    payload = "".join(json.dumps(r) + "\n" for r in requests)
    proc = subprocess.run(
        args, input=payload.encode("utf-8"),
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False,
    )
    out = proc.stdout.decode("utf-8", "replace")
    messages = {}
    for line in out.splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            msg = json.loads(line)
        except ValueError:
            continue
        if isinstance(msg, dict) and msg.get("id") is not None:
            messages[msg["id"]] = msg
    return messages, out, proc.stderr.decode("utf-8", "replace")


def call(msg_id, tool, arguments):
    return {"jsonrpc": "2.0", "id": msg_id, "method": "tools/call",
            "params": {"name": tool, "arguments": arguments}}


def result_text(msg):
    result = (msg or {}).get("result") or {}
    parts = []
    for block in result.get("content") or []:
        if isinstance(block, dict) and block.get("type") == "text":
            parts.append(block.get("text") or "")
    return "\n".join(parts)


def is_error(msg):
    return bool(((msg or {}).get("result") or {}).get("isError"))


UV = uv_exe()
if UV is None:
    print("FAIL : uv introuvable -- le serveur se lance par uv")
    sys.exit(1)

print("=== T6 : le refus du serveur MCP nomme le chemin et le perimetre ===")

TMP = tempfile.mkdtemp(prefix="m185-mcp-refusal-")
try:
    ws = os.path.join(TMP, "ws")
    proj = os.path.join(ws, "proj")
    outside = os.path.join(TMP, "outside")
    os.makedirs(proj)
    os.makedirs(outside)
    with io.open(os.path.join(proj, "a.txt"), "w", encoding="utf-8") as f:
        f.write("dedans\n")
    with io.open(os.path.join(outside, "s.txt"), "w", encoding="utf-8") as f:
        f.write("dehors\n")

    # A link that escapes: junction under Windows, symbolic link
    # elsewhere. Not creatable everywhere (permissions) -- then a named SKIP, never a
    # silent PASS.
    escape = os.path.join(proj, "esc")
    link_kind = ""
    if os.name == "nt":
        rc = subprocess.run(["cmd", "/c", "mklink", "/J", escape, outside],
                            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False)
        if rc.returncode == 0:
            link_kind = "jonction"
    else:
        try:
            os.symlink(outside, escape)
            link_kind = "lien symbolique"
        except OSError:
            link_kind = ""

    inside_path = os.path.join(proj, "a.txt")
    outside_path = os.path.join(outside, "s.txt")
    escape_path = os.path.join(escape, "s.txt")

    requests = [
        {"jsonrpc": "2.0", "id": 1, "method": "initialize",
         "params": {"protocolVersion": "2025-06-18", "capabilities": {},
                    "clientInfo": {"name": "t6", "version": "0"}}},
        {"jsonrpc": "2.0", "method": "notifications/initialized"},
        call(2, "read_text_file", {"path": inside_path}),
        call(3, "read_text_file", {"path": outside_path}),
        call(4, "read_text_file", {"path": escape_path}),
        call(5, "write_file", {"path": os.path.join(outside, "w.txt"), "content": "interdit"}),
        {"jsonrpc": "2.0", "id": 6, "method": "tools/call",
         "params": {"name": "no_such_tool", "arguments": {}}},
    ]
    messages, raw, err = play(requests, [ws])

    # --- Negative control, in this same file: the path INSIDE ------------
    inside_msg = messages.get(2)
    check(inside_msg is not None and not is_error(inside_msg),
          "temoin : chemin dans le perimetre -- isError absent",
          json.dumps(inside_msg, ensure_ascii=False)[:300])
    check("dedans" in result_text(inside_msg),
          "temoin : chemin dans le perimetre -- le contenu est rendu",
          result_text(inside_msg)[:200])

    # --- Oracle: the path OUTSIDE ----------------------------------------
    outside_msg = messages.get(3)
    check(outside_msg is not None and "error" not in (outside_msg or {}),
          "lecture hors perimetre : ce n'est PAS une erreur JSON-RPC",
          json.dumps(outside_msg, ensure_ascii=False)[:300])
    check(is_error(outside_msg),
          "lecture hors perimetre : resultat porteur de isError: true",
          json.dumps(outside_msg, ensure_ascii=False)[:300])
    text = result_text(outside_msg)
    check(outside_path in text,
          "lecture hors perimetre : le texte nomme le chemin demande", text[:300])
    check(os.path.abspath(ws) in text,
          "lecture hors perimetre : le texte nomme les dossiers autorises", text[:300])

    # --- Oracle: the link that escapes -----------------------------------
    if link_kind:
        escape_msg = messages.get(4)
        check(is_error(escape_msg),
              "%s qui s'echappe : resultat porteur de isError: true" % link_kind,
              json.dumps(escape_msg, ensure_ascii=False)[:300])
        escape_text = result_text(escape_msg)
        check(escape_path in escape_text and os.path.abspath(ws) in escape_text,
              "%s qui s'echappe : le texte nomme le chemin et le perimetre" % link_kind,
              escape_text[:300])
    else:
        skip("lien non creable sur ce systeme", "lien qui s'echappe")

    # --- The refused write writes nothing --------------------------------
    write_msg = messages.get(5)
    check(is_error(write_msg) and not os.path.exists(os.path.join(outside, "w.txt")),
          "ecriture hors perimetre : refus lisible, rien d'ecrit",
          json.dumps(write_msg, ensure_ascii=False)[:300])

    # --- A PROTOCOL defect remains a JSON-RPC error ----------------------
    unknown = messages.get(6)
    check(((unknown or {}).get("error") or {}).get("code") == -32601,
          "outil inconnu : reste une erreur JSON-RPC (-32601), pas un resultat",
          json.dumps(unknown, ensure_ascii=False)[:300])

    # --- Standard output carries only JSON-RPC ---------------------------
    stray = [l for l in raw.splitlines() if l.strip() and not l.strip().startswith('{"jsonrpc"')]
    check(not stray, "sortie standard : seulement du JSON-RPC", " | ".join(stray[:3]))

    # --- Control: the same call, outside AUTHORIZED, passes --------------
    messages2, _, _ = play(requests, [ws, outside])
    check(not is_error(messages2.get(3)) and "dehors" in result_text(messages2.get(3)),
          "temoin : dehors autorise, la meme lecture passe sans isError",
          json.dumps(messages2.get(3), ensure_ascii=False)[:300])
finally:
    shutil.rmtree(TMP, ignore_errors=True)

print("")
if not FAILURES:
    print("=== RESULT: PASS (%d PASS, %d SKIP) ===" % (PASSES, SKIPS))
    sys.exit(0)
print("=== RESULT: FAIL (%d FAIL, %d PASS, %d SKIP) ===" % (len(FAILURES), PASSES, SKIPS))
for name in FAILURES:
    print("  - " + name)
sys.exit(1)
