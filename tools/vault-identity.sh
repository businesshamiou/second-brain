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
#   vault-identity.sh get <key> [<vault-root>] vault_id | vault_origin | vault_ref
# usage (source):
#   . tools/vault-identity.sh
#   vid_ensure "$VAULT_ROOT" ; vid_get "$VAULT_ROOT" vault_id ; vid_ref "$VAULT_ROOT"
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

# vid_ensure <root>: generates the identity if the file is missing, still at
# the skeleton, or without vault_id. Never rewrites a generated identity.
vid_ensure() {
  local root="$1" f status id origin created
  f="$(vid_file "$root")"
  status="$(vid_get "$root" status)"
  id="$(vid_get "$root" vault_id)"
  if [ "$status" = "generated" ] && [ -n "$id" ]; then
    return 0
  fi
  id="$(vid_new_id)"
  origin="$(vid_origin_detect "$root")"
  created="$(date +"%Y-%m-%dT%H:%M:%S%z")"
  cat > "$f" <<EOF
---
type: vault-identity
title: "Identité de ce Vault"
description: "Identité générée à l'installation : un projet vérifie qu'il parle au bon Vault en comparant vault_id à son acte de naissance."
status: generated
vault_id: "$id"
vault_origin: "$origin"
created_at: "$created"
---

# IDENTITÉ DE CE VAULT

Ce fichier est généré une fois, à l'installation, par \`tools/vault-identity.sh ensure\`. Il n'est jamais édité à la main.

- \`vault_id\` : identifiant de ce Vault, recopié dans l'acte de naissance de chaque projet (\`.pre-commit-config.yaml\`).
- \`vault_origin\` : origine du clone.

Un projet dont l'acte nomme un autre \`vault_id\` est refusé par la résolution (\`tools/resolve-vault.sh\`), qui nomme les deux identités.

## Liens

- \`see also\` — [Décision — Initiation et adoption de projet, acte de naissance](./decisions/DECISION-2026-09-17-000545-project-initiation-birth-certificate-embedded-mcp-pilot-prompt.md)
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
    get)
      [ -n "${2:-}" ] || { echo "usage: vault-identity.sh get <cle> [<racine-du-vault>]" >&2; exit 1; }
      if [ "$2" = "vault_ref" ]; then
        vid_ref "${3:-$VID_SELF_ROOT}"
      else
        vid_get "${3:-$VID_SELF_ROOT}" "$2"
      fi
      ;;
    *)
      echo "usage: vault-identity.sh ensure|get <cle> [<racine-du-vault>]" >&2
      exit 1
      ;;
  esac
fi
