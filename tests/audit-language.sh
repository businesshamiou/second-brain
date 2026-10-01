#!/usr/bin/env bash
# Mission 245 (capture 105405, rubric B; the Owner's orientation of 2026-10-01):
# the language inventory, measured by a script, never by rereading. In an
# installation in one language, everything the client reads is in that
# language (machine identifiers excepted); this script lists every line that
# carries a marker of ANOTHER language. It corrects nothing: it is the input
# of the audit chain the Owner leads next (grill-with-docs, to-spec,
# to-tickets, implement with tdd).
#
# For each language L among FR, EN, ES, on a throwaway workspace (never a real
# installation, never the real profile: install.sh --test-mode with the
# scripted answers of Mission 244's tests/test-install-final-screen.sh, the
# clipboard simulated by SB_CLIPBOARD_FILE):
#   install.sh in L; then `sb doctor`, `sb help start`, `sb pilot-prompt
#   --accueil`, `project-bootstrap.sh order` (the order to fill), `sb new
#   --order` on a fixture order, `sb close --light` on the new project.
# Sources read: every output above, and the generated files -- USER.md, the
# project's state/STATE.md, the welcome Pilot's block and the project
# Pilot's block (the simulated clipboard), the names of the project's
# guardians (`name:` lines of its .pre-commit-config.yaml).
#
# A line is reported when a marker list of another language wins on it: the
# known labels of capture 105405 (strong markers, one is enough), else the
# function words and letters of each language (two hits at least, and more
# than the expected language's). The lists are below, in the script, and
# extensible. « Pilot », « Executor », « Vault », « Mission » and the like are
# machine identifiers, the same in every language: never markers.
#
# Output (standard output, or --out <file>): a Markdown table « source · line ·
# expected language · language found · excerpt », then the totals by language
# and by source. Exit 0 whatever it finds (an inventory, not a guardian), 1
# only when it could not run at all.
#
# usage: bash tests/audit-language.sh [--lang FR|EN|ES]... [--out <file>]

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_ROOT/tests/sandbox-vault.sh"
. "$REPO_ROOT/tools/lib/tmp.sh"

LANGS=""
OUT_FILE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --lang) LANGS="$LANGS ${2:-}"; shift 2 ;;
    --out) OUT_FILE="${2:-}"; shift 2 ;;
    *) echo "usage: bash tests/audit-language.sh [--lang FR|EN|ES]... [--out <file>]" >&2; exit 1 ;;
  esac
done
[ -n "$LANGS" ] || LANGS="FR EN ES"

sandbox_find_uv || { echo "audit-language: uv not found" >&2; exit 1; }
TMP="$(mktemp -d "$(sb_tmp_dir tests)/m245-language-XXXXXX")"
trap '[ -n "${KEEP_TMP:-}" ] || rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd -P)"
SOURCE="$TMP/source"
REF_CLONE="$(sandbox_reference_clone "$REPO_ROOT")" || { echo "audit-language: reference clone not built" >&2; exit 1; }
git clone --quiet -- "$REF_CLONE" "$SOURCE" >/dev/null 2>&1 || { echo "audit-language: source not built" >&2; exit 1; }
# pre-commit stand-in for the project born by `sb new --order` (the guardians'
# names are read from its configuration, not from a run): never the network.
mkdir -p "$TMP/bin"
cat > "$TMP/bin/pre-commit" <<'STUB'
#!/usr/bin/env bash
[ "$1" = install ] || exit 0
h="$(git rev-parse --git-path hooks)"; mkdir -p "$h"
printf '#!/usr/bin/env bash\nexit 0\n' > "$h/pre-commit"; chmod +x "$h/pre-commit"
STUB
chmod +x "$TMP/bin/pre-commit"
export PATH="$TMP/bin:$PATH"

CAP="$TMP/captured"
mkdir -p "$CAP"
capture() { # capture <lang> <source label> <file>: one captured source
  local n
  n="$(ls "$CAP" | wc -l | tr -d ' ')"
  { printf '%s\t%s\n' "$1" "$2"; tr -d '\r' < "$3"; } > "$CAP/$(printf '%03d' "$n").txt"
}

