#!/usr/bin/env python3
# T6 (Mission 185-C01, porte 3 de la capture 2026-09-17-144137) : un refus
# du serveur MCP du Vault est LISIBLE dans l'application de bureau.
#
# Defaut mesure sur le poste de l'Owner : une lecture hors perimetre par
# `second-brain-vault` s'affichait « <error>Tool execution failed</error> »,
# sans chemin ni raison. Cause lue dans le code : l'echec remontait comme
# une erreur JSON-RPC, que l'application replie en cette phrase unique. La
# specification MCP reserve l'erreur JSON-RPC aux defauts de protocole et
# demande qu'un echec d'EXECUTION d'outil soit un resultat porteur de
# `isError: true` -- c'est ce contenu-la que l'application rend tel quel.
#
# Oracle (PASS attendu) : `tools/call read_text_file` sur un chemin hors
# perimetre rend un RESULTAT avec `isError: true`, dont le texte contient le
# chemin demande ET la liste des dossiers autorises ; idem pour un lien qui
# s'echappe du perimetre.
# Temoin negatif (dans ce meme fichier) : le meme appel sur un chemin
# DEDANS ne porte pas `isError` et rend le contenu du fichier.
#
# Rien ne sort d'un dossier temporaire (prefixe m185) ; aucun appel reseau,
# aucun appel modele.
#
# usage: uv run --no-project tests/test-vault-mcp-refusal-message.py
# Code 0 : tous les cas PASS (ou SKIP nomme). Code 1 sinon.

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
    """uv, sur le PATH ou aux deux emplacements que les runners utilisent."""
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
    """Envoie les requetes au serveur, rend la liste des messages JSON."""
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

    # Un lien qui s'echappe : jonction sous Windows, lien symbolique
    # ailleurs. Non creable partout (droits) -- alors SKIP nomme, jamais un
    # PASS silencieux.
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

    # --- Temoin negatif, dans ce meme fichier : le chemin DEDANS ---------
    inside_msg = messages.get(2)
    check(inside_msg is not None and not is_error(inside_msg),
          "temoin : chemin dans le perimetre -- isError absent",
          json.dumps(inside_msg, ensure_ascii=False)[:300])
    check("dedans" in result_text(inside_msg),
          "temoin : chemin dans le perimetre -- le contenu est rendu",
          result_text(inside_msg)[:200])

    # --- Oracle : le chemin DEHORS ---------------------------------------
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

    # --- Oracle : le lien qui s'echappe ----------------------------------
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

    # --- L'ecriture refusee n'ecrit rien ---------------------------------
    write_msg = messages.get(5)
    check(is_error(write_msg) and not os.path.exists(os.path.join(outside, "w.txt")),
          "ecriture hors perimetre : refus lisible, rien d'ecrit",
          json.dumps(write_msg, ensure_ascii=False)[:300])

    # --- Un defaut de PROTOCOLE reste une erreur JSON-RPC ----------------
    unknown = messages.get(6)
    check(((unknown or {}).get("error") or {}).get("code") == -32601,
          "outil inconnu : reste une erreur JSON-RPC (-32601), pas un resultat",
          json.dumps(unknown, ensure_ascii=False)[:300])

    # --- La sortie standard ne porte que du JSON-RPC ---------------------
    stray = [l for l in raw.splitlines() if l.strip() and not l.strip().startswith('{"jsonrpc"')]
    check(not stray, "sortie standard : seulement du JSON-RPC", " | ".join(stray[:3]))

    # --- Temoin : le meme appel, dehors AUTORISE, passe ------------------
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
