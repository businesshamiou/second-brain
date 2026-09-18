#!/usr/bin/env bash
# Mission 187, T3: the skills are written in English, and the phrases that
# trigger them stay in both languages -- a French-speaking participant still
# says « wrap » or « clôture ».
#
# Oracle (PASS expected): the `description` of each of the six skills below
#   (front matter of skills/<name>/SKILL.md, read by the harnesses to
#   trigger a skill) carries every French and every English trigger phrase
#   listed for it here -- a closed list, one line per skill.
# Negative control: a throwaway copy of session-close/SKILL.md whose
#   description lost « wrap » and « clôture » fails, both phrases named.
#
# usage: bash tests/test-skill-triggers-bilingual.sh

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FAILURES=0
TMP="$(mktemp -d "${TMPDIR:-/tmp}/m187-triggers-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

# skill | French phrases (;-separated) | English phrases (;-separated)
TRIGGERS='ecriture-de-mission|écris la Mission;rédige la Mission|write the Mission
first-install|installe Second Brain;installer Second Brain|install Second Brain
project-bootstrap|adopte ce projet;nouveau projet|adopt this project;new project
recherche-interne|où est;trouve;cherche dans le Vault;quel fichier|where is
session-close|wrap;on ferme;clôture;clos la session|wrap;close
session-start|nouvelle session;nouvelle session pilote;ouvre la session;ouverture|open the session'

description_of() {
  # $1 = SKILL.md. The value of the front-matter `description` line.
  awk '/^---[[:space:]]*$/ { n++; next } n == 1 && /^description:/ { sub(/^description:[[:space:]]*/, ""); print; exit }' "$1"
}

check_skill() {
  # $1 = SKILL.md, $2 = French phrases, $3 = English phrases, $4 = label.
  # Prints one line per missing phrase; returns the number missing.
  local d missing=0 p
  d="$(description_of "$1")"
  old_ifs="$IFS"; IFS=';'
  for p in $2; do
    case "$d" in *"$p"*) ;; *) echo "    missing French trigger « $p » ($4)"; missing=$((missing + 1)) ;; esac
  done
  for p in $3; do
    case "$d" in *"$p"*) ;; *) echo "    missing English trigger \"$p\" ($4)"; missing=$((missing + 1)) ;; esac
  done
  IFS="$old_ifs"
  return "$missing"
}

echo "=== T3 : skill trigger phrases in both languages ==="
while IFS='|' read -r skill fr en; do
  f="$REPO_ROOT/skills/$skill/SKILL.md"
  if [ ! -f "$f" ]; then
    echo "  FAIL - $skill: SKILL.md not found"; FAILURES=$((FAILURES + 1)); continue
  fi
  if OUT="$(check_skill "$f" "$fr" "$en" "$skill")"; then
    echo "  PASS - $skill: French and English triggers present"
  else
    echo "  FAIL - $skill:"; printf '%s\n' "$OUT"; FAILURES=$((FAILURES + 1))
  fi
done <<TRIG
$TRIGGERS
TRIG

echo "=== negative control ==="
sed '/^description:/ { s/« wrap », //; s/wrap, //; s/« clôture », //; s/clôture//; s/wrap//g; }' \
  "$REPO_ROOT/skills/session-close/SKILL.md" > "$TMP/SKILL.md"
OUT="$(check_skill "$TMP/SKILL.md" "wrap;on ferme;clôture;clos la session" "wrap;close" "copy of session-close")"
case "$OUT" in
  *"« wrap »"*"« clôture »"*) echo "  PASS - control: a copy without « wrap » and « clôture » fails, both named" ;;
  *) echo "  FAIL - control: the stripped copy was not caught ($OUT)"; FAILURES=$((FAILURES + 1)) ;;
esac

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES) ==="
exit 1