for L in $LANGS; do
  l="$(printf '%s' "$L" | tr 'A-Z' 'a-z')"
  R="$TMP/$l"
  WS="$R/workspace"
  mkdir -p "$R"
  printf '{"language": "%s", "vaultName": "Brian", "workspacePath": "%s", "firstName": "Abde", "activity": "Media buyer", "whatMatters": "Clear reports", "aiTools": ["claude-code", "claude-ai"], "firstProject": {"create": false}, "git": {"userName": "Second Brain Installer", "userEmail": "installer@example.invalid"}}\n' \
    "$L" "$WS" > "$R/answers.json"
  SB_CLIPBOARD_FILE="$R/accueil-block.txt" bash "$REPO_ROOT/install.sh" --source "$SOURCE" --answers-file "$R/answers.json" \
    --test-mode --test-root "$R" > "$R/install.txt" 2>&1
  capture "$L" "install.sh (test mode)" "$R/install.txt"
  V="$WS/second-brain"
  [ -d "$V" ] || { echo "audit-language: $L: the installation produced no Vault" >&2; continue; }
  SB="$V/tools/sb/bin/sb"
  [ -f "$V/USER.md" ] && capture "$L" "USER.md" "$V/USER.md"
  [ -f "$R/accueil-block.txt" ] && capture "$L" "welcome Pilot block (clipboard)" "$R/accueil-block.txt"
  (cd "$WS" && "$SB" doctor > "$R/doctor.txt" 2>&1)
  capture "$L" "sb doctor" "$R/doctor.txt"
  (cd "$WS" && "$SB" help start > "$R/help-start.txt" 2>&1)
  capture "$L" "sb help start" "$R/help-start.txt"
  (cd "$WS" && SB_CLIPBOARD_FILE="$R/accueil-again.txt" "$SB" pilot-prompt --accueil > "$R/pilot-prompt.txt" 2>&1)
  capture "$L" "sb pilot-prompt --accueil" "$R/pilot-prompt.txt"
  bash "$V/tools/project-bootstrap.sh" order "$WS/idee" > "$R/order-to-fill.txt" 2>&1
  capture "$L" "project-bootstrap.sh order (the order to fill)" "$R/order-to-fill.txt"
  VID="$(bash "$V/tools/vault-identity.sh" get vault_id "$V" 2>/dev/null)"
  VORIGIN="$(bash "$V/tools/vault-identity.sh" get vault_origin "$V" 2>/dev/null)"
  mkdir -p "$WS/_orders"
  ORDER="$WS/_orders/ORDER-2026-10-01-120000-rapports.md"
  {
    echo "Session Executor — initiation (rapports)"
    echo ""
    echo "Ordre d'initiation"
    echo "- Type : create"
    echo "- Mode : answered"
    echo "- Nom : rapports"
    echo "- Emplacement : $WS"
    echo "- Vault + construction : vault_id=$VID, vault_origin=$VORIGIN, vault_ref=$(git -C "$V" rev-parse HEAD)"
    echo "- Git : git"
    echo "- Objet : weekly client reports"
    echo "- Autorisation Owner datée : yes, 2026-10-01"
  } > "$ORDER"
  (cd "$WS" && SB_CLIPBOARD_FILE="$R/project-block.txt" "$SB" new --order "$ORDER" > "$R/new.txt" 2>&1)
  capture "$L" "sb new --order" "$R/new.txt"
  [ -f "$R/project-block.txt" ] && capture "$L" "project Pilot block (clipboard)" "$R/project-block.txt"
  P="$WS/rapports"
  if [ -d "$P" ]; then
    [ -f "$P/.pre-commit-config.yaml" ] && { grep -E '^[[:space:]]*name:' "$P/.pre-commit-config.yaml" > "$R/guardians.txt"; capture "$L" "guardian names (project .pre-commit-config.yaml)" "$R/guardians.txt"; }
    (cd "$P" && "$SB" close --light > "$R/close.txt" 2>&1)
    capture "$L" "sb close --light" "$R/close.txt"
    [ -f "$P/state/STATE.md" ] && capture "$L" "project state/STATE.md" "$P/state/STATE.md"
  fi
done

cat > "$TMP/classify.py" <<'PY'
import os, re, sys
from collections import Counter

