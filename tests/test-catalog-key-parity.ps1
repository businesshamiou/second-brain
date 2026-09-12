#Requires -Version 5.1
<#
.SYNOPSIS
    Catalog key parity test (Mission 168, ticket 05; spec, Testing Decisions
    -- catalogs must have identical keys in the three languages).

.DESCRIPTION
    Rerun with one command, from the repository root:

        powershell -NoProfile -ExecutionPolicy Bypass -File tests\test-catalog-key-parity.ps1

    Proves the three installer catalogs (i18n/catalog.en.json,
    i18n/catalog.fr.json, i18n/catalog.es.json) declare exactly the same set
    of keys -- an installer given any of the three languages must be able to
    resolve every key the code looks up, never falling through to a missing
    key in one language only. The "_comment" key is excluded: it documents
    the file for a human reader and is never looked up by code.

    Exit code 0 means the three key sets are identical. Exit code 1 means at
    least one key is missing from, or extra in, one of the three catalogs;
    details are printed to stdout.
#>

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path $PSScriptRoot -Parent
$i18nDir = Join-Path $RepoRoot 'i18n'
$failures = New-Object System.Collections.Generic.List[string]

function Get-CatalogKeys {
    param([Parameter(Mandatory = $true)][string] $Path)
    $json = Get-Content -Raw -Path $Path | ConvertFrom-Json
    $keys = $json.PSObject.Properties.Name | Where-Object { $_ -ne '_comment' }
    return @($keys | Sort-Object)
}

$languages = @('en', 'fr', 'es')
$keysByLanguage = @{}
foreach ($lang in $languages) {
    $path = Join-Path $i18nDir "catalog.$lang.json"
    if (-not (Test-Path $path)) {
        Write-Output "  FAIL - catalog missing: $path"
        $failures.Add("catalog missing: $path") | Out-Null
        continue
    }
    $keysByLanguage[$lang] = Get-CatalogKeys -Path $path
    Write-Output "  $lang : $($keysByLanguage[$lang].Count) keys"
}

if ($failures.Count -eq 0) {
    $reference = $keysByLanguage['en']
    foreach ($lang in $languages) {
        $current = $keysByLanguage[$lang]
        $missing = @(Compare-Object -ReferenceObject $reference -DifferenceObject $current | Where-Object { $_.SideIndicator -eq '<=' } | ForEach-Object { $_.InputObject })
        $extra = @(Compare-Object -ReferenceObject $reference -DifferenceObject $current | Where-Object { $_.SideIndicator -eq '=>' } | ForEach-Object { $_.InputObject })
        if ($missing.Count -eq 0 -and $extra.Count -eq 0) {
            Write-Output "  PASS - catalog.$lang.json has exactly the reference (en) key set"
        }
        else {
            Write-Output "  FAIL - catalog.$lang.json differs from the reference (en) key set"
            foreach ($k in $missing) { Write-Output "    missing: $k" }
            foreach ($k in $extra) { Write-Output "    extra:   $k" }
            $failures.Add("catalog.$lang.json key set differs from en ($($missing.Count) missing, $($extra.Count) extra)") | Out-Null
        }
    }
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
