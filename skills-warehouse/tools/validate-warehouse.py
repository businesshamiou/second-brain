#!/usr/bin/env python3
"""Validate the thin Skills Warehouse checkout without network access."""
from __future__ import annotations
import hashlib, json, re, sys, zipfile
from pathlib import Path

ALLOWED = {"name", "description", "license", "compatibility", "allowed-tools", "metadata"}
FORBIDDEN_ROOTS = {"skills", "dist", "intake", "sources", "livrables"}
FORBIDDEN_PARTS = {".git", "node_modules", "__MACOSX", "__pycache__", ".pytest_cache", "releases"}
FRONT = re.compile(r"\A---\r?\n(.*?)\r?\n---(?:\r?\n|\Z)", re.S)

def skill_hash(folder: Path) -> str:
    h = hashlib.sha256()
    for path in sorted((p for p in folder.rglob("*") if p.is_file()), key=lambda p: p.as_posix()):
        h.update(path.relative_to(folder).as_posix().encode() + b"\0" + path.read_bytes() + b"\0")
    return h.hexdigest()

def fields(path: Path) -> dict[str, object]:
    match = FRONT.match(path.read_text(encoding="utf-8"))
    if not match: raise ValueError(f"missing/invalid front matter: {path}")
    result, metadata, active_meta = {}, {}, False
    for line in match.group(1).splitlines():
        if not line.strip() or line.lstrip().startswith("#"): continue
        if line.startswith("  "):
            if not active_meta or ":" not in line: raise ValueError(f"invalid nested front matter: {path}")
            key, value = line.strip().split(":", 1); metadata[key] = value.strip().strip('"').strip("'"); continue
        if ":" not in line: raise ValueError(f"invalid front matter: {path}")
        key, value = line.split(":", 1); key = key.strip()
        if key in result: raise ValueError(f"duplicate field {key}: {path}")
        active_meta = key == "metadata" and not value.strip()
        result[key] = metadata if active_meta else value.strip().strip('"').strip("'")
    if not set(result).issubset(ALLOWED): raise ValueError(f"disallowed fields: {path}")
    return result

def table_names(path: Path) -> set[str]:
    return set(re.findall(r"^\| `([a-z0-9-]+)` \|", path.read_text(encoding="utf-8"), re.M))

def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()

def validate_deliverable(release: Path, collection: Path, names: set[str], slug: str) -> int:
    """Validate the committed delivery's hashes, inventory, ZIP shape and byte identity."""
    required = {f"{slug}-skills-full.zip", "manifest.md", "LICENSES.md", "validation-report.md", "SHA256SUMS.txt", "chat-zips"}
    missing = [name for name in required if not (release / name).exists()]
    if missing: raise SystemExit(f"deliverable missing: {', '.join(missing)}")
    expected_hashes: dict[str, str] = {}
    for line in (release / "SHA256SUMS.txt").read_text(encoding="utf-8").splitlines():
        if not line.strip(): continue
        try: digest, relative = line.split("  ", 1)
        except ValueError: raise SystemExit(f"invalid SHA256SUMS entry: {line}")
        if not re.fullmatch(r"[0-9a-f]{64}", digest) or not relative or Path(relative).is_absolute() or ".." in Path(relative).parts:
            raise SystemExit(f"unsafe SHA256SUMS entry: {line}")
        if relative in expected_hashes: raise SystemExit(f"duplicate SHA256SUMS entry: {relative}")
        expected_hashes[relative] = digest
    actual_files = {path.relative_to(release).as_posix(): path for path in release.rglob("*") if path.is_file() and path.name != "SHA256SUMS.txt"}
    if set(expected_hashes) != set(actual_files): raise SystemExit("deliverable SHA256SUMS inventory mismatch")
    for relative, path in actual_files.items():
        if sha256(path) != expected_hashes[relative]: raise SystemExit(f"deliverable hash mismatch: {relative}")

    chat_zips = {path.stem: path for path in (release / "chat-zips").glob("*.zip")}
    if set(chat_zips) != names: raise SystemExit("deliverable chat ZIP inventory mismatch")
    master_path = release / f"{slug}-skills-full.zip"
    with zipfile.ZipFile(master_path) as master:
        master_entries = {info.filename: info for info in master.infolist() if not info.is_dir()}
        if set(entry.split("/", 1)[0] for entry in master_entries) - {"LICENSES.md", "skills"}: raise SystemExit("unexpected master ZIP root")
        if "LICENSES.md" not in master_entries: raise SystemExit("master ZIP missing LICENSES.md")
        for name in names:
            folder = collection / "skills" / name
            local_files = {path.relative_to(folder).as_posix(): path for path in folder.rglob("*") if path.is_file()}
            archive_files = {entry.removeprefix(f"skills/{name}/"): entry for entry in master_entries if entry.startswith(f"skills/{name}/")}
            if set(archive_files) != set(local_files): raise SystemExit(f"master inventory mismatch: {name}")
            for relative, local in local_files.items():
                if master.read(archive_files[relative]) != local.read_bytes(): raise SystemExit(f"master byte mismatch: {name}/{relative}")
            with zipfile.ZipFile(chat_zips[name]) as chat:
                chat_entries = {info.filename: info for info in chat.infolist() if not info.is_dir()}
                expected_chat = {f"{name}/{relative}" for relative in local_files}
                if set(chat_entries) != expected_chat or f"{name}/SKILL.md" not in chat_entries:
                    raise SystemExit(f"invalid chat ZIP shape: {name}")
                for relative, local in local_files.items():
                    if chat.read(f"{name}/{relative}") != local.read_bytes(): raise SystemExit(f"chat byte mismatch: {name}/{relative}")
    return len(actual_files)

