#!/usr/bin/env python3
"""sb -- the Second Brain command (Mission 236).

One program, grammar `sb <verb> [arguments]`, one verb per operation
(rules/RULES-2026-09-26-200933-sb-command-surface.md). It is the porcelain; the
scripts of tools/ stay the plumbing, and every verb calls them rather than
rewriting them.

Single source: tools/sb/verbs.json (group, usage, place, nature, what a verb is
built on, the former phrasings, the card an agent applies) and the `sb.*` keys
of i18n/catalog.{fr,en,es}.json (every text of the help). `generate` writes
docs/reference/commands.md, docs/COMMANDS-CARD.md and the Claude Code plugin
from them; `generate --check` refuses a generated file that drifted.

Exit codes: 0 done, 1 the underlying tool refused or failed, 2 usage, 3 wrong
place, 4 not allowed here (an Owner-only verb outside the laboratory).

Never: a model call, a deletion, a forced push, a write into the profile other
than the PATH entry `sb install --path` is asked for.

Launched by tools/sb/bin/sb (bash) and tools/sb/bin/sb.cmd (Windows), through
`uv run --no-project` like the other Python tools of the Vault.
"""
import datetime
import json
import os
import re
import shutil
import subprocess
import sys

SB_DIR = os.path.dirname(os.path.abspath(__file__))
VAULT = os.path.dirname(os.path.dirname(SB_DIR))
TOOLS = os.path.join(VAULT, "tools")
BIN_DIR = os.path.join(SB_DIR, "bin")
VERBS_FILE = os.path.join(SB_DIR, "verbs.json")
NATIVE_FILE = os.path.join(SB_DIR, "native-commands.tsv")
I18N = os.path.join(VAULT, "i18n")
CERTIFICATE_LINE = "# second-brain-birth-certificate: v1"
LANGS = ("fr", "en", "es")

EXIT_OK, EXIT_TOOL, EXIT_USAGE, EXIT_PLACE, EXIT_FORBIDDEN = 0, 1, 2, 3, 4

IS_WINDOWS = os.name == "nt"


# --- Output ---------------------------------------------------------------

def _setup_output():
    for stream in (sys.stdout, sys.stderr):
        try:
            stream.reconfigure(encoding="utf-8", errors="replace")
        except (AttributeError, ValueError):
            pass
    if IS_WINDOWS:
        try:
            import ctypes
            kernel32 = ctypes.windll.kernel32
            kernel32.SetConsoleOutputCP(65001)
            handle = kernel32.GetStdHandle(-11)
            mode = ctypes.c_uint32()
            if kernel32.GetConsoleMode(handle, ctypes.byref(mode)):
                kernel32.SetConsoleMode(handle, mode.value | 0x0004)
                return True
            return False
        except Exception:
            return False
    return True


COLOR = False


def bold(text):
    return f"\033[1m{text}\033[0m" if COLOR else text


def dim(text):
    return f"\033[2m{text}\033[0m" if COLOR else text


def out(text=""):
    print(text)


def err(text):
    print(text, file=sys.stderr)


# --- Language and catalogue ---------------------------------------------

def _read_language_line(path, frontmatter=False):
    try:
        with open(path, encoding="utf-8-sig") as f:
            lines = f.read().splitlines()
    except OSError:
        return ""
    if frontmatter:
        if not lines or lines[0].strip() != "---":
            return ""
        for line in lines[1:]:
            if line.strip() == "---":
                break
            m = re.match(r"^language:\s*\"?([A-Za-z]{2})", line)
            if m:
                return m.group(1).lower()
        return ""
    for line in lines:
        m = re.match(r"^language:\s*\"?([A-Za-z]{2})", line)
        if m:
            return m.group(1).lower()
    return ""


def _system_language():
    for var in ("LC_ALL", "LC_MESSAGES", "LANG"):
        value = os.environ.get(var, "")
        if value and value not in ("C", "POSIX", "C.UTF-8"):
            return value[:2].lower()
    if IS_WINDOWS:
        try:
            import ctypes
            primary = ctypes.windll.kernel32.GetUserDefaultUILanguage() & 0x3FF
            return {0x0C: "fr", 0x09: "en", 0x0A: "es"}.get(primary, "")
        except Exception:
            return ""
    return ""


def detect_language(option=None):
    for candidate in (
        option,
        os.environ.get("SB_LANG"),
        _read_language_line(os.path.join(VAULT, "USER.local.yaml")),
        _read_language_line(os.path.join(VAULT, "USER.md"), frontmatter=True),
        _system_language(),
    ):
        if candidate and candidate.lower()[:2] in LANGS:
            return candidate.lower()[:2]
    return "en"


class Catalog:
    def __init__(self, lang):
        self.lang = lang
        self.data = self._load(lang)
        self.fallback = self._load("en") if lang != "en" else self.data

    @staticmethod
    def _load(lang):
        try:
            with open(os.path.join(I18N, f"catalog.{lang}.json"), encoding="utf-8-sig") as f:
                return json.load(f)
        except (OSError, ValueError):
            return {}

    def has(self, key):
        return key in self.data or key in self.fallback

    def __call__(self, key, *args):
        text = self.data.get(key, self.fallback.get(key, key))
        if args:
            for i, value in enumerate(args):
                text = text.replace("{%d}" % i, str(value))
        return text


T = Catalog("en")


# --- Verbs ------------------------------------------------------------------

def load_verbs():
    with open(VERBS_FILE, encoding="utf-8") as f:
        data = json.load(f)
    return data


def verb_index(data):
    return {v["verb"]: v for v in data["verbs"]}


def form_places(v):
    """The forms of a verb that run in another place than the verb's own
    (`formPlaces` of verbs.json, Mission 241), flags only: `accueil` is the
    bare spelling of `--accueil`."""
    return [(form, p) for form, p in v.get("formPlaces", {}).items() if form.startswith("-")]


def effective_place(v, rest):
    """The place a call must satisfy: the form's own, when its first argument
    names one, else the verb's."""
    if rest and rest[0] in v.get("formPlaces", {}):
        return v["formPlaces"][rest[0]]
    return v["place"]


# --- Places -----------------------------------------------------------------

def norm(path):
    return os.path.normcase(os.path.realpath(os.path.abspath(path)))


def is_under(path, root):
    p, r = norm(path), norm(root)
    return p == r or p.startswith(r.rstrip(os.sep) + os.sep)


def find_up(start, predicate, stop=None):
    path = os.path.abspath(start)
    while True:
        if predicate(path):
            return path
        if stop and norm(path) == norm(stop):
            return None
        parent = os.path.dirname(path)
        if parent == path:
            return None
        path = parent


def is_workspace_root(path):
    return os.path.isfile(os.path.join(path, "VAULT-ROOT.md"))


def has_certificate(path):
    try:
        with open(os.path.join(path, ".pre-commit-config.yaml"), encoding="utf-8-sig") as f:
            return f.readline().rstrip("\r\n") == CERTIFICATE_LINE
    except OSError:
        return False


WORKSPACE = find_up(VAULT, is_workspace_root)


class Place:
    """Where a path lies, measured -- never assumed."""

    def __init__(self, path):
        self.path = os.path.abspath(path)
        self.exists = os.path.isdir(self.path)
        own_ws = find_up(self.path, is_workspace_root) if self.exists else None
        self.other_workspace = bool(own_ws and WORKSPACE and norm(own_ws) != norm(WORKSPACE))
        self.in_workspace = bool(WORKSPACE and is_under(self.path, WORKSPACE) and not self.other_workspace)
        self.at_root = bool(WORKSPACE and norm(self.path) == norm(WORKSPACE))
        self.in_vault = is_under(self.path, VAULT)
        self.project = None
        if self.in_workspace and not self.in_vault and self.exists:
            self.project = find_up(self.path, has_certificate, stop=WORKSPACE)
            if self.project and norm(self.project) == norm(WORKSPACE):
                self.project = None
        self.repo = git_toplevel(self.path) if self.exists else None

    def describe(self):
        if not self.in_workspace:
            if self.other_workspace:
                return T("sb.here.otherWorkspace", display_path(self.path))
            return T("sb.here.outside", display_path(self.path))
        if self.at_root:
            return T("sb.here.root", display_path(self.path))
        if self.in_vault:
            return T("sb.here.vault", display_path(self.path))
        if self.project:
            return T("sb.here.project", project_name(self.project), display_path(self.project))
        return T("sb.here.notAdopted", display_path(self.path))

    def satisfies(self, place):
        if place == "anywhere" or place == "laboratory":
            return True
        if place == "workspace":
            return self.in_workspace
        if place == "project":
            return self.project is not None
        if place == "project-or-vault":
            return self.project is not None or (self.in_vault and self.in_workspace)
        if place == "adoptable":
            return self.in_workspace and not self.at_root and not self.in_vault
        if place == "vault":
            return self.in_vault
        if place == "repository":
            return self.in_workspace and self.repo is not None
        return False


def refuse(code, reason, where_to=""):
    line = f"{T('sb.msg.refused')} : {reason}" if T.lang == "fr" else f"{T('sb.msg.refused')}: {reason}"
    err(line)
    if where_to:
        err(f"  → {where_to}")
    return code


def place_refusal(verb, place_obj, place_name=None):
    place_name = place_name or verb["place"]
    where = T(f"sb.place.{place_name}")
    hint = T(f"sb.goto.{place_name}")
    if place_obj.at_root and place_name in ("project", "project-or-vault", "adoptable"):
        hint = T("sb.goto.fromRoot")
    return refuse(EXIT_PLACE, T("sb.msg.wrongPlace", "sb " + verb["verb"], where, place_obj.describe()), hint)


# --- Git and tools ------------------------------------------------------

def git(args, cwd, check=False):
    try:
        proc = subprocess.run(["git", "-C", cwd] + args, capture_output=True, text=True,
                              encoding="utf-8", errors="replace")
    except OSError:
        return None
    if proc.returncode != 0:
        return None if not check else ""
    return proc.stdout.strip()


def git_toplevel(path):
    top = git(["rev-parse", "--show-toplevel"], path)
    return os.path.abspath(top) if top else None


def bash_exe():
    override = os.environ.get("SB_BASH")
    if override and os.path.isfile(override):
        return override
    if not IS_WINDOWS:
        return shutil.which("bash") or "/bin/bash"
    windir = os.environ.get("WINDIR", r"C:\Windows")
    git_exe = shutil.which("git")
    if git_exe:
        d = os.path.dirname(os.path.realpath(git_exe))
        for _ in range(3):
            candidate = os.path.join(d, "bin", "bash.exe")
            if os.path.isfile(candidate):
                return candidate
            d = os.path.dirname(d)
    portable = os.path.join(os.environ.get("USERPROFILE", ""), ".local", "share", "second-brain",
                            "PortableGit", "bin", "bash.exe")
    if os.path.isfile(portable):
        return portable
    found = shutil.which("bash")
    if found and not is_under(found, windir):
        return found
    default = r"C:\Program Files\Git\bin\bash.exe"
    return default if os.path.isfile(default) else "bash"


def in_git_bash():
    """Git Bash (MSYS) exports MSYSTEM to the programs it starts."""
    return IS_WINDOWS and bool(os.environ.get("MSYSTEM"))


def display_path(path):
    """A path in the form of the terminal sb runs in (Mission 237): C:\\... under
    PowerShell and cmd, /c/... under Git Bash; unchanged elsewhere."""
    if not path or not IS_WINDOWS:
        return path
    m = re.match(r"^/([a-zA-Z])(/.*)?$", path)
    if m:
        win = m.group(1).upper() + ":" + (m.group(2) or "/").replace("/", "\\")
    else:
        win = path.replace("/", "\\")
    if in_git_bash():
        m = re.match(r"^([a-zA-Z]):[\\/]?(.*)$", win)
        if m:
            return "/" + m.group(1).lower() + "/" + m.group(2).replace("\\", "/")
    return win


def display_paths_in(text):
    """Every /c/... or C:\\... path of a tool's line, in the terminal's form."""
    if not IS_WINDOWS or not text:
        return text
    return re.sub(r"(?:/[a-zA-Z](?=/)|[a-zA-Z]:[\\/])[^\s\u2014]*", lambda m: display_path(m.group(0)), text)


def shell_path(path):
    return path.replace("\\", "/") if IS_WINDOWS else path


def run_tool(script, args, cwd=None, capture=False):
    """Runs tools/<script> with bash; streams its output unless capture."""
    cmd = [bash_exe(), shell_path(os.path.join(TOOLS, script))] + [str(a) for a in args]
    try:
        if capture:
            proc = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True,
                                  encoding="utf-8", errors="replace")
            return proc.returncode, (proc.stdout or "") + (proc.stderr or "")
        sys.stdout.flush()
        proc = subprocess.run(cmd, cwd=cwd)
        return proc.returncode, ""
    except OSError as exc:
        return 127, str(exc)


