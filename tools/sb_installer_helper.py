#!/usr/bin/env python3
"""Second Brain installer helper (Mission 168, ticket 08 -- shell parity).

Role: the JSON/text-processing backend for tools/install.sh, the same way
tools/questionnaire.ps1, tools/generate-assistant.ps1 and
tools/deploy-skills.ps1 are install.ps1's own backend on Windows. POSIX
shell has no built-in JSON support, so every read or write of the install
notebook (.install/state.json), an -AnswersFile, or an i18n catalog goes
through one of the subcommands below instead of ad hoc shell parsing --
run via `uv run python3 tools/sb_installer_helper.py <subcommand> ...`
(uv is one of this installer's own prerequisites, ensured before this
script is ever called: tools/prerequisites.sh's ensure_prerequisites).

The schema mirrors install.ps1's Get-Carnet/Save-Carnet and
tools/questionnaire.ps1's $answers object field for field -- this file does
not invent a second schema, it re-reads and re-writes the same shape.

Each subcommand prints its result to stdout and exits 0 on success, or
prints a one-line message to stderr and exits non-zero on failure --
install.sh treats any non-zero exit as a step failure, matching install.ps1
using PowerShell exceptions for the same purpose.
"""
import argparse
import json
import os
import re
import sys
import unicodedata

SCHEMA_VERSION = 1
DEFAULT_ASSISTANT_NAME = "Brian"
MAX_INSTRUCTIONS_CHARS = 8000
MAX_WEB_PACKAGE_FILES = 25
MAX_CODEX_DEFAULT_SKILLS_BUDGET = 8000


def shq(value):
    """Single-quote a value for safe use in a POSIX shell eval."""
    return "'" + str(value).replace("'", "'\\''") + "'"


