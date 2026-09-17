#Requires -Version 5.1
<#
.SYNOPSIS
    Web package README/contents parity test (Mission 171-C01, step 8).

.DESCRIPTION
    The step's own explicitly required test: "the package contains what
    its README announces" (audit defect 9, and the flip side of defect 8 --
    a generator that silently drops a knowledge file would otherwise pass
    unnoticed as long as INSTRUCTIONS.md and README.md themselves still
    looked fine).

    Generates one test web package by dot-sourcing
    tools/generate-assistant.ps1 directly and calling New-AssistantForms
    against a minimal temp clone -- never the real second-brain checkout,
    and never install.ps1's own heavier end-to-end path (that is already
    covered by tests/test-assistant-generation.ps1). The temp clone carries
    only the source files New-AssistantForms's web-package path actually
    reads: assistant/ASSISTANT.md (the identity source) and every source
    path in $Script:WebPackageKnowledgeFiles's own SourcePaths lists
    (Mission 172: CONTEXT.md and the project/Second-Brain boundary rule,
    one source each, plus the session-start skill, its reading list, the
    Mission template, the project operating model brief and the Mission
    versioning rule -- the five sources METHOD.md condenses) -- copied from
    the real repository, never invented, so this test exercises the same
    content the real installer would.

    The check runs both directions against the generated README.md:
      - every filename the README announces (matched by the narrow regex
        below, deliberately not a general Markdown parser -- this only
        needs to check this generator's own fixed template) other than
        README.md itself (which documents itself, never something it
        uploads) must exist on disk in the package folder;
      - every file actually in the package folder, other than README.md
        itself, must be announced somewhere in README.md.
    README.md marks every real filename in backtick code spans
    (`` `LIKE-THIS.md` ``, see New-WebPackageReadme's own template), so the
    regex `` `([A-Za-z0-9._-]+\.md)` `` is sufficient and never matches the
    prose around it.

    Mission 183-C01: the indexes are regenerated over the test clone right
    after generation, exactly as the installer does -- without that step
    this test never saw the index.md the real installer left in the
    package (Mission 182: 5 announced, 6 present). The README's own file
    count is checked too, and no generated form may start with a UTF-8
    byte-order mark (Codex refuses such a SKILL.md).

    Rerun with:
        powershell -NoProfile -ExecutionPolicy Bypass -File tests\test-web-package-readme-matches-contents.ps1

    Exit code 0 means the package and its README agree exactly, in both
    directions. Exit code 1 means at least one file is announced but
    missing, or present but unannounced; details are printed to stdout.
#>

[CmdletBinding()]
param([switch] $KeepTemp)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path $PSScriptRoot -Parent
$failures = New-Object System.Collections.Generic.List[string]

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if ($Condition) { Write-Output "  PASS - $Message" }
    else { Write-Output "  FAIL - $Message"; $failures.Add($Message) | Out-Null }
}

. (Join-Path $RepoRoot 'tools\generate-assistant.ps1')

$TestRoot = Join-Path $env:TEMP ("sb-webpkg-readme-" + [Guid]::NewGuid().ToString('N'))
$TestClone = Join-Path $TestRoot 'clone'
New-Item -ItemType Directory -Force -Path $TestClone | Out-Null
Write-Output ""
Write-Output "TestRoot: $TestRoot"

try {
    Write-Output ""
    Write-Output "=== Web package: README announces exactly what the folder contains ==="

    # Minimal clone: only the source files New-AssistantForms's web-package
    # path reads (identity source + the knowledge-file sources it copies
    # from). The list below is built from $Script:WebPackageKnowledgeFiles
    # itself (plus the identity source), so this test never drifts out of
    # sync with which sources the generator actually reads.
    $sourceFiles = @('assistant\ASSISTANT.md') + @($Script:WebPackageKnowledgeFiles | ForEach-Object { $_.SourcePaths })
    foreach ($relative in $sourceFiles) {
        $src = Join-Path $RepoRoot $relative
        $dst = Join-Path $TestClone $relative
        New-Item -ItemType Directory -Force -Path (Split-Path $dst -Parent) | Out-Null
        Copy-Item -Path $src -Destination $dst -Force
    }

    $slug = New-AssistantForms -ClonePath $TestClone -Name 'Testy'
    $webDir = Join-Path $TestClone "web-package\$slug"

    # Mission 183-C01: regenerate the indexes exactly as the installer does
    # right after generating the forms (install.ps1 runs the clone's own
    # tools/build-indexes.sh -> build_indexes.py over the clone root).
    # Without this step the test never saw the index.md the real installer
    # left inside web-package/<slug>/ -- the "5 announced, 6 present"
    # defect measured by Mission 182.
    # uv is obtained the way the installer obtains it (tools/prerequisites.ps1:
    # reused if on PATH, otherwise installed under this test's own root, its
    # folders redirected there too) -- never assumed on PATH. The first
    # version called `uv` directly: green on a developer machine that has
    # it, red on the GitHub Windows runner that does not (CI run
    # 35157346970, "The term 'uv' is not recognized").
    . (Join-Path $RepoRoot 'tools\prerequisites.ps1')
    $uvContext = [PSCustomObject]@{ TestMode = $true; ProfileRoot = (Join-Path $TestRoot 'profile') }
    New-Item -ItemType Directory -Force -Path $uvContext.ProfileRoot | Out-Null
    Initialize-UvEnvironmentRedirection -Context $uvContext
    $uv = Resolve-OrInstall-Uv -Context $uvContext -Lock (Get-PrerequisitesLock).uv
    Write-Output "  uv: $($uv.Source) ($($uv.UvExe))"
    # The clone's own copy runs, as in the installer: build_indexes.py
    # derives its link target from its own location, and os.path.relpath
    # cannot cross drives. Run from this repository (D:\ on the GitHub
    # runner) over a clone under %TEMP% (C:\), it raised "path is on mount
    # 'D:', start on mount 'C:'" (CI run 35167643419).
    $cloneTools = Join-Path $TestClone 'tools'
    New-Item -ItemType Directory -Force -Path $cloneTools | Out-Null
    Copy-Item -Path (Join-Path $RepoRoot 'tools\build_indexes.py') -Destination $cloneTools -Force
    & $uv.UvExe run --no-project (Join-Path $cloneTools 'build_indexes.py') $TestClone *> (Join-Path $TestRoot 'build-indexes.log')
    Assert-True ($LASTEXITCODE -eq 0) "index regeneration over the test clone succeeded, as in the installer (exit $LASTEXITCODE)"
    $readmePath = Join-Path $webDir 'README.md'
    Assert-True (Test-Path $readmePath) "generated web package has a README.md"

    $actualFiles = @(Get-ChildItem -Path $webDir -File | ForEach-Object { $_.Name } | Where-Object { $_ -ne 'README.md' } | Sort-Object)
    Write-Output "  actual files (excluding README.md itself): $($actualFiles -join ', ')"

    $readmeText = Get-Content -Raw -Path $readmePath -Encoding UTF8
    $announced = @([regex]::Matches($readmeText, '`([A-Za-z0-9._-]+\.md)`') | ForEach-Object { $_.Groups[1].Value } | Where-Object { $_ -ne 'README.md' } | Sort-Object -Unique)
    Write-Output "  announced files (excluding README.md itself): $($announced -join ', ')"

    Assert-True ($actualFiles.Count -gt 0) "the package actually produced at least one file besides README.md (defect 8: it used to produce none)"
    Assert-True ($actualFiles.Count -eq 4) "the package holds INSTRUCTIONS.md plus the 3 knowledge files (has $($actualFiles.Count): $($actualFiles -join ', '))"

    $missingOnDisk = @($announced | Where-Object { $actualFiles -notcontains $_ })
    Assert-True ($missingOnDisk.Count -eq 0) "every file the README announces exists on disk (missing: $($missingOnDisk -join ', '))"

    $unannounced = @($actualFiles | Where-Object { $announced -notcontains $_ })
    Assert-True ($unannounced.Count -eq 0) "every file on disk is announced in the README (unannounced: $($unannounced -join ', '))"

    # The README states its own folder's file count ("This README (N files
    # total in this folder)"): it must match the folder, README included.
    $allCount = @(Get-ChildItem -Path $webDir -File).Count
    $statedMatch = [regex]::Match($readmeText, '\((\d+) files total in this folder\)')
    Assert-True ($statedMatch.Success -and [int]$statedMatch.Groups[1].Value -eq $allCount) "the README's stated file count matches the folder (stated: $($statedMatch.Groups[1].Value), present: $allCount)"

    # Mission 183-C01: no generated file starts with a UTF-8 byte-order mark
    # (Codex refuses a SKILL.md whose front matter does not start at byte 0).
    $formFiles = @(Get-ChildItem -Path $webDir -File | ForEach-Object { $_.FullName }) + @(
        (Join-Path $TestClone ".claude\agents\$slug.md"),
        (Join-Path $TestClone ".agents\skills\$slug\SKILL.md"))
    $withBom = @($formFiles | Where-Object {
        $bytes = [System.IO.File]::ReadAllBytes($_)
        $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
    } | ForEach-Object { Split-Path $_ -Leaf })
    Assert-True ($withBom.Count -eq 0) "no generated form starts with a UTF-8 byte-order mark (with one: $($withBom -join ', '))"
    $skillHead = [System.Text.Encoding]::UTF8.GetString([System.IO.File]::ReadAllBytes((Join-Path $TestClone ".agents\skills\$slug\SKILL.md")), 0, 3)
    Assert-True ($skillHead -eq '---') "the Codex SKILL.md front matter starts at byte 0 (first bytes: '$skillHead')"

    # Not this test's main point, but cheap to check here since the package
    # already exists: none of the flattened knowledge files leaves a
    # dangling relative Markdown link behind (the defect
    # Get-WebPackageKnowledgeFileContent exists to close) -- every link
    # remaining after generation must point back into the repository with
    # the fixed '../../' depth (assistant/ASSISTANT.md, or one of this
    # test's own copied knowledge sources), never a same-directory or
    # single-'../' link that only made sense at the source's own location.
    $danglingLinks = @()
    foreach ($file in (Get-ChildItem -Path $webDir -File -Filter '*.md')) {
        $text = Get-Content -Raw -Path $file.FullName -Encoding UTF8
        foreach ($match in [regex]::Matches($text, '\[[^\]]+\]\(([^)]+)\)')) {
            $target = $match.Groups[1].Value
            if ($target -match '^https?://|^mailto:|^#') { continue }
            if ($target -notmatch '^\.\./\.\./') {
                $danglingLinks += "$($file.Name) -> $target"
            }
        }
    }
    Assert-True ($danglingLinks.Count -eq 0) "no relative link in the package points anywhere but back into the repository at '../../' depth (dangling: $($danglingLinks -join '; '))"
}
catch {
    Write-Output "  FAIL - unhandled error: $($_.Exception.Message)"
    $failures.Add("unhandled error: $($_.Exception.Message)") | Out-Null
}

if (-not $KeepTemp) {
    try {
        . (Join-Path $RepoRoot 'tools\resolve-bash-exe.ps1')
        $cleanupBash = Resolve-BashExe
        & $cleanupBash -c "rm -rf -- '$($TestRoot -replace '\\','/')'"
    }
    catch { }
    Write-Output ""
    Write-Output "TestRoot removed: $TestRoot"
}
else {
    Write-Output ""
    Write-Output "TestRoot kept (-KeepTemp): $TestRoot"
}

Write-Output ""
if ($failures.Count -eq 0) {
    Write-Output "=== RESULT: PASS (all checks green) ==="
    exit 0
}
else {
    Write-Output "=== RESULT: FAIL ($($failures.Count) check(s) failed) ==="
    $failures | ForEach-Object { Write-Output "  - $_" }
    exit 1
}