def main() -> int:
    root = Path(__file__).resolve().parent.parent
    if not (root / "SYSTEM_NAMING_STANDARD.md").exists(): raise SystemExit("missing system naming standard")
    for name in FORBIDDEN_ROOTS:
        if (root / name).exists(): raise SystemExit(f"forbidden heavy root remains: {name}")
    archive = json.loads((root / "provenance" / "cold-archive-2026-09-02.json").read_text())
    assets = archive.get("assets", [])
    if len(assets) != 10 or any(not re.fullmatch(r"[0-9a-f]{64}", a.get("sha256", "")) for a in assets): raise SystemExit("cold archive manifest incomplete")
    baseline = json.loads((root / "provenance" / "migration-2026-09-02.json").read_text())
    mengto = json.loads((root / "provenance" / "mengto-skills-web-design-321c769.json").read_text())
    ingested = {item["name"]: item for item in mengto["skills"]}
    if mengto["integrated_skills"] != len(ingested) or mengto["upstream_license"] != "MIT": raise SystemExit("Meng To provenance incomplete")
    catalog = {item["slug"] for item in json.loads((root / "skill-collections" / "catalog.json").read_text())["categories"]}
    active, valid, legacy_matches, ingested_matches, collection_names = {}, 0, 0, 0, {}
    for spec in baseline["collections"]:
        slug, collection = spec["slug"], root / "skill-collections" / spec["slug"]
        if slug not in catalog: raise SystemExit(f"collection not catalogued: {slug}")
        for required in ("README.md", "registry.md", "LICENSES.md", "skills"):
            if not (collection / required).exists(): raise SystemExit(f"missing collection item: {collection / required}")
        if (collection / "releases").exists(): raise SystemExit(f"generated release remains: {collection / 'releases'}")
        names = {p.name for p in (collection / "skills").iterdir() if p.is_dir()}
        collection_names[slug] = names
        if not set(spec["skills"]).issubset(names) or table_names(collection / "registry.md") != names or table_names(collection / "LICENSES.md") != names: raise SystemExit(f"inventory mismatch: {slug}")
        for name in names:
            folder = collection / "skills" / name
            if any(part in FORBIDDEN_PARTS for p in folder.rglob("*") for part in p.relative_to(folder).parts): raise SystemExit(f"forbidden active path: {name}")
            front = fields(folder / "SKILL.md")
            if front.get("name") != name or not front.get("description") or len(str(front["description"])) > 200: raise SystemExit(f"invalid Skill header: {name}")
            metadata = front.get("metadata")
            if not isinstance(metadata, dict) or not all(isinstance(k, str) and isinstance(v, str) for k, v in metadata.items()): raise SystemExit(f"invalid metadata: {name}")
            if name in active: raise SystemExit(f"duplicate Skill: {name}")
            if name in spec["tree_sha256"]:
                if spec["tree_sha256"][name] != skill_hash(folder): raise SystemExit(f"legacy integrity mismatch: {name}")
                legacy_matches += 1
            elif name in ingested:
                if ingested[name]["canonical_skill_sha256"] != hashlib.sha256((folder / "SKILL.md").read_bytes()).hexdigest(): raise SystemExit(f"ingested integrity mismatch: {name}")
                if not {"upstream-repo", "upstream-license-evidence", "upstream-commit", "original-skill-sha256"}.issubset(metadata): raise SystemExit(f"ingested provenance missing: {name}")
                ingested_matches += 1
            else: raise SystemExit(f"unrecorded active Skill: {name}")
            active[name] = slug; valid += 1
    if len(active) != baseline["active_skill_count"] + len(ingested): raise SystemExit("active count mismatch")
    if ingested_matches != len(ingested): raise SystemExit("ingested coverage mismatch")
    delivery_count = 0
    delivery_files = 0
    chat_zips = 0
    for slug, names in collection_names.items():
        collection_deliverables = root / "deliverables" / slug
        if not collection_deliverables.is_dir():
            continue
        for release in sorted((path for path in collection_deliverables.iterdir() if path.is_dir()), key=lambda path: path.name):
            delivery_files += validate_deliverable(release, root / "skill-collections" / slug, names, slug)
            delivery_count += 1
            chat_zips += len(names)
    print(json.dumps({"status":"PASS","active_collections":len(baseline["collections"]),"active_skills":len(active),"six_field_front_matter":f"{valid}/{len(active)}","duplicates":0,"migration_tree_matches":legacy_matches,"mengto_ingested_tree_matches":ingested_matches,"cold_archive_assets":len(assets),"deliverables_checked":delivery_count,"deliverable_files":delivery_files,"chat_zips":chat_zips}, indent=2))
    return 0

if __name__ == "__main__": sys.exit(main())
