#!/usr/bin/env python3
"""The two profiles of the starting interview (Mission 240).

Owner profile: the section « ## Profil de départ » of the installed Vault's
USER.md -- five named fields, one per line, and a date line. Project profile:
the section « ## Profil du projet » of the project's README.md -- three named
fields and a date line. Both headings and every field name are fixed: the
Pilot, the mission-writing skill, the assistant and tools/build-state.sh read
them by name (docs/how-to/starting-interview.md).

This tool is the only writer of the two sections. It never rewrites a line
outside the section it owns, keeps the file's byte-order mark and line ends,
and never replaces a section silently: the Owner profile is written only from
a profile order carrying the Owner's dated authorization (written by the
welcome Pilot in <workspace>/_orders/, after showing the full profile), and an
existing project profile is kept as it is.

usage:
  starting_profile.py owner-show <USER.md>
  starting_profile.py owner-apply <order file> <USER.md> --archive <folder> [--today YYYY-MM-DD]
  starting_profile.py project-write <README.md> [--result T] [--blocker T] [--cadence T]
                      [--title NAME] [--today YYYY-MM-DD]

Last line of each command: OWNER-PROFILE <PRESENT|ABSENT> missing=<n> ·
OWNER-PROFILE-WRITTEN · PROJECT-PROFILE-<WRITTEN|KEPT|NONE> · REFUSED <reason>.
Exit: 0 done, 1 refused, 2 usage. Never a model call, never a deletion (the
order is moved, never removed; an archive already holding its name refuses).
"""
import datetime
import os
import re
import sys

OWNER_HEADING = "## Profil de départ"
PROJECT_HEADING = "## Profil du projet"
DATE_FIELD = "Mis à jour le"
OWNER_FIELDS = (
    "Ce que je fais",
    "Ce qui compte pour moi",
    "Trois casse-têtes du moment",
    "Rythme de revue",
    "Outils du quotidien",
)
PROJECT_FIELDS = ("Résultat attendu", "Blocage actuel", "Rythme de revue")
AUTH_FIELD = "Autorisation Owner datée"
EMPTY_VALUES = {"", "-", "—", "_(à remplir)_", "aucun", "none"}
FIELD_LINE = re.compile(r"^- \*\*(.+?) :\*\*[ \t]*(.*?)[ \t]*$")
DATE_RE = re.compile(r"[0-9]{4}-[0-9]{2}-[0-9]{2}")


def usage():
    sys.stderr.write(__doc__.split("usage:", 1)[1].split("Last line", 1)[0])
    return 2


def refuse(reason):
    print(f"REFUSED {reason}")
    return 1


class Doc:
    """A Markdown file read as lines, written back with its own BOM and line ends."""

    def __init__(self, path):
        self.path = path
        with open(path, "rb") as f:
            raw = f.read()
        self.bom = raw.startswith(b"\xef\xbb\xbf")
        text = raw[3:].decode("utf-8") if self.bom else raw.decode("utf-8")
        self.eol = "\r\n" if "\r\n" in text else "\n"
        self.final_eol = text.endswith("\n")
        self.lines = text.replace("\r\n", "\n").split("\n")
        if self.final_eol:
            self.lines.pop()

    def save(self):
        text = self.eol.join(self.lines) + (self.eol if self.final_eol else "")
        data = text.encode("utf-8")
        with open(self.path, "wb") as f:
            f.write((b"\xef\xbb\xbf" if self.bom else b"") + data)

    def frontmatter(self, key):
        if not self.lines or self.lines[0].strip() != "---":
            return ""
        for line in self.lines[1:]:
            if line.strip() == "---":
                break
            m = re.match(r"^" + re.escape(key) + r":\s*(.*)$", line)
            if m:
                return m.group(1).strip().strip('"')
        return ""

    def section_span(self, heading):
        """(start, end) of the section: its heading line to the line before the next `## `."""
        start = next((i for i, l in enumerate(self.lines) if l.rstrip() == heading), None)
        if start is None:
            return None
        end = len(self.lines)
        for i in range(start + 1, len(self.lines)):
            if self.lines[i].startswith("## "):
                end = i
                break
        return start, end

    def fields(self, heading):
        span = self.section_span(heading)
        if span is None:
            return None
        values = {}
        for line in self.lines[span[0] + 1:span[1]]:
            m = FIELD_LINE.match(line)
            if m:
                values[m.group(1).strip()] = m.group(2).strip()
        return values

    def put_section(self, heading, body):
        """Replaces the section, or inserts it before `## Liens` (at the end when there is none)."""
        block = [heading, ""] + body + [""]
        span = self.section_span(heading)
        if span is not None:
            self.lines[span[0]:span[1]] = block
            return
        at = next((i for i, l in enumerate(self.lines) if l.rstrip() == "## Liens"), None)
        if at is None:
            if self.lines and self.lines[-1].strip():
                self.lines.append("")
            self.lines.extend(block[:-1])
            self.final_eol = True
        else:
            self.lines[at:at] = block


def filled(value):
    return value is not None and value.strip() not in EMPTY_VALUES and not re.fullmatch(r"<[^>]*>", value.strip())


