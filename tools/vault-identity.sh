#!/usr/bin/env bash
# Identity of the installed Vault (Decision 2026-09-17-000545, A1 and A7).
#
# An installed Vault carries at its root VAULT-IDENTITY.md, generated once and
# tracked by Git like USER.md: `vault_id` (random identifier, never
# derived from the machine) and `vault_origin` (origin of the clone: remote URL, or
# folder path if there is no remote). The distributed repository carries only the
# skeleton (`status: template`, empty values): each installation generates
# its own identity, two Vaults on the same machine are never confused.
#
# usage (execute):
#   vault-identity.sh ensure [<vault-root>]   generates if missing, idempotent
#   vault-identity.sh get <key> [<vault-root>] vault_id | vault_origin | vault_ref | server_name | workspace_label
#   vault-identity.sh set-label <label> [<vault-root>]  poses workspace_label (normalised)
#   vault-identity.sh label-normalize <text>            the normalisation, alone
# usage (source):
#   . tools/vault-identity.sh
#   vid_ensure "$VAULT_ROOT" [label] ; vid_get "$VAULT_ROOT" vault_id ; vid_ref "$VAULT_ROOT"
#
# No dependency on Python: this file is read by the guardians and by the
# Vault resolution, which must run without uv.

VID_FILE_NAME="VAULT-IDENTITY.md"

vid_file() {
  printf '%s/%s\n' "$1" "$VID_FILE_NAME"
}

# vid_get <root> <key>: front matter value, empty if missing. CRLF
# line endings are tolerated (Windows clone with autocrlf).
vid_get() {
  local f
  f="$(vid_file "$1")"
  [ -f "$f" ] || return 0
  tr -d '\r' < "$f" | awk -v k="$2" '
    NR == 1 { if ($0 != "---") exit; next }
    $0 == "---" { exit }
    {
      i = index($0, ":")
      if (i > 0 && substr($0, 1, i - 1) == k) {
        v = substr($0, i + 1)
        sub(/^[ \t]+/, "", v)
        sub(/[ \t]+$/, "", v)
        if (v ~ /^".*"$/) v = substr(v, 2, length(v) - 2)
        print v
        exit
      }
    }'
}

# vid_label_normalize <text>: the workspace label in kebab case (Decision 162812
# A-B, Mission 206): accents folded to their letter (Latin-1 letters, ae, oe, ss),
# lower-cased, every run of characters that is not a-z or 0-9 becomes ONE hyphen,
# no hyphen at either end. `Workspaces` -> `workspaces`, `Mon Espace (2)` ->
# `mon-espace-2`, `ÉTÉ` -> `ete`. Its Python twin is `normalize_label` in
# tools/vault-mcp.py: same cases, same results, tested together. Empty when nothing
# of the text survives.
vid_label_normalize() {
  printf '%s' "$1" | sed \
    -e 's/à\|á\|â\|ã\|ä\|å\|À\|Á\|Â\|Ã\|Ä\|Å/a/g' \
    -e 's/æ\|Æ/ae/g' \
    -e 's/ç\|Ç/c/g' \
    -e 's/è\|é\|ê\|ë\|È\|É\|Ê\|Ë/e/g' \
    -e 's/ì\|í\|î\|ï\|Ì\|Í\|Î\|Ï/i/g' \
    -e 's/ñ\|Ñ/n/g' \
    -e 's/ò\|ó\|ô\|õ\|ö\|Ò\|Ó\|Ô\|Õ\|Ö/o/g' \
    -e 's/œ\|Œ/oe/g' \
    -e 's/ù\|ú\|û\|ü\|Ù\|Ú\|Û\|Ü/u/g' \
    -e 's/ý\|ÿ\|Ý/y/g' \
    -e 's/ß/ss/g' \
  | tr 'A-Z' 'a-z' \
  | sed -e 's/[^a-z0-9][^a-z0-9]*/-/g' -e 's/^-//' -e 's/-$//'
}

# vid_identity_name <root>: the name derived from the IDENTITY alone (Decision 152251
# C, Mission 191-C01): `second-brain-vault-` followed by the first 8 characters of
# vault_id after its `sb-` prefix (the prefix is the same for every Vault and would
# leave only 5 distinguishing characters). Empty (code 1) without a generated identity.
VID_SERVER_PREFIX="second-brain-vault"
vid_identity_name() {
  local id short
  id="$(vid_get "$1" vault_id)"
  [ -n "$id" ] || return 1
  short="${id#sb-}"
  short="$(printf '%s' "$short" | cut -c1-8)"
  [ -n "$short" ] || return 1
  printf '%s-%s\n' "$VID_SERVER_PREFIX" "$short"
}

# vid_server_name <root>: name of THIS Vault's MCP server (Decision 162812 A,
# Mission 206, which amends 152251 C): `second-brain-vault-<workspace_label>` when
# VAULT-IDENTITY.md carries a label (posed by the installer from the workspace
# folder), else the name by identity. The name is what the Owner reads; the identity
# stays what the system checks. Empty (code 1) when the Vault has no generated
# identity: the caller refuses, it never falls back to the fixed name.
vid_server_name() {
  local label
  vid_identity_name "$1" >/dev/null || return 1
  label="$(vid_label_normalize "$(vid_get "$1" workspace_label)")"
  if [ -n "$label" ]; then
    printf '%s-%s\n' "$VID_SERVER_PREFIX" "$label"
    return 0
  fi
  vid_identity_name "$1"
}