def run_python_tool(script, args, capture=True):
    cmd = [sys.executable, os.path.join(TOOLS, script)] + list(args)
    proc = subprocess.run(cmd, capture_output=capture, text=True, encoding="utf-8", errors="replace")
    return proc.returncode, (proc.stdout or "") + (proc.stderr or "")


# --- Project helpers --------------------------------------------------------

def read_frontmatter(path):
    try:
        with open(path, encoding="utf-8-sig") as f:
            text = f.read()
    except OSError:
        return {}
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return {}
    data = {}
    for line in lines[1:]:
        if line.strip() == "---":
            break
        m = re.match(r"^([A-Za-z_][\w-]*):\s*(.*)$", line)
        if m:
            data[m.group(1)] = m.group(2).strip().strip('"')
    return data


def registry_rows():
    path = os.path.join(VAULT, "projects", "PROJECT-REGISTRY.md")
    rows = []
    try:
        with open(path, encoding="utf-8-sig") as f:
            lines = f.read().splitlines()
    except OSError:
        return rows
    section = ""
    header = None
    for line in lines:
        if line.startswith("## "):
            section = line[3:].strip()
            header = None
            continue
        if not line.startswith("|"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if header is None:
            header = cells
            continue
        if set(line.replace("|", "").strip()) <= set("-: "):
            continue
        row = dict(zip(header, cells))
        row["_section"] = section
        rows.append(row)
    return rows


def project_name(project_path):
    prompt = read_frontmatter(os.path.join(project_path, "state", "PILOT-PROMPT.md"))
    name = prompt.get("pilot_project_name", "")
    for prefix in ("SB - ", "SB \u00b7 "):  # the ASCII prefix (Mission 237), then the first form
        if name.startswith(prefix):
            return name[len(prefix):]
    if WORKSPACE:
        rel = os.path.relpath(project_path, os.path.dirname(VAULT)).replace("\\", "/")
        for row in registry_rows():
            if row.get("relative_path") == rel:
                return row.get("display_name", rel)
    return os.path.basename(project_path)


def project_base(project_path):
    """The folder that holds state/, missions/, reports/ (state_path of the Pilot prompt)."""
    prompt = read_frontmatter(os.path.join(project_path, "state", "PILOT-PROMPT.md"))
    state_path = prompt.get("state_path", "state/STATE.md")
    base = os.path.dirname(os.path.dirname(os.path.join(project_path, state_path)))
    return os.path.normpath(base)


def newest(folder, prefix):
    """The newest <prefix><timestamp>... file, by the timestamp in its name
    (REPORT-ADDENDUM-..., MISSION-INDEX.md and the like are ordered by it too,
    or left out when they carry none)."""
    stamp = re.compile(r"(\d{4}-\d{2}-\d{2}-\d{6})")
    try:
        names = [n for n in os.listdir(folder) if n.startswith(prefix) and n.endswith(".md")]
    except OSError:
        return None
    dated = sorted((m.group(1), n) for n in names for m in [stamp.search(n)] if m)
    return os.path.join(folder, dated[-1][1]) if dated else None


def section(text, heading):
    m = re.search(r"(?m)^## " + re.escape(heading) + r"\s*$", text)
    if not m:
        return ""
    rest = text[m.end():]
    n = re.search(r"(?m)^## ", rest)
    return rest[: n.start()] if n else rest


def vault_version():
    version = ""
    try:
        with open(os.path.join(VAULT, "RELEASE-NOTES.md"), encoding="utf-8-sig") as f:
            for line in f:
                m = re.match(r"^## (v\d+\.\d+\.\d+)(.*)$", line)
                if m:
                    version = m.group(1)[1:] + (" (draft)" if "draft" in m.group(2) else "")
                    break
    except OSError:
        pass
    return version or "unknown"


# --- Rendering helpers ----------------------------------------------------

def table(rows, indent=2, gap=3, width=0):
    if not rows:
        return
    width = max([width] + [len(r[0]) for r in rows])
    for left, right in rows:
        out(" " * indent + left.ljust(width + gap) + right)


def text_block(text, indent=2):
    for line in text.split("\n"):
        if "\t" in line:
            continue
        out((" " * indent + line) if line else "")


def tabbed_block(text, indent=2):
    rows = []
    for line in text.split("\n"):
        if "\t" in line:
            left, right = line.split("\t", 1)
            rows.append((left, right))
    table(rows, indent=indent)


def aligned_lines(text, indent=2, gap=3):
    """Lines with a tab become two-column rows, all aligned on one width (a
    step may carry sub-rows under a line of its own, Mission 241); others
    stay as they are."""
    rows = [line.split("\t", 1) for line in text.split("\n") if "\t" in line]
    width = max([0] + [len(r[0]) for r in rows])
    lines = []
    for line in text.split("\n"):
        if "\t" in line:
            left, right = line.split("\t", 1)
            lines.append(" " * indent + left.ljust(width + gap) + right)
        else:
            lines.append((" " * indent + line) if line else "")
    return lines


def mixed_block(text, indent=2):
    """Lines with a tab become aligned two-column rows; others print as they are."""
    for line in aligned_lines(text, indent=indent):
        out(line)


# --- help -------------------------------------------------------------------

def help_home(data):
    out(bold(f"Second Brain · sb {vault_version()}"))
    out(T("sb.home.intro"))
    out(dim(T("sb.home.surfaces")))
    out()
    out(bold(T("sb.home.startTitle")))
    tabbed_block(T("sb.home.start"))
    width = max(len(v["verb"]) for v in data["verbs"])
    for group in data["groups"]:
        out()
        out(bold(T(f"sb.group.{group}")))
        table([(v["verb"], T(f"sb.verb.{v['verb']}.summary")) for v in data["verbs"] if v["group"] == group],
              gap=4, width=width)
    out()
    out(bold(T("sb.home.moreTitle")))
    tabbed_block(T("sb.home.more"))
    out(dim(T("sb.home.reference", display_path(os.path.join(VAULT, "docs", "reference", "commands.md")))))
    return EXIT_OK


def help_verb(v):
    name = v["verb"]
    out(bold(f"sb {name}") + " — " + T(f"sb.verb.{name}.summary"))
    out()
    out(bold(T("sb.label.usage")))
    for usage in v["usage"]:
        out("  " + usage)
    out()
    out(bold(T("sb.label.where")))
    out("  " + T(f"sb.place.{v['place']}") + " · " + T(f"sb.nature.{v['nature']}"))
    for form, form_place in form_places(v):
        out(f"  {form} : {T('sb.place.' + form_place)}" if T.lang == "fr" else f"  {form}: {T('sb.place.' + form_place)}")
    out()
    out(bold(T("sb.label.does")))
    text_block(T(f"sb.verb.{name}.does"))
    out()
    out(bold(T("sb.label.doesNot")))
    text_block(T(f"sb.verb.{name}.doesNot"))
    out()
    out(bold(T("sb.label.examples")))
    tabbed_block(T(f"sb.verb.{name}.examples"))
    out()
    out(bold(T("sb.label.surfaces")))
    table([("terminal", f"sb {name}"), ("Claude Code", f"/sb:{name}"), ("Codex", f"$sb {name}"),
           ("Pilot", T("sb.pilot.yes") if v.get("pilot") else T("sb.pilot.no"))])
    if v.get("next"):
        out()
        out(bold(T("sb.label.next")))
        for nxt in v["next"]:
            out("  " + nxt)
    if v.get("aliases"):
        out()
        out(bold(T("sb.label.aliases")))
        out("  " + ", ".join(f"« {a} »" for a in v["aliases"]))
    out()
    out(bold(T("sb.label.builtOn")))
    for piece in v.get("builtOn", []):
        out("  " + piece)
    return EXIT_OK


HELP_TOPICS = ("start", "concepts", "scenarios")


def v_help(data, args, place):
    verbs = verb_index(data)
    if not args:
        return help_home(data)
    topic = args[0]
    if topic in HELP_TOPICS:
        out(bold(T(f"sb.topic.{topic}.title")))
        out()
        mixed_block(T(f"sb.topic.{topic}"))
        return EXIT_OK
    if topic in verbs:
        return help_verb(verbs[topic])
    return refuse(EXIT_USAGE, T("sb.msg.unknownTopic", topic), T("sb.msg.seeHelp"))


# --- Verb implementations -------------------------------------------------

def card(v):
    """The agent's part of a verb, shown in a terminal."""
    out()
    out(bold(T("sb.label.agentPart")))
    text_block(T("sb.msg.agentVerb", v["verb"]))


def repo_line(path):
    head = git(["rev-parse", "--short", "HEAD"], path)
    if not head:
        return T("sb.status.noRepo")
    branch = git(["rev-parse", "--abbrev-ref", "HEAD"], path) or "?"
    upstream = git(["rev-parse", "--short", "@{upstream}"], path)
    porcelain = git(["status", "--porcelain"], path, check=True) or ""
    changes = len([l for l in porcelain.splitlines() if l.strip()])
    if upstream:
        counts = git(["rev-list", "--left-right", "--count", "@{upstream}...HEAD"], path) or "0 0"
        behind, ahead = (counts.split() + ["0", "0"])[:2]
        sync = T("sb.status.sync", ahead, behind, upstream)
    else:
        sync = T("sb.status.noUpstream")
    return T("sb.status.repo", branch, head, sync, changes)


def v_status(data, args, place):
    out(bold(T("sb.status.title")))
    rows = [
        (T("sb.status.workspace"), display_path(WORKSPACE) or "—"),
        (T("sb.status.vault"), f"{display_path(VAULT)} · {repo_line(VAULT)}"),
        (T("sb.status.here"), place.describe()),
    ]
    nxt = []
    if place.project:
        base = project_base(place.project)
        repo = git_toplevel(place.project)
        state_rows = []
        if repo:
            state_rows.append((T("sb.status.repository"), repo_line(repo)))
        state_file = os.path.join(base, "state", "STATE.md")
        try:
            with open(state_file, encoding="utf-8-sig") as f:
                state = f.read()
        except OSError:
            state = ""
        current = " ".join(section(state, "État courant").split())[:160]
        action = " ".join(section(state, "Prochaine action").split())[:160]
        doors = [l for l in section(state, "Portes ouvertes").splitlines() if l.startswith("- ")]
        if current:
            state_rows.append((T("sb.status.current"), current))
        if action:
            state_rows.append((T("sb.status.nextAction"), action))
        state_rows.append((T("sb.status.doors"), str(len(doors))))
        for label, folder, prefix in (("sb.status.lastHandoff", "handoffs", "HANDOFF-"),
                                      ("sb.status.lastReport", "reports", "REPORT-"),
                                      ("sb.status.lastMission", "missions", "MISSION-")):
            found = newest(os.path.join(base, folder), prefix)
            if found:
                state_rows.append((T(label), os.path.basename(found)))
        rows += state_rows
        nxt = ["sb open", "sb relay", "sb run <mission>"]
    elif place.at_root:
        nxt = ["sb list", "sb help scenarios"]
    elif place.in_vault:
        nxt = ["sb doctor", "sb open"]
    elif place.in_workspace:
        nxt = ["sb adopt", "sb help scenarios"]
    else:
        nxt = [f"cd {WORKSPACE}" if WORKSPACE else "sb install"]
    table(rows)
    out()
    out(bold(T("sb.label.next")))
    for n in nxt:
        out("  " + n)
    return EXIT_OK


def v_open(data, args, place):
    v = verb_index(data)["open"]
    out(bold(T("sb.open.title", place.describe())))
    code = EXIT_OK
    if place.in_vault:
        rc, _ = run_tool("session-preflight.sh", [], cwd=VAULT)
        code = EXIT_OK if rc == 0 else EXIT_TOOL
    else:
        rc, _ = run_tool("check-workspace-root.sh", [shell_path(WORKSPACE)])
        rc2, _ = run_tool("project-bootstrap.sh", ["identity", shell_path(place.project), "--check"])
        repo = git_toplevel(place.project)
        if repo:
            out(git(["status", "-sb"], repo, check=True) or "")
        code = EXIT_OK if rc2 == 0 else EXIT_TOOL
    card(v)
    return code


def commit_alone(repo, paths, message):
    """A mechanical commit (Mission 244): the files a tool just wrote, and only
    them, through the repository's own guardians -- their output shown, a
    refusal shown as it is and never worked around. Returns (state, rc):
    "nothing" when the files carry no change, "done", or "refused"."""
    rels = [os.path.relpath(p, repo).replace("\\", "/") for p in paths]
    changed = git(["status", "--porcelain", "--"] + rels, repo, check=True) or ""
    if not changed.strip():
        return "nothing", 0
    if norm(repo) == norm(VAULT) and os.path.isfile(os.path.join(VAULT, "tools", "session-preflight.sh")):
        # The Vault's guardians want a fresh preflight stamp (tools/session-preflight.sh).
        run_tool("session-preflight.sh", [], cwd=VAULT, capture=True)
    try:
        subprocess.run(["git", "-C", repo, "add", "--"] + rels, capture_output=True)
        proc = subprocess.run(["git", "-C", repo, "commit", "-q", "-m", message, "--"] + rels,
                              capture_output=True, text=True, encoding="utf-8", errors="replace")
    except OSError as exc:
        out("   " + str(exc))
        return "refused", 1
    shown = [l for l in ((proc.stdout or "") + (proc.stderr or "")).splitlines()
             if l.strip() and "CRLF will be replaced" not in l and "LF will be replaced" not in l]
    for line in shown:
        out(dim("   " + line))
    return ("done" if proc.returncode == 0 else "refused"), proc.returncode


# --- close (Mission 244): the situation, measured -------------------------------

STAMP_IN_NAME = re.compile(r"(\d{4}-\d{2}-\d{2}-\d{6})")
ARTEFACT_FOLDERS = ("missions", "reports", "captures", "handoffs", "decisions", "proposals")


def last_state_stamp(journal):
    """The latest `STATE:` line of a journal, as YYYY-MM-DD-HHMMSS (local time
    as written), or None. The journal is append-only but not sorted: the
    latest is the greatest."""
    try:
        with open(journal, encoding="utf-8-sig") as f:
            lines = f.read().splitlines()
    except OSError:
        return None
    best = None
    for line in lines:
        m = re.match(r"^(\d{4}-\d{2}-\d{2})T(\d{2}):(\d{2}):(\d{2})\S*\s+(?:STATE|ETAT):", line)
        if m:
            stamp = f"{m.group(1)}-{m.group(2)}{m.group(3)}{m.group(4)}"
            best = stamp if best is None or stamp > best else best
    return best


def artefacts_since(base, stamp):
    """Missions, Notes, reports, captures, handoffs, decisions and proposals
    whose name carries a timestamp later than <stamp>: what a close has to
    record. Index files carry none and are never counted."""
    found = []
    for folder in ARTEFACT_FOLDERS:
        try:
            names = os.listdir(os.path.join(base, folder))
        except OSError:
            continue
        for name in sorted(names):
            m = STAMP_IN_NAME.search(name)
            if name.endswith(".md") and m and (stamp is None or m.group(1) > stamp):
                found.append(f"{folder}/{name}")
    return found


def push_target(repo):
    """Where the repository's `origin` stands for a push (Mission 244, closing
    list line 6): "none" (no origin), "distribution" (an installed Vault whose
    origin is the address it was installed from -- `vault_origin` of its
    VAULT-IDENTITY.md -- and which has no `release` remote: the published
    product, never a push target), or "owner" (every other remote: the push
    hole stands). The laboratory, which carries `release`, keeps its hole."""
    url = git(["remote", "get-url", "origin"], repo)
    if not url:
        return "none", ""
    identity = read_frontmatter(os.path.join(repo, "VAULT-IDENTITY.md"))
    recorded = identity.get("vault_origin", "")

    def same(a, b):
        # A folder origin may be written /c/x by the shell and C:/x by Git.
        if a == b:
            return True
        m = re.match(r"^/([a-zA-Z])(/.*)$", a)
        a = f"{m.group(1)}:{m.group(2)}" if m and IS_WINDOWS else a
        return bool(a and b and "://" not in a + b and norm(a) == norm(b))

    if (identity.get("status") == "generated" and same(recorded, url)
            and git(["remote", "get-url", "release"], repo) is None):
        return "distribution", url
    return "owner", url


def push_line(repo):
    kind, url = push_target(repo)
    name = os.path.basename(repo.rstrip("\\/"))
    if kind == "none":
        return T("sb.close.push.none", name)
    if kind == "distribution":
        return T("sb.close.push.distribution", name, url)
    counts = git(["rev-list", "--left-right", "--count", "@{upstream}...HEAD"], repo)
    ahead = (counts.split() + ["0", "0"])[1] if counts else "?"
    if ahead == "0":
        return T("sb.close.push.even", name, url)
    return T("sb.close.push.owner", name, url, ahead)


def close_accueil():
    """`sb close --accueil` (Mission 244): the welcome session has no project,
    hence no handoff -- its trace is the orders it wrote. Listed as measured:
    those waiting in _orders/, those filed today in _archive/orders/."""
    out(bold(T("sb.close.accueil.title")))
    today = datetime.date.today().isoformat()
    waiting, filed = [], []
    for folder, bucket, only_today in (("_orders", waiting, False), (os.path.join("_archive", "orders"), filed, True)):
        try:
            names = sorted(os.listdir(os.path.join(WORKSPACE, folder)))
        except OSError:
            names = []
        for name in names:
            if name.endswith(".md") and (not only_today or today in name):
                bucket.append(display_path(os.path.join(WORKSPACE, folder, name)))
    out("  " + T("sb.close.accueil.waiting", len(waiting)))
    for p in waiting:
        out("    " + p)
    out("  " + T("sb.close.accueil.filed", len(filed)))
    for p in filed:
        out("    " + p)
    out()
    text_block(T("sb.close.accueil.rest"))
    return EXIT_OK


def light_close(base, repo, stamp):
    """`sb close --light` (Mission 244): the Executor half of a light close,
    mechanical -- one STATE: line, the state sheet, the digest, and a commit of
    those three files alone through the project's guardians. No execution Note:
    it is a planned path of the session-close skill, not an order outside a
    Mission."""
    head = git(["rev-parse", "--short", "HEAD"], repo) or "?"
    line = T("sb.close.light.state", stamp or "—", head)[:290]
    for script, args in (("append-journal.sh", [shell_path(base), line]),
                         ("build-state.sh", [shell_path(base)]),
                         ("build-digest.sh", [shell_path(base)])):
        rc, text = run_tool(script, args, capture=True)
        if rc != 0:
            out(display_paths_in(text.rstrip("\n")))
            return refuse(EXIT_TOOL, T("sb.close.light.toolFailed", script))
    files = [os.path.join(base, "state", n) for n in ("journal.md", "STATE.md", "DIGEST.md")]
    state, rc = commit_alone(repo, files, T("sb.close.light.message"))
    if state == "refused":
        return refuse(EXIT_TOOL, T("sb.close.light.refused"))
    out(T("sb.close.light.done", git(["rev-parse", "--short", "HEAD"], repo) or "?"))
    return EXIT_OK


def v_close(data, args, place):
    v = verb_index(data)["close"]
    if args and args[0] in ("--accueil", "accueil"):
        return close_accueil()
    target = place.project or VAULT
    repo = git_toplevel(target)
    out(bold(T("sb.close.title", place.describe())))
    if repo:
        out(git(["status", "-sb"], repo, check=True) or "")
    base = project_base(place.project) if place.project else VAULT
    journal = os.path.join(base, "state", "journal.md")
    stamp = last_state_stamp(journal)
    since = artefacts_since(base, stamp) if os.path.isfile(journal) else None
    out()
    if since is None:
        out(T("sb.close.situation.unmeasured", display_path(journal)))
    elif not since:
        out(T("sb.close.situation.light", stamp or "—"))
    else:
        handoffs = [a for a in since if a.startswith("handoffs/")]
        out(T("sb.close.situation.full", len(since), stamp or "—"))
        for a in since[:12]:
            out("    " + a)
        if handoffs:
            out(T("sb.close.situation.handoff", handoffs[-1]))
        else:
            out(T("sb.close.situation.noHandoff"))
    if repo:
        out(push_line(repo))
    if "--light" in args:
        if since is None or since or not repo:
            return refuse(EXIT_TOOL, T("sb.close.light.notLight"))
        return light_close(base, repo, stamp)
    if since == [] and repo:
        out()
        out(T("sb.close.light.hint"))
    card(v)
    return EXIT_OK


def v_handoff(data, args, place):
    v = verb_index(data)["handoff"]
    base = project_base(place.project) if place.project else VAULT
    stamp = datetime.datetime.now().strftime("%Y-%m-%d-%H%M%S")
    slug = args[0] if args else "<slug>"
    target = os.path.join(base, "handoffs", f"HANDOFF-{stamp}-{slug}.md")
    out(bold(T("sb.handoff.title")))
    table([(T("sb.handoff.file"), target),
           (T("sb.handoff.template"), os.path.join(VAULT, "templates", "handoff-template.md"))])
    card(v)
    return EXIT_OK


def v_profile(data, args, place):
    """The Owner's starting profile (Mission 240): shown, or applied from a
    profile order -- tools/starting_profile.py is the only writer."""
    v = verb_index(data)["profile"]
    user_md = os.path.join(VAULT, "USER.md")
    if not os.path.isfile(user_md):
        return refuse(EXIT_TOOL, T("sb.profile.noUser", display_path(VAULT)))
    if not args:
        out(bold(T("sb.profile.title", display_path(user_md))))
        rc, text = run_python_tool("starting_profile.py", ["owner-show", user_md])
        out(text.rstrip("\n"))
        card(v)
        return EXIT_OK if rc == 0 else EXIT_TOOL
    if args[0] != "--order" or len(args) != 2:
        return refuse(EXIT_USAGE, T("sb.msg.usage", "sb profile [--order <file>]"))
    order = os.path.abspath(args[1])
    archive = os.path.join(WORKSPACE, "_archive", "orders")
    out(bold(T("sb.profile.title", display_path(user_md))))
    rc, text = run_python_tool("starting_profile.py", ["owner-apply", order, user_md, "--archive", archive])
    lines = text.rstrip("\n").split("\n")
    refused = lines[-1].split(" ", 2) if lines and lines[-1].startswith("REFUSED ") else None
    if refused:
        # Mission 244 (finding 18): the tool's fixed code, said in the reader's language.
        detail = display_path(refused[2]) if len(refused) > 2 else ""
        key = "sb.profile.refused." + refused[1]
        return refuse(EXIT_TOOL, T(key, detail) if T.has(key) else lines[-1])
    out(display_paths_in("\n".join(lines)))
    if rc != 0:
        return EXIT_TOOL
    # Mission 244 (finding 17): the profile is committed here, USER.md alone,
    # through the Vault's guardians -- a gesture without judgement needs no agent.
    state, _ = commit_alone(VAULT, [user_md], "Starting profile applied from " + os.path.basename(order))
    if state == "refused":
        return refuse(EXIT_TOOL, T("sb.profile.commitRefused", display_path(user_md)))
    out(T("sb.profile.committed" if state == "done" else "sb.profile.nothingToCommit",
          git(["rev-parse", "--short", "HEAD"], VAULT) or "?"))
    card(v)
    return EXIT_OK


def workspace_target(arg):
    if os.path.isabs(arg):
        return os.path.abspath(arg)
    return os.path.abspath(os.path.join(WORKSPACE, arg))


def v_new(data, args, place):
    if not args:
        help_verb(verb_index(data)["new"])
        return EXIT_USAGE
    if args[0] == "--order":
        if len(args) < 2:
            return refuse(EXIT_USAGE, T("sb.msg.usage", "sb new --order <file>"))
        # Mission 244 (finding 18): the tool's messages in the reader's language;
        # the project's own language stays the one USER.md records.
        lang = [] if "--lang" in args else ["--lang", T.lang.upper()]
        rc, _ = run_tool("project-bootstrap.sh", ["--order", shell_path(os.path.abspath(args[1]))] + args[2:] + lang)
        return EXIT_OK if rc == 0 else EXIT_TOOL
    if len(args) < 2 or args[1].startswith("-"):
        return refuse(EXIT_USAGE, T("sb.msg.usage", 'sb new <folder> "<Display Name>" [--group <group>] [--lang FR|EN|ES]'))
    target = workspace_target(args[0])
    if not is_under(target, WORKSPACE) or norm(target) == norm(WORKSPACE) or is_under(target, VAULT):
        return refuse(EXIT_PLACE, T("sb.new.outside", target), T("sb.goto.workspace"))
    rc, _ = run_tool("project-bootstrap.sh", ["create", shell_path(target)] + args[1:])
    return EXIT_OK if rc == 0 else EXIT_TOOL


def v_adopt(data, args, place):
    rest = args
    if args and not args[0].startswith("-"):
        target = os.path.abspath(args[0])
        rest = args[1:]
        tplace = Place(target)
        if not tplace.satisfies("adoptable"):
            return place_refusal(verb_index(data)["adopt"], tplace)
    else:
        target = place.path
    rc, _ = run_tool("project-bootstrap.sh", ["adopt", shell_path(target)] + rest)
    return EXIT_OK if rc == 0 else EXIT_TOOL


def v_list(data, args, place):
    rows = registry_rows()
    out(bold(T("sb.list.title", len([r for r in rows if r.get("_section") == "Active"]))))
    if not rows:
        out("  " + T("sb.list.none"))
        return EXIT_OK
    table_rows = []
    for r in rows:
        table_rows.append((r.get("display_name", "?"),
                           f"{r.get('relative_path', '?')}  ·  {r.get('status', '?')}  ·  vcs {r.get('vcs', '?')}  ·  {r.get('conformity', '?')}  ·  SB - {r.get('display_name', '?')}"))
    table(table_rows)
    out()
    out(dim(T("sb.list.hint")))
    return EXIT_OK


def common_block(server_suffix):
    path = os.path.join(VAULT, "templates", "session-opening-prompt-template.md")
    with open(path, encoding="utf-8-sig") as f:
        text = f.read()
    m = re.search(r"<!-- PROMPT:BEGIN -->\n(.*?)\n<!-- PROMPT:END -->", text, re.S)
    block = m.group(1) if m else ""
    return block.replace("{{VAULT_SHORT_ID}}", server_suffix)


# Mission 242: the hosts a Pilot can run in -- a local MCP server and no need
# of a shell (rule on model-agnostic hosts). Claude Code is an Executor host.
PILOT_HOSTS = ("claude-desktop", "codex", "gemini", "cursor", "windsurf", "cline", "lmstudio")
HOST_ALIASES = {"claude": "claude-desktop", "desktop": "claude-desktop", "gemini-cli": "gemini",
                "lm-studio": "lmstudio"}
PROVEN_PILOT_HOSTS = ("claude-desktop",)
# Remote-server-only hosts (the rule's matrix, state "not supported today").
UNSUPPORTED_PILOT_HOSTS = ("chatgpt", "chatgpt-web", "chatgpt-desktop", "gemini-web")


def pilot_hosts_to_show(requested):
    """--host <name>: that host; else every Pilot host present on this machine
    (tools/lib/mcp-hosts.sh); none present: the proven one."""
    if requested:
        return [requested]
    present = []
    for h in mcp_hosts():
        if h["present"] and h["id"] in PILOT_HOSTS and h["id"] not in present:
            present.append(h["id"])
    return present or ["claude-desktop"]


def host_name(host):
    for h in mcp_hosts():
        if h["id"] == host:
            return h["name"]
    return host


def clipboard_copy(text):
    """The Pilot block on the clipboard (Mission 244, findings 27, 28), through
    tools/lib/clipboard.sh -- the one access function; SB_CLIPBOARD_FILE takes
    the bytes instead (tests). The file passes by the declared temporary folder."""
    _code, root = subprocess_tmp_root()
    folder = os.path.join(root or os.path.expanduser("~"), "tools")
    os.makedirs(folder, exist_ok=True)
    path = os.path.join(folder, "sb-block-%d.txt" % os.getpid())
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    script = f'. "{shell_path(os.path.join(TOOLS, "lib", "clipboard.sh"))}" && sb_clipboard_copy "{shell_path(path)}"'
    try:
        rc = subprocess.run([bash_exe(), "-c", script], capture_output=True).returncode
    except OSError:
        rc = 1
    try:
        os.unlink(path)
    except OSError:
        pass
    return rc == 0


def pop_delivery(args):
    """--copy and --out <file> taken out of the arguments (Mission 244):
    (copy, out file or None, rest, error)."""
    rest, copy, out_file, error = [], False, None, None
    i = 0
    while i < len(args):
        if args[i] == "--copy":
            copy = True
        elif args[i] == "--out":
            if i + 1 >= len(args):
                error = "--out"
            else:
                out_file = os.path.abspath(args[i + 1])
                i += 1
        else:
            rest.append(args[i])
        i += 1
    return copy, out_file, rest, error


def deliver_block(block, copy, out_file):
    """The block copied (a terminal, --copy, or a test's SB_CLIPBOARD_FILE) and
    written to --out; each said in one line, by its place."""
    text = "\n".join(block).rstrip("\n") + "\n"
    if out_file:
        with open(out_file, "w", encoding="utf-8", newline="\n") as f:
            f.write(text)
        out(T("sb.pilot.written", display_path(out_file)))
    if copy or sys.stdout.isatty() or os.environ.get("SB_CLIPBOARD_FILE"):
        if clipboard_copy(text):
            out(T("sb.pilot.copied"))
        else:
            out(T("sb.pilot.copyFailed"))
    else:
        out(T("sb.pilot.copyHint"))


def print_pilot(name, block, path_step, last_step, hosts, server, first_path, copy=False, out_file=None):
    """The block once, the same for every host, then the steps of each host
    (Mission 242): where to paste it, how to open without a shell, the first
    message, what the first answer shows. Mission 244: the block also goes to
    the clipboard, or to --out."""
    out(bold(T("sb.pilot.title", name)))
    out()
    out(T("sb.pilot.blockIntro"))
    out("---")
    for line in block:
        out(line)
    out("---")
    for host in hosts:
        state = T("sb.pilot.state.proven") if host in PROVEN_PILOT_HOSTS else T("sb.pilot.state.declared")
        out()
        out(bold(T("sb.pilot.hostTitle", host_name(host), state)))
        if host == "claude-desktop":
            out(T("sb.host.claude-desktop.step1", name))
            out(T("sb.host.claude-desktop.step2"))
            out(path_step)
        else:
            out(T("sb.pilot.fm.open", host_name(host), server))
            out(T(f"sb.host.{host}.noShell"))
            out(T("sb.pilot.fm.first", first_path))
        out(last_step)
    out()
    deliver_block(block, copy, out_file)
    return EXIT_OK


def pop_host(args):
    """--host <name> taken out of the arguments: (host or None, rest, error)."""
    if "--host" not in args:
        return None, list(args), None
    i = args.index("--host")
    if i + 1 >= len(args):
        return None, args, "missing"
    host = HOST_ALIASES.get(args[i + 1].lower(), args[i + 1].lower())
    if host in UNSUPPORTED_PILOT_HOSTS:
        return None, args, "!" + host
    if host not in PILOT_HOSTS:
        return None, args, args[i + 1]
    return host, args[:i] + args[i + 2:], None


def accueil_prompt(host=None, copy=False, out_file=None):
    """`sb pilot-prompt --accueil` (Mission 241): the block of the welcome Pilot
    `SB - Accueil`, as tools/project-bootstrap.sh accueil-prompt prints it,
    framed by the steps in the reader's language -- no bash to type; Mission
    242: the steps of each host present, or of --host."""
    rc, text = run_tool("project-bootstrap.sh", ["accueil-prompt"], capture=True)
    lines = text.replace("\r\n", "\n").split("\n")
    marks = [i for i, line in enumerate(lines) if line.strip() == "---"]
    if rc != 0 or len(marks) < 2:
        out(display_paths_in(text.rstrip("\n")))
        return EXIT_TOOL if rc != 0 else EXIT_OK
    block = lines[marks[0] + 1:marks[-1]]
    return print_pilot("SB - Accueil", block, T("sb.pilot.accueilStep3", display_path(WORKSPACE)),
                       T("sb.pilot.accueilStep4"), pilot_hosts_to_show(host), vault_server_name(),
                       display_path(WORKSPACE), copy, out_file)


def v_pilot_prompt(data, args, place):
    copy, out_file, args, derror = pop_delivery(args)
    if derror:
        return refuse(EXIT_USAGE, T("sb.msg.usage", "sb pilot-prompt [<folder>] [--copy] [--out <file>]"))
    host, args, error = pop_host(args)
    if error and error.startswith("!"):
        return refuse(EXIT_USAGE, T("sb.pilot.unsupportedHost", error[1:]), "docs/how-to/pilot-hosts-and-role-mixing.md")
    if error:
        return refuse(EXIT_USAGE, T("sb.pilot.unknownHost", error, ", ".join(PILOT_HOSTS)))
    if args and args[0] in ("--accueil", "accueil"):
        if len(args) > 1:
            return refuse(EXIT_USAGE, T("sb.msg.usage", "sb pilot-prompt --accueil [--host <host>]"))
        return accueil_prompt(host, copy, out_file)
    rest = [a for a in args if a != "--regen"]
    regen = "--regen" in args
    project = place.project
    if rest:
        # Mission 244 (finding 1): a bare folder name is also looked for in the
        # workspace, whatever the current folder (a PowerShell opens in system32).
        target = os.path.abspath(rest[0])
        if not os.path.isdir(target) and WORKSPACE and os.path.isdir(workspace_target(rest[0])):
            target = workspace_target(rest[0])
        tplace = Place(target)
        if not tplace.project:
            return place_refusal(verb_index(data)["pilot-prompt"], tplace)
        project = tplace.project
    if regen:
        rc, _ = run_tool("project-bootstrap.sh", ["prompt", shell_path(project)])
        if rc != 0:
            return EXIT_TOOL
    prompt_file = os.path.join(project, "state", "PILOT-PROMPT.md")
    fm = read_frontmatter(prompt_file)
    if not fm:
        return refuse(EXIT_TOOL, T("sb.pilot.noPrompt", prompt_file), "sb pilot-prompt --regen")
    server = fm.get("mcp_server", "")
    suffix = server[len("second-brain-vault-"):] if server.startswith("second-brain-vault-") else server
    return print_pilot(fm.get("pilot_project_name", ""), common_block(suffix).split("\n"),
                       T("sb.pilot.step3", display_path(project)), T("sb.pilot.step4", fm.get("canary", "")),
                       pilot_hosts_to_show(host), server, display_path(project), copy, out_file)


def find_mission(base, token):
    folder = os.path.join(base, "missions")
    if os.path.isfile(token):
        return os.path.abspath(token)
    try:
        names = sorted(n for n in os.listdir(folder) if n.startswith("MISSION-") and n.endswith(".md"))
    except OSError:
        return None
    hits = [n for n in names if re.search(r"-%s-" % re.escape(token.zfill(3)), n)]
    return os.path.join(folder, hits[-1]) if hits else None


def v_mission(data, args, place):
    v = verb_index(data)["mission"]
    base = project_base(place.project)
    out(bold(T("sb.mission.title")))
    table([(T("sb.mission.folder"), os.path.join(base, "missions")),
           (T("sb.mission.template"), os.path.join(VAULT, "templates", "mission-template.md")),
           (T("sb.mission.skill"), os.path.join(VAULT, "skills", "mission-writing", "SKILL.md"))])
    card(v)
    return EXIT_OK


def v_run(data, args, place):
    v = verb_index(data)["run"]
    base = project_base(place.project)
    if not args:
        out(bold(T("sb.run.pick")))
        folder = os.path.join(base, "missions")
        try:
            names = sorted(n for n in os.listdir(folder) if n.startswith("MISSION-") and n.endswith(".md"))[-5:]
        except OSError:
            names = []
        for n in names:
            out("  " + n)
        card(v)
        return EXIT_OK
    mission = find_mission(base, args[0])
    if not mission:
        return refuse(EXIT_TOOL, T("sb.run.notFound", args[0], os.path.join(base, "missions")))
    fm = read_frontmatter(mission)
    if fm.get("type") != "mission":
        return refuse(EXIT_TOOL, T("sb.run.notMission", mission))
    out(bold(T("sb.run.title", fm.get("mission_id", "?"))))
    table([(T("sb.run.file"), mission), (T("sb.run.status"), fm.get("status", "?")),
           (T("sb.run.subject"), fm.get("title", "")[:140])])
    out()
    out(T("sb.run.prompt"))
    out("  " + T("sb.run.promptLine", fm.get("mission_id", "?"), mission))
    card(v)
    return EXIT_OK


def v_relay(data, args, place):
    base = project_base(place.project)
    report = os.path.abspath(args[0]) if args else newest(os.path.join(base, "reports"), "REPORT-")
    if not report or not os.path.isfile(report):
        return refuse(EXIT_TOOL, T("sb.relay.none", os.path.join(base, "reports")))
    with open(report, encoding="utf-8-sig") as f:
        text = f.read()
    block = section(text, "RELAY")
    if not block.strip():
        return refuse(EXIT_TOOL, T("sb.relay.noBlock", report))
    out(bold(T("sb.relay.title", os.path.basename(report))))
    out(block.strip("\n"))
    return EXIT_OK


def v_push(data, args, place):
    dry = "--dry-run" in args
    rest = [a for a in args if a != "--dry-run"]
    repo = place.repo
    rng = None
    for a in rest:
        if ".." in a:
            rng = a
        else:
            repo = git_toplevel(os.path.abspath(a)) or os.path.abspath(a)
    if not repo:
        return refuse(EXIT_PLACE, T("sb.push.noRepo"), T("sb.goto.repository"))
    if not rng:
        upstream = git(["rev-parse", "--short", "@{upstream}"], repo)
        head = git(["rev-parse", "--short", "HEAD"], repo)
        if not upstream or not head:
            return refuse(EXIT_TOOL, T("sb.push.noUpstream", repo))
        if upstream == head:
            out(T("sb.push.nothing", repo, head))
            return EXIT_OK
        rng = f"{upstream}..{head}"
    tool_args = [shell_path(repo), rng] + (["--dry-run"] if dry else [])
    out(dim(f"verified-push.sh {' '.join(tool_args)}"))
    rc, _ = run_tool("verified-push.sh", tool_args)
    return EXIT_OK if rc == 0 else EXIT_TOOL


def v_search(data, args, place):
    if not args:
        return refuse(EXIT_USAGE, T("sb.msg.usage", "sb search <pattern> [--limit N]"))
    rest = list(args)
    if "--root" not in rest:
        rest = ["--root", shell_path(VAULT)] + rest
    rc, _ = run_tool("find-in-vault.sh", rest)
    return EXIT_OK if rc == 0 else EXIT_TOOL


def which_sb():
    names = ("sb.cmd", "sb") if IS_WINDOWS else ("sb",)
    for name in names:
        found = shutil.which(name)
        if found:
            return found
    return None


# Mission 241: the margin under the Codex cap sb doctor wants kept free, so
# that the next skill's description fits without shortening another first.
CODEX_MARGIN = 500


def codex_budget():
    sys.path.insert(0, TOOLS)
    try:
        import sb_installer_helper as helper
        default_entries, external_entries = helper._method_skill_entries(VAULT)
        total, _ = helper._codex_budget(default_entries, external_entries)
        return total, helper.MAX_CODEX_DEFAULT_SKILLS_BUDGET
    except Exception:
        return None, 8000


def mcp_hosts():
    """The hosts of the Vault's MCP server (Mission 242): the table of
    tools/lib/mcp-hosts.sh, one source for the installer, the containment check
    and sb. Each: id, name, format, config (native path), present."""
    script = f'. "{shell_path(os.path.join(TOOLS, "lib", "mcp-hosts.sh"))}" && mcp_hosts --native'
    try:
        proc = subprocess.run([bash_exe(), "-c", script], capture_output=True, text=True,
                              encoding="utf-8", errors="replace")
    except OSError:
        return []
    hosts = []
    for line in (proc.stdout or "").splitlines():
        cells = line.split("\t")
        if len(cells) != 5:
            continue
        config = cells[3]
        hosts.append({"id": cells[0], "name": cells[1], "format": cells[2], "config": config,
                      "present": cells[4] == "1"})
    return hosts


def vault_server_name():
    rc, text = run_tool("vault-identity.sh", ["get", "server_name"], capture=True)
    lines = [l.strip() for l in text.splitlines() if l.strip()]
    return lines[-1] if rc == 0 and lines else ""


def server_declared(host, server):
    """Read-only: does this host's configuration declare the server?"""
    try:
        with open(host["config"], encoding="utf-8-sig") as f:
            text = f.read()
    except OSError:
        return False
    if host["format"] == "codex-cli":
        pattern = r'(?m)^\[mcp_servers\.(?:"%s"|%s)\]' % (re.escape(server), re.escape(server))
        return re.search(pattern, text) is not None
    try:
        return server in (json.loads(text).get("mcpServers") or {})
    except (ValueError, AttributeError):
        return False


def dead_links(project):
    dead = []
    for sub in (os.path.join(".claude", "skills"), os.path.join(".agents", "skills")):
        folder = os.path.join(project, sub)
        try:
            entries = os.listdir(folder)
        except OSError:
            continue
        for name in entries:
            path = os.path.join(folder, name)
            if (os.path.islink(path) or _is_junction(path)) and not os.path.exists(path):
                dead.append(path)
    return dead


def skill_renames():
    """tools/skill-renames.tsv (Mission 237): old skill name -> new name."""
    renames = {}
    try:
        with open(os.path.join(TOOLS, "skill-renames.tsv"), encoding="utf-8") as f:
            for line in f:
                cells = line.rstrip("\r\n").split("\t")
                if line.strip() and not line.startswith("#") and len(cells) >= 2:
                    renames[cells[0]] = cells[1]
    except OSError:
        pass
    return renames


def _is_junction(path):
    try:
        return bool(os.lstat(path).st_file_attributes & 0x400)
    except (AttributeError, OSError):
        return False


def explain_refusal(fragment):
    """Rows of the refusal tables, and the bullet lines (message, cause, fix), of the
    troubleshooting guides that contain the fragment."""
    hits = []
    for guide in ("react-to-a-guardian-refusal.md", "troubleshoot.md", "add-a-skill.md"):
        path = os.path.join(VAULT, "docs", "how-to", guide)
        heading = ""
        try:
            with open(path, encoding="utf-8-sig") as f:
                lines = f.read().splitlines()
        except OSError:
            continue
        for line in lines:
            if line.startswith("#"):
                heading = line.lstrip("#").strip()
                continue
            if fragment.lower() not in line.lower():
                continue
            if line.startswith("|") and "---" not in line:
                cells = [c.strip() for c in line.strip().strip("|").split("|")]
                hits.append((guide, heading, " · ".join(cells)))
            elif line.startswith("- "):
                hits.append((guide, heading, line[2:].strip()))
    return hits


def v_doctor(data, args, place):
    if args:
        fragment = " ".join(args)
        hits = explain_refusal(fragment)
        out(bold(T("sb.doctor.explainTitle", fragment)))
        if not hits:
            out("  " + T("sb.doctor.noMatch"))
            return EXIT_TOOL
        for guide, heading, text in hits[:6]:
            out()
            out("  " + bold(heading))
            out("  " + text.replace("`", ""))
            out(dim("  docs/how-to/" + guide))
        return EXIT_OK
    out(bold(T("sb.doctor.title")))
    results = []

    def check(ok, label, detail, fix=""):
        results.append((ok, label, detail, fix))

    sb_path = which_sb()
    if sb_path and is_under(sb_path, BIN_DIR):
        check("ok", T("sb.doctor.path"), sb_path)
    elif sb_path:
        check("fail", T("sb.doctor.path"), T("sb.doctor.otherSb", sb_path), "sb install --path")
    else:
        check("warn", T("sb.doctor.path"), T("sb.doctor.noSb"), "sb install --path")
    for tool in ("git", "uv"):
        check("ok" if shutil.which(tool) else "fail", tool, shutil.which(tool) or T("sb.doctor.missing"),
              "sb install" if not shutil.which(tool) else "")
    rc, output = run_tool("check-workspace-root.sh", [shell_path(WORKSPACE)] if WORKSPACE else [], capture=True)
    verdict = [l for l in output.splitlines() if l.startswith("VERDICT")]
    gaps = [re.sub(r"^\S+:\s*", "", l).split(" \u2014 ")[0].strip()
            for l in output.splitlines() if l.startswith(("ÉCART", "ECART"))]
    root_detail = display_paths_in(verdict[-1] if verdict else output.strip()[-160:])
    if gaps:
        root_detail = T("sb.doctor.rootGaps", len(gaps), ", ".join(gaps))
    check("ok" if rc == 0 else "warn", T("sb.doctor.root"), root_detail, "sb clean" if rc != 0 else "")
    hooks = git(["config", "core.hooksPath"], VAULT)
    hooks_ok = bool(hooks and hooks.rstrip("/").endswith(".githooks"))
    check("ok" if hooks_ok else "warn", T("sb.doctor.hooks"), hooks or T("sb.doctor.unset"),
          "" if hooks_ok else f"git -C {shell_path(VAULT)} config core.hooksPath .githooks")
    porcelain = git(["status", "--porcelain"], VAULT, check=True) or ""
    n = len([l for l in porcelain.splitlines() if l.strip()])
    check("ok" if n == 0 else "warn", T("sb.doctor.vaultTree"), T("sb.doctor.changes", n))
    if IS_WINDOWS:
        # Mission 241: the documentation still names `bash <Vault>/tools/...`
        # for a few gestures; PowerShell does not know `bash` unless Git's
        # bin folder is on the PATH. Said, never blocking.
        found = shutil.which("bash")
        windir = os.environ.get("WINDIR", r"C:\Windows")
        if found and not is_under(found, windir):
            check("ok", "bash", found)
        else:
            check("warn", "bash", T("sb.doctor.noBash"),
                  T("sb.doctor.bashForm", bash_exe() if os.path.isabs(bash_exe()) else r"C:\Program Files\Git\bin\bash.exe"))
    total, cap = codex_budget()
    if total is not None:
        margin = cap - total
        state = "ok" if margin >= CODEX_MARGIN else "warn"
        check(state, T("sb.doctor.codex"), T("sb.doctor.codexDetail", total, cap, margin),
              "docs/how-to/add-a-skill.md" if state != "ok" else "")
    # Mission 242: the Vault's server in every host present, the name's length.
    server = vault_server_name()
    hosts = mcp_hosts()
    if server:
        length = len(f"mcp__{server}__list_allowed_directories")
        if length > 64:
            check("warn", T("sb.doctor.mcpName"), T("sb.doctor.mcpNameLong", server, length, 64),
                  "sb install --mcp --label <label>")
        present = [h for h in hosts if h["present"]]
        twice = {h["id"] for h in present if sum(1 for x in present if x["id"] == h["id"]) > 1}
        for h in present:
            where = f" ({display_path(h['config'])})" if h["id"] in twice else ""
            if server_declared(h, server):
                check("ok", T("sb.doctor.mcpHost", h["name"]), T("sb.doctor.mcpDeclared", server) + where)
            else:
                check("warn", T("sb.doctor.mcpHost", h["name"]), T("sb.doctor.mcpMissing", server) + where,
                      "sb install --mcp")
        absent = []
        for h in hosts:
            if not h["present"] and h["name"] not in absent:
                absent.append(h["name"])
        if absent:
            check("info", T("sb.doctor.mcpAbsent"), ", ".join(absent))
    if any(h["id"] == "claude-desktop" and h["present"] for h in hosts):
        # Mission 244 (finding 12): the application reloads its servers only once ENDED.
        check("info", T("sb.doctor.desktopHint"), T("sb.doctor.desktopHintDetail." + platform_key()))
    # Mission 244 (finding 20, orientation 3): an Executor is an agent with a shell.
    agents = [name for name, cmd in (("Claude Code", "claude"), ("Codex", "codex")) if shutil.which(cmd)]
    if agents:
        check("ok", T("sb.doctor.executor"), ", ".join(agents))
    else:
        check("warn", T("sb.doctor.executor"), T("sb.doctor.executorNone"), T("sb.doctor.executorFix." + platform_key()))
    state = plugin_state()
    check("ok" if state == "installed" else ("warn" if state == "stale" else "info"), T("sb.doctor.plugin"),
          {"installed": T("sb.doctor.pluginOk"), "market": T("sb.doctor.pluginNo"),
           "none": T("sb.doctor.marketNo"), "stale": T("sb.doctor.pluginStale")}[state],
          "" if state == "installed" else "sb install")
    if place.project:
        rc, output = run_tool("project-bootstrap.sh", ["identity", shell_path(place.project), "--check"], capture=True)
        check("ok" if rc == 0 else "fail", T("sb.doctor.identity"),
              project_name(place.project) if rc == 0 else output.strip().splitlines()[-1][:160] if output.strip() else "?",
              "sb pilot-prompt --regen" if rc != 0 else "")
        rc, output = run_tool("check-project-conformity.sh", [shell_path(place.project)], capture=True)
        last = [l for l in output.splitlines() if l.strip()]
        check("ok" if rc == 0 else "warn", T("sb.doctor.conformity"), last[-1][:160] if last else "?",
              "docs/how-to/bring-a-project-into-conformity.md" if rc != 0 else "")
        dead = dead_links(place.project)
        check("ok" if not dead else "warn", T("sb.doctor.links"),
              T("sb.doctor.deadLinks", len(dead)) if dead else T("sb.doctor.linksOk"),
              "sb adopt" if dead else "")
        renames = skill_renames()
        for d in dead:
            new = renames.get(os.path.basename(d))
            results.append(("info", "", d + (" -> " + new if new else ""),
                            "sb adopt" if new else ""))
    marks = {"ok": "OK  ", "warn": "WARN", "fail": "FAIL", "info": "INFO"}
    for ok, label, detail, fix in results:
        line = f"  {marks[ok]}  {label:<24} {detail}"
        out(line)
        if fix:
            out(dim(f"        → {fix}"))
    failed = any(r[0] == "fail" for r in results)
    out()
    out(T("sb.doctor.summaryFail") if failed else T("sb.doctor.summaryOk"))
    return EXIT_TOOL if failed else EXIT_OK


def _plugins_dir():
    return os.environ.get("SB_CLAUDE_PLUGINS_DIR") or os.path.join(os.path.expanduser("~"), ".claude", "plugins")


def plugin_state():
    """Read-only (Mission 237): "none" (no marketplace pointing at
    skills/claude-plugins in the user's Claude Code settings), "market" (the
    marketplace is known, sb is not installed) or "installed"."""
    base = _plugins_dir()
    target = norm(PLUGIN_ROOT)
    try:
        with open(os.path.join(base, "known_marketplaces.json"), encoding="utf-8") as f:
            known = json.load(f)
    except (OSError, ValueError):
        return "none"
    try:
        with open(os.path.join(base, "installed_plugins.json"), encoding="utf-8") as f:
            installed = json.load(f).get("plugins", {})
    except (OSError, ValueError, AttributeError):
        installed = {}
    state = "none"
    for market, entry in (known.items() if isinstance(known, dict) else []):
        if not isinstance(entry, dict):
            continue
        source = entry.get("source") or {}
        where = source.get("path") or source.get("directory") or entry.get("installLocation") or ""
        if where and norm(where) == target:
            records = installed.get(f"sb@{market}")
            if records:
                path = (records[0] or {}).get("installPath") if isinstance(records, list) else None
                return "stale" if path and _plugin_differs(path) else "installed"
            state = "market"
    return state


def _plugin_differs(install_path):
    """Claude Code installs a COPY of the plugin in its cache (measured,
    Mission 237): the copy is stale when a skill of the Vault's plugin differs
    from it, or is missing from it."""
    source = os.path.join(PLUGIN_ROOT, "sb", "skills")
    try:
        names = os.listdir(source)
    except OSError:
        return False
    for name in names:
        a = os.path.join(source, name, "SKILL.md")
        b = os.path.join(install_path, "skills", name, "SKILL.md")
        try:
            with open(a, "rb") as fa, open(b, "rb") as fb:
                if fa.read().replace(b"\r\n", b"\n") != fb.read().replace(b"\r\n", b"\n"):
                    return True
        except OSError:
            if os.path.isfile(a):
                return True
    return False


def _plugin_registered():
    return plugin_state() == "installed"


def claude_cmd():
    """The claude command line; SB_CLAUDE replaces it (tests)."""
    override = os.environ.get("SB_CLAUDE")
    if override:
        return [sys.executable, override] if override.endswith(".py") else [override]
    found = shutil.which("claude")
    return [found] if found else None


def dir_size(path):
    total, count = 0, 0
    for root, _dirs, files in os.walk(path):
        for name in files:
            try:
                total += os.path.getsize(os.path.join(root, name))
                count += 1
            except OSError:
                pass
    return total, count


def purge_temp(tmp_root, assume_yes):
    """Empties the declared temporary folder (Mission 237): the Owner's gesture
    (Decision 110852), run by the Owner's command. Never _trash nor _archive,
    never a folder of the workspace, never a drive or a profile root."""
    if not tmp_root or not os.path.isdir(tmp_root):
        return refuse(EXIT_TOOL, T("sb.clean.purge.none", display_path(tmp_root or "?")))
    real = norm(tmp_root)
    forbidden = [norm(os.path.expanduser("~")), norm(os.path.abspath(os.sep))]
    if WORKSPACE:
        forbidden.append(norm(WORKSPACE))
    if (real in forbidden or (WORKSPACE and is_under(tmp_root, WORKSPACE))
            or os.path.basename(real) in ("_trash", "_archive") or len(real) < 8):
        return refuse(EXIT_FORBIDDEN, T("sb.clean.purge.refused", display_path(tmp_root)))
    size, count = dir_size(tmp_root)
    if not assume_yes:
        if not sys.stdin.isatty():
            return refuse(EXIT_USAGE, T("sb.clean.purge.needYes"))
        try:
            answer = input(T("sb.clean.purge.confirm", display_path(tmp_root), count, round(size / 1048576, 1)) + " ")
        except EOFError:
            # Windows: NUL passes for a terminal, and reading it ends at once.
            out("")
            return refuse(EXIT_USAGE, T("sb.clean.purge.needYes"))
        if answer.strip().lower() not in ("y", "yes", "o", "oui", "s", "si", "sí"):
            out(T("sb.clean.purge.cancelled"))
            return EXIT_OK
    kept = []
    for name in os.listdir(tmp_root):
        path = os.path.join(tmp_root, name)
        try:
            if os.path.isdir(path) and not os.path.islink(path):
                shutil.rmtree(path)
            else:
                os.unlink(path)
        except OSError:
            kept.append(name)
    out(T("sb.clean.purge.done", display_path(tmp_root), count, round(size / 1048576, 1)))
    for name in kept:
        out("  " + T("sb.clean.purge.kept", name))
    return EXIT_OK


def v_clean(data, args, place):
    if "--purge-temp" in args:
        _code, tmp_root = subprocess_tmp_root()
        return purge_temp(tmp_root, "--yes" in args)
    out(bold(T("sb.clean.title")))
    run_tool("check-workspace-root.sh", [shell_path(WORKSPACE)])
    _code, tmp_root = subprocess_tmp_root()
    out()
    if tmp_root and os.path.isdir(tmp_root):
        size, count = dir_size(tmp_root)
        out(T("sb.clean.tmp", display_path(tmp_root), count, round(size / 1048576, 1)))
    trash = os.path.join(WORKSPACE, "_trash")
    if os.path.isdir(trash):
        size, count = dir_size(trash)
        out(T("sb.clean.trash", display_path(trash), count, round(size / 1048576, 1)))
    out()
    text_block(T("sb.clean.rule"), indent=0)
    return EXIT_OK


def subprocess_tmp_root():
    script = f'. "{shell_path(os.path.join(TOOLS, "lib", "tmp.sh"))}" && sb_tmp_root'
    try:
        proc = subprocess.run([bash_exe(), "-c", script], capture_output=True, text=True,
                              encoding="utf-8", errors="replace")
    except OSError:
        return 1, None
    value = (proc.stdout or "").strip().splitlines()
    path = value[-1] if value else ""
    if IS_WINDOWS and re.match(r"^/[a-zA-Z]/", path):
        path = path[1].upper() + ":" + path[2:].replace("/", "\\")
    return proc.returncode, path or None


def v_update(data, args, place):
    if not args:
        return refuse(EXIT_USAGE, T("sb.msg.usage", "sb update <version> [--lang FR|EN|ES]"))
    rc, _ = run_tool("second-brain-update.sh", [args[0], "--vault", shell_path(VAULT)] + args[1:])
    return EXIT_OK if rc == 0 else EXIT_TOOL


# --- PATH -------------------------------------------------------------------

PROFILE_MARK = "# Added by the Second Brain installer"


def _broadcast_environment():
    try:
        import ctypes
        result = ctypes.c_ulong()
        ctypes.windll.user32.SendMessageTimeoutW(0xFFFF, 0x001A, 0, "Environment", 0x0002, 5000,
                                                 ctypes.byref(result))
    except Exception:
        pass


def _simulated_path_file():
    """Tests only (like the installers' -TestMode): one PATH entry per line in
    this file instead of the user's real PATH."""
    return os.environ.get("SB_PATH_TEST_FILE")


def path_entry_present():
    sim = _simulated_path_file()
    if sim:
        try:
            with open(sim, encoding="utf-8") as f:
                return any(norm(l.strip()) == norm(BIN_DIR) for l in f if l.strip())
        except OSError:
            return False
    if IS_WINDOWS:
        import winreg
        try:
            with winreg.OpenKey(winreg.HKEY_CURRENT_USER, "Environment") as key:
                value, _ = winreg.QueryValueEx(key, "Path")
        except OSError:
            return False
        return any(norm(p) == norm(BIN_DIR) for p in value.split(";") if p)
    profile = os.path.join(os.path.expanduser("~"), ".profile")
    try:
        with open(profile, encoding="utf-8") as f:
            return BIN_DIR in f.read()
    except OSError:
        return False


def add_path_entry():
    """Same primitive as install.ps1's Add-InstallerPathEntry and install.sh's
    add_installer_path_entry: the user Path (Windows), a marked block in
    ~/.profile (elsewhere). Idempotent."""
    if path_entry_present():
        return "present"
    sim = _simulated_path_file()
    if sim:
        with open(sim, "a", encoding="utf-8") as f:
            f.write(BIN_DIR + "\n")
        return "added"
    if IS_WINDOWS:
        import winreg
        with winreg.OpenKey(winreg.HKEY_CURRENT_USER, "Environment", 0,
                            winreg.KEY_READ | winreg.KEY_WRITE) as key:
            try:
                value, kind = winreg.QueryValueEx(key, "Path")
            except OSError:
                value, kind = "", winreg.REG_EXPAND_SZ
            parts = [p for p in value.split(";") if p]
            parts.append(BIN_DIR)
            winreg.SetValueEx(key, "Path", 0, kind, ";".join(parts))
        _broadcast_environment()
        return "added"
    profile = os.path.join(os.path.expanduser("~"), ".profile")
    with open(profile, "a", encoding="utf-8") as f:
        f.write(f"\n{PROFILE_MARK}\nexport PATH=\"{BIN_DIR}:$PATH\"\n")
    return "added"


def remove_path_entry():
    if not path_entry_present():
        return "absent"
    sim = _simulated_path_file()
    if sim:
        with open(sim, encoding="utf-8") as f:
            kept = [l for l in f if l.strip() and norm(l.strip()) != norm(BIN_DIR)]
        with open(sim, "w", encoding="utf-8") as f:
            f.writelines(kept)
        return "removed"
    if IS_WINDOWS:
        import winreg
        with winreg.OpenKey(winreg.HKEY_CURRENT_USER, "Environment", 0,
                            winreg.KEY_READ | winreg.KEY_WRITE) as key:
            value, kind = winreg.QueryValueEx(key, "Path")
            parts = [p for p in value.split(";") if p and norm(p) != norm(BIN_DIR)]
            winreg.SetValueEx(key, "Path", 0, kind, ";".join(parts))
        _broadcast_environment()
        return "removed"
    profile = os.path.join(os.path.expanduser("~"), ".profile")
    with open(profile, encoding="utf-8") as f:
        lines = f.read().split("\n")
    kept = []
    for i, line in enumerate(lines):
        if BIN_DIR in line:
            if kept and kept[-1] == PROFILE_MARK:
                kept.pop()
            continue
        kept.append(line)
    with open(profile, "w", encoding="utf-8") as f:
        f.write("\n".join(kept))
    return "removed"


def v_install(data, args, place):
    if "--path" in args:
        state = add_path_entry()
        out(T(f"sb.install.path.{state}", BIN_DIR))
        out(dim(T("sb.install.path.reopen")))
        return EXIT_OK
    if "--run" in args:
        if IS_WINDOWS:
            cmd = ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File",
                   os.path.join(VAULT, "install.ps1")]
        else:
            cmd = [bash_exe(), os.path.join(VAULT, "install.sh")]
        return EXIT_OK if subprocess.run(cmd).returncode == 0 else EXIT_TOOL
    if "--plugin" in args:
        return install_plugin(1)
    if "--mcp" in args:
        label = None
        if "--label" in args:
            i = args.index("--label")
            if i + 1 >= len(args) or args[i + 1].startswith("-"):
                return refuse(EXIT_USAGE, T("sb.msg.usage", "sb install --mcp [--label <label>]"))
            label = args[i + 1]
        return install_mcp(1, label)
    # Mission 237: the whole sequence, each step idempotent ("already there" is
    # not an error): 1. sb on the PATH, 2. the marketplace, 3. the plugin.
    out(bold(T("sb.install.title")))
    state = add_path_entry()
    out(T("sb.install.step.path", 1, T(f"sb.install.path.{state}", display_path(BIN_DIR))))
    code = install_plugin(2)
    code = install_mcp(4) or code
    out()
    out(dim(T("sb.install.path.reopen")))
    return code


