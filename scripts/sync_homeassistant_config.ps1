# Sync tracked Home Assistant YAML/Python from this repo to the live HA /config share.
# Usage (from repo root):
#   powershell -ExecutionPolicy Bypass -File scripts/sync_homeassistant_config.ps1
# Override target: add -ConfigRoot '\\host\share\config'

param(
    [string]$ConfigRoot = '\\192.168.89.25\config'
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$haRoot = Join-Path $repoRoot 'homeassistant'

if (-not (Test-Path $haRoot)) {
    throw "Expected repo folder not found: $haRoot"
}

$pair = @(
    @{ Src = 'dashboards'; Note = 'Lovelace dashboard YAML' },
    @{ Src = 'packages'; Note = 'Packages (!include_dir_named packages)' }
)

foreach ($p in $pair) {
    $src = Join-Path $haRoot $p.Src
    if (-not (Test-Path $src)) {
        Write-Warning "Skip missing source: $src"
        continue
    }
    $dst = Join-Path $ConfigRoot $p.Src
    if (-not (Test-Path $dst)) {
        New-Item -ItemType Directory -Path $dst -Force | Out-Null
    }
    Write-Host "[$($p.Note)] $src -> $dst"
    Copy-Item -Path (Join-Path $src '*') -Destination $dst -Recurse -Force
}

Write-Host 'Home Assistant config sync finished.'
