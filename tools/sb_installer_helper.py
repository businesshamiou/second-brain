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
import stat
import subprocess
import sys
import unicodedata

SCHEMA_VERSION = 1
DEFAULT_ASSISTANT_NAME = "Brian"
MAX_INSTRUCTIONS_CHARS = 8000
MAX_WEB_PACKAGE_FILES = 25
MAX_CODEX_DEFAULT_SKILLS_BUDGET = 8000

# Knowledge files bundled into the web package alongside INSTRUCTIONS.md
# (Mission 171-C01 step 8, audit defects 8 and 9 -- shell/Python parity with
# tools/generate-assistant.ps1's own $Script:WebPackageKnowledgeFiles;
# that file's own comment carries the full reasoning for why these three
# and not more, and why they are copied verbatim rather than name-
# substituted). Kept as a tuple of (source path relative to the clone,
# file name inside web-package/<slug>/, one-line purpose for the README)
# so cmd_render_assistant and the README text below read from the same
# single list, never two.
WEB_PACKAGE_KNOWLEDGE_FILES = (
    (
        "CONTEXT.md",
        "GLOSSARY.md",
        "the product glossary (validated terms this assistant's own instructions and this package both use)",
    ),
    (
        os.path.join("rules", "RULES-2026-09-11-190000-project-second-brain-boundary.md"),
        "PROJECT-BOUNDARY.md",
        "the rule deciding whether something belongs in Second Brain itself or in one of your projects",
    ),
    (
        "README.md",
        "OVERVIEW.md",
        "this repository's own README: what Second Brain is, how it installs, and what is installed, and where",
    ),
)


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
        "assistantGenerated", "assistantDeployed", "skillsDeployed",
        "firstProjectCreated", "profileWritten",
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