def install_mcp(n, label=None):
    """Step 4 (Mission 237): the Vault's MCP server, through
    tools/install-vault-mcp.sh (idempotent: a second run changes nothing);
    SB_MCP_INSTALLER replaces it (tests). It is what the Pilot needs when its
    project path is not an authorized folder. Mission 242: in every host
    present (tools/lib/mcp-hosts.sh), in the reader's language, with the label
    `--label` names; a refusal (a name too long, another Vault's server) is
    relayed whole, with the name it proposes."""
    script = os.environ.get("SB_MCP_INSTALLER") or os.path.join(TOOLS, "install-vault-mcp.sh")
    rc, text = (1, "")
    running = desktop_running()
    stopped = False
    if running:
        # Mission 244 (finding 12): asked before writing; ended only on a yes.
        out(T("sb.install.desktop.running", len(running)))
        if ask_yes_no(T("sb.install.desktop.ask"), default_interactive=True):
            stopped = desktop_stop([pid for pid, _ in running])
            out(T("sb.install.desktop.stopped") if stopped else T("sb.install.desktop.notStopped"))
    cmd = [bash_exe(), shell_path(script), shell_path(WORKSPACE or ""), "--lang", T.lang.upper()]
    if label:
        cmd += ["--label", label]
    env = dict(os.environ, SB_DESKTOP_HANDLED="1")
    try:
        proc = subprocess.run(cmd, env=env,
                              capture_output=True, text=True, encoding="utf-8", errors="replace")
        rc, text = proc.returncode, ((proc.stdout or "") + (proc.stderr or "")).strip()
    except OSError as exc:
        text = str(exc)
    if rc != 0:
        lines = [l for l in text.splitlines() if l.strip()]
        out(T("sb.install.step.mcp", n, T("sb.install.failed", lines[-1] if lines else rc)))
        for line in lines[:-1]:
            out("   " + display_paths_in(line))
        return EXIT_TOOL
    out(T("sb.install.step.mcp", n, T("sb.install.added")))
    identity = os.path.join(VAULT, "VAULT-IDENTITY.md")
    state, _ = commit_alone(VAULT, [identity], "Workspace label recorded by sb install --mcp")
    if state == "done":
        # Mission 244 (finding 7): the label is committed, the Vault left clean.
        out(dim("   " + T("sb.install.identityCommitted", git(["rev-parse", "--short", "HEAD"], VAULT) or "?")))
    elif state == "refused":
        out(T("sb.install.identityRefused", display_path(identity)))
    # Mission 244 (finding 6): every line of the tool -- what was found, written,
    # read back -- so that its last line, the restart, names what is above it.
    for line in [l for l in text.splitlines() if l.strip()]:
        out(dim("   " + display_paths_in(line)))
    if running and not stopped:
        out(T("sb.install.desktop.gesture." + platform_key()))
    return EXIT_OK


