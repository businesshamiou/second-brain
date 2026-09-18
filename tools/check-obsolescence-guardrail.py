#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Obsolescence guardrail: reciprocity of `supersedes`/`amends` links and
status of superseded targets, on the .md files staged for this commit only.

(build history) Three refusals, each blocking:
  R1 - missing reciprocity (front-matter <-> ## Liens section, including
       inconsistency between the two)
  R2 - inconsistent status (superseded target still `status: active`,
       except `type: mission` documents, whose status is read as
       deprecated for this signal)
  R3 - unresolved target for a typed relation (closed vocabulary),
       except links suffixed `(hors Vault)`

Traced override: see OVERRIDE_FILENAME below. Refusal is the default
position; any abnormal condition (git root not found, unreadable
front-matter) blocks and is never bypassable by this same mechanism.
"""

from __future__ import annotations

import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

# English-only link vocabulary (build history). French was migrated
# across the whole indexed corpus (documented residue: 7 files with a
# pre-existing dead R3 link, frozen, outside this Mission's repair mandate); any
# French label met from now on is no longer recognised and no longer
# satisfies R1 reciprocity.
KNOWN_LINK_TYPES = {"applies", "supersedes", "amends", "source", "prescribed by", "see also"}
ACTIVE_STATUS_VALUES = {"active", "actif"}
HORS_MARKERS = ("(hors Vault)",)

# Front-matter relation <-> accepted link types <-> accepted inverses
RECIPROCAL_RELATIONS = (
    ("supersedes", ("supersedes",), ("superseded by",)),
    ("amends", ("amends",), ("amended by",)),
)

OVERRIDE_FILENAME = ".obsolescence-guardrail-override"

LIENS_HEADING_RE = re.compile(r"^## Liens\s*$")
LIENS_ENTRY_RE = re.compile(r"^-\s*`([^`]+)`\s*[—-]+\s*\[[^\]]*\]\(([^)]+)\)(.*)$")
# Front-matter keys: letters, digits, hyphen, underscore -- the
# adopted YAML/Agent Skills standard, never the improvised subset that
# rejected any hyphen (DECISION-2026-08-28-193624).
FM_KEY_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_-]*):\s*(.*)$")
FM_LIST_ITEM_RE = re.compile(r"^\s{2}-\s*(.*)$")
# One-level sub-key: same grammar as FM_KEY_RE, two spaces (Mission 107).
FM_DICT_ITEM_RE = re.compile(r"^\s{2}([A-Za-z_][A-Za-z0-9_-]*):\s*(.*)$")
CODE_FENCE_RE = re.compile(r"^\s*(```|~~~)")


@dataclass
class Violation:
    rule: str
    file: str
    message: str

    def render(self) -> str:
        return f"OBSOLESCENCE [{self.rule}] {self.file}: {self.message}"


def _unquote(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
        return value[1:-1]
    return value


def parse_front_matter(text: str):
    """The tool's own front-matter reader: flat key: value, plus
    one-level lists or dictionaries (string -> string pairs) with two
    spaces of indentation. Any other form (mixture, greater
    depth, empty sub-key) makes the front-matter unreadable (None, None):
    refusal is the default position."""
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return {}, text  # no front-matter: this is not an error
    fm: dict[str, object] = {}
    i = 1
    n = len(lines)
    while i < n and lines[i].strip() != "---":
        line = lines[i]
        if not line.strip():
            i += 1
            continue
        m = FM_KEY_RE.match(line)
        if not m:
            return None, None
        key, val = m.group(1), m.group(2).strip()
        if val == "":
            i += 1
            if i < n and FM_LIST_ITEM_RE.match(lines[i]):
                items = []
                while i < n:
                    item_m = FM_LIST_ITEM_RE.match(lines[i])
                    if not item_m:
                        break
                    items.append(_unquote(item_m.group(1)))
                    i += 1
                fm[key] = items
            elif i < n and FM_DICT_ITEM_RE.match(lines[i]):
                sub: dict[str, str] = {}
                while i < n:
                    dict_m = FM_DICT_ITEM_RE.match(lines[i])
                    if not dict_m:
                        break
                    sub_key, sub_val = dict_m.group(1), dict_m.group(2).strip()
                    if sub_val == "":
                        return None, None
                    sub[sub_key] = _unquote(sub_val)
                    i += 1
                fm[key] = sub
            else:
                fm[key] = ""
            continue
        fm[key] = _unquote(val)
        i += 1
    if i >= n:
        return None, None  # block never closed
    body = "\n".join(lines[i + 1 :])
    return fm, body


def _is_full_line_inline_code(stripped: str) -> bool:
    """A line entirely enclosed in a single pair of backticks is
    inline code (teaching example), not analysable prose."""
    return (
        len(stripped) >= 2
        and stripped[0] == "`"
        and stripped[-1] == "`"
        and stripped.count("`") == 2
    )


def extract_liens_entries(body: str):
    """System label != teaching prose (Mission 059, step 3): all
    content inside a fenced code block (``` / ~~~) is ignored,
    whether it is a fake `## Liens` heading or a fake entry; a
    line entirely in inline code (a single backtick span) is
    too. The boundary never cuts a code block opened by a
    section detection along the way."""
    entries = []
    in_section = False
    in_fence = False
    for line in body.splitlines():
        if CODE_FENCE_RE.match(line):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        stripped = line.strip()
        if _is_full_line_inline_code(stripped):
            continue
        if LIENS_HEADING_RE.match(line):
            in_section = True
            continue
        if not in_section:
            continue
        if line.startswith("## "):
            break
        m = LIENS_ENTRY_RE.match(stripped)
        if not m:
            continue
        ltype, path, suffix = m.group(1).strip(), m.group(2).strip(), m.group(3)
        hors = any(marker in suffix for marker in HORS_MARKERS)
        entries.append({"type": ltype, "path": path, "hors": hors})
    return entries


def resolve_target(source_dir: Path, raw_target: str):
    """Purely filesystem resolution: no dependency on a repository
    root. A target in any sibling repository of the same workspace
    (`../../<repo>/…`) resolves here exactly like a local target
    (Mission 059, step 2)."""
    if not raw_target:
        return None
    candidate = (source_dir / raw_target).resolve()
    return candidate if candidate.is_file() else None


def display_path(path: Path, root: Path, workspace_root: Path) -> str:
    """Display path for messages: relative to the repository root
    when the target lives there; otherwise relative to the workspace (prefix `../`) for
    a target of the sibling repository; otherwise absolute path, as a last resort."""
    try:
        return str(path.relative_to(root)).replace("\\", "/")
    except ValueError:
        pass
    try:
        rel = path.relative_to(workspace_root)
        return "../" + str(rel).replace("\\", "/")
    except ValueError:
        return str(path).replace("\\", "/")


def _fm_targets(fm: dict, field: str):
    raw = fm.get(field)
    if isinstance(raw, str) and raw:
        return [raw]
    if isinstance(raw, list):
        return [v for v in raw if v]
    return []


def check_files(root: Path, rel_paths: list[str]) -> list[Violation]:
    root = root.resolve()
    workspace_root = root.parent
    violations: list[Violation] = []
    cache: dict[str, object] = {}

    def load(path: Path):
        key = str(path)
        if key in cache:
            return cache[key]
        if not path.is_file():
            cache[key] = "missing"
            return "missing"
        text = path.read_text(encoding="utf-8")
        fm, body = parse_front_matter(text)
        if fm is None:
            cache[key] = "unreadable"
            return "unreadable"
        result = (fm, body)
        cache[key] = result
        return result

    for rel_path in rel_paths:
        rel_path = rel_path.replace("\\", "/")
        full = (root / rel_path).resolve()
        result = load(full)
        if result == "missing":
            continue
        if result == "unreadable":
            violations.append(Violation("FM", rel_path, "front-matter illisible"))
            continue
        fm, body = result
        liens_entries = extract_liens_entries(body)
        source_dir = full.parent

        # --- R3: every typed relation (closed vocabulary) must resolve ---
        # Cross-repository target (sibling repository of the same workspace) resolved like
        # a local target; only a target found nowhere produces
        # this refusal (Mission 059, step 2).
        for entry in liens_entries:
            if entry["type"] not in KNOWN_LINK_TYPES or entry["hors"]:
                continue
            if resolve_target(source_dir, entry["path"]) is None:
                violations.append(
                    Violation(
                        "R3",
                        rel_path,
                        f"cible introuvable pour `{entry['type']}`: {entry['path']}",
                    )
                )

        # --- R1 (consistency + reciprocity) and R2 (status) ---
        for fm_field, link_types, inverse_types in RECIPROCAL_RELATIONS:
            fm_resolved: set[Path] = set()
            for raw in _fm_targets(fm, fm_field):
                target = resolve_target(source_dir, raw)
                if target is None:
                    violations.append(
                        Violation(
                            "R3",
                            rel_path,
                            f"cible introuvable pour front-matter `{fm_field}`: {raw}",
                        )
                    )
                else:
                    fm_resolved.add(target)

            liens_resolved: set[Path] = set()
            for entry in liens_entries:
                if entry["type"] not in link_types or entry["hors"]:
                    continue
                target = resolve_target(source_dir, entry["path"])
                if target is not None:
                    liens_resolved.add(target)

            if fm_resolved != liens_resolved:
                violations.append(
                    Violation(
                        "R1",
                        rel_path,
                        f"incoherence front-matter/Liens pour `{fm_field}`/`{link_types[0]}`",
                    )
                )

            for target in fm_resolved | liens_resolved:
                target_display = display_path(target, root, workspace_root)
                tresult = load(target)
                if tresult in ("missing", "unreadable"):
                    violations.append(
                        Violation(
                            "R1",
                            rel_path,
                            f"reciprocite non verifiable, {target_display} {tresult}",
                        )
                    )
                    continue
                tfm, tbody = tresult
                tliens = extract_liens_entries(tbody)

                back_ok = False
                for e in tliens:
                    if e["type"] not in inverse_types or e["hors"]:
                        continue
                    back_target = resolve_target(target.parent, e["path"])
                    if back_target is not None and back_target == full:
                        back_ok = True
                        break
                if not back_ok:
                    violations.append(
                        Violation(
                            "R1",
                            rel_path,
                            f"reciprocite absente : {rel_path} `{link_types[0]}` {target_display}, "
                            f"{target_display} ne porte pas `{inverse_types[0]}` vers {rel_path}",
                        )
                    )

                if fm_field == "supersedes":
                    ttype = tfm.get("type")
                    tstatus = str(tfm.get("status") or "").strip().lower()
                    if ttype != "mission" and tstatus in ACTIVE_STATUS_VALUES:
                        violations.append(
                            Violation(
                                "R2",
                                rel_path,
                                f"statut incoherent : {target_display} declare remplace par "
                                f"{rel_path} mais porte encore status={tfm.get('status')!r}",
                            )
                        )

    return violations


def get_staged_md_files(root: Path) -> list[str]:
    out = subprocess.run(
        ["git", "diff", "--cached", "--name-only", "--diff-filter=AM", "--", "*.md"],
        cwd=root,
        capture_output=True,
        text=True,
        check=True,
    ).stdout
    files = [f.strip().replace("\\", "/") for f in out.splitlines() if f.strip()]
    return [f for f in files if not f.startswith("graphify-out/")]


def get_staged_paths(root: Path) -> set[str]:
    out = subprocess.run(
        ["git", "diff", "--cached", "--name-only"],
        cwd=root,
        capture_output=True,
        text=True,
        check=True,
    ).stdout
    return {f.strip().replace("\\", "/") for f in out.splitlines() if f.strip()}


def read_override_reason(root: Path) -> str | None:
    staged = get_staged_paths(root)
    if OVERRIDE_FILENAME not in staged:
        return None
    path = root / OVERRIDE_FILENAME
    if not path.is_file():
        return None
    reason = path.read_text(encoding="utf-8").strip()
    return reason or None


def main() -> int:
    try:
        root = Path(
            subprocess.run(
                ["git", "rev-parse", "--show-toplevel"],
                capture_output=True,
                text=True,
                check=True,
            ).stdout.strip()
        )
    except Exception as exc:  # noqa: BLE001 - refusal is the default position
        print(f"REFUS : impossible de determiner la racine git : {exc}", file=sys.stderr)
        return 1

    try:
        staged = get_staged_md_files(root)
    except Exception as exc:  # noqa: BLE001
        print(f"REFUS : impossible de lister les fichiers indexes : {exc}", file=sys.stderr)
        return 1

    if not staged:
        return 0

    try:
        violations = check_files(root, staged)
    except Exception as exc:  # noqa: BLE001 - refusal is the default position;
        # generic safety net: no raw Python trace may reach the
        # caller any more, even for a defect not anticipated here.
        print(f"REFUS : defaut du garde-fou d'obsolescence : {exc}", file=sys.stderr)
        return 1
    if not violations:
        return 0

    for v in violations:
        print(v.render(), file=sys.stderr)

    blocking = [v for v in violations if v.rule in ("R1", "R2", "R3")]
    hard = [v for v in violations if v.rule not in ("R1", "R2", "R3")]

    reason = read_override_reason(root) if blocking and not hard else None
    if reason is not None:
        print(
            f"CONTOURNEMENT trace : {OVERRIDE_FILENAME} indexe dans ce commit, "
            f"raison : {reason!r}. {len(blocking)} refus obsolescence ignore(s), "
            "0 defaut outil.",
            file=sys.stderr,
        )
        return 0

    print(
        f"REFUS : {len(violations)} violation(s) de reciprocite/statut/cible. "
        f"Contournement trace (jamais silencieux) : deposer/mettre a jour "
        f"{OVERRIDE_FILENAME} avec la raison, le stager, et reessayer.",
        file=sys.stderr,
    )
    return 1


if __name__ == "__main__":
    sys.exit(main())
