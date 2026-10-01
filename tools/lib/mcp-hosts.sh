#!/usr/bin/env bash
# The hosts of the Vault's MCP server (Mission 242, rule on model-agnostic Pilot
# and Executor hosts): one table, read by tools/install-vault-mcp.sh (which
# writes), tools/check-mcp-containment.sh (which reads) and `sb` (doctor,
# pilot-prompt --host). To be sourced; defines functions, changes nothing on its
# own, writes nothing.
#
#   . "<Vault>/tools/lib/mcp-hosts.sh"
#   mcp_hosts           # one line per host configuration, tab-separated:
#                       #   <id> <name> <format> <config path> <present 1|0>
#   mcp_hosts --native  # the same, config paths in the native form (C:\...
#                       #   under Git Bash, cygpath -w), for a Windows program
#   mcp_desktop_running / mcp_desktop_stop  # the Claude desktop application
#                       #   while it runs (Mission 244): see below
#   mcp_desktop_config / mcp_desktop_claude_bin  # the application as an
#                       #   Executor host, its Code tab (Mission 245): see below
#
# A host is PRESENT when its configuration folder exists or its command is on
# the PATH -- measured, never assumed. Formats:
#   claude-cli   `claude mcp add -s user` writes ~/.claude.json (Claude Code)
#   codex-cli    `codex mcp add` writes ~/.codex/config.toml (Codex CLI and app)
#   json         a JSON file whose key `mcpServers` maps a name to
#                {"command", "args"} (Claude Desktop, Gemini CLI, Windsurf,
#                Cline CLI, LM Studio)
#   json-stdio   the same, with "type": "stdio" (Cursor)
# Sources, read on 2026-09-28 (the rule's host matrix cites them): Gemini CLI
# google-gemini.github.io/gemini-cli/docs/tools/mcp-server.html; Cursor
# cursor.com/docs/mcp; Windsurf github.com/github/github-mcp-server
# docs/installation-guides/install-windsurf.md; Cline docs.cline.bot/mcp/
# configuring-mcp-servers (the CLI's ~/.cline/mcp.json; the VS Code extension
# edits its own file through its interface); LM Studio lmstudio.ai/blog/
# lmstudio-v0.3.17. Jan is configured through its interface only: not listed.

mcp_hosts__unix() {
  if command -v cygpath >/dev/null 2>&1; then cygpath -u "$1"; else printf '%s\n' "$1"; fi
}

mcp_hosts__row() { # <id> <name> <format> <config> <folder> <command>
  local present=0
  if { [ -n "$5" ] && [ -d "$5" ]; } || { [ -n "$6" ] && command -v "$6" >/dev/null 2>&1; }; then present=1; fi
  printf '%s\t%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" "$present"
}

# The Claude desktop application's configuration folders (the same measurement
# as tools/install-vault-mcp.sh): present only when the folder exists.
mcp_hosts__desktop_dirs() {
  local d
  case "$(uname -s 2>/dev/null)" in
    Darwin) d="$HOME/Library/Application Support/Claude"; [ -d "$d" ] && printf '%s\n' "$d" ;;
    MINGW*|MSYS*|CYGWIN*)
      if [ -n "${APPDATA:-}" ]; then
        d="$(mcp_hosts__unix "$APPDATA")/Claude"; [ -d "$d" ] && printf '%s\n' "$d"
      fi
      if [ -n "${LOCALAPPDATA:-}" ]; then
        for d in "$(mcp_hosts__unix "$LOCALAPPDATA")"/Packages/Claude_*/LocalCache/Roaming/Claude; do
          [ -d "$d" ] && printf '%s\n' "$d"
        done
      fi
      ;;
    *) d="${XDG_CONFIG_HOME:-$HOME/.config}/Claude"; [ -d "$d" ] && printf '%s\n' "$d" ;;
  esac
  return 0
}