def platform_key():
    return "windows" if IS_WINDOWS else ("macos" if sys.platform == "darwin" else "linux")


def desktop_running():
    """The Claude desktop application's processes, [(pid, path)], through
    tools/lib/mcp-hosts.sh (its path tells it from Claude Code; tests simulate
    the list, never a real process)."""
    script = f'. "{shell_path(os.path.join(TOOLS, "lib", "mcp-hosts.sh"))}" && mcp_desktop_running'
    try:
        proc = subprocess.run([bash_exe(), "-c", script], capture_output=True, text=True,
                              encoding="utf-8", errors="replace")
    except OSError:
        return []
    found = []
    for line in (proc.stdout or "").splitlines():
        cells = line.split("\t", 1)
        if len(cells) == 2 and cells[0].strip():
            found.append((cells[0].strip(), cells[1]))
    return found


def desktop_stop(pids):
    script = (f'. "{shell_path(os.path.join(TOOLS, "lib", "mcp-hosts.sh"))}" && mcp_desktop_stop '
              + " ".join(str(p) for p in pids if str(p).isdigit()))
    try:
        return subprocess.run([bash_exe(), "-c", script], capture_output=True).returncode == 0
    except OSError:
        return False


def ask_yes_no(question, default_interactive):
    """A yes/no question in the terminal. Without a terminal the answer is
    « no » (Mission 244 constraint: nothing is ended without an explicit yes).
    Tests only: SB_TEST_TTY_ANSWER stands for the typed answer, honoured when
    the process list is simulated (SB_TEST_PROCESS_LIST)."""
    simulated = os.environ.get("SB_TEST_TTY_ANSWER") if os.environ.get("SB_TEST_PROCESS_LIST") else None
    if simulated is None and not sys.stdin.isatty():
        out(question + " " + T("sb.install.desktop.nonInteractive"))
        return False
    if simulated is not None:
        answer = simulated
        out(question + " " + answer)
    else:
        try:
            answer = input(question + " ")
        except EOFError:
            # Windows: NUL passes for a terminal, and reading it ends at once.
            out(T("sb.install.desktop.nonInteractive"))
            return False
    answer = answer.strip().lower()
    if not answer:
        return default_interactive
    return answer in ("y", "yes", "o", "oui", "s", "si", "sí")


