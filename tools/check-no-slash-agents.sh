#!/usr/bin/env bash
# Refuses any mention, in the tracked documentation of this repository, of the
# Claude Code command `/agents`. Fixed in audit defect 4 (Mission
# 171-C01, step 9): the Vault's doctrine is to call the assistant by
# naming it ("demande a Brian : ..." ["ask Brian: ..."]) rather than by this command, which has
# no meaning outside the Claude Code tool itself. This guardian prevents a
# future edit from reintroducing it without noticing.
#
# Perimeter: all *.md files tracked by Git (git ls-files), including
# skills-warehouse/ and skills/external/ -- a mention of this command there
# would be just as wrong. This script and its non-regression test are
# excluded from the sweep (same reason as in check-private-patterns.sh: they cite
# the pattern in clear to define and test it).
#
# Distinction from a legitimate file path (e.g.
# `skills/external/ask-matt/agents/openai.yaml`, a FOLDER named "agents"):
# a real mention of the command is never followed by another "/" -- it is
# the only criterion kept, measured on the real corpus (no "agents" folder
# followed by anything other than a "/" in this repository).
#
# usage: tools/check-no-slash-agents.sh
# exit 0 if 0 occurrences outside the exception; exit 1 otherwise, cause printed.

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "REFUS : hors d'un depot Git : gardien non executable." >&2
  exit 1
}

# Same self-exclusion principle as check-private-patterns.sh: the
# definition/test pair cites the pattern in clear, never a real delivered document.
EXCLUDE_PATHSPECS=(
  ":(exclude)tools/check-no-slash-agents.sh"
  ":(exclude)tests/test-check-no-slash-agents.sh"
)

# `/agents` followed by a character that is neither a word character nor a "/" (space, end of
# line, backtick, punctuation): covers the bare invocation and its use between
# backticks; excludes the path segment `.../agents/<file>`.
PATTERN='/agents([^A-Za-z0-9_/]|$)'

# Case-sensitive by design: the Claude Code command is written in lower case
# ("/agents"), distinct from the file `AGENTS.md` (upper case) cited everywhere as a
# link -- a case-insensitive sweep would confuse the two (measured on
# this repository: the first version of this script wrongly refused on `./AGENTS.md`).
HITS="$(git -C "$REPO_ROOT" grep -In --no-color -E -- "$PATTERN" -- '*.md' "${EXCLUDE_PATHSPECS[@]}" 2>/dev/null || true)"

if [ -n "$HITS" ]; then
  echo "REFUS : mention de la commande Claude Code '/agents' trouvee dans la documentation :" >&2
  printf '%s\n' "$HITS" >&2
  echo "Remede : remplacer par la facon d'appeler l'assistant en le nommant, avec un exemple (ex. \"demande a Brian : ...\")." >&2
  exit 1
fi

echo "PASS : 0 mention de '/agents' dans la documentation suivie."
exit 0
