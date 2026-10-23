# Travel-router flash helpers for macOS and Linux. Sourced by
# scripts/flash_roaming_mikrotik.sh. No router I/O in this file.
# Bash 3.2 is enough. JSON reads use python3.

roaming_repo_root() {
  cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd
}

die() {
  echo "$*" >&2
  return 1
}

ip_to_int() {
  local ip=$1 a b c d
  [[ $ip =~ ^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$ ]] || die "Not an IPv4 address: $ip" || return
  a=${BASH_REMATCH[1]} b=${BASH_REMATCH[2]} c=${BASH_REMATCH[3]} d=${BASH_REMATCH[4]}
  (( a <= 255 && b <= 255 && c <= 255 && d <= 255 )) || die "Not an IPv4 address: $ip" || return
  echo $(( (a << 24) + (b << 16) + (c << 8) + d ))
}

int_to_ip() {
  local n=$1
  echo "$(( (n >> 24) & 255 )).$(( (n >> 16) & 255 )).$(( (n >> 8) & 255 )).$(( n & 255 ))"
}

ipv4_mask() {
  local prefix=$1
  if (( prefix <= 0 )); then echo 0; return; fi
  if (( prefix >= 32 )); then echo 4294967295; return; fi
  local host_bits=$(( 32 - prefix ))
  echo $(( (4294967295 << host_bits) & 4294967295 ))
}

network_int() {
  local addr=$1 prefix=$2
  local ip mask
  ip=$(ip_to_int "$addr") || return
  mask=$(ipv4_mask "$prefix")
  echo $(( ip & mask ))
}

cidr_parts() {
  local cidr=$1
  [[ $cidr =~ ^([0-9.]+)/([0-9]+)$ ]] || die "Not a CIDR: $cidr" || return
  local prefix=${BASH_REMATCH[2]}
  (( prefix >= 0 && prefix <= 32 )) || die "Prefix out of range: $cidr" || return
  local network
  network=$(network_int "${BASH_REMATCH[1]}" "$prefix") || return
  local size=1
  if (( prefix < 32 )); then size=$(( 1 << (32 - prefix) )); fi
  local broadcast=$(( network + size - 1 ))
  echo "$network $broadcast $prefix"
}

cidrs_overlap() {
  local left right
  left=$(cidr_parts "$1") || return
  right=$(cidr_parts "$2") || return
  local ln lb rn rb
  read -r ln lb _ <<<"$left"
  read -r rn rb _ <<<"$right"
  (( ln <= rb && rn <= lb ))
}

network_cidr() {
  local raw=$1
  [[ $raw =~ ^([0-9.]+)/([0-9]+)$ ]] || return 1
  local network
  network=$(network_int "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}") || return
  echo "$(int_to_ip "$network")/${BASH_REMATCH[2]}"
}

lan_plan() {
  local network=$1 prefix=$2
  (( prefix >= 16 && prefix <= 29 )) || die "Prefix length must be from 16 through 29. Got $prefix." || return
  local aligned
  aligned=$(network_int "$network" "$prefix") || return
  local given
  given=$(ip_to_int "$network") || return
  (( aligned == given )) || die "$network/$prefix is not aligned to that prefix." || return
  local parts
  parts=$(cidr_parts "$network/$prefix") || return
  local net_int broadcast
  read -r net_int broadcast _ <<<"$parts"
  local gateway=$(( net_int + 1 ))
  local pool_start=$(( net_int + 2 ))
  local pool_end=$(( broadcast - 1 ))
  echo "cidr=$(int_to_ip "$net_int")/$prefix"
  echo "network=$(int_to_ip "$net_int")"
  echo "prefix=$prefix"
  echo "gateway=$(int_to_ip "$gateway")"
  echo "address=$(int_to_ip "$gateway")/$prefix"
  echo "pool=$(int_to_ip "$pool_start")-$(int_to_ip "$pool_end")"
}

hotel_blocks() {
  printf '%s\n' 192.168.88.0/24 192.168.0.0/24 192.168.1.0/24 10.0.0.0/24
}

inventory_cidrs() {
  local markdown=$1 seen= cidr line
  while IFS= read -r line; do
    cidr=$(network_cidr "$line" 2>/dev/null || true)
    [[ -n $cidr ]] || continue
    case " $seen " in
      *" $cidr "*) ;;
      *) seen="$seen $cidr"; echo "$cidr" ;;
    esac
  done < <(printf '%s\n' "$markdown" | grep -oE '[0-9]{1,3}(\.[0-9]{1,3}){3}/[0-9]{1,2}' || true)
}

lan_allowed() {
  local lan=$1 other=$2 block
  shift 2
  for block in "$@"; do
    [[ -n $block ]] || continue
    if cidrs_overlap "$lan" "$block"; then
      echo "overlaps $block"
      return 1
    fi
  done
  if [[ -n $other ]] && cidrs_overlap "$lan" "$other"; then
    echo "overlaps $other"
    return 1
  fi
  return 0
}

roaming_slug() {
  local name=$1
  local slug
  slug=$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')
  [[ -n $slug ]] || die "Name '$name' has no letters or digits." || return
  echo "$slug"
}