def _run_claude(args):
    cmd = claude_cmd()
    if not cmd:
        return None, ""
    try:
        proc = subprocess.run(cmd + args, capture_output=True, text=True, encoding="utf-8", errors="replace")
    except OSError as exc:
        return 1, str(exc)
    return proc.returncode, ((proc.stdout or "") + (proc.stderr or "")).strip()


def install_plugin(first_step):
    """Adds the marketplace second-brain (skills/claude-plugins) and installs
    sb@second-brain in the user's Claude Code settings -- the Owner's gesture,
    by the Owner's command; the installer never does it (rule Q17)."""
    n = first_step
    if not claude_cmd():
        out(T("sb.install.step.market", n, T("sb.install.noClaude")))
        return EXIT_OK
    state = plugin_state()
    if state == "none":
        rc, text = _run_claude(["plugin", "marketplace", "add", PLUGIN_ROOT])
        if rc != 0:
            out(T("sb.install.step.market", n, T("sb.install.failed", text.splitlines()[-1] if text else rc)))
            return EXIT_TOOL
        out(T("sb.install.step.market", n, T("sb.install.added")))
    else:
        out(T("sb.install.step.market", n, T("sb.install.already")))
    if plugin_state() == "stale":
        # A copy older than the Vault's plugin: reinstalled from the Vault.
        _run_claude(["plugin", "uninstall", "sb@second-brain"])
    if plugin_state() != "installed":
        rc, text = _run_claude(["plugin", "install", "sb@second-brain"])
        if rc != 0:
            out(T("sb.install.step.plugin", n + 1, T("sb.install.failed", text.splitlines()[-1] if text else rc)))
            return EXIT_TOOL
        out(T("sb.install.step.plugin", n + 1, T("sb.install.added")))
        out(dim(T("sb.install.reload")))
    else:
        out(T("sb.install.step.plugin", n + 1, T("sb.install.already")))
    return EXIT_OK


