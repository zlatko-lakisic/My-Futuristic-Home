#!/usr/bin/env bash
# Flash a spare MikroTik as a travel router and register it on Kuca.
# macOS and Linux equivalent of scripts/flash_roaming_mikrotik.ps1.
# Dry-run unless --apply is passed. Reset still requires --confirmed-board.
# Uses OpenSSH with SSH_ASKPASS. It does not use sshpass.
#
#   bash scripts/flash_roaming_mikrotik.sh --config .cursor/secrets/roaming-flash.json
#   bash scripts/flash_roaming_mikrotik.sh --config .cursor/secrets/roaming-flash.json --apply --confirmed
#   bash scripts/flash_roaming_mikrotik.sh --config .cursor/secrets/roaming-flash.json --rollback

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=roaming/roaming_flash.sh
source "$SCRIPT_DIR/roaming/roaming_flash.sh"

config=
apply=no
rollback=no
confirmed=no
confirmed_board=no
reflash_live=no
offline=no

while [[ $# -gt 0 ]]; do
  case $1 in
    --config) config=$2; shift 2 ;;
    --apply) apply=yes; shift ;;
    --rollback) rollback=yes; shift ;;
    --confirmed) confirmed=yes; shift ;;
    --confirmed-board) confirmed_board=yes; shift ;;
    --reflash-live) reflash_live=yes; shift ;;
    --offline) offline=yes; shift ;;
    *) die "Unknown argument: $1" ;;
  esac
done

repo=$(roaming_repo_root)
[[ -n $config ]] || config="$repo/.cursor/secrets/roaming-flash.json"
kuca_secret="$repo/.cursor/secrets/.router-kuca"
mostar_secret="$repo/.cursor/secrets/.router-mostar"
out_dir="$repo/infrastructure/roaming/out"

python3 -c 'import json' >/dev/null 2>&1 || die "python3 is required to read the JSON config."
command -v ssh >/dev/null || die "OpenSSH is required. This script does not use sshpass."