# vid_set_label <root> <label>: poses (or replaces) `workspace_label` in the front
# matter of VAULT-IDENTITY.md, the value normalised and quoted. Line endings are kept
# as they are (a CRLF file stays CRLF); the rest of the file is byte for byte.
# vid_ensure never calls it on a label already there: the installer decides.
vid_set_label() {
  local root="$1" label f tmp
  label="$(vid_label_normalize "$2")"
  [ -n "$label" ] || return 1
  f="$(vid_file "$root")"
  [ -f "$f" ] || return 1
  tmp="$(mktemp)" || return 1
  if awk -v lab="$label" '
    { cr = ($0 ~ /\r$/) ? "\r" : ""; line = $0; sub(/\r$/, "", line) }
    NR == 1 { if (line != "---") bad = 1; infm = 1; print $0; next }
    infm && line == "---" { if (!done) print "workspace_label: \"" lab "\"" cr; infm = 0; done = 1; print $0; next }
    infm && index(line, "workspace_label:") == 1 { print "workspace_label: \"" lab "\"" cr; done = 1; next }
    { print $0 }
    END { if (bad || !done) exit 3 }
  ' "$f" > "$tmp"; then
    cat "$tmp" > "$f"
    rm -f "$tmp"
    return 0
  fi
  rm -f "$tmp"
  return 1
}

# vid_ref <root>: current commit of the Vault, "unknown" without Git.
vid_ref() {
  git -C "$1" rev-parse HEAD 2>/dev/null || echo unknown
}

vid_new_id() {
  local hex
  hex="$(od -An -N8 -tx1 /dev/urandom 2>/dev/null | tr -d ' \n')"
  if [ -z "$hex" ]; then
    hex="$(printf '%08x%08x' "$$" "$(date +%s)")"
  fi
  printf 'sb-%s\n' "$hex"
}

vid_origin_detect() {
  local url
  url="$(git -C "$1" remote get-url origin 2>/dev/null || true)"
  if [ -n "$url" ]; then
    printf '%s\n' "$url"
  else
    (cd "$1" && pwd)
  fi
}

# vid_ensure <root> [label]: generates the identity if the file is missing, still at
# the skeleton, or without vault_id, carrying `workspace_label` when a label is given.
# Never rewrites a generated identity; on one that has no label yet, a given label
# is added (the identity itself is untouched).
vid_ensure() {
  local root="$1" f status id origin created label labelline=""
  label="$(vid_label_normalize "${2:-}")"
  f="$(vid_file "$root")"
  status="$(vid_get "$root" status)"
  id="$(vid_get "$root" vault_id)"
  if [ "$status" = "generated" ] && [ -n "$id" ]; then
    if [ -n "$label" ] && [ -z "$(vid_get "$root" workspace_label)" ]; then
      vid_set_label "$root" "$label"
    fi
    return 0
  fi
  id="$(vid_new_id)"
  origin="$(vid_origin_detect "$root")"
  created="$(date +"%Y-%m-%dT%H:%M:%S%z")"
  [ -n "$label" ] && labelline="workspace_label: \"$label\""
  cat > "$f" <<EOF
---
type: vault-identity
title: "Identity of this Vault"
description: "Identity generated at installation: a project checks that it talks to the right Vault by comparing vault_id with its birth certificate."
status: generated
vault_id: "$id"
vault_origin: "$origin"
${labelline:+$labelline
}created_at: "$created"
---

# IDENTITY OF THIS VAULT

This file is generated once, at installation, by \`tools/vault-identity.sh ensure\`. It is never edited by hand.

- \`vault_id\`: identifier of this Vault, copied into the birth certificate of each project (\`.pre-commit-config.yaml\`), and the source of the name of its MCP server.
- \`vault_origin\`: origin of the clone.
- \`workspace_label\` (optional): the normalised name of the workspace folder, posed by \`tools/install-vault-mcp.sh\`; the name of the MCP server is \`second-brain-vault-<workspace_label>\` (the first 8 characters of \`vault_id\` when there is none).

A project whose certificate names another \`vault_id\` is refused by the resolution (\`tools/resolve-vault.sh\`), which names both identities.

## Liens

- \`see also\` — [Decision — Project initiation and adoption, birth certificate](./decisions/DECISION-2026-09-17-000545-project-initiation-birth-certificate-embedded-mcp-pilot-prompt.md)
EOF
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  set -u
  VID_SELF_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
  case "${1:-}" in
    ensure)
      vid_ensure "${2:-$VID_SELF_ROOT}"
      vid_get "${2:-$VID_SELF_ROOT}" vault_id
      ;;
    set-label)
      [ -n "${2:-}" ] || { echo "usage: vault-identity.sh set-label <libelle> [<racine-du-vault>]" >&2; exit 1; }
      vid_set_label "${3:-$VID_SELF_ROOT}" "$2" || { echo "REFUS : libelle non pose (libelle vide ou identite absente)" >&2; exit 1; }
      vid_get "${3:-$VID_SELF_ROOT}" workspace_label
      ;;
    label-normalize)
      printf '%s\n' "$(vid_label_normalize "${2:-}")"
      ;;
    get)
      [ -n "${2:-}" ] || { echo "usage: vault-identity.sh get <cle> [<racine-du-vault>]" >&2; exit 1; }
      if [ "$2" = "vault_ref" ]; then
        vid_ref "${3:-$VID_SELF_ROOT}"
      elif [ "$2" = "server_name" ]; then
        vid_server_name "${3:-$VID_SELF_ROOT}"
      else
        vid_get "${3:-$VID_SELF_ROOT}" "$2"
      fi
      ;;
    *)
      echo "usage: vault-identity.sh ensure|get <cle>|set-label <libelle>|label-normalize <texte> [<racine-du-vault>]" >&2
      exit 1
      ;;
  esac
fi
