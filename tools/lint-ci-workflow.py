#!/usr/bin/env python3
"""Structural YAML/GitHub Actions lint, standard library only.

Mission 168, ticket 10: `actionlint` and `shellcheck` are absent from this
machine (measured, Mission 168 report S13) -- the fallback the ticket itself
prescribes is "analyse YAML par uv run + bibliotheque standard", not a
third-party YAML parser (PyYAML is not in the standard library, and pulling
it in as a dependency would defeat the point of the fallback). This script
is that fallback: an indentation-based structural check plus a handful of
GitHub Actions-specific shape checks, run via `uv run` (no project, no
dependency) so it needs nothing beyond CPython itself.

It is deliberately NOT a full YAML 1.2 parser -- it catches the error
classes that actually matter for a hand-written workflow file (tabs,
ragged/inconsistent dedents, unbalanced quotes and brackets, duplicate keys
at the same nesting level) and verifies the handful of keys GitHub Actions
itself requires, without claiming to validate the full YAML or Actions
schema. What it does not claim to check: `uses:` action versions, expression
syntax inside `${{ }}`, or anything only the real GitHub Actions parser
enforces.

usage: uv run tools/lint-ci-workflow.py <workflow.yml> [<workflow.yml> ...]
exit 0 if every file passes every check; exit 1 otherwise, one line per
finding on stderr.
"""

from __future__ import annotations

import sys
from pathlib import Path

REQUIRED_TOP_KEYS = {"name", "on", "jobs"}


def strip_comment(line: str) -> str:
    """Remove a trailing `# ...` comment, respecting quoted strings."""
    in_single = False
    in_double = False
    for i, ch in enumerate(line):
        if ch == "'" and not in_double:
            in_single = not in_single
        elif ch == '"' and not in_single:
            in_double = not in_double
        elif ch == "#" and not in_single and not in_double:
            if i == 0 or line[i - 1] in (" ", "\t"):
                return line[:i]
    return line


def leading_spaces(line: str) -> int:
    n = 0
    for ch in line:
        if ch == " ":
            n += 1
        else:
            break
    return n


def check_quotes_and_brackets(path: Path, lines: list[str]) -> list[str]:
    findings = []
    single = 0
    double = 0
    curly = 0
    square = 0
    for lineno, raw in enumerate(lines, start=1):
        content = strip_comment(raw.rstrip("\n"))
        in_single = False
        in_double = False
        for idx, ch in enumerate(content):
            if ch == "'" and not in_double:
                # An apostrophe flanked by word characters on both sides
                # (runner's, ticket's, don't) is English punctuation inside
                # an unquoted plain scalar (a step/job `name:` value, or a
                # comment already stripped above) -- never a YAML
                # single-quote delimiter, which is always bounded by
                # whitespace, punctuation, or another quote. Counting it
                # would flag every possessive/contraction as a broken quote.
                before = content[idx - 1] if idx > 0 else ""
                after = content[idx + 1] if idx + 1 < len(content) else ""
                if before.isalnum() and after.isalnum():
                    continue
                in_single = not in_single
                single += 1
            elif ch == '"' and not in_single:
                in_double = not in_double
                double += 1
            elif ch == "{" and not in_single and not in_double:
                curly += 1
            elif ch == "}" and not in_single and not in_double:
                curly -= 1
            elif ch == "[" and not in_single and not in_double:
                square += 1
            elif ch == "]" and not in_single and not in_double:
                square -= 1
        if curly < 0 or square < 0:
            findings.append(
                f"{path}:{lineno}: unbalanced bracket (closed before opened)"
            )
            curly = max(curly, 0)
            square = max(square, 0)
    if single % 2 != 0:
        findings.append(f"{path}: odd number of single quotes ({single}) in file")
    if double % 2 != 0:
        findings.append(f"{path}: odd number of double quotes ({double}) in file")
    if curly != 0:
        findings.append(f"{path}: unbalanced '{{' / '}}' across file (net {curly})")
    if square != 0:
        findings.append(f"{path}: unbalanced '[' / ']' across file (net {square})")
    return findings