def read_json(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def write_json_atomic(path, data):
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")
    os.replace(tmp, path)


# --- Answers extraction (shared by load-carnet and load-answers-file) ------

def extract_answers_exports(answers):
    a = answers or {}
    out = []
    for key in ("language", "vaultName", "workspacePath", "firstName", "activity", "whatMatters"):
        val = a.get(key)
        out.append(f"ANSWER_{key.upper()}={shq('' if val is None else val)}")
    out.append(f"ANSWER_AITOOLS={shq(' '.join(a.get('aiTools') or []))}")
    out.append(f"ANSWER_SKILLCOLLECTIONS={shq(' '.join(a.get('skillCollections') or []))}")
    fp = a.get("firstProject") or {}
    fp_create = fp.get("create")
    fp_create_str = "" if fp_create is None else ("true" if fp_create else "false")
    out.append(f"ANSWER_FP_CREATE={shq(fp_create_str)}")
    out.append(f"ANSWER_FP_NAME={shq(fp.get('name') or '')}")
    out.append(f"ANSWER_FP_DISPLAYNAME={shq(fp.get('displayName') or '')}")
    git = a.get("git") or {}
    out.append(f"ANSWER_GIT_USERNAME={shq(git.get('userName') or '')}")
    out.append(f"ANSWER_GIT_USEREMAIL={shq(git.get('userEmail') or '')}")
    return out


def cmd_load_carnet(args):
    if os.path.exists(args.path):
        data = read_json(args.path)
    else:
        data = {"schemaVersion": SCHEMA_VERSION, "answers": {}, "steps": {}, "verdict": None, "lastRunAt": None}
    out = [
        f"CARNET_EXISTED={shq('true' if os.path.exists(args.path) else 'false')}",
        f"CARNET_VERDICT={shq(data.get('verdict') or '')}",
        f"CARNET_LAST_RUN_AT={shq(data.get('lastRunAt') or '')}",
    ]
    out += extract_answers_exports(data.get("answers") or {})
    steps = data.get("steps") or {}
    for step in (
        "workspaceCreated", "cloned", "guardiansConfigured", "markerWritten",
        "assistantGenerated", "skillsDeployed", "firstProjectCreated", "profileWritten",
    ):
        out.append(f"STEP_{step.upper()}={shq('true' if steps.get(step) else '')}")
    asst = data.get("assistant") or {}
    out.append(f"PREV_ASSISTANT_SLUG={shq(asst.get('slug') or '')}")
    print("\n".join(out))


def cmd_load_answers_file(args):
    if not os.path.exists(args.path):
        print(f"Answers file not found: {args.path}", file=sys.stderr)
        return 1
    data = read_json(args.path)
    if not data.get("workspacePath"):
        print(f"Answers file is missing required field: workspacePath", file=sys.stderr)
        return 1
    print("\n".join(extract_answers_exports(data)))
    return 0


def _bool_or_none(text):
    if text in (None, ""):
        return None
    return text == "true"


def cmd_save_carnet(args):
    data = {
        "schemaVersion": SCHEMA_VERSION,
        "answers": {
            "language": args.language or None,
            "vaultName": args.vault_name or None,
            "workspacePath": args.workspace_path or None,
            "firstName": args.first_name or None,
            "activity": args.activity or None,
            "aiTools": [t for t in (args.ai_tools or "").split(" ") if t],
            "whatMatters": args.what_matters or None,
            "skillCollections": [t for t in (args.skill_collections or "").split(" ") if t],
            "firstProject": {
                "create": _bool_or_none(args.fp_create),
                "name": args.fp_name or None,
                "displayName": args.fp_display_name or None,
            },
            "git": {
                "userName": args.git_user_name or None,
                "userEmail": args.git_user_email or None,
            },
        },
        "steps": {name: True for name in (args.steps or "").split(",") if name},
        "verdict": args.verdict or None,
        "lastRunAt": args.last_run_at or None,
    }
    if args.assistant_slug:
        data["assistant"] = {"name": args.assistant_name or "", "slug": args.assistant_slug}
    if args.context_test_mode:
        data["context"] = {
            "testMode": args.context_test_mode == "true",
            "profileRoot": args.context_profile_root or "",
        }
    write_json_atomic(args.path, data)
    return 0


def cmd_field(args):
    data = read_json(args.file)
    value = data
    for part in args.path.split("."):
        if isinstance(value, dict):
            value = value.get(part)
        else:
            value = None
            break
    if value is None:
        print("")
    elif isinstance(value, bool):
        print("true" if value else "false")
    else:
        print(value)
    return 0


def cmd_format_catalog(args):
    catalog = read_json(args.file)
    template = catalog.get(args.key)
    if template is None:
        print(f"Missing catalog key: {args.key}", file=sys.stderr)
        return 1
    text = template
    for i, value in enumerate(args.args):
        text = text.replace("{" + str(i) + "}", value)
    print(text)
    return 0


# --- Assistant identity generation (ticket 06 parity) ----------------------

def slugify(name):
    decomposed = unicodedata.normalize("NFD", name)
    stripped = "".join(ch for ch in decomposed if unicodedata.category(ch) != "Mn")
    ascii_text = unicodedata.normalize("NFC", stripped).lower()
    slug = re.sub(r"[^a-z0-9]+", "-", ascii_text).strip("-")
    return slug or "assistant"


def cmd_slugify(args):
    print(slugify(args.name))
    return 0


def _assistant_body(clone_path, name):
    source_path = os.path.join(clone_path, "assistant", "ASSISTANT.md")
    if not os.path.exists(source_path):
        raise SystemExit(f"Assistant identity source not found: {source_path}")
    with open(source_path, encoding="utf-8") as f:
        raw = f.read().replace("\r\n", "\n")
    start_marker = "<!-- corps-generateur:debut -->"
    end_marker = "<!-- corps-generateur:fin -->"
    start = raw.find(start_marker)
    end = raw.find(end_marker)
    if start < 0 or end < 0 or end <= start:
        raise SystemExit(f"Assistant identity source is missing its corps-generateur markers: {source_path}")
    body = raw[start + len(start_marker):end].strip() + "\n"
    return body.replace("{{ASSISTANT_NAME}}", name)


def _yaml_double_quoted_safe(text):
    return text.replace("\\", "\\\\").replace('"', '\\"')


def _assistant_generated_paths(slug):
    return [
        os.path.join(".claude", "agents", f"{slug}.md"),
        os.path.join(".agents", "skills", slug),
        os.path.join("web-package", slug),
    ]


def cmd_render_assistant(args):
    clone_path = args.clone_path
    name = args.name
    slug = slugify(name)
    body = _assistant_body(clone_path, name)
    safe_name = _yaml_double_quoted_safe(name)

    subagent_path = os.path.join(clone_path, ".claude", "agents", f"{slug}.md")
    os.makedirs(os.path.dirname(subagent_path), exist_ok=True)
    subagent_description = (
        f"Read-only assistant for this Second Brain workspace: answers questions about its "
        f"rules, decisions, knowledge and skills, always citing the source file by path. Use "
        f"when asked about {safe_name}, Second Brain, the Vault, or how something in this "
        f"workspace works. Never writes or runs anything."
    )
    subagent_content = "\n".join([
        "---",
        f"name: {slug}",
        f'description: "{subagent_description}"',
        "tools: Read, Glob, Grep",
        "---",
        "",
        body.rstrip(),
        "",
        "## Liens",
        "",
        "- `see also` -- [assistant/ASSISTANT.md](../../assistant/ASSISTANT.md)",
        "",
    ])
    with open(subagent_path, "w", encoding="utf-8", newline="\n") as f:
        f.write(subagent_content)

    skill_path = os.path.join(clone_path, ".agents", "skills", slug, "SKILL.md")
    os.makedirs(os.path.dirname(skill_path), exist_ok=True)
    skill_description = (
        f"Read-only assistant for this Second Brain workspace: answers questions about its "
        f"rules, decisions, knowledge and skills, always citing the source file by path. Use "
        f"when asked about {safe_name}, Second Brain, or how something in this workspace works."
    )
    skill_content = "\n".join([
        "---",
        f"name: {slug}",
        f'description: "{skill_description}"',
        "---",
        "",
        body.rstrip(),
        "",
        "## Liens",
        "",
        "- `see also` -- [assistant/ASSISTANT.md](../../../assistant/ASSISTANT.md)",
        "",
    ])
    with open(skill_path, "w", encoding="utf-8", newline="\n") as f:
        f.write(skill_content)

    web_dir = os.path.join(clone_path, "web-package", slug)
    os.makedirs(web_dir, exist_ok=True)
    instructions_text = "\n".join([
        body.rstrip(),
        "",
        "## Liens",
        "",
        "- `see also` -- [assistant/ASSISTANT.md](../../assistant/ASSISTANT.md)",
        "",
    ])
    if len(instructions_text) > MAX_INSTRUCTIONS_CHARS:
        print(
            f"Generated web package instructions for '{name}' are {len(instructions_text)} "
            f"characters, over the {MAX_INSTRUCTIONS_CHARS}-character ceiling (ticket 06 criterion 4).",
            file=sys.stderr,
        )
        return 1
    with open(os.path.join(web_dir, "INSTRUCTIONS.md"), "w", encoding="utf-8", newline="\n") as f:
        f.write(instructions_text)
    readme_text = "\n".join([
        f"# {name} -- web package",
        "",
        f"Generated by tools/generate-assistant.ps1 or tools/sb_installer_helper.py from "
        f"assistant/ASSISTANT.md (Mission 168, tickets 06 and 08). To use {name} in a claude.ai "
        f"or ChatGPT Project:",
        "",
        "1. Create a Project (requires a paid plan -- Claude Pro or above, or ChatGPT Plus or "
        "above; this package is not designed or tested against free-tier accounts).",
        "2. Paste the contents of INSTRUCTIONS.md into the Project's custom instructions field.",
        f"3. That is the whole package for now -- {name}'s identity lives entirely in those "
        f"instructions; nothing else needs uploading.",
        "",
        "## Liens",
        "",
        "- `see also` -- [assistant/ASSISTANT.md](../../assistant/ASSISTANT.md)",
        "",
    ])
    with open(os.path.join(web_dir, "README.md"), "w", encoding="utf-8", newline="\n") as f:
        f.write(readme_text)

    file_count = len([n for n in os.listdir(web_dir) if os.path.isfile(os.path.join(web_dir, n))])
    if file_count > MAX_WEB_PACKAGE_FILES:
        print(
            f"Web package for '{name}' has {file_count} files, over the "
            f"{MAX_WEB_PACKAGE_FILES}-file ceiling (ticket 06 criterion 4).",
            file=sys.stderr,
        )
        return 1

    print(slug)
    return 0


def cmd_move_assistant_trash(args):
    import shutil
    import datetime

    clone_path = args.clone_path
    old_slug = args.old_slug
    timestamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    trash_root = os.path.join(clone_path, "_trash", f"assistant-rename-{old_slug}-{timestamp}")
    moved_any = False
    for rel_path in _assistant_generated_paths(old_slug):
        source_path = os.path.join(clone_path, rel_path)
        if not os.path.exists(source_path):
            continue
        destination_path = os.path.join(trash_root, rel_path)
        os.makedirs(os.path.dirname(destination_path), exist_ok=True)
        shutil.move(source_path, destination_path)
        moved_any = True
    print("moved" if moved_any else "none")
    return 0


# --- Skill deployment by link (ticket 07 parity) ---------------------------

def _skill_dir_entries(skills_root, exclude_names=()):
    if not os.path.isdir(skills_root):
        return []
    entries = []
    for name in sorted(os.listdir(skills_root)):
        if name in exclude_names:
            continue
        full = os.path.join(skills_root, name)
        if os.path.isdir(full) and os.path.exists(os.path.join(full, "SKILL.md")):
            entries.append((name, full))
    return entries


def _skill_description(skill_md_path):
    if not os.path.exists(skill_md_path):
        return ""
    with open(skill_md_path, encoding="utf-8") as f:
        text = f.read()
    match = re.search(r'(?m)^description:\s*"((?:[^"\\]|\\.)*)"', text)
    if match:
        return match.group(1)
    match = re.search(r"(?m)^description:\s*(.+)$", text)
    if match:
        return match.group(1).strip()
    return ""


def _available_warehouse_slugs(clone_path):
    root = os.path.join(clone_path, "skills-warehouse", "skill-collections")
    if not os.path.isdir(root):
        return []
    return sorted(
        name for name in os.listdir(root)
        if os.path.isdir(os.path.join(root, name, "skills"))
    )


def _publish_skill_link(link_path, target_path):
    resolved_target = os.path.realpath(target_path)
    if os.path.lexists(link_path):
        if os.path.islink(link_path):
            existing_target = os.path.realpath(link_path)
            if os.path.normcase(existing_target.rstrip("/")) == os.path.normcase(resolved_target.rstrip("/")):
                return "AlreadyLinked"
        return "Conflict"
    os.makedirs(os.path.dirname(link_path), exist_ok=True)
    os.symlink(resolved_target, link_path, target_is_directory=True)
    return "Created"


def cmd_deploy_skills(args):
    clone_path = args.clone_path
    default_entries = _skill_dir_entries(os.path.join(clone_path, "skills"), exclude_names={"external"})

    total = 0
    for name, source_path in default_entries:
        total += len(_skill_description(os.path.join(source_path, "SKILL.md")))
    if total > MAX_CODEX_DEFAULT_SKILLS_BUDGET:
        print(
            f"Default-deployed skills' descriptions total {total} characters, over the "
            f"{MAX_CODEX_DEFAULT_SKILLS_BUDGET}-character Codex budget ceiling (ticket 07 criterion 3).",
            file=sys.stderr,
        )
        return 1

    tokens = [t for t in (args.collections or "").split(" ") if t]
    available_warehouse = {s.lower() for s in _available_warehouse_slugs(clone_path)}
    collected = []
    unknown_tokens = []
    for raw_token in tokens:
        token = raw_token.strip().lower()
        if not token:
            continue
        if token == "external":
            collected += _skill_dir_entries(os.path.join(clone_path, "skills", "external"))
        elif token in available_warehouse:
            collected += _skill_dir_entries(
                os.path.join(clone_path, "skills-warehouse", "skill-collections", token, "skills")
            )
        else:
            unknown_tokens.append(raw_token)

    seen = set()
    duplicates = []
    to_link = []
    for name, source_path in default_entries + collected:
        if name in seen:
            duplicates.append(name)
            continue
        seen.add(name)
        to_link.append((name, source_path))

    conflict_count = 0
    for name, source_path in to_link:
        for target_root in (args.claude_skills_dir, args.codex_agents_skills_dir):
            link_path = os.path.join(target_root, name)
            status = _publish_skill_link(link_path, source_path)
            if status == "Conflict":
                conflict_count += 1
                print(f"CONFLICT {link_path}")

    for name in duplicates:
        print(f"DUPLICATE {name}")
    for token in unknown_tokens:
        print(f"UNKNOWN {token}")
    print(f"DEFAULT_COUNT {len(default_entries)}")
    print(f"BUDGET {total} {MAX_CODEX_DEFAULT_SKILLS_BUDGET}")
    print(f"CONFLICT_COUNT {conflict_count}")
    return 0


# --- USER.md profile (ticket 05 parity) ------------------------------------

def cmd_write_user_profile(args):
    language_labels = {"FR": "français (FR)", "EN": "English (EN)", "ES": "español (ES)"}
    language_label = language_labels.get(args.language, args.language)
    ai_tools = args.ai_tools.split(" ") if args.ai_tools else []
    ai_tools_text = ", ".join(t for t in ai_tools if t) or "aucun renseigné"
    skill_collections = args.skill_collections.split(" ") if args.skill_collections else []
    skill_collections_text = ", ".join(t for t in skill_collections if t) or "aucune"

    lines = [
        "---",
        "type: profile",
        f'title: "Fiche utilisateur — {args.first_name}"',
        f'description: "Rédigée par le questionnaire d\'installation (Mission 168, tickets 05 '
        f'et 08), à partir des réponses données le {args.installed_at}."',
        "status: active",
        "---",
        "",
        "# FICHE UTILISATEUR",
        "",
        "## Qui",
        "",
        f"- **Prénom :** {args.first_name}",
        f"- **Langue de travail :** {language_label}",
        "",
        "## Activité",
        "",
        f"{args.activity}",
        "",
        "## Façon de travailler",
        "",
        f"- **Outils IA :** {ai_tools_text}",
        f"- **Ce qui compte :** {args.what_matters}",
        "",
        "## Environnement",
        "",
        f"- **Système :** {args.os_info}",
        f"- **Shell :** {args.shell_info}",
        f"- **Fuseau horaire :** {args.timezone}",
        f"- **Git :** {args.git_version}",
        f"- **Claude Code détecté :** {args.claude_detected}",
        f"- **Codex détecté :** {args.codex_detected}",
        "",
        "## Origine",
        "",
        f"- **Assistant :** {args.vault_name}",
        f"- **Espace de travail :** {args.workspace_path}",
        f"- **Collections de skills :** {skill_collections_text}",
        f"- **Installé le :** {args.installed_at}",
        "",
        "## Liens",
        "",
        "- `see also` — [AGENTS.md](./AGENTS.md)",
        "",
    ]
    with open(args.path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))
    return 0