mcp_hosts() {
  if [ "${1:-}" = "--native" ] && command -v cygpath >/dev/null 2>&1; then
    local h_id h_name h_fmt h_cfg h_present
    mcp_hosts | while IFS="$(printf '	')" read -r h_id h_name h_fmt h_cfg h_present; do
      [ "$h_cfg" = "-" ] || h_cfg="$(cygpath -w "$h_cfg")"
      printf '%s	%s	%s	%s	%s
' "$h_id" "$h_name" "$h_fmt" "$h_cfg" "$h_present"
    done
    return 0
  fi
  local d found=0
  while IFS= read -r d; do
    [ -n "$d" ] || continue
    found=1
    printf '%s\t%s\t%s\t%s\t%s\n' claude-desktop "Claude Desktop" json "$d/claude_desktop_config.json" 1
  done <<MCP_HOSTS_EOF
$(mcp_hosts__desktop_dirs)
MCP_HOSTS_EOF
  [ "$found" = 1 ] || printf '%s\t%s\t%s\t%s\t%s\n' claude-desktop "Claude Desktop" json "-" 0
  mcp_hosts__row claude-code "Claude Code" claude-cli "$HOME/.claude.json" "" claude
  mcp_hosts__row codex "Codex" codex-cli "${CODEX_HOME:-$HOME/.codex}/config.toml" "" codex
  mcp_hosts__row gemini "Gemini CLI" json "$HOME/.gemini/settings.json" "$HOME/.gemini" gemini
  mcp_hosts__row cursor "Cursor" json-stdio "$HOME/.cursor/mcp.json" "$HOME/.cursor" cursor
  mcp_hosts__row windsurf "Windsurf" json "$HOME/.codeium/windsurf/mcp_config.json" "$HOME/.codeium/windsurf" windsurf
  mcp_hosts__row cline "Cline (CLI)" json "$HOME/.cline/mcp.json" "$HOME/.cline" cline
  mcp_hosts__row lmstudio "LM Studio" json "$HOME/.lmstudio/mcp.json" "$HOME/.lmstudio" lms
}

