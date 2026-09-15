#!/usr/bin/env python3
"""Run the pinned SkillSpector static security gate for one Skill or a skill directory."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
import subprocess
import tempfile
from pathlib import Path


SEVERITY_ORDER = {"INFO": 0, "LOW": 1, "MEDIUM": 2, "HIGH": 3, "CRITICAL": 4}


def tree_sha256(folder: Path) -> str:
    digest = hashlib.sha256()
    for path in sorted((item for item in folder.rglob("*") if item.is_file()), key=lambda item: item.as_posix()):
        digest.update(path.relative_to(folder).as_posix().encode("utf-8"))
        digest.update(b"\0")
        digest.update(path.read_bytes())
        digest.update(b"\0")
    return digest.hexdigest()


def discover_targets(path: Path) -> list[Path]:
    if (path / "SKILL.md").is_file():
        return [path]
    targets = sorted((item for item in path.iterdir() if item.is_dir() and (item / "SKILL.md").is_file()), key=lambda item: item.name)
    if not targets:
        raise ValueError(f"No Skill directories found at {path}")
    return targets


def resolve_binary(value: str | None) -> str:
    candidate = value or os.environ.get("SKILLSPECTOR_BIN") or shutil.which("skillspector")
    if not candidate:
        raise SystemExit("SkillSpector is required: set SKILLSPECTOR_BIN or add skillspector to PATH")
    return candidate


def outcome(report: dict[str, object], returncode: int) -> str:
    assessment = report.get("risk_assessment", {})
    completeness = report.get("analysis_completeness", {})
    maximum = str(assessment.get("max_issue_severity", "INFO")).upper()
    if returncode != 0 or not report.get("execution_successful"):
        return "OPEN"
    if not completeness.get("is_complete"):
        return "OPEN"
    if SEVERITY_ORDER.get(maximum, SEVERITY_ORDER["CRITICAL"]) >= SEVERITY_ORDER["HIGH"]:
        return "OPEN"
    return "PASS"


def compact_findings(report: dict[str, object]) -> list[dict[str, object]]:
    result = []
    for item in report.get("issues", []):
        location = item.get("location") or {}
        result.append({
            "id": item.get("id"),
            "severity": item.get("severity"),
            "file": location.get("file"),
            "line": location.get("start_line"),
            "finding": item.get("finding"),
            "fingerprint": item.get("match_fingerprint"),
        })
    return result


def compact_record(report: dict[str, object], target: Path, root: Path, returncode: int) -> dict[str, object]:
    assessment = report.get("risk_assessment", {})
    completeness = report.get("analysis_completeness", {})
    return {
        "name": target.name,
        "path": target.relative_to(root).as_posix(),
        "tree_sha256": tree_sha256(target),
        "status": outcome(report, returncode),
        "returncode": returncode,
        "risk_score": assessment.get("score"),
        "severity": assessment.get("severity"),
        "max_issue_severity": assessment.get("max_issue_severity"),
        "recommendation": assessment.get("recommendation"),
        "analysis_complete": completeness.get("is_complete"),
        "coverage_percent": completeness.get("coverage_percent"),
        "findings": compact_findings(report),
    }


def scan(binary: str, input_path: Path, targets: list[Path], root: Path, timeout_seconds: int) -> list[dict[str, object]]:
    with tempfile.TemporaryDirectory(prefix="skillspector-") as directory:
        raw_report = Path(directory) / "report.json"
        command = [binary, "scan", str(input_path), "--no-llm", "--format", "json", "--output", str(raw_report)]
        if len(targets) > 1:
            command.append("--recursive")
        try:
            result = subprocess.run(command, capture_output=True, text=True, encoding="utf-8", errors="replace", check=False, timeout=timeout_seconds)
        except subprocess.TimeoutExpired:
            return [{
                "name": target.name,
                "path": target.relative_to(root).as_posix(),
                "tree_sha256": tree_sha256(target),
                "status": "OPEN",
                "error": f"SkillSpector exceeded the {timeout_seconds}-second security-gate limit",
                "findings": [],
            } for target in targets]
        if not raw_report.is_file():
            return [{
                "name": target.name,
                "path": target.relative_to(root).as_posix(),
                "tree_sha256": tree_sha256(target),
                "status": "OPEN",
                "returncode": result.returncode,
                "error": result.stderr.strip() or result.stdout.strip() or "SkillSpector did not produce a JSON report",
                "findings": [],
            } for target in targets]
        report = json.loads(raw_report.read_text(encoding="utf-8"))
    if len(targets) == 1:
        return [compact_record(report, targets[0], root, result.returncode)]
    reports = {str(item.get("name")): item for item in report.get("skills", []) if isinstance(item, dict)}
    records = []
    for target in targets:
        item = reports.get(target.name)
        if item is None:
            records.append({
                "name": target.name,
                "path": target.relative_to(root).as_posix(),
                "tree_sha256": tree_sha256(target),
                "status": "OPEN",
                "returncode": result.returncode,
                "error": "SkillSpector recursive report omitted this Skill",
                "findings": [],
            })
        else:
            records.append(compact_record(item, target, root, result.returncode))
    return records


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, type=Path, help="One Skill directory or a directory of immediate Skill children.")
    parser.add_argument("--report", required=True, type=Path, help="Aggregate JSON report path.")
    parser.add_argument("--skillspector-bin", help="Pinned SkillSpector executable; defaults to SKILLSPECTOR_BIN or PATH.")
    parser.add_argument("--timeout-seconds", type=int, default=120, help="Fail closed if one scanner invocation exceeds this limit.")
    parser.add_argument("--require-pass", action="store_true", help="Exit non-zero unless every scanned Skill passes.")
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parent.parent)
    args = parser.parse_args()

    root = args.root.resolve()
    input_path = args.input.resolve()
    if not input_path.is_dir():
        raise SystemExit(f"SkillSpector input must be a directory: {input_path}")
    targets = discover_targets(input_path)
    binary = resolve_binary(args.skillspector_bin)
    lock = json.loads((root / "tools" / "skillspector-lock.json").read_text(encoding="utf-8"))
    if args.timeout_seconds < 1:
        raise SystemExit("--timeout-seconds must be positive")
    skills = scan(binary, input_path, targets, root, args.timeout_seconds)
    status = "PASS" if all(item["status"] == "PASS" for item in skills) else "OPEN"
    payload = {
        "schema_version": "1",
        "status": status,
        "tool": lock,
        "mode": "static-no-llm",
        "skills": skills,
    }
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8", newline="\n")
    print(json.dumps({"status": status, "skills": len(skills), "report": str(args.report)}, indent=2))
    return 0 if status == "PASS" or not args.require_pass else 1


if __name__ == "__main__":
    raise SystemExit(main())
