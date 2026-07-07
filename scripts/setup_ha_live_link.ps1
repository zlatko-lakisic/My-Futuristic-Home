# Create ha-live symlink one level above the repo for cross-platform workspace use.
# Points at the live Home Assistant /config SMB share (same target as sync_homeassistant_config.ps1).
#
# Layout:
#   Projects/ha-live              -> \\192.168.89.25\config
#   Projects/My-Futuristic-Home/
#
# Usage (from repo root):
#   powershell -ExecutionPolicy Bypass -File scripts/setup_ha_live_link.ps1
# Override share: -ConfigRoot '\\host\share\config'
# Replace existing link: -Force
#
# Requires SymbolicLink creation (Windows Developer Mode or elevated shell).

param(
    [string]$ConfigRoot = '\\192.168.89.25\config',
    [string]$LinkName = 'ha-live',
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$parentRoot = Split-Path -Parent $repoRoot
$linkPath = Join-Path $parentRoot $LinkName
$legacyLinkPath = Join-Path $repoRoot $LinkName

if (-not (Test-Path $ConfigRoot)) {
    throw "Config path not reachable: $ConfigRoot"
}

function Get-LinkTarget {
    param([string]$Path)
    $item = Get-Item -LiteralPath $Path -Force
    if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
        return $item.Target
    }
    return $null
}

if (Test-Path -LiteralPath $legacyLinkPath) {
    $legacyTarget = Get-LinkTarget -Path $legacyLinkPath
    if ($legacyTarget) {
        Write-Host "Removing legacy in-repo link: $legacyLinkPath"
        Remove-Item -LiteralPath $legacyLinkPath -Force
    }
}

if (Test-Path -LiteralPath $linkPath) {
    $existingTarget = Get-LinkTarget -Path $linkPath
    $normalizedConfig = (Resolve-Path -LiteralPath $ConfigRoot).Path
    $normalizedExisting = if ($existingTarget) {
        try { (Resolve-Path -LiteralPath $existingTarget[0]).Path } catch { $existingTarget[0] }
    } else { $null }

    if ($normalizedExisting -and ($normalizedExisting -ieq $normalizedConfig)) {
        Write-Host "ha-live already points at $ConfigRoot"
        exit 0
    }

    if (-not $Force) {
        throw "Path already exists: $linkPath. Use -Force to replace it."
    }

    Remove-Item -LiteralPath $linkPath -Recurse -Force
}

New-Item -ItemType SymbolicLink -Path $linkPath -Target $ConfigRoot | Out-Null
Write-Host "Created $linkPath -> $ConfigRoot"
Write-Host "Reopen My-Futuristic-Home.code-workspace if ha-live was missing."
