#!/usr/bin/env bash
# Controle de liens sur les fichiers .md stages.
# Shell portable : aucune dependance a Python, meme structure que check-secrets.sh.
# Le refus est la position par defaut : toute condition anormale bloque.
#
# (build history) : le balayage de liens (regles 2/3 ci-dessous) reconnait la
# couche dans laquelle il lit -- un exemple pedagogique a l'interieur d'un
# bloc de code cloture (``` ou ~~~) ou d'un span de code inline (backticks
# apparies, meme imbrique comme un span `` `x` `` a deux niveaux) n'est plus
# balaye comme un lien reel. Additif seulement : la regle 1 (section
# "## Liens" obligatoire, juste en dessous) garde son mecanisme exact,
# inchange, et n'est pas affaiblie.

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/relpath.sh"

# Garde Git (Mission 125, meme raison qu'a check-secrets.sh) : refus
# explicite hors d'un depot, plutot qu'un $VAULT_ROOT vide qui rendrait un
# faux PASS silencieux plus loin.
VAULT_ROOT="$(git rev-parse --show-toplevel)" || {
  echo "REFUS : hors d'un depot Git : gardien non executable." >&2
  exit 1
}
# Racine du workspace (parent du depot courant) : sert a identifier le depot
# cible d'un lien sortant (DECISION-2026-09-02-005041) -- ../../<depot>/...
WORKSPACE_ROOT="$(dirname "$VAULT_ROOT")"

STAGED="$(git diff --cached --name-only --diff-filter=AM -- '*.md' || true)"

if [ -z "$STAGED" ]; then
  exit 0
fi

# Retire tout span de code inline d'une ligne avant le balayage de liens :
# backticks apparies par longueur de delimiteur egale (regle CommonMark des
# spans de code), un run non apparie est laisse tel quel (texte litteral).
strip_inline_code() {
  awk '
    {
      s = $0
      out = ""
      n = length(s)
      i = 1
      while (i <= n) {
        c = substr(s, i, 1)
        if (c == "`") {
          run = 0
          j = i
          while (j <= n && substr(s, j, 1) == "`") { run++; j++ }
          k = j
          found = 0
          while (k <= n) {
            if (substr(s, k, 1) == "`") {
              crun = 0
              m = k
              while (m <= n && substr(s, m, 1) == "`") { crun++; m++ }
              if (crun == run) { found = 1; endk = m; break }
              k = m
            } else {
              k++
            }
          }
          if (found) {
            out = out " "
            i = endk
          } else {
            out = out substr(s, i, run)
            i = j
          }
        } else {
          out = out c
          i++
        }
      }
      print out
    }
  '
}

BLOCK=0