def build_parser():
    parser = argparse.ArgumentParser(prog="sb_installer_helper.py")
    sub = parser.add_subparsers(dest="command", required=True)

    p = sub.add_parser("load-carnet")
    p.add_argument("path")
    p.set_defaults(func=cmd_load_carnet)

    p = sub.add_parser("load-answers-file")
    p.add_argument("path")
    p.set_defaults(func=cmd_load_answers_file)

    p = sub.add_parser("save-carnet")
    p.add_argument("path")
    p.add_argument("--language", default="")
    p.add_argument("--vault-name", default="")
    p.add_argument("--workspace-path", default="")
    p.add_argument("--first-name", default="")
    p.add_argument("--activity", default="")
    p.add_argument("--ai-tools", default="")
    p.add_argument("--what-matters", default="")
    p.add_argument("--skill-collections", default="")
    p.add_argument("--fp-create", default="")
    p.add_argument("--fp-name", default="")
    p.add_argument("--fp-display-name", default="")
    p.add_argument("--git-user-name", default="")
    p.add_argument("--git-user-email", default="")
    p.add_argument("--steps", default="")
    p.add_argument("--verdict", default="")
    p.add_argument("--last-run-at", default="")
    p.add_argument("--assistant-name", default="")
    p.add_argument("--assistant-slug", default="")
    p.add_argument("--context-test-mode", default="")
    p.add_argument("--context-profile-root", default="")
    p.set_defaults(func=cmd_save_carnet)

    p = sub.add_parser("field")
    p.add_argument("file")
    p.add_argument("path")
    p.set_defaults(func=cmd_field)

    p = sub.add_parser("format-catalog")
    p.add_argument("file")
    p.add_argument("key")
    p.add_argument("args", nargs="*")
    p.set_defaults(func=cmd_format_catalog)

    p = sub.add_parser("slugify")
    p.add_argument("name")
    p.set_defaults(func=cmd_slugify)

    p = sub.add_parser("render-assistant")
    p.add_argument("clone_path")
    p.add_argument("name")
    p.set_defaults(func=cmd_render_assistant)

    p = sub.add_parser("move-assistant-trash")
    p.add_argument("clone_path")
    p.add_argument("old_slug")
    p.set_defaults(func=cmd_move_assistant_trash)

    p = sub.add_parser("deploy-skills")
    p.add_argument("clone_path")
    p.add_argument("claude_skills_dir")
    p.add_argument("codex_agents_skills_dir")
    p.add_argument("--collections", default="")
    p.set_defaults(func=cmd_deploy_skills)

    p = sub.add_parser("write-user-profile")
    p.add_argument("path")
    p.add_argument("--language", default="EN")
    p.add_argument("--vault-name", default=DEFAULT_ASSISTANT_NAME)
    p.add_argument("--workspace-path", default="")
    p.add_argument("--first-name", default="")
    p.add_argument("--activity", default="")
    p.add_argument("--ai-tools", default="")
    p.add_argument("--what-matters", default="")
    p.add_argument("--skill-collections", default="")
    p.add_argument("--installed-at", default="")
    p.add_argument("--os-info", default="unknown")
    p.add_argument("--shell-info", default="unknown")
    p.add_argument("--timezone", default="unknown")
    p.add_argument("--git-version", default="unknown")
    p.add_argument("--claude-detected", default="False")
    p.add_argument("--codex-detected", default="False")
    p.set_defaults(func=cmd_write_user_profile)

    return parser


def main(argv):
    # Force UTF-8 on stdout/stderr regardless of the host locale or
    # console code page (measured directly on this machine's own Windows
    # terminal: an accented catalog string -- e.g. the "-- Name" signature,
    # or any French/Spanish catalog text -- printed as a mangled
    # replacement character without this; install.ps1's own extensive
    # -Encoding UTF8 discipline exists for the exact same reason). install.sh
    # captures every one of these subcommands' stdout via `$(...)`, so a
    # silent mangle here would corrupt the carnet and the verdict text.
    for stream in (sys.stdout, sys.stderr):
        if hasattr(stream, "reconfigure"):
            stream.reconfigure(encoding="utf-8")
    parser = build_parser()
    args = parser.parse_args(argv)
    return args.func(args) or 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