def check_indentation_tree(path: Path, lines: list[str]) -> list[str]:
    """Walk the file as an indentation tree; flag tabs, ragged dedents and
    duplicate mapping keys at the same level under the same parent."""
    findings = []
    # stack entries: (indent, seen_keys_at_this_level)
    stack: list[tuple[int, set[str]]] = [(-1, set())]
    in_block_scalar = False
    block_scalar_indent = -1

    for lineno, raw in enumerate(lines, start=1):
        line = raw.rstrip("\n")
        if "\t" in line:
            findings.append(f"{path}:{lineno}: tab character (YAML forbids tabs for indentation)")

        stripped_for_blank = line.strip()
        if in_block_scalar:
            # A block scalar (| or >) body: any line indented deeper than
            # the scalar's own key stays inside it, no matter what it
            # contains (shell code, '#', ':' and all) -- until a line
            # dedents back to, or past, the scalar key's own indent.
            if stripped_for_blank == "":
                continue
            indent = leading_spaces(line)
            if indent > block_scalar_indent:
                continue
            in_block_scalar = False
            # fall through: this line ends the block scalar, re-process it
            # as ordinary structure below.

        content = strip_comment(line)
        if content.strip() == "":
            continue

        indent = leading_spaces(content)
        body = content[indent:]

        # Pop back to the parent level for this indent.
        while stack and indent < stack[-1][0]:
            stack.pop()
        if not stack or (stack and indent > stack[-1][0] and stack[-1][0] != -1 and indent not in (s[0] for s in stack)):
            pass  # deeper than parent: valid new level, handled below.

        if stack[-1][0] == indent:
            level_keys = stack[-1][1]
        elif indent > stack[-1][0]:
            level_keys = set()
            stack.append((indent, level_keys))
        else:
            # Dedented to a level never seen before at this indent -- ragged.
            findings.append(
                f"{path}:{lineno}: indentation does not match any enclosing level ({indent} spaces)"
            )
            level_keys = set()
            stack.append((indent, level_keys))

        item = body[2:] if body.startswith("- ") else body
        key = None
        if ":" in item:
            candidate = item.split(":", 1)[0].strip()
            if candidate and not candidate.startswith(("'", '"')) and " " not in candidate:
                key = candidate
            elif candidate.startswith(("'", '"')) and len(candidate) >= 2 and candidate[0] == candidate[-1]:
                key = candidate

        if key is not None and not body.startswith("- "):
            if key in level_keys:
                findings.append(f"{path}:{lineno}: duplicate key '{key}' at this level")
            level_keys.add(key)

        value_part = item.split(":", 1)[1].strip() if key is not None and ":" in item else ""
        if value_part in ("|", ">", "|-", ">-", "|+", ">+"):
            in_block_scalar = True
            block_scalar_indent = indent

    return findings


def check_actions_shape(path: Path, text: str, lines: list[str]) -> list[str]:
    findings = []
    top_keys = set()
    for line in lines:
        content = strip_comment(line.rstrip("\n"))
        if content.strip() == "" or content.startswith(" ") or content.startswith("\t"):
            continue
        if ":" in content:
            top_keys.add(content.split(":", 1)[0].strip().strip("'\""))

    missing = REQUIRED_TOP_KEYS - top_keys
    if missing:
        findings.append(f"{path}: missing required top-level key(s): {sorted(missing)}")

    if "jobs:" not in text:
        findings.append(f"{path}: no 'jobs:' block found")
        return findings

    # Rough per-job shape check: every '  <job-id>:' line directly under
    # jobs: should be followed, before the next same-indent sibling, by a
    # 'runs-on:' and a 'steps:' line at one indent level deeper.
    job_indent = None
    i = 0
    n = len(lines)
    while i < n:
        content = strip_comment(lines[i].rstrip("\n"))
        if content.strip() == "jobs:":
            job_indent = leading_spaces(lines[i + 1].rstrip("\n")) if i + 1 < n else None
            break
        i += 1

    if job_indent is None:
        findings.append(f"{path}: 'jobs:' block has no children")
        return findings

    j = i + 1
    while j < n:
        content = strip_comment(lines[j].rstrip("\n"))
        if content.strip() == "":
            j += 1
            continue
        indent = leading_spaces(content)
        if indent < job_indent:
            break
        if indent == job_indent and content.strip().endswith(":"):
            job_name = content.strip()[:-1]
            block_end = j + 1
            while block_end < n:
                c2 = strip_comment(lines[block_end].rstrip("\n"))
                if c2.strip() == "":
                    block_end += 1
                    continue
                if leading_spaces(c2) <= job_indent:
                    break
                block_end += 1
            block = "\n".join(lines[j:block_end])
            if "runs-on:" not in block:
                findings.append(f"{path}: job '{job_name}' has no 'runs-on:'")
            if "steps:" not in block:
                findings.append(f"{path}: job '{job_name}' has no 'steps:'")
            j = block_end
            continue
        j += 1

    return findings


def lint_file(path: Path) -> list[str]:
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines(keepends=True)
    findings: list[str] = []
    findings += check_quotes_and_brackets(path, lines)
    findings += check_indentation_tree(path, lines)
    findings += check_actions_shape(path, text, lines)
    return findings


def main(argv: list[str]) -> int:
    if not argv:
        print("usage: uv run tools/lint-ci-workflow.py <workflow.yml> [...]", file=sys.stderr)
        return 1
    all_findings: list[str] = []
    for arg in argv:
        path = Path(arg)
        if not path.is_file():
            all_findings.append(f"{path}: not a file")
            continue
        all_findings += lint_file(path)
    if all_findings:
        for f in all_findings:
            print(f, file=sys.stderr)
        print(f"REFUS : {len(all_findings)} probleme(s) structurel(s) trouve(s).", file=sys.stderr)
        return 1
    print(f"PASS : {len(argv)} fichier(s) YAML, 0 probleme structurel trouve.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
