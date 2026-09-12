# Tools

- `validate-warehouse.py` validates the active thin checkout without network access.
- `package-collection-release.py` builds one collection in a required empty, immutable `deliverables/<collection>/<version>/` directory. It creates chat ZIPs and the collection ZIP from one in-memory canonical tree, validates byte identity, and emits manifest, licence inventory, report and SHA-256 checksums.
- `scan-skillspector.py` is the mandatory static security gate for every incoming Skill and every new collection release. It requires the pinned external SkillSpector executable recorded in `skillspector-lock.json`.

Example:

```powershell
$env:SKILLSPECTOR_BIN = 'C:\path\to\skillspector.exe'
python tools/scan-skillspector.py --input skill-collections\web-design\skills --report provenance\skillspector\web-design.json --require-pass
python tools/package-collection-release.py --collection web-design --version 2026-09-02-v1 --skillspector-report provenance\skillspector\web-design.json --output-dir deliverables\web-design\2026-09-02-v1
```

The producer refuses to overwrite a non-empty delivery directory. Publish an external mirror only after this immutable local delivery validates, then record its URL and checksums under `logs/releases/`.
