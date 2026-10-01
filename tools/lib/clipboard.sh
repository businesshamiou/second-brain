#!/usr/bin/env bash
# The clipboard (Mission 244, findings 27 and 28): a Pilot block copied from a
# terminal's output is cut at its long lines, and a fresh Windows (the Sandbox)
# has no Notepad. The tool puts the block on the clipboard itself; the Owner
# pastes it (Ctrl+V). One access function, read by tools/project-bootstrap.sh
# and `sb` (pilot-prompt, the installer's last screen). To be sourced; defines
# functions, changes nothing on its own.
#
#   . "<Vault>/tools/lib/clipboard.sh"
#   sb_clipboard_copy <file>   # 0 copied, 1 no clipboard tool on this machine
#
# Order: SB_CLIPBOARD_FILE (tests: the file receives the bytes, the real
# clipboard is never touched); Windows (Git Bash): PowerShell Set-Clipboard on
# the file read as UTF-8 -- never clip.exe, which garbles accents; macOS:
# pbcopy; Linux: wl-copy, else xclip. The caller decides WHEN to copy (a
# terminal, or an explicit --copy): a test that captures the output never
# reaches the real clipboard.
#
# bash 3.2, POSIX tools only.

sb_clipboard_copy() {
  local f="$1" native
  [ -f "$f" ] || return 1
  if [ -n "${SB_CLIPBOARD_FILE:-}" ]; then
    cat "$f" > "$SB_CLIPBOARD_FILE" || return 1
    return 0
  fi
  case "$(uname -s 2>/dev/null)" in
    MINGW*|MSYS*|CYGWIN*)
      command -v powershell.exe >/dev/null 2>&1 || return 1
      native="$f"
      command -v cygpath >/dev/null 2>&1 && native="$(cygpath -w "$f")"
      native="$(printf '%s' "$native" | sed "s/'/''/g")"
      powershell.exe -NoProfile -NonInteractive -Command \
        "Set-Clipboard -Value (Get-Content -Raw -Encoding UTF8 -LiteralPath '$native')" >/dev/null 2>&1
      return $?
      ;;
    Darwin)
      command -v pbcopy >/dev/null 2>&1 || return 1
      pbcopy < "$f"
      return $?
      ;;
    *)
      if command -v wl-copy >/dev/null 2>&1; then
        wl-copy < "$f"
        return $?
      fi
      if command -v xclip >/dev/null 2>&1; then
        xclip -selection clipboard < "$f"
        return $?
      fi
      return 1
      ;;
  esac
}