def _web_package_knowledge_file_content(clone_path, source_relative_path):
    """Reads one knowledge-file source, then prepares it for the web
    package: words are never rewritten or name-substituted (see
    WEB_PACKAGE_KNOWLEDGE_FILES's own comment), but the source's own
    '## Liens' section and every other relative Markdown link in its body
    are stripped -- both are correct only from the source's own location
    in this repository, never from web-package/<slug>/, always two levels
    below the clone root (shell/PowerShell parity: mirrors
    tools/generate-assistant.ps1's own Get-WebPackageKnowledgeFileContent,
    including that function's own comment for the full reasoning). A
    fresh '## Liens' entry is appended, pointing back at the exact source
    with the same '../../' depth every other generated form already uses.
    A missing source fails loudly: a silently thinner package is exactly
    the defect (8) this ticket exists to close."""
    source_path = os.path.join(clone_path, source_relative_path)
    if not os.path.exists(source_path):
        raise SystemExit(f"Web package knowledge file source not found: {source_path}")
    with open(source_path, encoding="utf-8") as f:
        raw = f.read().replace("\r\n", "\n")

    liens_marker = "\n## Liens"
    liens_index = raw.find(liens_marker)
    body = raw[:liens_index] if liens_index >= 0 else raw
    body = body.rstrip()
    body = re.sub(r'\[([^\]]+)\]\((?!https?://|mailto:|#)[^)]+\)', r'\1', body)

    source_link = source_relative_path.replace("\\", "/")
    liens_line = f"- `see also` -- [{source_link}](../../{source_link})"
    return "\n".join([body, "", "## Liens", "", liens_line, ""])


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

    for source_relative_path, file_name, _purpose in WEB_PACKAGE_KNOWLEDGE_FILES:
        knowledge_content = _web_package_knowledge_file_content(clone_path, source_relative_path)
        with open(os.path.join(web_dir, file_name), "w", encoding="utf-8", newline="\n") as f:
            f.write(knowledge_content)

    # Rewritten for Mission 171-C01 step 8 (audit defects 8 and 9): names
    # every file this function actually writes into web_dir, built from
    # WEB_PACKAGE_KNOWLEDGE_FILES so the two can never drift apart -- see
    # tools/generate-assistant.ps1's own New-WebPackageReadme for the full
    # rationale (this mirrors it exactly, shell/Python parity).
    knowledge_lines = [f"- `{file_name}` -- {purpose}." for _src, file_name, purpose in WEB_PACKAGE_KNOWLEDGE_FILES]
    readme_text = "\n".join([
        f"# {name} -- web package",
        "",
        f"Generated by tools/generate-assistant.ps1 (or tools/sb_installer_helper.py on macOS/Linux) "
        f"from assistant/ASSISTANT.md and this repository's own documents (Mission 171-C01). This is "
        f"a claude.ai or ChatGPT **Project** package -- custom instructions plus a few "
        f"project-knowledge files -- not a Skill package: nothing in this folder is a zip meant to "
        f"be uploaded so it can trigger on its own.",
        "",
        f"To use {name} in a claude.ai or ChatGPT Project:",
        "",
        "1. Create a Project (requires a paid plan -- Claude Pro or above, or ChatGPT Plus or "
        "above; this package is not designed or tested against free-tier accounts).",
        "2. Paste the contents of `INSTRUCTIONS.md` into the Project's custom instructions field. "
        "Do not upload INSTRUCTIONS.md itself as a file -- it belongs in that field.",
        "3. Upload each of these files to the Project's knowledge (or files) section:",
        "",
        *knowledge_lines,
        "",
        f"This README ({len(WEB_PACKAGE_KNOWLEDGE_FILES) + 2} files total in this folder) is for "
        f"your own reference and never needs uploading itself.",
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


# --- Skill deployment by link (ticket 07; combined budget and unconditional
# external deployment, Mission 171-C01 step 4 -- see tools/deploy-skills.ps1's
# own header comment for the full rationale, this file mirrors it exactly) --

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


def _method_skill_entries(clone_path):
    # The two unconditional method-skill sources (Mission 171-C01 step 4):
    # skills/ (default, excluding external/) and skills/external/ itself.
    # Warehouse collections (skills-warehouse/) are never a source here any
    # more -- the retired eighth question used to gate both skills/external/
    # and warehouse collections through one free-text token list; both are
    # superseded (external is now unconditional, warehouse is delivered as
    # zip packages instead, a separate mechanism).
    default_entries = _skill_dir_entries(os.path.join(clone_path, "skills"), exclude_names={"external"})
    external_entries = _skill_dir_entries(os.path.join(clone_path, "skills", "external"))
    return default_entries, external_entries


def _codex_budget(default_entries, external_entries):
    # Doctrine rule 3 (Mission 171-C01 step 4): sums BOTH sources together,
    # unlike the superseded ticket-07 measurement which only summed
    # default_entries. Never raises -- the caller turns an over-budget total
    # into a per-target fallback instead of a failure (Doctrine: "Pas d'arret").
    total = 0
    breakdown = []
    for name, source_path in default_entries + external_entries:
        length = len(_skill_description(os.path.join(source_path, "SKILL.md")))
        total += length
        breakdown.append((name, length))
    return total, breakdown


def _merge_skill_entries(entry_lists):
    # Keeps the first occurrence of each skill name across ordered entry
    # lists, recording the rest as duplicates -- mirrors
    # tools/deploy-skills.ps1's Merge-SkillEntriesByName exactly.
    seen = set()
    duplicates = []
    merged = []
    for entries in entry_lists:
        for name, source_path in entries:
            if name in seen:
                duplicates.append(name)
                continue
            seen.add(name)
            merged.append((name, source_path))
    return merged, duplicates


def _is_windows_platform():
    return os.name == "nt"


def _is_reparse_point(path):
    # Detects BOTH a symbolic link and an NTFS junction. os.path.islink()
    # alone misses a junction (a different reparse tag,
    # IO_REPARSE_TAG_MOUNT_POINT, not IO_REPARSE_TAG_SYMLINK), but every
    # reparse point -- either tag -- sets the same FILE_ATTRIBUTE_REPARSE_POINT
    # bit (measured directly on this machine: a junction created by
    # tools/deploy-skills.ps1's own Publish-SkillLink reports this bit set on
    # os.lstat().st_file_attributes, while os.path.islink() on that same path
    # returns False). st_file_attributes only exists on Windows.
    try:
        attrs = os.lstat(path).st_file_attributes
    except (AttributeError, OSError):
        return False
    return bool(attrs & stat.FILE_ATTRIBUTE_REPARSE_POINT)


def _create_windows_junction(link_path, target_path):
    # An NTFS junction, not a symbolic link: os.symlink() fails on this
    # machine with WinError 1314 ("the client does not have the required
    # privilege") -- measured directly while building Mission 171-C01 step
    # 4 -- because creating a symbolic link on Windows needs Developer Mode
    # or an elevated process, neither of which this unattended installer
    # may ever require. A junction needs neither (same constraint, same fix
    # already applied on the PowerShell side,
    # tools/deploy-skills.ps1's own Publish-SkillLink). mklink is a cmd.exe
    # builtin, not its own executable, so it must run through `cmd /c`,
    # never as a direct subprocess target.
    #
    # os.path.normpath() is mandatory here, not cosmetic: this helper is
    # install.sh's own backend, called from Git Bash where $HOME and every
    # path built from it use forward slashes (C:/Users/...). cmd.exe's
    # mklink parses its own arguments looking for "/switch" tokens, and a
    # forward-slash path like "C:/Users/..." is misread as a run of
    # switches -- measured directly: "Option non valide - \"Users\"." --
    # even though a mixed-separator path resolves correctly for ordinary
    # filesystem APIs. normpath() converts every forward slash to a
    # backslash on Windows, which mklink parses correctly.
    subprocess.run(
        ["cmd", "/c", "mklink", "/J", os.path.normpath(link_path), os.path.normpath(target_path)],
        check=True, capture_output=True, text=True,
    )


def _publish_skill_link(link_path, target_path):
    resolved_target = os.path.realpath(target_path)
    if os.path.lexists(link_path):
        if os.path.islink(link_path) or _is_reparse_point(link_path):
            try:
                existing_target = os.path.realpath(link_path)
            except OSError:
                existing_target = None
            if existing_target and (
                os.path.normcase(existing_target.rstrip("/\\")) == os.path.normcase(resolved_target.rstrip("/\\"))
            ):
                return "AlreadyLinked"
        return "Conflict"
    os.makedirs(os.path.dirname(link_path), exist_ok=True)
    if _is_windows_platform():
        _create_windows_junction(link_path, resolved_target)
    else:
        os.symlink(resolved_target, link_path, target_is_directory=True)
    return "Created"


def cmd_deploy_skills(args):
    # Unconditional deployment (Mission 171-C01 step 4): no --collections
    # input any more (the retired eighth question used to supply it) --
    # skills/ and skills/external/ are always the two sources. Codex drops
    # skills/external/ under Doctrine rule 3 when the combined description
    # budget is over the ceiling; Claude Code never does.
    clone_path = args.clone_path
    default_entries, external_entries = _method_skill_entries(clone_path)
    total, _breakdown = _codex_budget(default_entries, external_entries)
    over_budget = total > MAX_CODEX_DEFAULT_SKILLS_BUDGET

    claude_entries, claude_duplicates = _merge_skill_entries([default_entries, external_entries])
    codex_source_lists = [default_entries] if over_budget else [default_entries, external_entries]
    codex_entries, codex_duplicates = _merge_skill_entries(codex_source_lists)

    conflict_count = 0
    for target_root, entries in (
        (args.claude_skills_dir, claude_entries),
        (args.codex_agents_skills_dir, codex_entries),
    ):
        for name, source_path in entries:
            link_path = os.path.join(target_root, name)
            status = _publish_skill_link(link_path, source_path)
            if status == "Conflict":
                conflict_count += 1
                print(f"CONFLICT {link_path}")

    for name in sorted(set(claude_duplicates + codex_duplicates)):
        print(f"DUPLICATE {name}")
    print(f"DEFAULT_COUNT {len(default_entries)}")
    print(f"EXTERNAL_COUNT {len(external_entries)}")
    print(f"BUDGET {total} {MAX_CODEX_DEFAULT_SKILLS_BUDGET}")
    print(f"FALLBACK {'1' if over_budget else '0'}")
    print(f"CONFLICT_COUNT {conflict_count}")
    return 0


# --- Assistant deployment by link, profile-level (Mission 171-C01 step 6;
# audit Defect 3 -- see tools/deploy-skills.ps1's own header comment for the
# full rationale, this file mirrors it exactly for install.sh's own parity) -

def _create_windows_hardlink(link_path, target_path):
    # Unlike the junction case above (_create_windows_junction), Python's
    # own os.link() calls CreateHardLinkW directly -- no subprocess/mklink
    # needed. Measured directly on this machine: no elevation, no
    # Developer Mode, and afterwards os.path.samefile(link_path,
    # target_path) is True -- both directory entries address the very same
    # on-disk data, so a correction through the source path is visible
    # through the link immediately (never a stale copy). A junction cannot
    # play this role here: it only ever targets a DIRECTORY on Windows, and
    # the assistant's Claude Code subagent form is a single file.
    os.link(target_path, link_path)


def _publish_file_link(link_path, target_path):
    # File analogue of _publish_skill_link above. Idempotency check uses
    # os.path.samefile() rather than _is_reparse_point(): a hard link is
    # NOT a reparse point on Windows (measured directly, same finding as
    # tools/deploy-skills.ps1's own Publish-FileLink), so the reparse-point
    # test that correctly detects a junction/symlink never fires for one --
    # samefile() instead compares the two paths' own (device, inode/file
    # index) pair, True exactly when they are the same hard-linked file.
    resolved_target = os.path.realpath(target_path)
    if os.path.lexists(link_path):
        try:
            if os.path.samefile(link_path, resolved_target):
                return "AlreadyLinked"
        except OSError:
            pass
        return "Conflict"
    os.makedirs(os.path.dirname(link_path), exist_ok=True)
    if _is_windows_platform():
        _create_windows_hardlink(link_path, resolved_target)
    else:
        os.symlink(resolved_target, link_path)
    return "Created"


def cmd_deploy_assistant(args):
    # Scoped to exactly the ONE assistant slug the caller passes (install.sh
    # already resolved $ASSISTANT_SLUG for the 'assistant' step) -- never a
    # scan of every .claude/agents/*.md or .agents/skills/* entry, which
    # would reach past this one installation into whatever else a
    # participant's own profile already has under those folders. Two forms
    # only: the Claude Code subagent (a file, _publish_file_link/hard link)
    # and the Codex skill (a directory, _publish_skill_link/junction -- the
    # same primitive cmd_deploy_skills above already uses). The web package
    # is never linked here (no profile-level location by design).
    clone_path = args.clone_path
    slug = args.slug

    subagent_source = os.path.join(clone_path, ".claude", "agents", f"{slug}.md")
    subagent_link = os.path.join(args.claude_agents_dir, f"{slug}.md")
    subagent_status = _publish_file_link(subagent_link, subagent_source)
    if subagent_status == "Conflict":
        print(f"CONFLICT {subagent_link}")

    skill_source = os.path.join(clone_path, ".agents", "skills", slug)
    skill_link = os.path.join(args.codex_agents_skills_dir, slug)
    skill_status = _publish_skill_link(skill_link, skill_source)
    if skill_status == "Conflict":
        print(f"CONFLICT {skill_link}")

    print(f"SUBAGENT_STATUS {subagent_status}")
    print(f"CODEX_SKILL_STATUS {skill_status}")
    return 0


def cmd_remove_assistant_links(args):
    # Rename cleanup (Mission 171-C01 step 6), called for the OLD slug only,
    # right before cmd_deploy_assistant links the NEW one -- see
    # tools/deploy-skills.ps1's own Remove-DeployedAssistantLinks for the
    # full rationale (moved-not-deleted content under _trash/, stale
    # profile-level pointer removed on its own). Removes only this
    # installer's own reparse point (the Codex skill junction) or hard link
    # (the Claude Code subagent) -- a foreign file or directory a
    # participant put at that exact path is left untouched.
    old_slug = args.old_slug
    removed = []

    old_subagent_link = os.path.join(args.claude_agents_dir, f"{old_slug}.md")
    if os.path.lexists(old_subagent_link) and not _is_reparse_point(old_subagent_link):
        try:
            still_hardlinked = os.stat(old_subagent_link).st_nlink > 1
        except OSError:
            still_hardlinked = False
        if still_hardlinked:
            os.remove(old_subagent_link)
            removed.append(old_subagent_link)

    old_skill_link = os.path.join(args.codex_agents_skills_dir, old_slug)
    if os.path.lexists(old_skill_link) and _is_reparse_point(old_skill_link):
        if _is_windows_platform():
            os.rmdir(old_skill_link)
        else:
            os.remove(old_skill_link)
        removed.append(old_skill_link)

    print("moved" if removed else "none")
    for path in removed:
        print(f"REMOVED {path}")
    return 0


# --- USER.md profile (ticket 05 parity) ------------------------------------

def cmd_write_user_profile(args):
    language_labels = {"FR": "français (FR)", "EN": "English (EN)", "ES": "español (ES)"}
    language_label = language_labels.get(args.language, args.language)
    ai_tools = args.ai_tools.split(" ") if args.ai_tools else []
    ai_tools_text = ", ".join(t for t in ai_tools if t) or "aucun renseigné"

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
    p.set_defaults(func=cmd_deploy_skills)

    p = sub.add_parser("deploy-assistant")
    p.add_argument("clone_path")
    p.add_argument("claude_agents_dir")
    p.add_argument("codex_agents_skills_dir")
    p.add_argument("slug")
    p.set_defaults(func=cmd_deploy_assistant)

    p = sub.add_parser("remove-assistant-links")
    p.add_argument("claude_agents_dir")
    p.add_argument("codex_agents_skills_dir")
    p.add_argument("old_slug")
    p.set_defaults(func=cmd_remove_assistant_links)

    p = sub.add_parser("write-user-profile")
    p.add_argument("path")
    p.add_argument("--language", default="EN")
    p.add_argument("--vault-name", default=DEFAULT_ASSISTANT_NAME)
    p.add_argument("--workspace-path", default="")
    p.add_argument("--first-name", default="")
    p.add_argument("--activity", default="")
    p.add_argument("--ai-tools", default="")
    p.add_argument("--what-matters", default="")
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
