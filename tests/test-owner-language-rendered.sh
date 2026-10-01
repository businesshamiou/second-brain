#!/usr/bin/env bash
# Mission 218, lot 3 (Decision 012459): the Owner's language is recorded once
# in USER.md, rendered in each project's Pilot prompt, and the common prompt
# carries one fixed sentence and no new placeholder.
#
#   (a) the installer, simulated in fr (sb_installer_helper.py
#       write-user-profile) -> USER.md carries `language: fr` in its front
#       matter; the PowerShell twin (Write-UserProfile) the same, when a
#       PowerShell is on this machine (SKIP otherwise, said);
#   (b) USER.md `language: fr` -> project-bootstrap.sh renders `language:
#       "fr"` and the French sentence in the Pilot prompt, and the project's
#       CLAUDE.md in French;
#   (c) no language recorded, no explicit language -> `language: ""` and the
#       sentence "the language of the Owner's messages"; never English as
#       the recorded language;
#   (d) no language in USER.md but an explicit --lang ES from the caller (the
#       installer calls the bootstrap before it writes USER.md) -> `es`;
#   (e) the common prompt carries the fixed sentence, and `{{VAULT_SHORT_ID}}`
#       is its only placeholder: the pasted text is the same for every project;
#   (f) the catalogues fr/en/es carry the Pilot prompt's two language keys;
#   (g) `prompt` regenerates an existing Pilot prompt with the language;
#   (h) negative control: a template carrying a second placeholder fails (e).
#
# usage: bash tests/test-owner-language-rendered.sh
# Exit 0: all cases PASS (a PowerShell SKIP included). Exit 1 otherwise.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_ROOT/tests/sandbox-vault.sh"

FAILURES=0
PASSES=0
pass() { echo "  PASS - $1"; PASSES=$((PASSES + 1)); }
fail() { echo "  FAIL - $1"; FAILURES=$((FAILURES + 1)); }
check() { local n="$1"; shift; if "$@"; then pass "$n"; else fail "$n"; fi; }

if ! sandbox_find_uv; then
  echo "FAIL : uv introuvable"
  exit 1
fi

TMP="$(mktemp -d "${TMPDIR:-/tmp}/m218-lang-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd)"
mkdir -p "$TMP/bin"
printf '#!/usr/bin/env bash\nexit 0\n' > "$TMP/bin/pre-commit"
chmod +x "$TMP/bin/pre-commit"
PATH="$TMP/bin:$PATH"; export PATH

# The BOM that Windows PowerShell 5.1 writes is removed, as the bootstrap does.
fm_field() { tr -d '\r' < "$1" | awk -v k="$2" 'NR==1{sub(/^\357\273\277/,"")} NR==1&&$0=="---"{f=1;next} f&&$0=="---"{exit} f&&index($0,k": ")==1{sub("^"k": *","");gsub(/^"|"$/,"");print;exit}'; }
has_field() { tr -d '\r' < "$1" | awk -v k="$2" 'NR==1&&$0=="---"{f=1;next} f&&$0=="---"{exit} f&&index($0,k":")==1{ok=1} END{exit ok?0:1}'; }

write_profile() { # write_profile <path> <FR|EN|ES>
  uv run --no-project "$REPO_ROOT/tools/sb_installer_helper.py" write-user-profile "$1" \
    --language "$2" --vault-name V --workspace-path W --first-name F --activity A \
    --ai-tools "" --what-matters M --installed-at "2026-09-23T01:00:00-04:00" \
    --os-info o --shell-info s --timezone t --git-version g --claude-detected no --codex-detected no >/dev/null 2>&1
}

# --- (a) the installer records the language ------------------------------------------------
write_profile "$TMP/USER-fr.md" FR
check "(a) sb_installer_helper.py : USER.md porte 'language: fr' au front matter" [ "$(fm_field "$TMP/USER-fr.md" language)" = "fr" ]
PS=""
command -v pwsh >/dev/null 2>&1 && PS=pwsh
[ -z "$PS" ] && command -v powershell.exe >/dev/null 2>&1 && PS=powershell.exe
if [ -n "$PS" ]; then
  QPS="$(sandbox_native_path "$REPO_ROOT/tools/questionnaire.ps1" 2>/dev/null || printf '%s' "$REPO_ROOT/tools/questionnaire.ps1")"
  OUTPS="$(sandbox_native_path "$TMP/USER-ps.md" 2>/dev/null || printf '%s' "$TMP/USER-ps.md")"
  "$PS" -NoProfile -ExecutionPolicy Bypass -Command ". '$QPS'; Write-UserProfile -Path '$OUTPS' -Answers ([pscustomobject]@{language='ES';aiTools=@();firstName='F';activity='A';whatMatters='M';vaultName='V';workspacePath='W'}) -EnvironmentFacts ([pscustomobject]@{OS='o';Shell='s';Timezone='t';Git='g';ClaudeCodeDetected=\$false;CodexDetected=\$false}) -InstalledAt 'now'" >/dev/null 2>&1
  check "(a) Write-UserProfile (PowerShell) : USER.md porte 'language: es'" [ "$(fm_field "$TMP/USER-ps.md" language 2>/dev/null)" = "es" ]
else
  echo "  SKIP - (a) Write-UserProfile : aucun PowerShell sur ce poste"
fi
check "(a) squelette USER.md du depot : cle 'language:' presente" has_field "$REPO_ROOT/USER.md" language

