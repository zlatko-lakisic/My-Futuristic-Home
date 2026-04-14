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

$files = @(
    'configuration.yaml',
    'scripts.yaml',
    'automations.yaml',
    'templates.yaml',
    'scenes.yaml',
    'mqtt.yaml'
)

foreach ($f in $files) {
    $srcPath = Join-Path $haRoot $f
    if (-not (Test-Path $srcPath)) {
        Write-Warning "Skip missing file: $srcPath"
        continue
    }
    Copy-Item -Path $srcPath -Destination (Join-Path $ConfigRoot $f) -Force
    Write-Host "[YAML root] $f -> $ConfigRoot"
}

$pair = @(
    @{ Src = 'automations'; Note = 'Automations (!include_dir_merge_list automations/)' },
    @{ Src = 'dashboards'; Note = 'Lovelace dashboard YAML' },
    @{ Src = 'packages'; Note = 'Packages (!include_dir_named packages)' },
    @{ Src = 'www'; Note = 'Static files (config www -> /local/)' },
    @{ Src = 'blueprints'; Note = 'Blueprints (optional)' }
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
