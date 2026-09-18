# Mission 188 -- the Windows half of the setup-test-env action (setup.sh
# holds the same steps for Linux and macOS).
#
# usage: powershell -NoProfile -ExecutionPolicy Bypass -File setup.ps1 -EnvDir <dir> -UvBin <dir> [-PythonVersion 3.12]
#
# Installs only what is missing: uv (version and install-script SHA-256 read
# from tools/prerequisites.lock.json), a uv-managed Python, and pre-commit as
# a uv tool, all under -EnvDir and -UvBin. Nothing is put on PATH, nothing
# touches the profile. Writes <EnvDir>\env.ps1, the variables that point uv
# there.

param(
    [Parameter(Mandatory = $true)][string]$EnvDir,
    [Parameter(Mandatory = $true)][string]$UvBin,
    [string]$PythonVersion = '3.12'
)

# Continue, not Stop: under Windows PowerShell 5.1 a native program's stderr
# redirected with 2>$null would turn into a terminating error. Every failure
# below is checked by exit code and thrown explicitly.
$ErrorActionPreference = 'Continue'
if ($env:SB_REPO_ROOT) { $repoRoot = $env:SB_REPO_ROOT }
else { $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path }
$lock = Get-Content -Raw -LiteralPath (Join-Path $repoRoot 'tools\prerequisites.lock.json') | ConvertFrom-Json
$uvUrl = $lock.uv.installScriptUrl
$uvSha = $lock.uv.installScriptSha256
$uvVersion = $lock.uv.version
$pcVersion = $lock.preCommit.version
if (-not $uvUrl -or -not $uvSha -or -not $uvVersion -or -not $pcVersion) {
    throw 'REFUS : pins unreadable in prerequisites.lock.json'
}

New-Item -ItemType Directory -Force -Path $EnvDir, $UvBin | Out-Null
$installed = @()

function Get-ToolVersion([string]$exe) {
    if (-not (Test-Path -LiteralPath $exe)) { return '' }
    $out = & $exe --version 2>$null
    if ($LASTEXITCODE -ne 0) { return '' }
    return ($out | Out-String).Trim()
}

# --- uv ----------------------------------------------------------------------
$uv = Join-Path $UvBin 'uv.exe'
if (-not ((Get-ToolVersion $uv) -like "* $uvVersion*")) {
    $script = Join-Path $EnvDir 'install-uv.ps1'
    Invoke-WebRequest -Uri $uvUrl -OutFile $script -UseBasicParsing
    $hash = (Get-FileHash -Algorithm SHA256 -Path $script).Hash
    if ($hash -ne $uvSha) { throw "REFUS : uv install script hash $hash, expected $uvSha" }
    $env:UV_UNMANAGED_INSTALL = $UvBin
    $env:UV_NO_MODIFY_PATH = '1'
    $env:UV_SYSTEM_CERTS = '1'
    & powershell -NoProfile -ExecutionPolicy Bypass -File $script
    $rc = $LASTEXITCODE
    Remove-Item Env:\UV_UNMANAGED_INSTALL, Env:\UV_NO_MODIFY_PATH, Env:\UV_SYSTEM_CERTS
    if ($rc -ne 0) { throw "uv install script failed ($rc)" }
    Remove-Item -LiteralPath $script -Force
    $installed += 'uv'
}

# --- where uv keeps everything else ------------------------------------------
$vars = [ordered]@{
    UV_CACHE_DIR          = (Join-Path $EnvDir 'cache')
    UV_PYTHON_INSTALL_DIR = (Join-Path $EnvDir 'python')
    UV_PYTHON_BIN_DIR     = (Join-Path $EnvDir 'bin')
    UV_TOOL_DIR           = (Join-Path $EnvDir 'tools')
    UV_TOOL_BIN_DIR       = (Join-Path $EnvDir 'bin')
    UV_PYTHON_PREFERENCE  = 'only-managed'
    UV_PYTHON_INSTALL_REGISTRY = '0'
    UV_SYSTEM_CERTS       = '1'
}
$envLines = @()
foreach ($k in $vars.Keys) {
    Set-Item -Path "Env:\$k" -Value $vars[$k]
    $envLines += ('$env:{0} = ''{1}''' -f $k, $vars[$k])
}
Set-Content -LiteralPath (Join-Path $EnvDir 'env.ps1') -Value $envLines -Encoding ASCII

# --- Python ------------------------------------------------------------------
& $uv python find $PythonVersion 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    & $uv python install $PythonVersion
    if ($LASTEXITCODE -ne 0) { throw "uv python install failed ($LASTEXITCODE)" }
    $installed += 'python'
}

# --- pre-commit --------------------------------------------------------------
$pc = Join-Path $EnvDir 'bin\pre-commit.exe'
if (-not ((Get-ToolVersion $pc) -like "* $pcVersion*")) {
    & $uv tool install --force --python $PythonVersion "pre-commit==$pcVersion"
    if ($LASTEXITCODE -ne 0) { throw "uv tool install pre-commit failed ($LASTEXITCODE)" }
    $installed += 'pre-commit'
}

Write-Output "uv:         $(Get-ToolVersion $uv)"
Write-Output "python:     $(& $uv python find $PythonVersion)"
Write-Output "pre-commit: $(Get-ToolVersion $pc)"
if ($installed.Count -eq 0) { Write-Output 'setup-test-env: warm, nothing installed' }
else { Write-Output "setup-test-env: installed $($installed -join ' ')" }
exit 0