def render(names, values, today):
    return [f"- **{n} :** {values.get(n, '')}".rstrip() for n in names] + [f"- **{DATE_FIELD} :** {today}"]


def order_fields(path):
    """The fields of an order, read by their exact name followed by a colon (as project-bootstrap.sh --order)."""
    values = {}
    with open(path, encoding="utf-8-sig") as f:
        for line in f.read().replace("\r\n", "\n").split("\n"):
            m = re.match(r"^[-*\s]*([^:]+?)\s*:\s*(.*?)\s*$", line)
            if m and m.group(1) not in values:
                values[m.group(1)] = m.group(2).strip("`")
    return values


def owner_show(user_md):
    doc = Doc(user_md)
    values = doc.fields(OWNER_HEADING)
    if values is None:
        print(f"{OWNER_HEADING} : absent")
        print("MISSING " + " · ".join(OWNER_FIELDS))
        print(f"OWNER-PROFILE ABSENT missing={len(OWNER_FIELDS)}")
        return 0
    span = doc.section_span(OWNER_HEADING)
    for line in doc.lines[span[0]:span[1]]:
        print(line)
    missing = [n for n in OWNER_FIELDS if not filled(values.get(n))]
    print("MISSING " + (" · ".join(missing) if missing else "-"))
    print(f"OWNER-PROFILE PRESENT missing={len(missing)}")
    return 0


def owner_apply(order, user_md, archive, today):
    if not os.path.isfile(order):
        return refuse(f"order not found: {order}")
    doc = Doc(user_md)
    if doc.frontmatter("status") == "template":
        return refuse("USER.md is the distributed skeleton (status: template): a profile is written in an installed Vault, never in the laboratory's")
    fields = order_fields(order)
    if not DATE_RE.search(fields.get(AUTH_FIELD, "")):
        return refuse(f"profile order without « {AUTH_FIELD} » carrying a date (YYYY-MM-DD)")
    given = {n: fields[n] for n in OWNER_FIELDS if filled(fields.get(n))}
    if not given:
        return refuse("profile order without any field of « " + OWNER_HEADING[3:] + " »")
    target = os.path.join(archive, os.path.basename(order))
    if os.path.exists(target):
        return refuse(f"the archive already holds {target}: nothing written, nothing moved")
    current = doc.fields(OWNER_HEADING) or {}
    merged = {n: (given[n] if n in given else current.get(n, "")) for n in OWNER_FIELDS}
    doc.put_section(OWNER_HEADING, render(OWNER_FIELDS, merged, today))
    doc.save()
    os.makedirs(archive, exist_ok=True)
    os.replace(order, target)
    span = doc.section_span(OWNER_HEADING)
    for line in doc.lines[span[0]:span[1]]:
        print(line)
    kept = [n for n in OWNER_FIELDS if n not in given]
    print("KEPT " + (" · ".join(kept) if kept else "-"))
    print(f"ARCHIVED {target}")
    print("OWNER-PROFILE-WRITTEN")
    return 0


def project_write(readme, answers, title, today):
    if not any(filled(v) for v in answers.values()):
        print("PROJECT-PROFILE-NONE")
        return 0
    values = {n: (answers[n] if filled(answers[n]) else "") for n in PROJECT_FIELDS}
    if not os.path.exists(readme):
        if not title:
            return refuse(f"{readme} absent and no --title to create it")
        with open(readme, "w", encoding="utf-8", newline="\n") as f:
            f.write(f"# {title}\n\n## Liens\n\n- `see also` — [Journal du projet](./state/journal.md)\n")
    doc = Doc(readme)
    if doc.section_span(PROJECT_HEADING) is not None:
        print(f"{PROJECT_HEADING} : present, kept as it is")
        print("PROJECT-PROFILE-KEPT")
        return 0
    doc.put_section(PROJECT_HEADING, render(PROJECT_FIELDS, values, today))
    doc.save()
    span = doc.section_span(PROJECT_HEADING)
    for line in doc.lines[span[0]:span[1]]:
        print(line)
    print("PROJECT-PROFILE-WRITTEN")
    return 0


def main(argv):
    if not argv:
        return usage()
    cmd, args = argv[0], argv[1:]
    opts = {}
    pos = []
    i = 0
    while i < len(args):
        if args[i].startswith("--") and i + 1 < len(args):
            opts[args[i][2:]] = args[i + 1]
            i += 2
        else:
            pos.append(args[i])
            i += 1
    today = opts.get("today") or datetime.date.today().isoformat()
    if cmd == "owner-show" and len(pos) == 1:
        return owner_show(pos[0])
    if cmd == "owner-apply" and len(pos) == 2 and "archive" in opts:
        return owner_apply(pos[0], pos[1], opts["archive"], today)
    if cmd == "project-write" and len(pos) == 1:
        answers = {"Résultat attendu": opts.get("result", ""), "Blocage actuel": opts.get("blocker", ""),
                   "Rythme de revue": opts.get("cadence", "")}
        return project_write(pos[0], answers, opts.get("title", ""), today)
    return usage()


if __name__ == "__main__":
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    sys.exit(main(sys.argv[1:]))