def v_uninstall(data, args, place):
    if "--path" in args:
        out(T(f"sb.install.path.{remove_path_entry()}", BIN_DIR))
        return EXIT_OK
    out(bold(T("sb.uninstall.title")))
    text_block(T("sb.uninstall.steps", WORKSPACE or "<workspace>", BIN_DIR), indent=0)
    out(dim(os.path.join(VAULT, "docs", "how-to", "uninstall.md")))
    return EXIT_OK


def v_add_skill(data, args, place):
    if not args:
        return refuse(EXIT_USAGE, T("sb.msg.usage", "sb add-skill <skill folder>"))
    folder = os.path.abspath(args[0])
    skill_md = os.path.join(folder, "SKILL.md")
    if not os.path.isfile(skill_md):
        return refuse(EXIT_TOOL, T("sb.addSkill.noSkill", skill_md))
    fm = read_frontmatter(skill_md)
    name = fm.get("name", "")
    desc = fm.get("description", "")
    problems = []
    if not re.fullmatch(r"[a-z0-9]+(-[a-z0-9]+)*", name or ""):
        problems.append(T("sb.addSkill.badName", name))
    if name and name != os.path.basename(folder):
        problems.append(T("sb.addSkill.nameFolder", name, os.path.basename(folder)))
    if not desc:
        problems.append(T("sb.addSkill.noDesc"))
    total, cap = codex_budget()
    already = is_under(folder, os.path.join(VAULT, "skills"))
    after = (total or 0) + (0 if already else len(desc))
    out(bold(T("sb.addSkill.title", name or "?")))
    table([("name", name or "—"), ("description", f"{len(desc)} " + T("sb.addSkill.chars")),
           ("Codex", f"{after} / {cap}")])
    if after > cap:
        problems.append(T("sb.addSkill.budget", after, cap))
    for p in problems:
        out("  ✗ " + p)
    out()
    text_block(T("sb.addSkill.next"), indent=0)
    return EXIT_TOOL if problems else EXIT_OK