plan_uses_live_router() {
  local name=$1 username=$2 lan=$3 vpn=$4 reflash=$5
  local identity="${name}-Roaming"
  local hits=
  case " $identity " in
    *" Kuca-Roaming "*|*" Kuca-Mostar "*|*" Kuca "*) ;;
  esac
  [[ $identity == Kuca-Roaming || $identity == Kuca || $identity == Kuca-Mostar ]] && hits="${hits}identity $identity, "
  [[ $username == l2tp-roaming-kuca ]] && hits="${hits}username $username, "
  if cidrs_overlap "$lan" 192.168.86.0/24; then hits="${hits}LAN $lan overlaps 192.168.86.0/24, "; fi
  [[ $vpn == 172.16.91.25 ]] && hits="${hits}VPN address $vpn, "
  if [[ -z $hits ]]; then return 0; fi
  [[ $reflash == yes ]] && return 0
  hits=${hits%, }
  die "Refusing live-router values ($hits). Pass --reflash-live only when you mean that router." || return
}

board_denied() {
  local identity=$1 serial=$2
  local hits=
  [[ $identity == Kuca || $identity == Kuca-Mostar || $identity == Kuca-Roaming ]] && hits="identity $identity"
  [[ $serial == 628105BB1449 ]] && hits="${hits:+$hits, }serial $serial"
  if [[ -n $hits ]]; then
    echo "$hits"
    return 0
  fi
  return 1
}

