# The declared temporary folder (Mission 234, rule on workspace hygiene S2),
# PowerShell twin of tools/lib/tmp.sh. To be dot-sourced; defines functions.
#
#   . (Join-Path <Vault> 'tools\lib\tmp.ps1')
#   Get-SbTmpRoot            # the declared folder, created if missing
#   Get-SbTmpDir -Use tests  # <root>\<use>, created
#
# Order: $env:SB_TMP; the line "Dossier temporaire declare : `<path>`" (accented in the marker) of the
# workspace marker VAULT-ROOT.md found by walking up from this Vault; the
# default <system temporary folder>\second-brain. A root below a folder that
# carries VAULT-ROOT.md is refused (throws).

$script:SbTmpLibDir = $PSScriptRoot
$script:SbTmpMarkerLabel = 'Dossier temporaire d' + [char]0x00E9 + 'clar' + [char]0x00E9

function Find-SbTmpMarkerDir([string]$Start) {
    $dir = $null
    try { $dir = (Resolve-Path -LiteralPath $Start -ErrorAction Stop).ProviderPath } catch { return $null }
    while ($dir) {
        if (Test-Path -LiteralPath (Join-Path $dir 'VAULT-ROOT.md') -PathType Leaf) { return $dir }
        $parent = Split-Path -Parent $dir
        if (-not $parent -or $parent -eq $dir) { break }
        $dir = $parent
    }
    return $null
}

function Get-SbTmpMarkerValue([string]$MarkerFile) {
    if (-not (Test-Path -LiteralPath $MarkerFile -PathType Leaf)) { return '' }
    $text = [System.IO.File]::ReadAllText($MarkerFile, [System.Text.Encoding]::UTF8)
    $m = [regex]::Match($text, [regex]::Escape($script:SbTmpMarkerLabel) + ' : `([^`]*)`')
    if ($m.Success) { return $m.Groups[1].Value }
    return ''
}

function Get-SbTmpRoot {
    $root = ''
    if ($env:SB_TMP) {
        $root = $env:SB_TMP
    } else {
        $marker = Find-SbTmpMarkerDir (Join-Path $script:SbTmpLibDir '..\..')
        if ($marker) { $root = Get-SbTmpMarkerValue (Join-Path $marker 'VAULT-ROOT.md') }
    }
    if (-not $root) {
        $system = if ($env:LOCALAPPDATA) { Join-Path $env:LOCALAPPDATA 'Temp' } else { [System.IO.Path]::GetTempPath() }
        $root = Join-Path $system 'second-brain'
    }
    # Refused before anything is created: walk up from the nearest existing ancestor.
    $existing = $root
    while (-not (Test-Path -LiteralPath $existing -PathType Container)) {
        $parent = Split-Path -Parent $existing
        if (-not $parent -or $parent -eq $existing) { break }
        $existing = $parent
    }
    $walk = Find-SbTmpMarkerDir $existing
    if ($walk) {
        throw "REFUS : dossier temporaire declare sous une racine d'espace ($walk porte VAULT-ROOT.md) : $root ; il doit vivre hors de l'espace de travail (regle 112218 S2.3)"
    }
    New-Item -ItemType Directory -Force -Path $root | Out-Null
    return (Resolve-Path -LiteralPath $root).ProviderPath.TrimEnd('\', '/')
}

function Get-SbTmpDir([Parameter(Mandatory = $true)][string]$Use) {
    if ($Use -notmatch '^[A-Za-z0-9._-]+$' -or $Use -eq '.' -or $Use -eq '..') {
        throw "REFUS : usage du dossier temporaire invalide : '$Use' (un nom de dossier)"
    }
    $d = Join-Path (Get-SbTmpRoot) $Use
    New-Item -ItemType Directory -Force -Path $d | Out-Null
    return $d
}