def v_publish(data, args, place):
    if git(["remote", "get-url", "release"], VAULT) is None:
        return refuse(EXIT_FORBIDDEN, T("sb.publish.notLab"), T("sb.goto.laboratory"))
    rc, _ = run_tool("publish-from-laboratory.sh", args, cwd=VAULT)
    return EXIT_OK if rc == 0 else EXIT_TOOL


def installer_finish(data, args):
    """The installer's last screen (Mission 244, findings 5, 20, 27, 28): not a
    verb -- install.ps1 and install.sh call it once, at the very end. Outside
    the installers' test mode: `sb install` (PATH, plugin when Claude Code is
    there, the server in every host present, the Claude application asked
    about first), then `sb doctor`. Always: the welcome Pilot's block on the
    clipboard (a test names SB_CLIPBOARD_FILE; never the real clipboard in test
    mode), or in a file under the Vault's .install/ folder; then the three
    gestures, each starting with its place, for the family the Owner chose
    (claude: the Claude desktop app, proven; openai: Codex, declared).
    usage: sb.py installer-finish [--test-mode] [--family claude|openai] [--tools <csv>]"""
    test_mode = "--test-mode" in args
    family = args[args.index("--family") + 1] if "--family" in args and args.index("--family") + 1 < len(args) else "claude"
    tools = args[args.index("--tools") + 1] if "--tools" in args and args.index("--tools") + 1 < len(args) else ""
    place = Place(WORKSPACE) if WORKSPACE else Place(VAULT)
    if test_mode:
        out(dim(T("sb.finish.testMode")))
    else:
        out()
        v_install(data, [], place)
        out()
        v_doctor(data, [], place)
        named = [t.strip() for t in tools.split(",") if t.strip()]
        for agent, cmd in (("claude-code", "claude"), ("codex", "codex")):
            if agent in named and not shutil.which(cmd):
                out(T(f"sb.finish.missing.{agent}.{platform_key()}"))
    rc, text = run_tool("project-bootstrap.sh", ["accueil-prompt"], capture=True)
    lines = text.replace("\r\n", "\n").split("\n")
    marks = [i for i, line in enumerate(lines) if line.strip() == "---"]
    block = "\n".join(lines[marks[0] + 1:marks[-1]]).rstrip("\n") + "\n" if rc == 0 and len(marks) >= 2 else ""
    out()
    copied = False
    if block and (not test_mode or os.environ.get("SB_CLIPBOARD_FILE")):
        copied = clipboard_copy(block)
    if copied:
        out(T("sb.finish.copied"))
    elif block:
        target = os.path.join(VAULT, ".install", "accueil-block.txt")
        os.makedirs(os.path.dirname(target), exist_ok=True)
        with open(target, "w", encoding="utf-8", newline="\n") as f:
            f.write(block)
        out(T("sb.finish.written", display_path(target)))
    family = "openai" if family == "openai" else "claude"
    out(bold(T("sb.finish.title")))
    for n in (1, 2, 3):
        out("  " + T(f"sb.finish.{family}.{n}", display_path(WORKSPACE or VAULT)))
    if family == "openai":
        out(dim("  " + T("sb.finish.openai.declared")))
    return EXIT_OK


HANDLERS = {
    "help": v_help, "status": v_status, "open": v_open, "close": v_close, "handoff": v_handoff,
    "profile": v_profile, "new": v_new, "adopt": v_adopt, "list": v_list, "pilot-prompt": v_pilot_prompt,
    "mission": v_mission, "run": v_run, "relay": v_relay, "push": v_push, "search": v_search,
    "doctor": v_doctor, "clean": v_clean, "update": v_update, "install": v_install,
    "uninstall": v_uninstall, "add-skill": v_add_skill, "publish": v_publish,
}


# --- generate ---------------------------------------------------------------

def _rel(from_file, to_path):
    return os.path.relpath(os.path.join(VAULT, to_path), os.path.dirname(from_file)).replace("\\", "/")


def _link(from_file, piece):
    """`tools/x.sh` or `skill session-start` or `docs/...` -> a Markdown link when it names a file."""
    m = re.match(r"^skill ([\w-]+)$", piece)
    if m:
        return f"[skill `{m.group(1)}`]({_rel(from_file, 'skills/' + m.group(1) + '/SKILL.md')})"
    path = piece.split(" ", 1)[0]
    if os.path.exists(os.path.join(VAULT, path)):
        rest = piece[len(path):]
        return f"[`{path}`]({_rel(from_file, path)}){rest}"
    return f"`{piece}`"