# --- The Claude desktop application while it runs (Mission 244, capture 121525
# finding 12) ---------------------------------------------------------------------
# Closing its window does not stop it (Windows: it stays in the background); it
# then rewrites claude_desktop_config.json from memory -- the `mcpServers`
# section written meanwhile was measured gone -- and loads a new server only
# once it has been ENDED and reopened. So the writer asks before writing, and
# says the exact gesture otherwise.
#
#   mcp_desktop_running         # one line per process of the application,
#                               #   `<pid><TAB><path>`; nothing when none
#   mcp_desktop_stop <pid>...   # ends those processes; 0 when done
#
# The application is told by its PATH, never by the name alone: Claude Code
# runs as `claude.exe` too (measured 2026-09-30: `%APPDATA%\Claude\claude-code\
# <version>\claude.exe` next to `C:\Program Files\WindowsApps\Claude_*\app\
# Claude.exe`), and ending it would end the agent's own session.
# Tests only: SB_TEST_PROCESS_LIST names a file of `<pid><TAB><path>` lines read
# instead of the system's list; SB_TEST_PROCESS_STOP_LOG receives `stop <pid>`
# lines instead of ending anything -- a test never touches a real process.
mcp_desktop__is_app() {
  case "$1" in
    *[Cc]laude-code*|*[Cc]laude-[Cc]ode*) return 1 ;;
    *WindowsApps*[\\/]Claude_*|*AnthropicClaude*|*/Claude.app/*|*claude-desktop*|*Claude-Desktop*) return 0 ;;
  esac
  return 1
}

mcp_desktop_running() {
  local list pid path
  if [ -n "${SB_TEST_PROCESS_LIST:-}" ]; then
    list="$(cat "$SB_TEST_PROCESS_LIST" 2>/dev/null)"
  else
    case "$(uname -s 2>/dev/null)" in
      MINGW*|MSYS*|CYGWIN*)
        command -v powershell.exe >/dev/null 2>&1 || return 0
        list="$(powershell.exe -NoProfile -NonInteractive -Command \
          'Get-Process -Name claude -ErrorAction SilentlyContinue | ForEach-Object { "{0}`t{1}" -f $_.Id, $_.Path }' 2>/dev/null | tr -d '\r')"
        ;;
      Darwin) list="$(ps -axo pid=,comm= 2>/dev/null | awk '{ p = $1; $1 = ""; sub(/^ /, ""); print p "\t" $0 }')" ;;
      *) list="$(ps -eo pid=,args= 2>/dev/null | awk '{ p = $1; $1 = ""; sub(/^ /, ""); print p "\t" $0 }')" ;;
    esac
  fi
  printf '%s\n' "$list" | while IFS="$(printf '\t')" read -r pid path; do
    [ -n "$pid" ] && mcp_desktop__is_app "$path" && printf '%s\t%s\n' "$pid" "$path"
  done
  return 0
}

mcp_desktop_stop() {
  local pid
  [ $# -gt 0 ] || return 0
  if [ -n "${SB_TEST_PROCESS_STOP_LOG:-}" ]; then
    for pid in "$@"; do printf 'stop %s\n' "$pid" >> "$SB_TEST_PROCESS_STOP_LOG"; done
    return 0
  fi
  if [ -n "${SB_TEST_PROCESS_LIST:-}" ]; then
    return 1  # a simulated list is never stopped for real
  fi
  case "$(uname -s 2>/dev/null)" in
    MINGW*|MSYS*|CYGWIN*)
      powershell.exe -NoProfile -NonInteractive -Command "Stop-Process -Id $(printf '%s,' "$@" | sed 's/,$//') -Force -ErrorAction SilentlyContinue" >/dev/null 2>&1
      ;;
    Darwin) osascript -e 'quit app "Claude"' >/dev/null 2>&1 || kill "$@" 2>/dev/null ;;
    *) kill "$@" 2>/dev/null ;;
  esac
  sleep 2
  return 0
}

# --- The Claude desktop application as an Executor host (Mission 245, capture
# 105405 finding A1) ------------------------------------------------------------
# The application includes Claude Code in its Code tab (code.claude.com/docs/en/
# desktop-quickstart): a client who has only the application already has an
# agent with a shell, without the `claude` command on the PATH. It is told by
# its configuration file, claude_desktop_config.json, in one of the folders
# above. The application also carries its own Claude Code, under
# `<folder>/claude-code/<version>/` (measured 2026-10-01: %APPDATA%\Claude\
# claude-code\2.1.284\claude.exe answers `--version` and `plugin --help`, and
# the Code tab reads the same ~/.claude/plugins as the command line).
#
#   mcp_desktop_config [--native]      # the application's configuration file,
#                                      #   one line per folder where it exists
#   mcp_desktop_claude_bin [--native]  # the application's own Claude Code, its
#                                      #   newest version; nothing when none
mcp_desktop__out() { # <--native|""> <path>
  if [ "$1" = "--native" ] && command -v cygpath >/dev/null 2>&1; then cygpath -w "$2"; else printf '%s\n' "$2"; fi
}

mcp_desktop_config() {
  local d
  while IFS= read -r d; do
    [ -n "$d" ] && [ -f "$d/claude_desktop_config.json" ] && mcp_desktop__out "${1:-}" "$d/claude_desktop_config.json"
  done <<MCP_DESKTOP_EOF
$(mcp_hosts__desktop_dirs)
MCP_DESKTOP_EOF
  return 0
}

mcp_desktop_claude_bin() {
  local d v bin=""
  while IFS= read -r d; do
    { [ -n "$d" ] && [ -d "$d/claude-code" ]; } || continue
    for v in $(ls -1 "$d/claude-code" 2>/dev/null | sort -V 2>/dev/null); do
      if [ -f "$d/claude-code/$v/claude.exe" ]; then bin="$d/claude-code/$v/claude.exe"
      elif [ -f "$d/claude-code/$v/claude" ]; then bin="$d/claude-code/$v/claude"
      fi
    done
  done <<MCP_DESKTOP_EOF
$(mcp_hosts__desktop_dirs)
MCP_DESKTOP_EOF
  [ -n "$bin" ] && mcp_desktop__out "${1:-}" "$bin"
  return 0
}

# mcp_tool_name_length <server>: the longest name a host may show the model for
# this server's tools under the `mcp__<server>__<tool>` form (Claude, Codex),
# the longest tool being list_allowed_directories (24 characters, measured by
# tools/list, Mission 242). The Gemini API caps a function name at 64.
MCP_TOOL_NAME_MAX=64
MCP_LONGEST_TOOL="list_allowed_directories"
mcp_tool_name_length() {
  printf '%s' "mcp__$1__$MCP_LONGEST_TOOL" | wc -c | tr -d ' '
}
