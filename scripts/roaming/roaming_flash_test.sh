#!/usr/bin/env bash
# Same checks as RoamingFlash.Tests.ps1, for the macOS and Linux shell port.
set -u
failures=0
fail() { echo "FAIL: $1"; failures=$((failures + 1)); }

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=roaming_flash.sh
source "$SCRIPT_DIR/roaming_flash.sh"

field() { printf '%s\n' "$2" | sed -n "s/^$1=//p"; }

plan=$(lan_plan 10.50.0.0 24) || fail 'lan plan'
[[ $(field gateway "$plan") == 10.50.0.1 ]] || fail 'gateway'
[[ $(field pool "$plan") == 10.50.0.2-10.50.0.254 ]] || fail 'pool endpoints'
if lan_plan 192.168.87.0 23 >/dev/null 2>&1; then fail 'unaligned prefix is rejected'; fi

if lan_allowed 192.168.1.0/24 '' $(hotel_blocks) >/dev/null; then fail 'hotel range is rejected'; fi
if lan_allowed 192.168.88.0/24 '' $(hotel_blocks) >/dev/null; then fail 'factory and Mostar range is rejected'; fi
if ! lan_allowed 10.50.0.0/24 '' $(hotel_blocks) >/dev/null; then fail 'unrelated LAN is allowed'; fi
cidrs_overlap 10.50.0.0/23 10.50.1.0/24 || fail 'overlapping prefixes are detected'

inventory=$(inventory_cidrs $'# sample\n| `192.168.89.0/24` | home |')
printf '%s\n' "$inventory" | grep -qx '192.168.89.0/24' || fail 'inventory parser reads networks.md style prefixes'

full=$(select_vpn_address '' '172.16.91.25 172.16.91.30' '172.16.91.2-172.16.91.29' vpn_pool)
[[ $(field stopped "$full") == true ]] || fail 'address picker stops when the pool covers every free host'
[[ $(field pool "$full") == *172.16.91.2-172.16.91.29* ]] || fail 'stopped picker names the pool'
open=$(select_vpn_address '' '172.16.91.25 172.16.91.30' '' '')
[[ $(field address "$open") == 172.16.91.3 ]] || fail 'no remote pool still returns the lowest free host'
reused=$(select_vpn_address 172.16.91.25 '172.16.91.25' '172.16.91.2-172.16.91.29' vpn_pool)
[[ $(field reused "$reused") == true && $(field address "$reused") == 172.16.91.25 ]] || fail 'existing secret keeps its address'