def render_reference(data, en):
    target = os.path.join(VAULT, "docs", "reference", "commands.md")
    L = []
    L += ["---", "type: reference", 'title: "Commands"',
          'description: "Every verb of the sb command: usage, where it runs, what it does and does not do, examples, and the card an agent applies. Generated by tools/sb/sb.py generate from tools/sb/verbs.json and the catalogues; never edited by hand."',
          "status: generated", "generated_by: tools/sb/sb.py", "---", "",
          "# COMMANDS", "",
          "Generated by `tools/sb/sb.py generate` from `tools/sb/verbs.json` and the `sb.*` keys of the i18n catalogues. Do not edit by hand. The rule behind it: [the sb command surface](" + _rel(target, "rules/RULES-2026-09-26-200933-sb-command-surface.md") + ").", "",
          "## Grammar", "",
          "`sb <verb> [arguments]` in any terminal; `/sb:<verb>` in Claude Code (plugin `sb`); `$sb <verb>` in Codex; a message that starts with `sb ` to the Pilot or to any other agent. `sb help` shows the welcome screen, `sb help start` the first steps, `sb help <verb>` one page, `sb --version` the version.", "",
          "**For an agent that receives `sb <verb>`:** with a shell, run `sb <verb> <arguments>` (if `sb` is not on the `PATH`: `bash <Vault>/tools/sb/bin/sb` in a POSIX shell such as Git Bash, `& \"<Vault>\\tools\\sb\\bin\\sb.cmd\"` in PowerShell, the Vault being named by the `VAULT-ROOT.md` marker found walking up), show its output as it is, then apply the verb's card below. Exit 3 means wrong place: say where the verb runs, and stop. **Without a shell (the Pilot):** apply the card of a verb marked *Pilot: yes*; for any other verb, answer that it needs a shell and must be typed in an Executor window.", "",
          "## Exit codes", "",
          "| Code | Meaning |", "|---|---|",
          "| 0 | done (or the card of an agent verb shown) |",
          "| 1 | the underlying tool refused or failed; its own message is shown as is |",
          "| 2 | usage: unknown verb, missing or extra argument |",
          "| 3 | wrong place: the refusal names where the verb runs |",
          "| 4 | not allowed here: an Owner-only verb outside the laboratory |", "",
          "## Places", "", "| Place | Where |", "|---|---|"]
    for p in data["places"]:
        L.append(f"| `{p}` | {en.get('sb.place.' + p, p)} |")
    L.append("")
    # Mission 241: the guides `sb help <topic>` are cited here, rendered from
    # the same catalogue keys as in the terminal (English; --lang fr|es).
    L += ["## Help pages", "",
          "`sb help` alone shows the welcome screen; its first line points to `sb help start`. Three guides answer by name, in the language of your profile or the one `--lang fr`, `--lang en` or `--lang es` asks for. Their text lives in the `sb.topic.*` keys of the catalogues; below, the English version, as the terminal shows it.", ""]
    for topic in HELP_TOPICS:
        L += [f"### sb help {topic}", "", "**" + en.get(f"sb.topic.{topic}.title", topic) + ".**", "", "```text"]
        L += [line.rstrip() for line in aligned_lines(en.get(f"sb.topic.{topic}", ""), indent=0)]
        L += ["```", ""]
    for group in data["groups"]:
        L += [f"## {en.get('sb.group.' + group, group)}", ""]
        for v in [x for x in data["verbs"] if x["group"] == group]:
            name = v["verb"]
            L += [f"### sb {name}", "", en.get(f"sb.verb.{name}.summary", ""), ""]
            runs = f"{en.get('sb.place.' + v['place'], v['place'])} (`{v['place']}`)"
            for form, form_place in form_places(v):
                runs += f"; `{form}`: {en.get('sb.place.' + form_place, form_place)} (`{form_place}`)"
            L += ["- **Usage:** " + " · ".join(f"`{u}`" for u in v["usage"]),
                  f"- **Runs:** {runs} · {en.get('sb.nature.' + v['nature'], v['nature'])}",
                  f"- **Surfaces:** `sb {name}` · `/sb:{name}` · `$sb {name}` · Pilot: {'yes' if v.get('pilot') else 'no — needs a shell'}",
                  "- **Built on:** " + ", ".join(_link(target, p) for p in v.get("builtOn", []))]
            if v.get("aliases"):
                L.append("- **Also recognised:** " + ", ".join(f"« {a} »" for a in v["aliases"]))
            if v.get("next"):
                L.append("- **Next:** " + " · ".join(f"`{n}`" for n in v["next"]))
            L += ["", "**What it does.** " + " ".join(en.get(f"sb.verb.{name}.does", "").split("\n")), "",
                  "**What it does not do.** " + " ".join(en.get(f"sb.verb.{name}.doesNot", "").split("\n")), "",
                  "**Examples.**", "", "```text"]
            for line in en.get(f"sb.verb.{name}.examples", "").split("\n"):
                L.append(line.replace("\t", "   # ") if "\t" in line else line)
            L += ["```", "", "**Card (what the agent does).** " + v["card"], ""]
    L += ["## Liens", "",
          "- `prescribed by` — [Rule — The sb command surface](" + _rel(target, "rules/RULES-2026-09-26-200933-sb-command-surface.md") + ")",
          "- `see also` — [Command card](" + _rel(target, "docs/COMMANDS-CARD.md") + ")",
          "- `see also` — [Skills](" + _rel(target, "docs/reference/skills.md") + ")",
          "- `see also` — [Start something new](" + _rel(target, "docs/how-to/start-something-new.md") + ")", ""]
    return target, "\n".join(L)


def render_card(data, en):
    target = os.path.join(VAULT, "docs", "COMMANDS-CARD.md")
    L = ["---", "type: reference", 'title: "Command card"',
         'description: "The sb command on one page: every verb, its usage and where it runs. Generated by tools/sb/sb.py generate; never edited by hand."',
         "status: generated", "generated_by: tools/sb/sb.py", "---", "",
         "# SB — COMMAND CARD", "",
         "`sb <verb>` in a terminal · `/sb:<verb>` in Claude Code · `$sb <verb>` in Codex · `sb <verb>` as a message to the Pilot. `sb help <verb>` for the full page, in your language.", ""]
    first = en.get("sb.home.start", "").split("\n")[0].split("\t")
    if len(first) == 2:
        # Mission 241: the first line of the welcome screen, cited.
        L += [f"**{first[0]}** `{first[1]}` — {en.get('sb.topic.start.title', '')}: [Help pages](" + _rel(target, "docs/reference/commands.md") + "#help-pages).", ""]
    for group in data["groups"]:
        L += [f"## {en.get('sb.group.' + group, group)}", "", "| Verb | Usage | Runs | Does |", "|---|---|---|---|"]
        for v in [x for x in data["verbs"] if x["group"] == group]:
            runs = f"`{v['place']}`" + "".join(f"; `{form}`: `{p}`" for form, p in form_places(v))
            L.append(f"| `{v['verb']}` | `{v['usage'][0]}` | {runs} | {en.get('sb.verb.' + v['verb'] + '.summary', '')} |")
        L.append("")
    L += ["Exit codes: 0 done · 1 the tool refused · 2 usage · 3 wrong place · 4 not allowed here.", "",
          "## Liens", "",
          "- `see also` — [Commands, full reference](" + _rel(target, "docs/reference/commands.md") + ")",
          "- `see also` — [Rule — The sb command surface](" + _rel(target, "rules/RULES-2026-09-26-200933-sb-command-surface.md") + ")", ""]
    return target, "\n".join(L)


PLUGIN_ROOT = os.path.join(VAULT, "skills", "claude-plugins")


def render_plugin(data, en):
    files = []
    market = os.path.join(PLUGIN_ROOT, ".claude-plugin", "marketplace.json")
    files.append((market, json.dumps({
        "name": "second-brain",
        "description": "Second Brain: the sb command surface for Claude Code.",
        "owner": {"name": "Second Brain"},
        "plugins": [{"name": "sb", "source": "./sb",
                     "description": "The sb command of Second Brain as /sb:<verb> -- one thin skill per verb."}],
    }, indent=2, ensure_ascii=False) + "\n"))
    manifest = os.path.join(PLUGIN_ROOT, "sb", ".claude-plugin", "plugin.json")
    files.append((manifest, json.dumps({
        "name": "sb",
        "description": "The sb command of Second Brain: /sb:<verb> runs `sb <verb>` and applies its card. One operation, one verb.",
        "version": vault_version().split(" ")[0],
        "author": {"name": "Second Brain"},
        "license": "MIT",
    }, indent=2, ensure_ascii=False) + "\n"))
    for v in data["verbs"]:
        name = v["verb"]
        path = os.path.join(PLUGIN_ROOT, "sb", "skills", name, "SKILL.md")
        summary = en.get(f"sb.verb.{name}.summary", "")
        hint = v["usage"][0][len("sb " + name):].strip()
        L = ["---", f"name: {name}", "description: " + json.dumps(f"sb {name} — {summary}", ensure_ascii=False)]
        if hint:
            L.append("argument-hint: " + json.dumps(hint, ensure_ascii=False))
        L += ["disable-model-invocation: true", 'license: "MIT"', "---", "",
              f"# /sb:{name}", "",
              f"The Second Brain command `sb {name}`, relayed ([rule]({_rel(path, 'rules/RULES-2026-09-26-200933-sb-command-surface.md')})).", "",
              f"1. Run in the shell: `sb {name} $ARGUMENTS`. If `sb` is not found, run `bash <Vault>/tools/sb/bin/sb {name} $ARGUMENTS` (in PowerShell: `& \"<Vault>\\tools\\sb\\bin\\sb.cmd\" {name} $ARGUMENTS`), the Vault being the folder the `VAULT-ROOT.md` marker names, found walking up from the current folder.",
              "2. Show its output as it is. Exit code 3 means wrong place: say where the verb runs, and stop. Exit code 1: the tool refused; report its message, do not work around it.",
              f"3. Then apply the card: {v['card']}", "",
              "## Liens", "",
              f"- `see also` — [Commands]({_rel(path, 'docs/reference/commands.md')})", ""]
        files.append((path, "\n".join(L)))
    return files


def generate(data, check_only):
    en = Catalog._load("en")
    outputs = [render_reference(data, en), render_card(data, en)] + render_plugin(data, en)
    drift = []
    for path, content in outputs:
        try:
            with open(path, encoding="utf-8", newline="") as f:
                current = f.read()
        except OSError:
            current = None
        if current != content:
            drift.append(path)
            if not check_only:
                os.makedirs(os.path.dirname(path), exist_ok=True)
                with open(path, "w", encoding="utf-8", newline="\n") as f:
                    f.write(content)
    for path in drift:
        print(("DRIFT " if check_only else "WROTE ") + os.path.relpath(path, VAULT).replace("\\", "/"))
    print(f"GENERATED {len(outputs)} files, {len(drift)} {'drifted' if check_only else 'written'}")
    return EXIT_TOOL if (check_only and drift) else EXIT_OK


# --- main -------------------------------------------------------------------

def main(argv):
    global COLOR, T
    vt = _setup_output()
    lang_opt = None
    args = []
    i = 0
    while i < len(argv):
        a = argv[i]
        if a == "--lang" and i + 1 < len(argv):
            lang_opt = argv[i + 1]
            i += 2
            continue
        if a.startswith("--lang="):
            lang_opt = a.split("=", 1)[1]
            i += 1
            continue
        args.append(a)
        i += 1
    T = Catalog(detect_language(lang_opt))
    COLOR = bool(vt and sys.stdout.isatty() and not os.environ.get("NO_COLOR"))
    data = load_verbs()
    if not args or args[0] in ("-h", "--help"):
        return help_home(data)
    if args[0] in ("-V", "--version", "version"):
        head = git(["rev-parse", "--short", "HEAD"], VAULT) or "?"
        out(f"sb {vault_version()} · Second Brain · vault {head} · {VAULT}")
        return EXIT_OK
    if args[0] == "generate":
        return generate(data, "--check" in args[1:])
    if args[0] == "installer-finish":
        return installer_finish(data, args[1:])
    verbs = verb_index(data)
    name, rest = args[0], args[1:]
    if name not in verbs:
        return refuse(EXIT_USAGE, T("sb.msg.unknownVerb", name), T("sb.msg.seeHelp"))
    if rest and rest[0] in ("-h", "--help") and name != "help":
        return help_verb(verbs[name])
    wanted = effective_place(verbs[name], rest)
    if WORKSPACE is None and wanted not in ("anywhere",):
        return refuse(EXIT_PLACE, T("sb.msg.noWorkspace", VAULT), "sb install")
    place = Place(os.getcwd())
    if not place.in_workspace and not place.other_workspace and WORKSPACE and wanted != "anywhere":
        # Mission 244 (finding 1): outside any workspace -- a PowerShell opens in
        # system32 -- sb serves the workspace of its own Vault and says so in one
        # line; inside another workspace it still refuses (that space has its own
        # sb). Never another workspace than its own.
        err(dim(T("sb.here.usingOwn", display_path(WORKSPACE))))
        os.chdir(WORKSPACE)
        place = Place(WORKSPACE)
    if not place.satisfies(wanted):
        # A verb that takes a folder argument checks that folder, not the current one.
        if not (wanted == verbs[name]["place"] and verbs[name].get("folderArg")
                and rest and not rest[0].startswith("-")):
            return place_refusal(verbs[name], place, wanted)
    return HANDLERS[name](data, rest, place)


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv[1:]))
    except KeyboardInterrupt:
        sys.exit(130)