while IFS= read -r file; do
  [ -z "$file" ] && continue
  case "$file" in
    graphify-out/*) continue ;;
  esac

  FULLPATH="$VAULT_ROOT/$file"
  [ -f "$FULLPATH" ] || continue

  DIR="$(dirname "$FULLPATH")"

  # --- 1. Section "## Liens" obligatoire -- bornee au corpus documentaire,
  # jamais au materiel adopte de skills/external/ (corps verbatim garanti
  # par empreintes, hors du graphe de citations du corpus). La resolution
  # des liens (regles 2/3 ci-dessous) reste globale, external/ compris.
  # DECISION-2026-08-28-203627. skills-warehouse/ ajoute (Mission 168,
  # arbitrage Owner 2026-09-11, option b -- meme principe que
  # DECISION-203627 : sous-arbre adopte tel quel, T24, ses propres standards
  # de provenance en tiennent lieu, jamais la convention de liens du Vault). ---
  case "$file" in
    skills/external/*|skills-warehouse/*) : ;;
    *)
      if ! grep -qE '^## Liens[[:space:]]*$' "$FULLPATH"; then
        echo "LIENS: section manquante: $file" >&2
        BLOCK=1
      fi
      ;;
  esac

  # --- 2/3. Liens relatifs : cible resolue, ou avertissement si aucun lien interne ---
  HAS_INTERNAL=0
  LINE_NO=0
  IN_FENCE=0

  while IFS= read -r line || [ -n "$line" ]; do
    LINE_NO=$((LINE_NO + 1))

    # --- couche : bloc de code cloture (Mission 060) -- retire l'indentation
    # eventuelle par expansion de parametre bash pure (aucun sous-processus,
    # contrairement a `sed` : le cout par ligne doit rester nul pour les gros
    # fichiers) avant de tester le delimiteur de cloture ---
    LTRIM="${line#"${line%%[![:space:]]*}"}"
    case "$LTRIM" in
      '```'*|'~~~'*)
        if [ "$IN_FENCE" -eq 1 ]; then IN_FENCE=0; else IN_FENCE=1; fi
        continue
        ;;
    esac
    if [ "$IN_FENCE" -eq 1 ]; then
      continue
    fi

    # Filtre rapide sur la ligne brute, identique au comportement d'avant
    # la Mission 060 : evite de payer le cout d'un sous-processus awk par
    # ligne (strip_inline_code) pour l'immense majorite des lignes qui ne
    # contiennent aucune sous-chaine candidate -- la performance sur les
    # gros fichiers ne doit pas se degrader.
    case "$line" in
      *'](./'*|*'](../'*) : ;;
      *) continue ;;
    esac

    # --- couche : code inline (Mission 060) -- le balayage qui suit porte
    # sur SCAN_LINE (spans de code retires), jamais sur $line brute. Seules
    # les lignes qui ont deja passe le filtre rapide ci-dessus paient ce
    # cout. ---
    SCAN_LINE="$(printf '%s' "$line" | strip_inline_code)"

    case "$SCAN_LINE" in
      *'](./'*|*'](../'*) : ;;
      *) continue ;;
    esac

    # Note (DECISION-2026-09-02-005041) : la mention "(hors <depot>)" est
    # pour le lecteur seulement ; le gardien decide desormais par le chemin
    # resolu (interne au depot courant, ou sortant vers un depot frere),
    # jamais par la presence ou l'absence de cette mention sur la ligne.

    TARGETS="$(printf '%s' "$SCAN_LINE" | grep -oE '\]\(\.{1,2}/[^)]*\)' | sed -E 's/^\]\((.*)\)$/\1/')"
    [ -z "$TARGETS" ] && continue

    while IFS= read -r TARGET; do
      [ -z "$TARGET" ] && continue
      case "$TARGET" in
        *.md) : ;;
        *) continue ;;
      esac

      TARGET_PATH="$DIR/$TARGET"
      RESOLVED="$(abs_path "$TARGET_PATH")"

      if [ -z "$RESOLVED" ]; then
        echo "LIENS: cible introuvable: $file:$LINE_NO -> $TARGET" >&2
        BLOCK=1
        continue
      fi

      case "$RESOLVED" in
        "$VAULT_ROOT"/*)
          # --- lien interne au depot courant : comportement inchange,
          # absente = refus. ---
          if [ -f "$RESOLVED" ]; then
            HAS_INTERNAL=1
          else
            echo "LIENS: cible introuvable: $file:$LINE_NO -> $TARGET" >&2
            BLOCK=1
          fi
          ;;
        *)
          # --- lien sortant (DECISION-2026-09-02-005041) : controle plein
          # seulement si le depot cible (premier segment sous la racine du
          # workspace) est present sur disque ; sinon avertissement, jamais
          # de refus -- morts par construction dans un paquet autonome. ---
          REL_TO_WS="${RESOLVED#"$WORKSPACE_ROOT"/}"
          if [ "$REL_TO_WS" = "$RESOLVED" ]; then
            echo "LIENS: avertissement (depot cible non determinable depuis l'espace de travail, lien non verifie) : $file:$LINE_NO -> $TARGET" >&2
          else
            TARGET_REPO_NAME="${REL_TO_WS%%/*}"
            TARGET_REPO_ROOT="$WORKSPACE_ROOT/$TARGET_REPO_NAME"
            if [ -d "$TARGET_REPO_ROOT" ]; then
              if [ -f "$RESOLVED" ]; then
                HAS_INTERNAL=1
              else
                echo "LIENS: cible introuvable: $file:$LINE_NO -> $TARGET" >&2
                BLOCK=1
              fi
            else
              echo "LIENS: avertissement (depot cible absent du disque, lien non verifie) : $file:$LINE_NO -> $TARGET" >&2
            fi
          fi
          ;;
      esac
    done <<TARGETS_EOF
$TARGETS
TARGETS_EOF
  done < "$FULLPATH"

  if [ "$HAS_INTERNAL" -eq 0 ]; then
    echo "LIENS: avertissement, aucun lien interne: $file" >&2
  fi
done <<STAGED_EOF
$STAGED
STAGED_EOF

if [ "$BLOCK" -ne 0 ]; then
  exit 1
fi

exit 0