# --- (e) the common prompt -----------------------------------------------------------------------
TPL="$REPO_ROOT/templates/session-opening-prompt-template.md"
# Mission 244 (finding 10): the fixed sentence now also gives a first message
# without language (the path alone) the recorded language.
FIXED="Speak to the Owner in the language they write in, from your first line; a first message that carries no language (the project's path alone) gets the language the PILOT-PROMPT records, which is also the language of the files you deposit."
block() { tr -d '\r' < "$1" | sed -n '/<!-- PROMPT:BEGIN -->/,/<!-- PROMPT:END -->/p'; }
prompt_ok() { block "$1" | grep -qF -- "$FIXED" && [ "$(block "$1" | grep -o '{{[A-Z_]*}}' | sort -u | paste -sd' ' -)" = "{{VAULT_SHORT_ID}}" ]; }
check "(e) prompt commun : phrase fixe presente, {{VAULT_SHORT_ID}} seule variable" prompt_ok "$TPL"
sed 's/from your first line;/from your first line in {{LANGUAGE}};/' "$TPL" > "$TMP/tpl-witness.md"
if prompt_ok "$TMP/tpl-witness.md"; then
  fail "(h) temoin : un gabarit a deux variables passe (e)"
else
  pass "(h) temoin : un gabarit a deux variables echoue (e)"
fi

# --- (f) catalogues --------------------------------------------------------------------------------
for l in fr en es; do
  C="$REPO_ROOT/i18n/catalog.$l.json"
  check "(f) catalog.$l.json : cles languageSet et languageUnset" sh -c "grep -q '\"projectBootstrap.pilotPrompt.languageSet\": \"[^\"]' '$C' && grep -q '\"projectBootstrap.pilotPrompt.languageUnset\": \"[^\"]' '$C'"
done

# --- (b), (c), (d), (g): the bootstrap in a throwaway Vault -----------------------------------------
WS="$TMP/ws"; V="$WS/second-brain"
mkdir -p "$WS"
sandbox_vault "$REPO_ROOT" "$V" || { echo "FAIL : Vault jetable non construit"; exit 1; }
bash "$V/tools/write-marker.sh" --marker-only "$WS" >/dev/null || { echo "FAIL : marqueur"; exit 1; }
BOOT="$V/tools/project-bootstrap.sh"
SENT_FR="$(sed -n 's/^  "projectBootstrap.pilotPrompt.languageSet": "\([^{]*\).*/\1/p' "$REPO_ROOT/i18n/catalog.fr.json")"
SENT_UNSET_EN="$(sed -n 's/^  "projectBootstrap.pilotPrompt.languageUnset": "\(.\{20\}\).*/\1/p' "$REPO_ROOT/i18n/catalog.en.json")"

# (c) first, on the skeleton USER.md (no language recorded)
bash "$BOOT" create "$WS/nolang" "Nolang" --vcs none >"$TMP/c.out" 2>&1
PP="$WS/nolang/state/PILOT-PROMPT.md"
check "(c) sans langue : champ 'language' present et vide" sh -c "tr -d '\r' < '$PP' | grep -qx 'language: \"\"'"
check "(c) sans langue : phrase 'langue des messages de l'Owner', jamais l'anglais enregistre" \
  sh -c "[ -n '$SENT_UNSET_EN' ] && grep -qF '$SENT_UNSET_EN' '$PP' && ! tr -d '\r' < '$PP' | grep -qx 'language: \"en\"'"

# (d) explicit language from the caller
bash "$BOOT" create "$WS/esp" "Esp" --vcs none --lang ES >"$TMP/d.out" 2>&1
check "(d) sans langue dans USER.md, --lang ES explicite : language es" sh -c "tr -d '\r' < '$WS/esp/state/PILOT-PROMPT.md' | grep -qx 'language: \"es\"'"
check "(d) --lang ES : CLAUDE.md du projet redige en espagnol, sans consigne francaise" \
  sh -c "grep -q 'Redactar en español' '$WS/esp/CLAUDE.md' && ! grep -q 'Rédiger en français' '$WS/esp/CLAUDE.md'"

# (b) the installer's USER.md in fr
write_profile "$V/USER.md" FR
bash "$BOOT" create "$WS/fra" "Fra" --vcs none >"$TMP/b.out" 2>&1
PP="$WS/fra/state/PILOT-PROMPT.md"
check "(b) USER.md fr : language \"fr\" et phrase francaise dans le PILOT-PROMPT" \
  sh -c "tr -d '\r' < '$PP' | grep -qx 'language: \"fr\"' && [ -n '$SENT_FR' ] && grep -qF '$SENT_FR' '$PP'"
check "(b) USER.md fr : CLAUDE.md du projet redige en francais" grep -q "Rédiger en français" "$WS/fra/CLAUDE.md"

# (g) prompt regenerates the language of an existing project
bash "$BOOT" prompt "$WS/nolang" >"$TMP/g.out" 2>&1
check "(g) prompt : le PILOT-PROMPT regenere porte la langue de USER.md (fr)" sh -c "tr -d '\r' < '$WS/nolang/state/PILOT-PROMPT.md' | grep -qx 'language: \"fr\"'"

# (i) a USER.md written by Windows PowerShell 5.1 starts with a UTF-8 BOM: still read
{ printf '\357\273\277'; tr -d '\r' < "$V/USER.md" | sed 's/^language: fr$/language: es/'; } > "$TMP/USER-bom.md"
cp "$TMP/USER-bom.md" "$V/USER.md"
bash "$BOOT" prompt "$WS/nolang" >"$TMP/i.out" 2>&1
check "(i) USER.md avec BOM (PowerShell 5.1) : langue lue (es)" sh -c "tr -d '\r' < '$WS/nolang/state/PILOT-PROMPT.md' | grep -qx 'language: \"es\"'"

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== RESULT: PASS ($PASSES PASS) ==="
  exit 0
fi
echo "=== RESULT: FAIL ($FAILURES FAIL, $PASSES PASS) ==="
exit 1