read_secret_field() {
  local path=$1 field=$2
  local line key value
  while IFS= read -r line || [[ -n $line ]]; do
    [[ $line =~ ^[[:space:]]*# || -z $line ]] && continue
    key=${line%%=*}
    value=${line#*=}
    if [[ $key == "$field" ]]; then
      printf '%s' "$value"
      return 0
    fi
  done <"$path"
  return 1
}

ros_ssh() {
  local host=$1 user=$2 password=$3 accept_new=$4 command=$5
  local askpass
  askpass=$(mktemp)
  cat >"$askpass" <<'EOF'
#!/bin/sh
printf '%s\n' "$ROAMING_SSH_PASSWORD"
EOF
  chmod 700 "$askpass"
  local -a opts=(-n -T -o ConnectTimeout=15 -o PreferredAuthentications=publickey,password,keyboard-interactive -o NumberOfPasswordPrompts=1)
  if [[ $accept_new == yes ]]; then
    opts+=(-o StrictHostKeyChecking=accept-new)
  else
    opts+=(-o StrictHostKeyChecking=yes)
  fi
  ROAMING_SSH_PASSWORD=$password DISPLAY="${DISPLAY:-:0}" SSH_ASKPASS="$askpass" SSH_ASKPASS_REQUIRE=force \
    ssh "${opts[@]}" "$user@$host" "$command"
  local status=$?
  rm -f "$askpass"
  return "$status"
}

ros_scp() {
  local host=$1 user=$2 password=$3 source=$4 dest=$5
  local askpass
  askpass=$(mktemp)
  cat >"$askpass" <<'EOF'
#!/bin/sh
printf '%s\n' "$ROAMING_SSH_PASSWORD"
EOF
  chmod 700 "$askpass"
  ROAMING_SSH_PASSWORD=$password DISPLAY="${DISPLAY:-:0}" SSH_ASKPASS="$askpass" SSH_ASKPASS_REQUIRE=force \
    scp -o ConnectTimeout=15 -o StrictHostKeyChecking=accept-new "$source" "$user@$host:$dest"
  local status=$?
  rm -f "$askpass"
  return "$status"
}

if [[ $rollback == yes ]]; then
  [[ -f $config ]] || die "Config not found: $config"
  eval "$(load_config_json "$config" no)"
  fill_derived_config
  journal="$out_dir/kuca-journal-$cfg_slug.json"
  [[ -f $journal ]] || die "No journal at $journal. There is nothing to roll back."
  lines=$(python3 - "$journal" <<'PY'
import json, sys
with open(sys.argv[1], encoding='utf-8') as handle:
    journal = json.load(handle)
for entry in journal.get('entries', []):
    fields = [
        'JOURNAL',
        entry.get('op', ''),
        entry.get('kind', ''),
        entry.get('name', ''),
        entry.get('previous', ''),
        entry.get('list', '') or entry.get('service', ''),
        entry.get('address', ''),
        entry.get('comment', ''),
    ]
    print('|'.join(fields))
PY
)
  if [[ $offline == yes ]]; then
    echo "Rollback is offline. Reconnect this computer to the house, then run --rollback without --offline."
    echo "commands: $(printf '%s\n' "$lines" | grep -c '^JOURNAL|' || true)"
    exit 0
  fi
  kuca_ip=$(read_secret_field "$kuca_secret" IP)
  kuca_user=$(read_secret_field "$kuca_secret" Username)
  kuca_pass=$(read_secret_field "$kuca_secret" Password || true)
  while IFS= read -r command; do
    [[ -n $command ]] || continue
    ros_ssh "$kuca_ip" "$kuca_user" "$kuca_pass" no ":do { $command } on-error={}" >/dev/null
  done < <(rollback_from_journal_lines "$lines")
  rm -f "$journal"
  echo "Rollback finished and the journal was removed."
  exit 0
fi

[[ -f $config ]] || die "Config not found. Copy infrastructure/roaming/roaming.example.json to .cursor/secrets/roaming-flash.json and fill it in."
if ! assignments=$(load_config_json "$config" yes); then
  die "The secrets file still has empty wifiPassword, adminPassword, or l2tp.ipsecSecret."
fi
# shellcheck disable=SC2086
eval "$assignments"
fill_derived_config

inventory=$(cat "$repo/infrastructure/networks.md")
blocked=$( { hotel_blocks; inventory_cidrs "$inventory"; } | sort -u )
if [[ $reflash_live == yes ]]; then
  blocked=$(printf '%s\n' "$blocked" | grep -vx '192.168.86.0/24' || true)
fi
# shellcheck disable=SC2086
blocked_args=()
while IFS= read -r cidr; do
  [[ -n $cidr ]] && blocked_args+=("$cidr")
done <<<"$blocked"
if ! reason=$(lan_allowed "$cfg_lan_cidr" "$cfg_local_cidr" "${blocked_args[@]}"); then
  die "VPN LAN $cfg_lan_cidr $reason."
fi
if ! reason=$(lan_allowed "$cfg_local_cidr" "$cfg_lan_cidr" "${blocked_args[@]}"); then
  die "Local LAN $cfg_local_cidr $reason."
fi

ipsec_state=unchecked
key_count=0
pool_note=offline
write_password=no
SNAP_SECRETS=
SNAP_ROUTES=
SNAP_LISTS=
SNAP_WWW=
SNAP_API=
SNAP_API_SSL=
ssh_key_1=
ssh_key_2=

if [[ $offline == yes ]]; then
  if [[ -z $cfg_l2tp_password ]]; then
    cfg_l2tp_password=$(new_l2tp_password)
    write_password=yes
  fi
  pick=$(select_vpn_address '' '' '' '')
else
  kuca_ip=$(read_secret_field "$kuca_secret" IP)
  kuca_user=$(read_secret_field "$kuca_secret" Username)
  kuca_pass=$(read_secret_field "$kuca_secret" Password || true)
  secret_text=$(ros_ssh "$kuca_ip" "$kuca_user" "$kuca_pass" no '/ppp secret print terse proplist=name,remote-address,service')
  route_text=$(ros_ssh "$kuca_ip" "$kuca_user" "$kuca_pass" no '/ip route print terse proplist=dst-address,gateway,comment')
  address_text=$(ros_ssh "$kuca_ip" "$kuca_user" "$kuca_pass" no '/ip address print terse proplist=address')
  list_text=$(ros_ssh "$kuca_ip" "$kuca_user" "$kuca_pass" no '/ip firewall address-list print terse proplist=list,address')
  active_text=$(ros_ssh "$kuca_ip" "$kuca_user" "$kuca_pass" no '/ppp active print terse proplist=name,address')
  profile_text=$(ros_ssh "$kuca_ip" "$kuca_user" "$kuca_pass" no '/ppp profile print terse proplist=name,remote-address')
  pool_text=$(ros_ssh "$kuca_ip" "$kuca_user" "$kuca_pass" no '/ip pool print terse proplist=name,ranges')
  service_text=$(ros_ssh "$kuca_ip" "$kuca_user" "$kuca_pass" no '/ip service print terse proplist=name,address')
  ipsec_text=$(ros_ssh "$kuca_ip" "$kuca_user" "$kuca_pass" no ':put ("ipsec-secret=" . [/interface l2tp-server server get ipsec-secret])')
  key_text=$(ros_ssh "$kuca_ip" "$kuca_user" "$kuca_pass" no ':foreach i in=[/user ssh-keys find where user=admin] do={ :put [/user ssh-keys get $i key] }')
  server_ipsec=$(printf '%s\n' "$ipsec_text" | tr -d '\r' | sed -n 's/.*ipsec-secret="\{0,1\}\([^" ]*\)"\{0,1\}.*/\1/p' | head -n 1)
  ipsec_state=$(ipsec_result "$server_ipsec" "$cfg_ipsec")
  unset server_ipsec
  [[ $ipsec_state == match ]] || die 'IPsec secret mismatch. The server secret was not changed.'
  keys=()
  while IFS= read -r line; do
    [[ $line == ssh-* ]] && keys+=("$line")
  done <<<"$key_text"
  key_count=${#keys[@]}
  if [[ $apply == yes && $key_count -ne 2 ]]; then
    die "Kuca admin has $key_count SSH keys. The flash stops before any reset because it needs exactly two."
  fi
  ssh_key_1=
  ssh_key_2=
  if [[ ${#keys[@]} -ge 1 ]]; then ssh_key_1=${keys[0]}; fi
  if [[ ${#keys[@]} -ge 2 ]]; then ssh_key_2=${keys[1]}; fi
  taken=
  while IFS= read -r line; do
    [[ $line =~ remote-address=([^[:space:]]+) ]] && taken="$taken ${BASH_REMATCH[1]}"
    [[ $line =~ address=([^[:space:]]+) ]] && taken="$taken ${BASH_REMATCH[1]}"
    [[ $line =~ gateway=([^[:space:]]+) ]] && taken="$taken ${BASH_REMATCH[1]}"
  done <<<"$secret_text"$'\n'"$address_text"$'\n'"$route_text"$'\n'"$active_text"
  existing_remote=
  while IFS= read -r line; do
    [[ $line == *"name=$cfg_l2tp_user"* || $line == *"name=\"$cfg_l2tp_user\""* ]] || continue
    [[ $line =~ remote-address=([^[:space:]]+) ]] && existing_remote=${BASH_REMATCH[1]}
    SNAP_SECRETS+=$'\n'"$cfg_l2tp_user"$'\t'"$existing_remote"
  done <<<"$secret_text"
  pool_name=
  pool_ranges=
  if [[ $profile_text =~ name=\"?mostardesigns.com\ l2tp\"?[[:space:]].*remote-address=([^[:space:]]+) ]]; then
    pool_name=${BASH_REMATCH[1]}
  fi
  if [[ $pool_name =~ ^[0-9.]+$ ]]; then pool_name=; fi
  if [[ -n $pool_name && $pool_text =~ name=\"?${pool_name}\"?[[:space:]].*ranges=([^[:space:]]+) ]]; then
    pool_ranges=${BASH_REMATCH[1]}
  fi
  pool_note=$pool_name
  pick=$(select_vpn_address "$existing_remote" "$taken" "$pool_ranges" "$pool_name")
  if [[ -z $cfg_l2tp_password ]]; then
    cfg_l2tp_password=$(new_l2tp_password)
    write_password=yes
  fi
  while IFS= read -r line; do
    [[ $line =~ comment=([^[:space:]]+).*gateway=([^[:space:]]+) || $line =~ gateway=([^[:space:]]+).*comment=([^[:space:]]+) ]] || continue
    SNAP_ROUTES+=$'\n'"${BASH_REMATCH[1]}"$'\t'"${BASH_REMATCH[2]}"
  done <<<"$route_text"
  while IFS= read -r line; do
    [[ $line =~ list=([^[:space:]]+) ]] || continue
    list_name=${BASH_REMATCH[1]}
    [[ $line =~ address=([^[:space:]]+) ]] || continue
    SNAP_LISTS+=$'\n'"$list_name"$'\t'"${BASH_REMATCH[1]}"
  done <<<"$list_text"
  SNAP_WWW=$(printf '%s\n' "$service_text" | sed -n 's/.*name=www .*address="\{0,1\}\([^" ]*\)"\{0,1\}.*/\1/p' | head -n 1)
  SNAP_API=$(printf '%s\n' "$service_text" | sed -n 's/.*name=api .*address="\{0,1\}\([^" ]*\)"\{0,1\}.*/\1/p' | head -n 1)
  SNAP_API_SSL=$(printf '%s\n' "$service_text" | sed -n 's/.*name=api-ssl .*address="\{0,1\}\([^" ]*\)"\{0,1\}.*/\1/p' | head -n 1)
fi

vpn_address=$(printf '%s\n' "$pick" | sed -n 's/^address=//p')
stopped=$(printf '%s\n' "$pick" | sed -n 's/^stopped=//p')
pool_shown=$(printf '%s\n' "$pick" | sed -n 's/^pool=//p')
[[ $stopped == true ]] && die "No free VPN address outside the L2TP pool. Pool: $pool_shown"
reflash_flag=no
[[ $reflash_live == yes ]] && reflash_flag=yes
plan_uses_live_router "$cfg_name" "$cfg_l2tp_user" "$cfg_lan_cidr" "$vpn_address" "$reflash_flag"

format_plan "$vpn_address" "$ipsec_state" "$key_count" "$pool_note"
stage=$(apply_stage "$apply" "$confirmed" "$confirmed_board" no)
if [[ $stage == dry-run ]]; then
  echo 'Dry-run only. Pass --apply --confirmed to register this router on Kuca.'
  exit 0
fi
if [[ $stage == need-kuca-confirm ]]; then
  echo 'Kuca was not changed. Pass --apply --confirmed after you accept the name, subnet, secret, and VPN address above.'
  exit 2
fi

[[ $offline == no ]] || die 'Kuca was not read, so nothing can be written.'
if [[ $write_password == yes ]]; then
  save_l2tp_password "$config" "$cfg_l2tp_password"
fi
mkdir -p "$out_dir"
journal="$out_dir/kuca-journal-$cfg_slug.json"
changes=$(build_kuca_commands "$vpn_address" "$write_password")
changes_file=$(mktemp)
printf '%s\n' "$changes" >"$changes_file"
python3 - "$journal" "$cfg_slug" "$cfg_l2tp_user" "$cfg_lan_cidr" "$vpn_address" "$changes_file" <<'PY'
import json, sys
journal_path, slug, username, lan, vpn, changes_path = sys.argv[1:7]
entries = []
with open(changes_path, encoding='utf-8') as handle:
    for line in handle:
        line = line.rstrip('\n')
        if not line.startswith('JOURNAL|'):
            continue
        fields = (line.split('|') + [''] * 8)[:8]
        _, op, kind, name, previous, list_name, address, comment = fields
        entries.append({
            'op': op, 'kind': kind, 'name': name, 'previous': previous,
            'list': list_name, 'address': address, 'comment': comment,
        })
with open(journal_path, 'w', encoding='utf-8') as handle:
    json.dump({'slug': slug, 'username': username, 'lanCidr': lan, 'vpnAddress': vpn, 'entries': entries}, handle, indent=2)
    handle.write('\n')
PY
rm -f "$changes_file"
while IFS= read -r command; do
  [[ $command == JOURNAL\|* || -z $command ]] && continue
  ros_ssh "$kuca_ip" "$kuca_user" "$kuca_pass" no "$command" >/dev/null
done <<<"$changes"
echo "Kuca registration is journaled at $journal."
echo 'Cable a LAN port of the new board to this computer, then rerun with --apply --confirmed --confirmed-board.'
[[ $confirmed_board == yes ]] || exit 0

echo 'Looking for an on-link 192.168.88.1. A routed answer can be Mostar and does not count.'
locals=
arps=
if command -v ip >/dev/null; then
  while read -r _addr iface; do
    [[ $_addr == */* ]] || continue
    locals+=$'\n'"${_addr%/*} ${_addr#*/} $iface"
  done < <(ip -4 -o addr show | awk '{print $4, $2}')
  while read -r aip aiface astate; do
    arps+=$'\n'"$aip $aiface $astate"
  done < <(ip -4 neigh show 192.168.88.1 | awk '{print $1, $3, $NF}')
else
  echo 'ip(8) is required to prove the board is on-link.' >&2
  exit 1
fi
iface=$(on_link_factory "$locals" "$arps" || true)
[[ -n $iface ]] || die "192.168.88.1 is not on-link. Cable a LAN port to this computer, or run --rollback after reconnecting to the house. Journal: $journal"

factory_pass=$cfg_factory
board_text=$(ros_ssh 192.168.88.1 admin "$factory_pass" yes '/system resource print terse proplist=version; /system identity print terse proplist=name; /system routerboard print terse proplist=serial-number,model; :do { /interface wireless print terse proplist=name } on-error={}; :do { /interface wifi print terse proplist=name } on-error={}')
board_version=$(printf '%s\n' "$board_text" | sed -n 's/.*version=\([^[:space:]]*\).*/\1/p' | head -n 1)
board_identity=$(printf '%s\n' "$board_text" | sed -n 's/.*name=\([^[:space:]]*\).*/\1/p' | head -n 1)
board_serial=$(printf '%s\n' "$board_text" | sed -n 's/.*serial-number=\([^[:space:]]*\).*/\1/p' | head -n 1)
if reason=$(board_denied "$board_identity" "$board_serial"); then
  die "This board is on the denylist ($reason). It was not reset. Reconnect to the house and run --rollback. Journal: $journal"
fi
if ! version_ok "$board_version"; then
  echo "The board was not reset. Reconnect to the house and run --rollback. Journal: $journal" >&2
  exit 1
fi
echo "board: $board_identity serial=$board_serial version=$board_version"
echo 'Second confirmation accepted. Resetting this board only.'
package=wireless
[[ $board_text == *wifi1* && $board_text != *wlan1* ]] && package=wifi
second=
[[ $package == wireless && $board_text == *wlan2* ]] && second=wlan2
[[ $package == wifi && $board_text == *wifi2* ]] && second=wifi2
rsc=$(emit_rsc "$package" "$second" "$ssh_key_1" "$ssh_key_2")
rsc_path="$out_dir/flash.rsc"
printf '%s\n' "$rsc" >"$rsc_path"
ros_scp 192.168.88.1 admin "$factory_pass" "$rsc_path" flash.rsc
ros_ssh 192.168.88.1 admin "$factory_pass" yes '/system reset-configuration no-defaults=yes skip-backup=yes run-after-reset=flash.rsc' || true

deadline=$((SECONDS + 180))
reached=no
prefix=${cfg_lan_network%.*}
while (( SECONDS < deadline )); do
  if command -v ip >/dev/null && ip -4 addr show | grep -q "$prefix\\."; then
    reached=yes
    break
  fi
  sleep 5
done
[[ $reached == yes ]] || die "The board did not come back on $cfg_lan_cidr within 180 seconds. Reconnect to the house and run --rollback if registration should be removed. Journal: $journal"

check=$(ros_ssh "$cfg_lan_gateway" admin "$cfg_admin" yes '/log print terse proplist=message where message~"roaming-flash"; /file remove [find where name="flash.rsc"]; /system identity print terse proplist=name; /interface l2tp-client print terse proplist=name,disabled,user; /user ssh-keys print count-only where user=admin')
if [[ $check == *'did not appear'* || $check == *'syntax error'* ]]; then
  die "The import logged a script error. flash.rsc was removed if it was still on the board. Journal: $journal"
fi
printf '%s\n' "$check"
echo 'Flash finished. Guest Wi-Fi is joined later with the join-guest script.'
