#!/usr/bin/env python3
"""Build and validate one immutable Skills Warehouse collection release."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
import tempfile
import zipfile
from pathlib import Path, PurePosixPath


ALLOWED_FIELDS = {"name", "description", "license", "compatibility", "allowed-tools", "metadata"}
FORBIDDEN_PARTS = {".git", "node_modules", "__MACOSX", "__pycache__", ".pytest_cache", "releases"}
FORBIDDEN_NAMES = {".DS_Store", "Thumbs.db"}
FRONT_RE = re.compile(rb"\A---\r?\n(?P<front>.*?)\r?\n---(?P<body>\r?\n.*|\Z)", re.DOTALL)


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def tree_sha256(files: dict[str, bytes]) -> str:
    digest = hashlib.sha256()
    for relative, data in sorted(files.items()):
        digest.update(relative.encode("utf-8"))
        digest.update(b"\0")
        digest.update(data)
        digest.update(b"\0")
    return digest.hexdigest()


def scalar(text: str) -> str:
    text = text.strip()
    if len(text) >= 2 and text[0] == text[-1] == '"':
        return str(json.loads(text))
    if len(text) >= 2 and text[0] == text[-1] == "'":
        return text[1:-1].replace("''", "'")
    return text


def parse_skill(data: bytes, source: str) -> tuple[dict[str, object], bytes]:
    match = FRONT_RE.match(data)
    if not match:
        raise ValueError(f"Invalid or missing front matter: {source}")
    fields: dict[str, object] = {}
    current_mapping: str | None = None
    for number, line in enumerate(match.group("front").decode("utf-8").splitlines(), 1):
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if line.startswith("  "):
            if current_mapping != "metadata" or ":" not in line:
                raise ValueError(f"Unsupported nested YAML at {source}:{number}")
            key, value = line.strip().split(":", 1)
            metadata = fields.setdefault("metadata", {})
            assert isinstance(metadata, dict)
            metadata[key] = scalar(value)
            continue
        if line[:1].isspace() or ":" not in line:
            raise ValueError(f"Unsupported YAML at {source}:{number}")
        key, value = line.split(":", 1)
        key = key.strip()
        if key in fields:
            raise ValueError(f"Duplicate front-matter key {key!r}: {source}")
        if not value.strip():
            if key != "metadata":
                raise ValueError(f"Only metadata may be a mapping: {source}:{number}")
            fields[key] = {}
            current_mapping = key
        else:
            fields[key] = scalar(value)
            current_mapping = None
    return fields, match.group("body")


def forbidden(path: PurePosixPath) -> bool:
    return any(part in FORBIDDEN_PARTS for part in path.parts) or path.name in FORBIDDEN_NAMES or path.suffix.lower() == ".zip"


def load_active(collection: Path) -> tuple[dict[str, dict[str, bytes]], dict[str, dict[str, object]], dict[str, bytes]]:
    skills_root = collection / "skills"
    if not skills_root.is_dir():
        raise ValueError(f"Missing collection skills directory: {skills_root}")
    trees: dict[str, dict[str, bytes]] = {}
    fields_by_name: dict[str, dict[str, object]] = {}
    bodies: dict[str, bytes] = {}
    for skill_dir in sorted((path for path in skills_root.iterdir() if path.is_dir()), key=lambda item: item.name):
        name = skill_dir.name
        files: dict[str, bytes] = {}
        for path in sorted(skill_dir.rglob("*"), key=lambda item: item.as_posix().lower()):
            if not path.is_file():
                continue
            relative = PurePosixPath(path.relative_to(skill_dir).as_posix())
            if forbidden(relative):
                raise ValueError(f"Forbidden active file: {name}/{relative}")
            files[relative.as_posix()] = path.read_bytes()
        if "SKILL.md" not in files:
            raise ValueError(f"Missing SKILL.md: {name}")
        fields, body = parse_skill(files["SKILL.md"], str(skill_dir / "SKILL.md"))
        if not set(fields).issubset(ALLOWED_FIELDS):
            raise ValueError(f"Disallowed front-matter fields in {name}: {sorted(set(fields)-ALLOWED_FIELDS)}")
        if fields.get("name") != name:
            raise ValueError(f"Front-matter name does not match folder: {name}")
        description = str(fields.get("description", ""))
        if not description or len(description) > 200 or "\n" in description or "\r" in description:
            raise ValueError(f"Invalid chat-compatible description: {name}")
        if not str(fields.get("license", "")):
            raise ValueError(f"Missing licence field: {name}")
        metadata = fields.get("metadata")
        if not isinstance(metadata, dict) or not all(isinstance(key, str) and isinstance(value, str) for key, value in metadata.items()):
            raise ValueError(f"metadata must be a one-level string mapping: {name}")
        if not {"upstream-repo", "upstream-license-evidence"}.issubset(metadata):
            raise ValueError(f"Missing upstream licence metadata: {name}")
        trees[name] = files
        fields_by_name[name] = fields
        bodies[name] = body
    if not trees or len(trees) != len(set(trees)):
        raise ValueError("Collection must contain unique active Skills")
    return trees, fields_by_name, bodies


def listed_skills(markdown: str) -> set[str]:
    return set(re.findall(r"^\| `([a-z0-9-]+)` \|", markdown, re.MULTILINE))


def write_zip(path: Path, entries: list[tuple[str, bytes]]) -> None:
    with zipfile.ZipFile(path, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for name, data in sorted(entries):
            info = zipfile.ZipInfo(name, (1980, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            archive.writestr(info, data)


def zip_skill_trees(path: Path) -> dict[str, dict[str, bytes]]:
    result: dict[str, dict[str, bytes]] = {}
    with zipfile.ZipFile(path) as archive:
        for member in archive.infolist():
            parts = PurePosixPath(member.filename).parts
            if member.is_dir() or len(parts) < 3 or parts[0] != "skills":
                continue
            result.setdefault(parts[1], {})[PurePosixPath(*parts[2:]).as_posix()] = archive.read(member)
    return result


def latest_prior_release(releases: Path, version: str, slug: str) -> Path | None:
    candidates = [path / f"{slug}-skills-full.zip" for path in releases.iterdir() if path.is_dir() and path.name != version]
    candidates = [path for path in candidates if path.is_file()]
    return sorted(candidates, key=lambda item: item.parent.name)[-1] if candidates else None


def validate_packages(release: Path, slug: str, trees: dict[str, dict[str, bytes]], licenses: bytes) -> None:
    names = sorted(trees)
    master_path = release / f"{slug}-skills-full.zip"
    with zipfile.ZipFile(master_path) as master:
        members = master.namelist()
        if "LICENSES.md" not in members or master.read("LICENSES.md") != licenses:
            raise ValueError("Collection ZIP LICENSES.md mismatch")
        if any(forbidden(PurePosixPath(item)) for item in members):
            raise ValueError("Forbidden path in collection ZIP")
        master_names = {PurePosixPath(item).parts[1] for item in members if len(PurePosixPath(item).parts) >= 3 and PurePosixPath(item).parts[0] == "skills"}
        if master_names != set(names):
            raise ValueError("Collection ZIP inventory mismatch")
        for name in names:
            chat_path = release / "chat-zips" / f"{name}.zip"
            with zipfile.ZipFile(chat_path) as chat:
                chat_members = chat.namelist()
                top = {PurePosixPath(item).parts[0] for item in chat_members if PurePosixPath(item).parts}
                if top != {name} or f"{name}/SKILL.md" not in chat_members:
                    raise ValueError(f"Invalid chat ZIP structure: {name}")
                if any(forbidden(PurePosixPath(item)) for item in chat_members):
                    raise ValueError(f"Forbidden path in chat ZIP: {name}")
                for relative, expected in trees[name].items():
                    chat_bytes = chat.read(f"{name}/{relative}")
                    master_bytes = master.read(f"skills/{name}/{relative}")
                    if chat_bytes != expected or master_bytes != expected:
                        raise ValueError(f"Package byte mismatch: {name}/{relative}")


def validate_skillspector_report(path: Path, trees: dict[str, dict[str, bytes]]) -> None:
    report = json.loads(path.read_text(encoding="utf-8"))
    if report.get("status") != "PASS" or report.get("mode") != "static-no-llm":
        raise ValueError("SkillSpector report is not a passing static scan")
    records = report.get("skills")
    if not isinstance(records, list):
        raise ValueError("SkillSpector report has no skill records")
    by_name = {item.get("name"): item for item in records if isinstance(item, dict)}
    if set(by_name) != set(trees):
        raise ValueError("SkillSpector report inventory does not match collection")
    for name, files in trees.items():
        record = by_name[name]
        if record.get("status") != "PASS" or record.get("tree_sha256") != tree_sha256(files):
            raise ValueError(f"SkillSpector report does not cover current Skill bytes: {name}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--collection", required=True)
    parser.add_argument("--version", required=True)
    parser.add_argument("--baseline-zip", type=Path)
    parser.add_argument("--skillspector-report", required=True, type=Path, help="Passing aggregate SkillSpector JSON report for this collection.")
    parser.add_argument("--output-dir", required=True, type=Path, help="New or empty immutable delivery directory.")
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parent.parent)
    args = parser.parse_args()
    root = args.root.resolve()
    slug = args.collection
    catalog = json.loads((root / "skill-collections" / "catalog.json").read_text(encoding="utf-8"))
    if slug not in {item["slug"] for item in catalog["categories"]}:
        raise SystemExit(f"Unknown collection slug: {slug}")
    collection = root / "skill-collections" / slug
    for required in ("README.md", "registry.md", "LICENSES.md", "skills"):
        if not (collection / required).exists():
            raise SystemExit(f"Incomplete collection contract: {collection / required}")
    target = args.output_dir.resolve()
    delivery_target = root / "deliverables" / slug / args.version
    try:
        target.relative_to(root)
    except ValueError:
        pass
    else:
        if target != delivery_target:
            raise SystemExit("--output-dir inside the repository must be deliverables/<collection>/<version>")
    if target.exists() and any(target.iterdir()):
        raise SystemExit(f"Refusing to overwrite non-empty delivery directory: {target}")
    target.mkdir(parents=True, exist_ok=True)

    trees, fields, bodies = load_active(collection)
    validate_skillspector_report(args.skillspector_report.resolve(), trees)
    names = sorted(trees)
    registry_text = (collection / "registry.md").read_text(encoding="utf-8")
    licenses_bytes = (collection / "LICENSES.md").read_bytes()
    if listed_skills(registry_text) != set(names) or listed_skills(licenses_bytes.decode("utf-8")) != set(names):
        raise SystemExit("Collection registry or licence inventory does not match active Skills")

    baseline_path = args.baseline_zip.resolve() if args.baseline_zip else None
    baseline = zip_skill_trees(baseline_path) if baseline_path else {}
    if baseline_path:
        for name in names:
            if baseline.get(name) != trees[name]:
                raise SystemExit(f"Active migration tree differs from baseline ZIP: {name}")

    prior_path = None
    prior = {}
    work = Path(tempfile.mkdtemp(prefix=f"skills-warehouse-{slug}-{args.version}-"))
    release = work / "delivery"
    chat_dir = release / "chat-zips"
    chat_dir.mkdir(parents=True)
    try:
        (release / "LICENSES.md").write_bytes(licenses_bytes)
        for name in names:
            write_zip(chat_dir / f"{name}.zip", [(f"{name}/{relative}", data) for relative, data in trees[name].items()])
        master_entries: list[tuple[str, bytes]] = [("LICENSES.md", licenses_bytes)]
        for name in names:
            master_entries.extend((f"skills/{name}/{relative}", data) for relative, data in trees[name].items())
        write_zip(release / f"{slug}-skills-full.zip", master_entries)
        validate_packages(release, slug, trees, licenses_bytes)

        inventory = [(name, relative, data) for name in names for relative, data in sorted(trees[name].items())]
        manifest = [
            f"# Manifest — {slug}", "", f"Version: `{args.version}`", "",
            f"Active Skills: **{len(names)}**", "", f"Skill files: **{len(inventory)}**", "",
            "## Skills", "", "| Skill | Files |", "|---|---:|",
        ]
        manifest.extend(f"| `{name}` | {len(trees[name])} |" for name in names)
        manifest.extend(["", "## File inventory", "", "| Path | Bytes | SHA-256 |", "|---|---:|---|"])
        manifest.extend(f"| `skills/{name}/{relative}` | {len(data)} | `{sha256_bytes(data)}` |" for name, relative, data in inventory)
        manifest.extend(["", "## Delivery files", "", f"- `{slug}-skills-full.zip`", "- `LICENSES.md`", "- `validation-report.md`", "- `SHA256SUMS.txt` (self-excluded)"])
        manifest.extend(f"- `chat-zips/{name}.zip`" for name in names)
        manifest.append("")
        (release / "manifest.md").write_text("\n".join(manifest), encoding="utf-8", newline="\n")

        desc_diff = 0
        body_diff = 0
        tree_diff = 0
        rows = []
        comparison = prior if prior_path else baseline
        comparison_path = prior_path if prior_path else baseline_path
        if comparison_path is None:
            comparison_label = "none"
        else:
            try:
                comparison_label = comparison_path.relative_to(root).as_posix()
            except ValueError:
                comparison_label = comparison_path.as_posix()
        for name in names:
            other = comparison.get(name)
            if other is None:
                desc_state = body_state = tree_state = "NEW"
            else:
                other_fields, other_body = parse_skill(other["SKILL.md"], f"comparison:{name}")
                desc_state = "same" if str(other_fields.get("description", "")) == str(fields[name]["description"]) else "CHANGED"
                body_state = "same" if other_body == bodies[name] else "CHANGED"
                tree_state = "same" if other == trees[name] else "CHANGED"
                desc_diff += desc_state == "CHANGED"
                body_diff += body_state == "CHANGED"
                tree_diff += tree_state == "CHANGED"
            rows.append((name, desc_state, body_state, tree_state, sha256_file(chat_dir / f"{name}.zip")))

        proven = sum(1 for item in fields.values() if item["license"] != "NOASSERTION")
        report = [
            f"# Validation report — {slug}", "", f"Version: `{args.version}`", "", "Result: **PASS**", "",
            "## Required controls", "",
            f"- Allowed six-field front-matter contract: **{len(names)}/{len(names)}**",
            f"- `name` equals directory: **{len(names)}/{len(names)}**",
            "- Duplicate names inside collection: **0**",
            f"- Registry coverage: **{len(names)}/{len(names)}**",
            f"- Licence inventory coverage: **{len(names)}/{len(names)}**",
            f"- Upstream licence positively proven: **{proven}/{len(names)}**; `NOASSERTION`: **{len(names)-proven}**",
            f"- Chat/collection file byte identity: **{len(names)}/{len(names)}**",
            f"- Chat ZIP structure and forbidden-file checks: **{len(names)}/{len(names)}**",
            "- Collection ZIP structure and forbidden-file checks: **PASS**",
            "- Body or companion-file exceptions: **none**", "",
            "## Comparison", "", f"Comparison source: `{comparison_label}`", "",
            f"- Description differences: **{desc_diff}**",
            f"- Body differences: **{body_diff}**",
            f"- Full-tree differences: **{tree_diff}**", "",
            "| Skill | Description | Body | Full tree | Chat ZIP SHA-256 |", "|---|---|---|---|---|",
        ]
        report.extend(f"| `{name}` | {desc} | {body} | {tree} | `{digest}` |" for name, desc, body, tree, digest in rows)
        report.extend(["", "## Exceptions", "", "Licence exceptions are recorded in `LICENSES.md`. No body or companion-file exceptions were introduced by this release.", ""])
        (release / "validation-report.md").write_text("\n".join(report), encoding="utf-8", newline="\n")

        targets = sorted((path for path in release.rglob("*") if path.is_file() and path.name != "SHA256SUMS.txt"), key=lambda item: item.relative_to(release).as_posix())
        sums = "".join(f"{sha256_file(path)}  {path.relative_to(release).as_posix()}\n" for path in targets)
        (release / "SHA256SUMS.txt").write_text(sums, encoding="ascii", newline="\n")
        for line in sums.splitlines():
            expected, relative = line.split("  ", 1)
            if sha256_file(release / Path(relative)) != expected:
                raise ValueError(f"Checksum validation failed: {relative}")

        for source in release.iterdir():
            shutil.move(str(source), str(target / source.name))
    finally:
        if work.exists():
            shutil.rmtree(work)

    result = {
        "status": "PASS", "collection": slug, "version": args.version, "skills": len(names),
        "files": sum(len(item) for item in trees.values()),
        "package": str(target / f"{slug}-skills-full.zip"),
        "sha256": sha256_file(target / f"{slug}-skills-full.zip"),
    }
    print(json.dumps(result, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
