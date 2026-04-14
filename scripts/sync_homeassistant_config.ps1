# Sync Home Assistant YAML between this repo (homeassistant/) and the live HA /config share.
#
# Push (default): repo -> live (deploy after editing in Git).
# Pull: live -> repo (refresh Git from the Samba share / HA host).
#
# Usage (from repo root):
#   powershell -ExecutionPolicy Bypass -File scripts/sync_homeassistant_config.ps1
#   powershell -ExecutionPolicy Bypass -File scripts/sync_homeassistant_config.ps1 -Direction Pull
# Override target: -ConfigRoot '\\host\share\config'

param(
    [string]$ConfigRoot = '\\192.168.89.25\config',
    [ValidateSet('Push', 'Pull')]
    [string]$Direction = 'Push'
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$haRoot = Join-Path $repoRoot 'homeassistant'

if (-not (Test-Path $haRoot)) {
    throw "Expected repo folder not found: $haRoot"
}

if (-not (Test-Path $ConfigRoot)) {
    throw "Config path not reachable: $ConfigRoot"
}

$rootYaml = @(
    'configuration.yaml',
    'scripts.yaml',
    'automations.yaml',
    'templates.yaml',
    'scenes.yaml',
    'mqtt.yaml'
)

$neverPullFromLive = @(
    'secrets.yaml',
    'service_account.json'
)

foreach ($f in $rootYaml) {
    if ($Direction -eq 'Push') {
        $srcPath = Join-Path $haRoot $f
        if (-not (Test-Path $srcPath)) {
            Write-Warning "Skip missing file: $srcPath"
            continue
        }
        Copy-Item -Path $srcPath -Destination (Join-Path $ConfigRoot $f) -Force
        Write-Host "[Push YAML root] $f -> $ConfigRoot"
    }
    else {
        if ($neverPullFromLive -contains $f) { continue }
        $livePath = Join-Path $ConfigRoot $f
        $dstPath = Join-Path $haRoot $f
        if (-not (Test-Path $livePath)) {
            Write-Warning "Skip missing on live: $livePath"
            continue
        }
        Copy-Item -Path $livePath -Destination $dstPath -Force
        Write-Host "[Pull YAML root] $livePath -> $dstPath"
    }
}

$dirs = @(
    @{ Src = 'automations'; Note = 'Automations (!include_dir_merge_list automations/)' },
    @{ Src = 'dashboards'; Note = 'Lovelace dashboard YAML' },
    @{ Src = 'packages'; Note = 'Packages (!include_dir_named packages)' },
    @{ Src = 'www'; Note = 'Static files (config www -> /local/)' },
    @{ Src = 'blueprints'; Note = 'Blueprints (optional)' }
)

# Under www/, do not pull HACS card drops or ephemeral snapshots into Git (large / runtime-only).
$wwwPullSkip = @('community', 'tmp', 'snapshots')

foreach ($p in $dirs) {
    $name = $p.Src
    if ($Direction -eq 'Push') {
        $src = Join-Path $haRoot $name
        if (-not (Test-Path $src)) {
            Write-Warning "Skip missing source: $src"
            continue
        }
        $dst = Join-Path $ConfigRoot $name
        if (-not (Test-Path $dst)) {
            New-Item -ItemType Directory -Path $dst -Force | Out-Null
        }
        Write-Host "[Push $($p.Note)] $src -> $dst"
        Copy-Item -Path (Join-Path $src '*') -Destination $dst -Recurse -Force
    }
    else {
        $src = Join-Path $ConfigRoot $name
        if (-not (Test-Path $src)) {
            Write-Warning "Skip missing on live: $src"
            continue
        }
        $dst = Join-Path $haRoot $name
        if (-not (Test-Path $dst)) {
            New-Item -ItemType Directory -Path $dst -Force | Out-Null
        }
        Write-Host "[Pull $($p.Note)] $src -> $dst"
        if ($name -eq 'www') {
            Get-ChildItem -LiteralPath $src -Force | ForEach-Object {
                if ($wwwPullSkip -contains $_.Name) {
                    Write-Host "  [Pull www] skip $($_.Name)"
                    return
                }
                Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $dst $_.Name) -Recurse -Force
            }
        }
        else {
            Copy-Item -Path (Join-Path $src '*') -Destination $dst -Recurse -Force
        }
    }
}

Write-Host "Home Assistant config sync finished ($Direction)."
