#!/usr/bin/env bash
# Mount HA /config one level above the repo for cross-platform workspace use.
#
# Layout:
#   Projects/ha-live/             SMB mount of 192.168.89.25/config
#   Projects/My-Futuristic-Home/
#
# Usage (from repo root):
#   bash scripts/setup_ha_live_link.sh
#   SMB_USER=ha SMB_PASS=secret bash scripts/setup_ha_live_link.sh
#   SMB_HOST=192.168.89.25 bash scripts/setup_ha_live_link.sh
# Replace existing mount/link: FORCE=1 bash scripts/setup_ha_live_link.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

LINK_NAME="${LINK_NAME:-ha-live}"
LINK_PATH="$(cd "$REPO_ROOT/.." && pwd)/$LINK_NAME"
LEGACY_LINK_PATH="$REPO_ROOT/$LINK_NAME"
SMB_HOST="${SMB_HOST:-192.168.89.25}"
SMB_SHARE="${SMB_SHARE:-config}"
FORCE="${FORCE:-0}"

is_mounted() {
  local path="$1"
  mount | grep -q " on ${path} "
}

mount_share() {
  local mount_point="$1"

  mkdir -p "$mount_point"

  local smb_url
  if [[ -n "${SMB_USER:-}" ]]; then
    if [[ -n "${SMB_PASS:-}" ]]; then
      smb_url="//${SMB_USER}:${SMB_PASS}@${SMB_HOST}/${SMB_SHARE}"
    else
      smb_url="//${SMB_USER}@${SMB_HOST}/${SMB_SHARE}"
    fi
  else
    smb_url="//${SMB_HOST}/${SMB_SHARE}"
  fi

  echo "Mounting ${SMB_HOST}/${SMB_SHARE} at ${mount_point}"
  mount_smbfs "$smb_url" "$mount_point"
}

remove_legacy_in_repo_link() {
  if [[ -L "$LEGACY_LINK_PATH" ]]; then
    echo "Removing legacy in-repo link: $LEGACY_LINK_PATH"
    rm "$LEGACY_LINK_PATH"
  fi
}

remove_legacy_in_repo_link

if is_mounted "$LINK_PATH"; then
  if [[ -f "$LINK_PATH/configuration.yaml" ]]; then
    echo "ha-live already mounted at $LINK_PATH"
    exit 0
  fi
  echo "ERROR: $LINK_PATH is mounted but does not look like HA /config." >&2
  exit 1
fi

if [[ -L "$LINK_PATH" ]]; then
  if [[ "$FORCE" != "1" ]]; then
    echo "ERROR: $LINK_PATH is a symlink (legacy setup). Set FORCE=1 to replace with a direct mount." >&2
    exit 1
  fi
  rm "$LINK_PATH"
fi

if [[ -e "$LINK_PATH" ]]; then
  if [[ "$FORCE" == "1" ]] && [[ -d "$LINK_PATH" ]] && [[ -z "$(ls -A "$LINK_PATH")" ]]; then
    :
  elif [[ "$FORCE" == "1" ]] && [[ -d "$LINK_PATH" ]]; then
    echo "ERROR: $LINK_PATH is not empty. Unmount or clear it before remounting." >&2
    exit 1
  else
    echo "ERROR: $LINK_PATH exists and is not an SMB mount. Set FORCE=1 to replace an empty directory." >&2
    exit 1
  fi
fi

mount_share "$LINK_PATH"

if [[ ! -f "$LINK_PATH/configuration.yaml" ]]; then
  echo "ERROR: Mount at $LINK_PATH is not reachable or does not look like HA /config." >&2
  echo "Set SMB_USER/SMB_PASS if the share requires credentials." >&2
  exit 1
fi

echo "Mounted $LINK_PATH -> //${SMB_HOST}/${SMB_SHARE}"
echo "Reopen My-Futuristic-Home.code-workspace if ha-live was missing."