vpn_octet() {
  local address=${1%%/*}
  [[ $address =~ ^172\.16\.91\.([0-9]+)$ ]] || return 1
  echo "${BASH_REMATCH[1]}"
}

address_in_ranges() {
  local address=$1 ranges=$2 start end piece
  [[ -n $ranges ]] || return 1
  local IFS=','
  for piece in $ranges; do
    piece=${piece// /}
    [[ $piece =~ ^([0-9.]+)-([0-9.]+)$ ]] || continue
    start=$(ip_to_int "${BASH_REMATCH[1]}") || return
    end=$(ip_to_int "${BASH_REMATCH[2]}") || return
    if (( address >= start && address <= end )); then return 0; fi
  done
  return 1
}

select_vpn_address() {
  local existing=$1 taken=$2 ranges=$3 pool_name=$4
  local octet candidate
  if octet=$(vpn_octet "$existing"); then
    echo "address=172.16.91.$octet"
    echo "reused=true"
    echo "stopped=false"
    echo "pool="
    return 0
  fi
  if [[ -n $pool_name && -z $ranges ]]; then
    echo "address="
    echo "reused=false"
    echo "stopped=true"
    echo "pool=pool $pool_name was not readable"
    return 0
  fi
  local taken_octets=" 0 1 2 29 30 31 "
  local item
  for item in $taken; do
    if octet=$(vpn_octet "$item"); then taken_octets="$taken_octets$octet "; fi
  done
  for octet in 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28; do
    case " $taken_octets " in
      *" $octet "*) continue ;;
    esac
    candidate=$(ip_to_int "172.16.91.$octet") || return
    if address_in_ranges "$candidate" "$ranges"; then continue; fi
    echo "address=172.16.91.$octet"
    echo "reused=false"
    echo "stopped=false"
    echo "pool=$ranges"
    return 0
  done
  local pool_text=$ranges
  [[ -n $pool_text ]] || pool_text='(no remote pool)'
  echo "address="
  echo "reused=false"
  echo "stopped=true"
  echo "pool=$pool_text"
}

new_l2tp_password() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -base64 48 | tr -cd 'A-Za-z0-9' | cut -c1-24
    return
  fi
  python3 -c 'import secrets,string; alphabet=string.ascii_letters+string.digits; print("".join(secrets.choice(alphabet) for _ in range(24)))'
}

resolve_l2tp_password() {
  if [[ -n ${1:-} ]]; then
    printf '%s\n' "$1"
    return
  fi
  new_l2tp_password
}

ipsec_result() {
  local server=$1 config=$2
  if [[ -z $server || -z $config ]]; then echo mismatch; return; fi
  if [[ $server == "$config" ]]; then echo match; else echo mismatch; fi
}

upgrade_message() {
  local running=$1
  cat <<EOF
This board is running RouterOS $running. The flash needs RouterOS 7.15 or newer because the generated file uses /user ssh-keys add and the RouterOS 7 wireless syntax. The floor is provisional until a bench run confirms those commands.
Do not expect this script to upgrade the board. Download the routeros package for its architecture (hAP ac lite is routeros-smips) from mikrotik.com, copy it to Files in Winbox, reboot, then run the flash again. Most boxed hAP ac lite boards ship on RouterOS 6, so the first attempt often stops here.
EOF
}

version_ok() {
  local text=$1 major minor patch
  if [[ ! $text =~ ([0-9]+)\.([0-9]+)(\.([0-9]+))? ]]; then
    upgrade_message "$text"
    return 1
  fi
  major=${BASH_REMATCH[1]} minor=${BASH_REMATCH[2]} patch=${BASH_REMATCH[4]:-0}
  if (( major > 7 || (major == 7 && minor > 15) || (major == 7 && minor == 15 && patch >= 0) )); then
    return 0
  fi
  upgrade_message "$text"
  return 1
}

on_link_factory() {
  local locals=$1 arps=$2
  local lip lprefix liface aip aiface astate
  while read -r lip lprefix liface; do
    [[ -n $lip ]] || continue
    local cid
    cidr=$(network_cidr "$lip/$lprefix" 2>/dev/null || true)
    [[ $cidr == 192.168.88.0/24 ]] || continue
    while read -r aip aiface astate; do
      [[ $aip == 192.168.88.1 && $aiface == "$liface" ]] || continue
      case $astate in
        Reachable|Stale|Permanent) echo "$liface"; return 0 ;;
      esac
    done <<<"$arps"
  done <<<"$locals"
  return 1
}

apply_stage() {
  local apply=$1 confirmed=$2 board=$3 onlink=$4
  [[ $apply == yes ]] || { echo dry-run; return; }
  [[ $confirmed == yes ]] || { echo need-kuca-confirm; return; }
  [[ $board == yes ]] || { echo kuca-written-need-board; return; }
  [[ $onlink == yes ]] || { echo need-on-link; return; }
  echo reset
}

ros_quote() {
  local value=${1-}
  value=${value//\\/\\\\}
  value=${value//\"/\\\"}
  value=${value//\$/\\$}
  printf '"%s"' "$value"
}

append_service_address() {
  local previous=$1 cidr=$2 part found=no
  local IFS=','
  local parts=()
  if [[ -n $previous ]]; then
    for part in $previous; do
      part=${part// /}
      [[ -n $part ]] || continue
      parts+=("$part")
      [[ $part == "$cidr" ]] && found=yes
    done
  fi
  if [[ $found == yes ]]; then
    local IFS=,
    echo "${parts[*]}"
    return
  fi
  (( ${#parts[@]} > 0 )) || die "Refusing to replace an empty service address with only $cidr." || return
  parts+=("$cidr")
  local IFS=,
  echo "${parts[*]}"
}

format_plan() {
  cat <<EOF
identity: $cfg_identity
vpn-lan: $cfg_lan_cid
local-lan: $cfg_local_cid
ppp-secret: $cfg_l2tp_use
vpn-address: $1
ipsec: $2
admin-keys: $3
pool: $4
EOF
}

fill_derived_config() {
  [[ $cfg_name =~ ^[A-Za-z0-9][A-Za-z0-9-]{0,30}$ ]] || die "Name '$cfg_name' must start with a letter or digit and use only letters, digits, and hyphens." || return
  cfg_slug=$(roaming_slug "$cfg_name") || return
  cfg_identity="${cfg_name}-Roaming"
  cfg_nyc_ssid="${cfg_name}-Roaming-NYC"
  cfg_local_ssid="${cfg_name}-Roaming"
  cfg_radio_ssid="${cfg_slug}-radio"
  [[ -n $cfg_l2tp_user ]] || cfg_l2tp_user="l2tp-roaming-$cfg_slug"
  [[ -n $cfg_local_wifi ]] || cfg_local_wifi=$cfg_wifi
  [[ -n $cfg_country ]] || cfg_country='united states'
  [[ -n $cfg_prefix ]] || cfg_prefix=24
  [[ -n $cfg_local_prefix ]] || cfg_local_prefix=24
  [[ -n $cfg_local_network ]] || cfg_local_network=172.31.250.0
  [[ -n $cfg_l2tp_server ]] || cfg_l2tp_server=nyc.mostardesigns.com
  local plan
  plan=$(lan_plan "$cfg_lan_network" "$cfg_prefix") || return
  cfg_lan_cidr=$(printf '%s\n' "$plan" | sed -n 's/^cidr=//p')
  cfg_lan_network_aligned=$(printf '%s\n' "$plan" | sed -n 's/^network=//p')
  cfg_lan_gateway=$(printf '%s\n' "$plan" | sed -n 's/^gateway=//p')
  cfg_lan_address=$(printf '%s\n' "$plan" | sed -n 's/^address=//p')
  cfg_lan_pool=$(printf '%s\n' "$plan" | sed -n 's/^pool=//p')
  plan=$(lan_plan "$cfg_local_network" "$cfg_local_prefix") || return
  cfg_local_cidr=$(printf '%s\n' "$plan" | sed -n 's/^cidr=//p')
  cfg_local_network_aligned=$(printf '%s\n' "$plan" | sed -n 's/^network=//p')
  cfg_local_gateway=$(printf '%s\n' "$plan" | sed -n 's/^gateway=//p')
  cfg_local_address=$(printf '%s\n' "$plan" | sed -n 's/^address=//p')
  cfg_local_pool=$(printf '%s\n' "$plan" | sed -n 's/^pool=//p')
}

load_config_json() {
  local path=$1 require=$2
  python3 - "$path" "$require" <<'PY'
import json, sys
path, require = sys.argv[1], sys.argv[2] == 'yes'
with open(path, encoding='utf-8') as handle:
    raw = json.load(handle)
def get(obj, key, default=''):
    value = obj.get(key, default) if isinstance(obj, dict) else default
    return '' if value is None else value
l2tp = raw.get('l2tp') or {}
home = raw.get('homeNetworks') or ['192.168.89.0/24', '10.0.10.0/24', '172.16.90.0/24']
extra = raw.get('managementExtra') or ['192.168.90.0/24']
def sh(value):
    text = '' if value is None else str(value)
    return "'" + text.replace("'", "'\\''") + "'"
fields = {
    'cfg_name': get(raw, 'name'),
    'cfg_wifi': get(raw, 'wifiPassword'),
    'cfg_local_wifi': get(raw, 'localWifiPassword'),
    'cfg_admin': get(raw, 'adminPassword'),
    'cfg_factory': get(raw, 'factoryPassword'),
    'cfg_lan_network': get(raw, 'lanNetwork'),
    'cfg_prefix': get(raw, 'prefixLength', 24),
    'cfg_local_network': get(raw, 'localNetwork', '172.31.250.0'),
    'cfg_local_prefix': get(raw, 'localPrefixLength', 24),
    'cfg_country': get(raw, 'country', 'united states'),
    'cfg_l2tp_server': get(l2tp, 'server', 'nyc.mostardesigns.com'),
    'cfg_l2tp_user': get(l2tp, 'username'),
    'cfg_l2tp_password': get(l2tp, 'password'),
    'cfg_ipsec': get(l2tp, 'ipsecSecret'),
    'cfg_home': '\n'.join(str(item) for item in home),
    'cfg_extra': '\n'.join(str(item) for item in extra),
}
if require and (not fields['cfg_wifi'] or not fields['cfg_admin'] or not fields['cfg_ipsec']):
    sys.exit(2)
for key, value in fields.items():
    print(f"{key}={sh(value)}")
PY
}

save_l2tp_password() {
  local path=$1 password=$2
  python3 - "$path" "$password" <<'PY'
import json, sys
path, password = sys.argv[1], sys.argv[2]
with open(path, encoding='utf-8') as handle:
    raw = json.load(handle)
raw.setdefault('l2tp', {})
if not raw['l2tp'].get('password'):
    raw['l2tp']['password'] = password
with open(path, 'w', encoding='utf-8') as handle:
    json.dump(raw, handle, indent=2)
    handle.write('\n')
PY
}

service_list() {
  local seen= cid
  while IFS= read -r cidr; do
    [[ -n $cidr ]] || continue
    case " $seen " in
      *" $cidr "*) ;;
      *) seen="$seen $cidr"; printf '%s,' "$cidr" ;;
    esac
  done <<EOF
$cfg_home
$cfg_extra
$cfg_lan_cid
$cfg_local_cid
172.16.91.0/27
EOF
  printf '\n'
}

isp_home_tests() {
  local cid
  while IFS= read -r cidr; do
    [[ -n $cidr ]] || continue
    echo "  :if (\$ip in $cidr) do={ :set atHome true }"
  done <<EOF
$cfg_home
EOF
}

emit_rsc() {
  local package=$1 second=$2 key1=$3 key2=$4
  [[ -n $key1 && -n $key2 ]] || die 'Exactly two admin SSH keys are required.' || return
  if [[ $package == wifi && $second == wlan2 ]]; then second=wifi2; fi
  local services
  services=$(service_list)
  services=${services%,}
  {
    echo '/interface bridge'
    echo 'add name=nyc_bridge comment=roaming-vpn-lan protocol-mode=none'
    echo 'add name="roaming lan bridge" comment=roaming-local-lan protocol-mode=none'
    echo '/interface ethernet'
    echo 'set [find default-name=ether1] name="ether1 - wan" comment=roaming-wan'
    echo '/interface bridge port'
    local port
    for port in ether2 ether3 ether4 ether5; do
      echo "add bridge=nyc_bridge interface=$port"
    done
    echo '/interface list'
    echo 'add name=LAN'
    echo 'add name=WAN'
    echo '/interface list member'
    echo 'add interface=nyc_bridge list=LAN'
    echo 'add interface="roaming lan bridge" list=LAN'
    echo 'add interface="ether1 - wan" list=WAN'
    echo '/ip address'
    echo "add address=$cfg_lan_address interface=nyc_bridge network=$cfg_lan_network_aligned comment=roaming-vpn-lan"
    echo "add address=$cfg_local_address interface=\"roaming lan bridge\" network=$cfg_local_network_aligned comment=roaming-local-lan"
    echo '/user'
    echo "set [find name=admin] password=$(ros_quote "$cfg_admin")"
    echo '/user ssh-keys'
    echo "add user=admin key=$(ros_quote "$key1")"
    echo "add user=admin key=$(ros_quote "$key2")"
    echo '/tool mac-server'
    echo 'set allowed-interface-list=LAN'
    echo '/tool mac-server mac-winbox'
    echo 'set allowed-interface-list=LAN'
    echo '/system identity'
    echo "set name=$(ros_quote "$cfg_identity")"
    local wait_type=wireless
    [[ $package == wifi ]] && wait_type=wifi
    cat <<EOF
:delay 1s
:local radioWait 0
:local radiosReady false
:while (\$radioWait < 60) do={
  :do {
    :if ([:len [/interface $wait_type find]] > 0) do={ :set radiosReady true }
  } on-error={}
  :if (\$radiosReady) do={ :set radioWait 60 } else={ :delay 2s; :set radioWait (\$radioWait + 1) }
}
:if (\$radiosReady = false) do={ :log error "roaming-flash: radio interfaces did not appear" }
EOF
    echo '/ip pool'
    echo "add name=roaming-vpn-pool ranges=$cfg_lan_pool"
    echo "add name=roaming-local-pool ranges=$cfg_local_pool"
    echo '/ip dhcp-server'
    echo 'add name=roaming-vpn interface=nyc_bridge address-pool=roaming-vpn-pool lease-time=1d'
    echo 'add name=roaming-local interface="roaming lan bridge" address-pool=roaming-local-pool lease-time=10m'
    echo '/ip dhcp-server network'
    echo "add address=$cfg_lan_cidr gateway=$cfg_lan_gateway dns-server=$cfg_lan_gateway comment=roaming-vpn"
    echo "add address=$cfg_local_cidr gateway=$cfg_local_gateway dns-server=8.8.8.8 comment=roaming-local"
    echo '/ip dns'
    echo 'set allow-remote-requests=yes servers=10.0.10.10,8.8.8.8'
    echo '/ip firewall address-list'
    local cid
    while IFS= read -r cidr; do
      [[ -n $cidr ]] || continue
      echo "add list=roaming-home-lan address=$cidr comment=roaming-home"
    done <<EOF
$cfg_home
EOF
    local IFS=,
    for cidr in $services; do
      echo "add list=roaming-mgmt address=$cidr comment=roaming-mgmt"
    done
    unset IFS
    cat <<EOF
/routing table
add name=via_nyc fib
/ip route
add dst-address=0.0.0.0/0 gateway=172.16.91.1 routing-table=via_nyc comment=roaming-via-nyc
/interface l2tp-client
add name=mikrotik-kuca-l2tp connect-to=$(ros_quote "$cfg_l2tp_server") user=$(ros_quote "$cfg_l2tp_user") password=$(ros_quote "$cfg_l2tp_password") ipsec-secret=$(ros_quote "$cfg_ipsec") use-ipsec=yes add-default-route=yes default-route-distance=1 use-peer-dns=no disabled=yes profile=default-encryption comment=roaming-l2tp
/ip firewall mangle
add chain=prerouting action=mark-routing new-routing-mark=via_nyc passthrough=no in-interface=nyc_bridge comment=roaming-via-nyc disabled=yes
/ip firewall nat
add chain=srcnat action=masquerade src-address=$cfg_lan_cidr out-interface="ether1 - wan" comment=roaming-home-masquerade
add chain=srcnat action=masquerade src-address=$cfg_local_cidr out-interface="ether1 - wan" comment=roaming-local-masquerade
/ip firewall filte
add chain=input action=accept connection-state=established,related,untracked comment=roaming-established
add chain=input action=accept protocol=icmp comment=roaming-icmp
add chain=input action=accept src-address-list=roaming-mgmt dst-port=22,80,8291,8728,8729 protocol=tcp comment=roaming-mgmt
add chain=input action=accept in-interface=all-ppp comment=roaming-from-vpn
add chain=input action=accept in-interface=nyc_bridge comment=roaming-from-vpn-lan
add chain=input action=accept in-interface="roaming lan bridge" comment=roaming-from-local-lan
add chain=input action=drop in-interface-list=WAN comment=roaming-drop-wan
/ip service
set ssh address=$(ros_quote "$services")
set www address=$(ros_quote "$services")
set winbox address=$(ros_quote "$services")
set api address=$(ros_quote "$services")
set api-ssl address=$(ros_quote "$services")
set ftp disabled=yes
set telnet disabled=yes
EOF
    if [[ $package == wireless ]]; then
      cat <<EOF
/interface wireless security-profiles
set [find default=yes] supplicant-identity=MikroTik
add name=ap-sp mode=dynamic-keys authentication-types=wpa2-psk wpa2-pre-shared-key=$(ros_quote "$cfg_wifi")
add name=local-sp mode=dynamic-keys authentication-types=wpa2-psk wpa2-pre-shared-key=$(ros_quote "$cfg_local_wifi")
add name=uplink-sp mode=dynamic-keys authentication-types=wpa2-psk wpa2-pre-shared-key=""
add name=guest-open mode=none
/interface wireless
set [find default-name=wlan1] name=wlan_roaming mode=ap-bridge ssid=$(ros_quote "$cfg_radio_ssid") security-profile=ap-sp country=$(ros_quote "$cfg_country") frequency=auto channel-width=20mhz band=2ghz-b/g/n hide-ssid=yes disabled=no
add master-interface=wlan_roaming name=wlan_nyc ssid=$(ros_quote "$cfg_nyc_ssid") security-profile=ap-sp disabled=no
add master-interface=wlan_roaming name=wlan_kuca ssid=$(ros_quote "$cfg_local_ssid") security-profile=local-sp disabled=no
add master-interface=wlan_roaming name=wlan_uplink mode=station ssid="" security-profile=uplink-sp disabled=no
EOF
      if [[ -n $second ]]; then
        cat <<EOF
set [find default-name=$second] name=wlan_nyc_5 mode=ap-bridge ssid=$(ros_quote "$cfg_nyc_ssid") security-profile=ap-sp country=$(ros_quote "$cfg_country") frequency=auto disabled=no
add master-interface=wlan_nyc_5 name=wlan_kuca_5 ssid=$(ros_quote "$cfg_local_ssid") security-profile=local-sp disabled=no
EOF
      fi
      echo '/interface bridge port'
      echo 'add bridge=nyc_bridge interface=wlan_nyc'
      echo 'add bridge="roaming lan bridge" interface=wlan_kuca'
      if [[ -n $second ]]; then
        echo 'add bridge=nyc_bridge interface=wlan_nyc_5'
        echo 'add bridge="roaming lan bridge" interface=wlan_kuca_5'
      fi
    else
      cat <<EOF
/interface wifi security
add name=sec-ap authentication-types=wpa2-psk passphrase=$(ros_quote "$cfg_wifi")
add name=sec-local authentication-types=wpa2-psk passphrase=$(ros_quote "$cfg_local_wifi")
add name=sec-uplink authentication-types=wpa2-psk passphrase=""
add name=sec-open
/interface wifi configuration
add name=cfg-ap-hidden mode=ap ssid=$(ros_quote "$cfg_radio_ssid") country=$(ros_quote "$cfg_country") hide-ssid=yes security=sec-ap
add name=cfg-nyc mode=ap ssid=$(ros_quote "$cfg_nyc_ssid") country=$(ros_quote "$cfg_country") security=sec-ap
add name=cfg-local mode=ap ssid=$(ros_quote "$cfg_local_ssid") country=$(ros_quote "$cfg_country") security=sec-local
add name=cfg-station mode=station ssid="" country=$(ros_quote "$cfg_country") security=sec-uplink
/interface wifi
set [find default-name=wifi1] name=wlan_uplink configuration=cfg-ap-hidden disabled=no
add name=wifi-nyc master-interface=wlan_uplink configuration=cfg-nyc disabled=no
add name=wifi-local master-interface=wlan_uplink configuration=cfg-local disabled=no
EOF
      if [[ -n $second ]]; then
        cat <<EOF
set [find default-name=$second] name=wifi-5 configuration=cfg-nyc disabled=no
add name=wifi-local-5 master-interface=wifi-5 configuration=cfg-local disabled=no
EOF
      fi
      echo '/interface bridge port'
      echo 'add bridge=nyc_bridge interface=wifi-nyc'
      echo 'add bridge="roaming lan bridge" interface=wifi-local'
      if [[ -n $second ]]; then
        echo 'add bridge=nyc_bridge interface=wifi-5'
        echo 'add bridge="roaming lan bridge" interface=wifi-local-5'
      fi
    fi
    echo '/system script'
    echo 'add name=roaming-isp-routes policy=read,write,test,policy dont-require-permissions=no source={'
    cat <<'EOF'
:local wan ""
:local addr ""
:local ether [/ip dhcp-client find where interface="ether1 - wan"]
:if ([:len $ether] > 0) do={
  :if ([/ip dhcp-client get $ether status] = "bound") do={
    :if ([/interface get [find name="ether1 - wan"] running]) do={
      :set wan "ether1 - wan"
      :set addr [/ip dhcp-client get $ether address]
    }
  }
}
:if ([:len $wan] = 0) do={
  :local wifi [/ip dhcp-client find where interface="wlan_uplink"]
  :if ([:len $wifi] > 0) do={
    :if ([/ip dhcp-client get $wifi status] = "bound") do={
      :if ([/interface get [find name="wlan_uplink"] running]) do={
        :set wan "wlan_uplink"
        :set addr [/ip dhcp-client get $wifi address]
      }
    }
  }
}
:local atHome false
:if ([:len $addr] > 0) do={
  :local ip [:toip [:pick $addr 0 [:find $addr "/"]]]
EOF
    isp_home_tests
    cat <<'EOF'
}
:if ($atHome) do={
  /interface l2tp-client set [find name="mikrotik-kuca-l2tp"] disabled=yes
  /ip firewall mangle set [find where comment="roaming-via-nyc"] disabled=yes
  /ip firewall nat set [find where comment="roaming-home-masquerade"] out-interface=$wan disabled=no
} else={
  :if ([:len $wan] > 0) do={
    /interface l2tp-client set [find name="mikrotik-kuca-l2tp"] disabled=no
    /ip firewall mangle set [find where comment="roaming-via-nyc"] disabled=no
    /ip firewall nat set [find where comment="roaming-home-masquerade"] disabled=yes
  }
}
:local localOut "ether1 - wan"
:if ([:len [/interface find where name="wlan_uplink"]] > 0) do={
  :if ([/interface get [find name="wlan_uplink"] running]) do={ :set localOut "wlan_uplink" }
}
/ip firewall nat set [find where comment="roaming-local-masquerade"] out-interface=$localOut disabled=no
:local dnsClient [/ip dhcp-client find where interface=$localOut]
:if ([:len $dnsClient] > 0) do={
  :local dns [/ip dhcp-client get $dnsClient dns-server]
  :if ([:len $dns] > 0) do={
    /ip dhcp-server network set [find where comment="roaming-local"] dns-server=$dns
  }
}
EOF
    echo '}'
    echo 'add name=join-guest policy=read,write,test,policy dont-require-permissions=no source={'
    if [[ $package == wireless ]]; then
      cat <<'EOF'
:global JoinSsid
:global JoinPass
:if ([:typeof $JoinSsid] = "nothing") do={ :error "set JoinSsid before running join-guest" }
:if ([:len $JoinSsid] = 0) do={ :error "JoinSsid is empty" }
:if ([:typeof $JoinPass] = "nothing") do={ :set JoinPass "" }
:local profile "uplink-sp"
:if ([:len $JoinPass] = 0) do={
  :set profile "guest-open"
} else={
  /interface wireless security-profiles set [find name="uplink-sp"] wpa2-pre-shared-key=$JoinPass
  :set profile "uplink-sp"
}
/interface wireless connect-list remove [find where comment="current-guest"]
/interface wireless connect-list add interface=wlan_uplink ssid=$JoinSsid security-profile=$profile comment="current-guest"
/interface wireless set [find name="wlan_uplink"] ssid=$JoinSsid security-profile=$profile disabled=no
/system script run roaming-wifi-channel
EOF
    else
      cat <<'EOF'
:global JoinSsid
:global JoinPass
:if ([:typeof $JoinSsid] = "nothing") do={ :error "set JoinSsid before running join-guest" }
:if ([:len $JoinSsid] = 0) do={ :error "JoinSsid is empty" }
:if ([:typeof $JoinPass] = "nothing") do={ :set JoinPass "" }
:if ([:len $JoinPass] = 0) do={
  /interface wifi configuration set cfg-station security=sec-open
} else={
  /interface wifi security set sec-uplink passphrase=$JoinPass
  /interface wifi configuration set cfg-station security=sec-uplink
}
/interface wifi configuration set cfg-station ssid=$JoinSsid
/system script run roaming-wifi-mode
EOF
    fi
    echo '}'
    if [[ $package == wireless ]]; then
      echo 'add name=roaming-wifi-channel policy=read,write,test,policy,sniff dont-require-permissions=no source={'
      cat <<'EOF'
:local uplink [/interface wireless find where name="wlan_uplink"]
:if ([:len $uplink] = 0) do={ :return }
:if ([/interface wireless get $uplink running]) do={ :return }
:local ssid [/interface wireless get $uplink ssid]
:if ([:len $ssid] = 0) do={ :return }
:local freq ""
:do {
  :foreach row in=[/interface wireless scan wlan_roaming duration=5] do={
    :if (($row->"ssid") = $ssid) do={
      :if ([:len $freq] = 0) do={
        :local raw ($row->"channel")
        :local slash [:find $raw "/"]
        :if ($slash >= 0) do={ :set freq [:pick $raw 0 $slash] } else={ :set freq $raw }
      }
    }
  }
} on-error={ :log warning "roaming-wifi-channel: scan failed" }
:if ([:len $freq] > 0) do={
  /interface wireless set [find name="wlan_roaming"] scan-list=$freq frequency=auto
  :log info ("roaming-wifi-channel: scan-list=" . $freq)
}
EOF
      echo '}'
    else
      echo 'add name=roaming-wifi-mode policy=read,write,test,policy dont-require-permissions=no source={'
      cat <<'EOF'
:local etherUp false
:local client [/ip dhcp-client find where interface="ether1 - wan"]
:if ([:len $client] > 0) do={
  :if ([/ip dhcp-client get $client status] = "bound") do={
    :if ([/interface get [find name="ether1 - wan"] running]) do={ :set etherUp true }
  }
}
:local ssid ""
:do { :set ssid [/interface wifi configuration get cfg-station ssid] } on-error={}
:if ($etherUp || [:len $ssid] = 0) do={
  /interface wifi set [find name="wlan_uplink"] configuration=cfg-ap-hidden
  :log info "roaming-wifi-mode: AP master"
} else={
  /interface wifi set [find name="wlan_uplink"] configuration=cfg-station
  :log info "roaming-wifi-mode: station master"
}
EOF
      echo '}'
    fi
    echo '/system scheduler'
    echo 'add name=roaming-isp-routes interval=1m on-event=roaming-isp-routes policy=read,write,test,policy start-time=startup'
    if [[ $package == wireless ]]; then
      echo 'add name=roaming-wifi-channel interval=1m on-event=roaming-wifi-channel policy=read,write,test,policy,sniff start-time=startup'
    else
      echo 'add name=roaming-wifi-mode interval=1m on-event=roaming-wifi-mode policy=read,write,test,policy start-time=startup'
    fi
    cat <<'EOF'
/ip dhcp-client
add interface="ether1 - wan" add-default-route=yes default-route-distance=2 check-gateway=ping use-peer-dns=no use-peer-ntp=no script=roaming-isp-routes comment=roaming-wan
add interface=wlan_uplink add-default-route=yes default-route-distance=3 check-gateway=ping use-peer-dns=no use-peer-ntp=no script=roaming-isp-routes comment=roaming-wifi-wan
/system script
add name=roaming-delete-flash policy=read,write,policy dont-require-permissions=no source={
  :do { /file remove [find where name="flash.rsc"] } on-error={}
}
/system schedule
add name=roaming-delete-flash on-event=roaming-delete-flash policy=read,write,policy start-time=startup
EOF
  }
}

# Snapshot lines:
# SNAP_SECRETS: name<TAB>remote
# SNAP_ROUTES: comment<TAB>gateway
# SNAP_LISTS: list<TAB>address
build_kuca_commands() {
  local vpn=$1 write_password=$2
  local comment="roaming:$cfg_slug"
  local quoted_name quoted_comment
  quoted_name=$(ros_quote "$cfg_l2tp_user")
  quoted_comment=$(ros_quote "$comment $cfg_identity $cfg_lan_cidr")
  local existing_remote=
  local name remote
  while IFS=$'\t' read -r name remote; do
    [[ $name == "$cfg_l2tp_user" ]] && existing_remote=$remote
  done <<<"$SNAP_SECRETS"
  if [[ -n $existing_remote ]]; then
    echo "/ppp secret set [find where name=$quoted_name] remote-address=$vpn comment=$quoted_comment"
    echo "JOURNAL|set|ppp-secret|$cfg_l2tp_user|$existing_remote|||"
  else
    local pass_arg=
    if [[ $write_password == yes ]]; then pass_arg=" password=$(ros_quote "$cfg_l2tp_password")"; fi
    echo "/ppp secret add name=$quoted_name profile=$(ros_quote 'mostardesigns.com l2tp') service=l2tp remote-address=$vpn$pass_arg comment=$quoted_comment"
    echo "JOURNAL|add|ppp-secret|$cfg_l2tp_user||||"
  fi
  local route_gateway=
  local rcomment rgateway
  while IFS=$'\t' read -r rcomment rgateway; do
    [[ $rcomment == "$comment" ]] && route_gateway=$rgateway
  done <<<"$SNAP_ROUTES"
  if [[ -n $route_gateway ]]; then
    echo "/ip route set [find where comment=$(ros_quote "$comment")] gateway=$vpn"
    echo "JOURNAL|set|route||$route_gateway|||$comment"
  else
    echo "/ip route add dst-address=$cfg_lan_cidr gateway=$vpn comment=$(ros_quote "$comment")"
    echo "JOURNAL|add|route|||||$comment"
  fi
  local list_name have list address
  for list_name in support Local; do
    have=no
    while IFS=$'\t' read -r list address; do
      [[ $list == "$list_name" && $address == "$cfg_lan_cidr" ]] && have=yes
    done <<<"$SNAP_LISTS"
    if [[ $have == no ]]; then
      echo "/ip firewall address-list add list=$list_name address=$cfg_lan_cidr comment=$(ros_quote "$comment")"
      echo "JOURNAL|add|address-list|||$list_name|$cfg_lan_cidr|$comment"
    fi
  done
  local service previous appended
  for service in www api api-ssl; do
    case $service in
      www) previous=$SNAP_WWW ;;
      api) previous=$SNAP_API ;;
      api-ssl) previous=$SNAP_API_SSL ;;
    esac
    appended=$(append_service_address "$previous" "$cfg_lan_cidr") || return
    echo "/ip service set $service address=$(ros_quote "$appended")"
    echo "JOURNAL|set|service||$previous|$service||"
  done
}

rollback_from_journal_lines() {
  local lines=$1
  local reversed=()
  local line
  while IFS= read -r line; do
    [[ $line == JOURNAL\|* ]] || continue
    reversed+=("$line")
  done <<<"$lines"
  local i op kind name previous list address comment
  for (( i=${#reversed[@]}-1; i>=0; i-- )); do
    IFS='|' read -r _ op kind name previous list address comment <<<"${reversed[$i]}"
    case $kind in
      service) echo "/ip service set $list address=$(ros_quote "$previous")" ;;
      address-list) echo "/ip firewall address-list remove [find where list=$(ros_quote "$list") and address=$address and comment=$(ros_quote "$comment")]" ;;
      route)
        if [[ $op == set ]]; then
          echo "/ip route set [find where comment=$(ros_quote "$comment")] gateway=$previous"
        else
          echo "/ip route remove [find where comment=$(ros_quote "$comment")]"
        fi
        ;;
      ppp-secret)
        if [[ $op == set ]]; then
          echo "/ppp secret set [find where name=$(ros_quote "$name")] remote-address=$previous"
        else
          echo "/ppp secret remove [find where name=$(ros_quote "$name")]"
        fi
        ;;
    esac
  done
}