[[ $(resolve_l2tp_password 'stored-secret') == stored-secret ]] || fail 'stored L2TP password is reused'
generated=$(resolve_l2tp_password '')
[[ ${#generated} -ge 16 ]] || fail 'missing password is generated'
[[ $(resolve_l2tp_password "$generated") == "$generated" ]] || fail 'a later resolve returns the same password'

[[ $(ipsec_result same same) == match ]] || fail 'matching ipsec'
[[ $(ipsec_result same other) == mismatch ]] || fail 'different ipsec'
if version_ok '6.49.6' >/dev/null; then fail 'RouterOS 6 is below the floor'; fi
version_ok '6.49.6' 2>&1 | grep -q routeros-smips || fail 'upgrade message names the hAP ac lite package'
version_ok '7.15' || fail '7.15 is the floor'
version_ok '7.15.2' || fail 'newer than the floor is accepted'
if version_ok '7.14.3' >/dev/null; then fail '7.14 is refused'; fi

if plan_uses_live_router Kuca l2tp-roaming-kuca 192.168.86.0/24 172.16.91.25 no >/dev/null 2>&1; then
  fail 'live Kuca-Roaming values are refused'
fi
plan_uses_live_router Kuca l2tp-roaming-kuca 192.168.86.0/24 172.16.91.25 yes || fail 'reflash flag allows those registration values'
board_denied MikroTik 628105BB1449 >/dev/null && true || fail 'live roaming serial is always denied'
if board_denied MikroTik AABBCCDDEEFF >/dev/null; then fail 'an unknown board is not denied'; fi

locals=$'192.168.88.10 24 Ethernet'
arps=$'192.168.88.1 Ethernet Reachable'
on_link_factory "$locals" "$arps" >/dev/null || fail 'on-link ARP is a find'
routed_locals=$'192.168.89.20 24 Ethernet'
if on_link_factory "$routed_locals" "$arps" >/dev/null; then fail 'a routed 192.168.88.1 is not a find'; fi

[[ $(apply_stage no no no no) == dry-run ]] || fail 'default stage is dry-run'
[[ $(apply_stage yes no no no) == need-kuca-confirm ]] || fail 'apply waits for confirmation'
[[ $(apply_stage yes yes no no) == kuca-written-need-board ]] || fail 'kuca confirmation is not a reset'
[[ $(apply_stage yes yes yes no) == need-on-link ]] || fail 'reset waits for an on-link board'
[[ $(apply_stage yes yes yes yes) == reset ]] || fail 'reset is the last stage'

cfg_name=Trip
cfg_wifi=wifi-secret
cfg_local_wifi=
cfg_admin=admin-secret
cfg_factory=
cfg_lan_network=10.50.0.0
cfg_prefix=24
cfg_local_network=172.31.250.0
cfg_local_prefix=24
cfg_country='united states'
cfg_l2tp_server=nyc.mostardesigns.com
cfg_l2tp_user=
cfg_l2tp_password=stored-secret
cfg_ipsec=ipsec-secret
cfg_home=$'192.168.89.0/24\n10.0.10.0/24\n172.16.90.0/24'
cfg_extra=192.168.90.0/24
fill_derived_config
[[ $cfg_l2tp_user == l2tp-roaming-trip ]] || fail 'secret name follows the router name'
cfg_name=Cabin
cfg_lan_network=10.51.0.0
cfg_l2tp_user=
fill_derived_config
cabin_user=$cfg_l2tp_user
cfg_name=Trip
cfg_lan_network=10.50.0.0
cfg_l2tp_user=
cfg_l2tp_password=stored-secret
fill_derived_config
[[ $cfg_l2tp_user != "$cabin_user" ]] || fail 'a second name gets a different secret'
plan_text=$(format_plan 172.16.91.6 match 2 vpn_pool)
[[ $plan_text != *stored-secret* && $plan_text != *admin-secret* && $plan_text != *ipsec-secret* ]] || fail 'plan text omits secrets'

keys1='ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAITestKeyOne fixture-one'
keys2='ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQTestKeyTwo fixture-two'
legacy=$(emit_rsc wireless wlan2 "$keys1" "$keys2")
wifi=$(emit_rsc wifi wifi2 "$keys1" "$keys2")
bridge_at=$(printf '%s\n' "$legacy" | grep -n 'add name=nyc_bridge' | head -n 1 | cut -d: -f1)
port_at=$(printf '%s\n' "$legacy" | grep -n 'add bridge=nyc_bridge interface=ether2' | head -n 1 | cut -d: -f1)
list_at=$(printf '%s\n' "$legacy" | grep -n 'add interface=nyc_bridge list=LAN' | head -n 1 | cut -d: -f1)
address_at=$(printf '%s\n' "$legacy" | grep -n '/ip address' | head -n 1 | cut -d: -f1)
user_at=$(printf '%s\n' "$legacy" | grep -n 'set \[find name=admin\] password=' | head -n 1 | cut -d: -f1)
key_at=$(printf '%s\n' "$legacy" | grep -n '/user ssh-keys' | head -n 1 | cut -d: -f1)
mac_at=$(printf '%s\n' "$legacy" | grep -n '/tool mac-server mac-winbox' | head -n 1 | cut -d: -f1)
[[ -n $bridge_at && $bridge_at -lt $port_at && $port_at -lt $list_at && $list_at -lt $address_at && $address_at -lt $user_at && $user_at -lt $key_at && $key_at -lt $mac_at ]] || fail 'bridge, ports, and LAN list come before the address, password, keys, and MAC Winbox'
printf '%s\n' "$legacy" | grep -q 'name=join-guest' || fail 'legacy file has join-guest'
printf '%s\n' "$legacy" | grep -q 'roaming-local-masquerade' || fail 'local subnet is masqueraded'
printf '%s\n' "$legacy" | grep -q '172.31.250.0/24' || fail 'local subnet is present'
mangle=$(printf '%s\n' "$legacy" | grep 'mark-routing')
[[ $mangle != *172.31.250.0/24* ]] || fail 'local subnet is absent from the via_nyc mark'
printf '%s\n' "$legacy" | grep -qi wireguard && fail 'legacy file has no WireGuard'
printf '%s\n' "$legacy" | grep -q cfg-station && fail 'legacy file has no wifi mode configuration'
printf '%s\n' "$legacy" | grep -q 'default-name=wlan2' || fail 'hAP ac lite second radio is wlan2'
printf '%s\n' "$wifi" | grep -q 'name=roaming-wifi-mode' || fail 'wifi file has the mode switch'
printf '%s\n' "$wifi" | grep -q 'default-name=wifi2' || fail 'wifi second radio uses wifi2'
printf '%s\n' "$legacy" | grep -q '192.168.89.0/24' || fail 'at-home list is in the uplink script'
printf '%s\n' "$legacy" | grep -q 'in 192.168.90.0/24' && fail 'house Wi-Fi is not an at-home prefix'
printf '%s\n' "$legacy" | grep -q '192.168.90.0/24' || fail 'house Wi-Fi is allowed to manage the router'

if append_service_address '' 10.50.0.0/24 >/dev/null 2>&1; then fail 'an empty service address is not replaced'; fi
[[ $(append_service_address '10.0.10.0/24' '10.50.0.0/24') == '10.0.10.0/24,10.50.0.0/24' ]] || fail 'service address is appended'

SNAP_SECRETS=
SNAP_ROUTES=
SNAP_LISTS=
SNAP_WWW=10.0.10.0/24
SNAP_API=10.0.10.0/24
SNAP_API_SSL=10.0.10.0/24
created=$(build_kuca_commands 172.16.91.6 yes)
printf '%s\n' "$created" | grep -q 'stored-secret' || fail 'a new secret is created with the stored password'
SNAP_SECRETS=$'l2tp-roaming-trip\t172.16.91.6'
SNAP_ROUTES=$'roaming:trip\t172.16.91.6'
SNAP_LISTS=$'support\t10.50.0.0/24\nLocal\t10.50.0.0/24'
SNAP_WWW='10.0.10.0/24,10.50.0.0/24'
SNAP_API='10.0.10.0/24,10.50.0.0/24'
SNAP_API_SSL='10.0.10.0/24,10.50.0.0/24'
updated=$(build_kuca_commands 172.16.91.6 no)
printf '%s\n' "$updated" | grep -q 'stored-secret' && fail 'a rerun does not write the L2TP password again'

journal_lines='JOURNAL|set|service||10.0.10.0/24|api-ssl||
JOURNAL|add|route|||||roaming:trip
JOURNAL|add|ppp-secret|l2tp-roaming-trip||||'
rollback=$(rollback_from_journal_lines "$journal_lines")
first=$(printf '%s\n' "$rollback" | head -n 1)
last=$(printf '%s\n' "$rollback" | tail -n 1)
[[ $first == *ppp\ secret\ remove* ]] || fail 'rollback removes the last-added secret first'
[[ $last == *api-ssl* && $last == *10.0.10.0/24* ]] || fail 'rollback restores the previous service address last'
printf '%s\n' "$rollback" | grep -q 'pool set' && fail 'rollback does not touch the shared pool'

example="$SCRIPT_DIR/../../infrastructure/roaming/roaming.example.json"
grep -q '"factoryPassword": ""' "$example" || fail 'example sticker password may be blank'
grep -q '"name": "Kuca"' "$example" || fail 'example name is the live router'

if (( failures > 0 )); then
  echo "$failures shell test(s) failed."
  exit 1
fi
echo 'Roaming flash shell tests passed.'