# Strong markers: the labels capture 105405 measured in the wrong language,
# and the place labels of every language. One is enough.
STRONG = {
    "FR": ["Profil de départ", "Outils du quotidien", "Ce que je fais", "Ce qui compte pour moi",
           "Tu es l'Executor", "Dans l'Executor", "Dans le terminal", "Dans le Pilot", "session d'accueil",
           "contrôle de secrets", "VERDICT: CONFORME", "gum n'est pas disponible", "Pour l'Executor",
           "Étape", "Fiche d'état", "Ordre d'initiation", "Profil du projet"],
    "EN": ["You are the Executor", "In the terminal", "In the Pilot", "In the Executor", "Step:",
           "welcome session", "starting profile", "Nothing blocking", "VERDICT: COMPLIANT"],
    "ES": ["Eres el Executor", "En la terminal", "En el Pilot", "En el Executor", "Paso", "paso",
           "sesión de acogida", "Perfil de partida"],
}
# Weak markers: function words (whole words) and letters proper to a language.
WORDS = {
    "FR": "le la les des du de est sont pour dans avec une un sur pas ne et ou ton ta tes ce cette qui que "
          "puis aucun aucune déjà être fait faire ici voici chaque",
    "EN": "the and with your you is are not for this that each then from into only when which already "
          "here there has have of to",
    "ES": "el los las del para con una uno está están es por tu tus cada luego ya aquí que pero sin ningún",
}
LETTERS = {"FR": "èêçàùâîôûœ", "EN": "", "ES": "ñáíóú¿¡"}
IDENTIFIERS = {"Pilot", "Executor", "Vault", "Mission", "Owner", "RELAY", "Project"}

def words(line):
    return [w for w in re.findall(r"[A-Za-zÀ-ÿ']+", line) if w not in IDENTIFIERS]

def score(line):
    s = Counter()
    lw = [w.lower() for w in words(line)]
    for lang, ws in WORDS.items():
        vocab = set(ws.split())
        s[lang] += sum(1 for w in lw if w in vocab)
    for lang, letters in LETTERS.items():
        s[lang] += sum(1 for ch in line if ch in letters)
    return s

def found(line, expected):
    for lang, labels in STRONG.items():
        if lang != expected and any(lab in line for lab in labels):
            return lang
    s = score(line)
    lang, top = max(s.items(), key=lambda kv: kv[1]) if s else (None, 0)
    if lang and lang != expected and top >= 2 and top > s.get(expected, 0):
        return lang
    return None

rows = []
for name in sorted(os.listdir(sys.argv[1])):
    with open(os.path.join(sys.argv[1], name), encoding="utf-8", errors="replace") as f:
        head, *lines = f.read().split("\n")
    expected, source = head.split("\t", 1)
    for n, line in enumerate(lines, 1):
        text = line.strip()
        if not text or text.startswith(("---", "```")) or re.fullmatch(r"[\W\d_]+", text):
            continue
        lang = found(text, expected)
        if lang:
            # The throwaway folder's path, in any of its forms, said <tmp>.
            excerpt = re.sub(r"(?:[A-Za-z]:|/[a-z])?[/\\][^\s`'\"]*?m245-language-[A-Za-z0-9]+", "<tmp>", text)
            excerpt = excerpt.replace("|", "\\|")
            rows.append((source, n, expected, lang, excerpt[:110] + ("…" if len(excerpt) > 110 else "")))

out = ["# Language inventory (tests/audit-language.sh)", "",
       f"{len(rows)} line(s) carry a marker of another language than the installation's.", "",
       "| Source | Line | Expected | Found | Excerpt |", "|---|---|---|---|---|"]
out += [f"| {s} | {n} | {e} | {l} | {x} |" for s, n, e, l, x in rows]
out += ["", "## Totals by installation language", "", "| Expected | Lines | FR found | EN found | ES found |", "|---|---|---|---|---|"]
for e in ("FR", "EN", "ES"):
    sub = [r for r in rows if r[2] == e]
    c = Counter(r[3] for r in sub)
    out.append(f"| {e} | {len(sub)} | {c.get('FR', 0)} | {c.get('EN', 0)} | {c.get('ES', 0)} |")
out += ["", "## Totals by source", "", "| Source | FR install | EN install | ES install | Total |", "|---|---|---|---|---|"]
sources = []
for r in rows:
    if r[0] not in sources:
        sources.append(r[0])
for s in sources:
    c = Counter(r[2] for r in rows if r[0] == s)
    out.append(f"| {s} | {c.get('FR', 0)} | {c.get('EN', 0)} | {c.get('ES', 0)} | {sum(c.values())} |")
# UTF-8 whatever the console's code page (Windows: cp1252 by default).
sys.stdout.reconfigure(encoding="utf-8", newline="\n")
print("\n".join(out))
PY

if [ -n "$OUT_FILE" ]; then
  uv run --no-project python "$(sandbox_native_path "$TMP/classify.py")" "$(sandbox_native_path "$CAP")" > "$OUT_FILE"
  echo "audit-language: $(sed -n 3p "$OUT_FILE") -> $OUT_FILE"
else
  uv run --no-project python "$(sandbox_native_path "$TMP/classify.py")" "$(sandbox_native_path "$CAP")"
fi
exit 0
