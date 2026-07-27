# MikroTik RouterOS — NYC / Home (`Kuca`)

**Device model:** RB962UiGS-5HacT2HnT (hAP ac)  
**Identity:** `Kuca`  
**Software:** RouterOS 7.23.2 (export dated 2026-07-27)  
**Serial / software id:** redacted  
**Sanitized export:** [`mikrotik_home_config.rsc`](mikrotik_home_config.rsc)

This is the primary NYC gateway. Mostar (`Kuca-Mostar`) connects back here over L2TP (primary) and optional WireGuard / OpenVPN.

---

## Role

| Role | Detail |
| --- | --- |
| WAN | `ether1 - WAN` via DHCP (`/ip dhcp-client`) |
| Perimeter | Bridge `perimiter` — mgmt / servers / switches (`10.0.10.0/24`) |
| House LAN | Bridge `home_lan` — trusted wired (`192.168.89.0/24`) |
| Home Wi‑Fi VLAN | `home_wifi_vlan` (VLAN 2) — `192.168.90.0/24` |
| IoT VLAN | `iot_vlan` (VLAN 4) — `172.16.90.0/24` |
| VPN pool | `172.16.91.0/27` (L2TP / OVPN / WG peer addressing) |
| Torrent breakout VLAN | `172.16.55.0/29` on perimeter; marked `torrent_over_mostar` toward Mostar |

---

## Bridge & interfaces

```routeros
/interface bridge
add admin-mac=<REDACTED_MAC> auto-mac=no comment=defconf name=Lan
add name=home_lan
add name=perimiter

/interface ethernet
set [ find default-name=ether1 ] comment=WAN name="ether1 - WAN"
set [ find default-name=ether2 ] comment=10.0.10.1
set [ find default-name=ether3 ] comment="MSNSwitch - 10.0.10.254"
set [ find default-name=ether4 ] comment="proxmox - direct 10.0.10.11"
set [ find default-name=ether5 ] arp=local-proxy-arp comment=192.168.89.1

/interface vlan
add arp=proxy-arp interface=home_lan name=home_wifi_vlan vlan-id=2
add arp=proxy-arp interface=home_lan name=iot_vlan vlan-id=4
```

**Bridge membership (summary):**

- `perimiter`: ether2, ether3, ether4  
- `home_lan`: ether5, wlan3 (5 GHz maint SSID)  
- Wireless SSIDs include `Kuca 2g`, hidden `router_maintinence`, plus virtual APs

---

## Addressing

```routeros
/ip address
add address=192.168.89.1/24 interface=home_lan network=192.168.89.0
add address=10.0.10.1/24 interface=perimiter network=10.0.10.0
add address=172.16.90.1/24 interface=iot_vlan network=172.16.90.0
add address=192.168.90.1/24 interface=home_wifi_vlan network=192.168.90.0
add address=172.16.91.1/27 interface=Lan network=172.16.91.0
add address=172.16.55.1/29 comment=torrent-vlan-network interface=perimiter network=172.16.55.0
add address=172.16.91.1/30 interface=wg-mostar network=172.16.91.0
```

WAN uses DHCP on `ether1 - WAN` (no static public IP in export).

---

## Mostar / remote site VPN

Mostar is expected at:

| Path | Status in export | Notes |
| --- | --- | --- |
| **L2TP/IPsec server** | Enabled | Profile `mostardesigns.com l2tp`; remote peer address `172.16.91.30` |
| **OpenVPN server** | Enabled | TCP/UDP 1194; client profile remote `172.16.91.29` |
| **WireGuard `wg-mostar`** | Interface present, **disabled** | Listen `51820`; peer allowed `172.16.91.2/32` + Mostar LAN `192.168.88.0/24` + ISP side `192.168.100.0/24` |

Routes toward Mostar LAN / ISP CPE LAN:

```routeros
/ip route
add dst-address=192.168.88.0/24 gateway=172.16.91.30
add dst-address=192.168.100.0/24 gateway=172.16.91.30
```

Torrent traffic from `172.16.55.2` is policy-routed over the Mostar tunnel:

```routeros
/routing table
add fib name=torrent_over_mostar

/ip firewall mangle
add action=mark-routing chain=prerouting dst-address-list=!Local \
    new-routing-mark=torrent_over_mostar passthrough=no src-address=172.16.55.2

/ip route
add check-gateway=ping dst-address=0.0.0.0/0 gateway=172.16.91.30 \
    routing-table=torrent_over_mostar
```

Gateway is the Mostar L2TP peer (`172.16.91.30`). WireGuard `wg-mostar` / `172.16.91.2` is disabled; do not point this table at it unless WG is re-enabled on both ends.

NAT masquerades Mostar L2TP (`192.168.88.0/24`) and WireGuard (`172.16.91.0/24`) clients out WAN when they break out through NYC.

Related remote-site files:

- [`mikrotik_mostar_config.rsc`](mikrotik_mostar_config.rsc) — sanitized Mostar export  
- [`mikrotik_mostar_public_wan_ip.rsc`](mikrotik_mostar_public_wan_ip.rsc) — ISP public IP → HA `:global PublicIP`

---

## Firewall highlights

- FastTrack + established/related accept  
- Winbox (`8291`) restricted to `support` address-list  
- L2TP/IPsec (`1701/500/4500`), OpenVPN (`1194`), WireGuard (`51820`) accepted on WAN  
- Port-scan / SYN-flood / bogon / spam protections  
- Public HTTP/HTTPS/mail ports DNAT to Traefik host `10.0.10.6`  
- `homeassistant` API user group for the HACS MikroTik integration (API-only policies)

---

## Scripts & schedulers

| Name | Purpose |
| --- | --- |
| `cloudns-update` | Hourly dynamic DNS update (token redacted in export) |
| `EnableDns` / `DisableDns` | Toggle DNS/NTP failover NAT toward `10.0.10.1` |
| `DNS Fialover Scheduler` | Every 30s health-check of `10.0.10.10` (ping + resolve) |
| `ping_proxmox_stack` | Ping `10.0.10.11`; bounce `ether4` if down |
| `recreate-traefik-docker` | Watch Docker API on `10.0.10.6:2375`; webhook recreate if Traefik stopped |
| `Daily Reboot` | 03:00 daily reboot |

---

## Static DNS (selected)

| Hostname | IP | Purpose |
| --- | --- | --- |
| `ha.mostardesigns.com` | `10.0.10.6` | Home Assistant / shared services host |
| `mqtt.mostardesigns.com` | `192.168.89.26` | MQTT broker |
| `proxmox.mostardesigns.com` | `10.0.10.6` | Proxmox UI (via Traefik host mapping) |
| `traefik.mostardesigns.com` | `10.0.10.6` | Edge proxy |
| `frigate.mostardesigns.com` | `10.0.10.6` | NVR |
| `freeipa.mostardesigns.com` | `10.0.10.10` | FreeIPA / DNS |
| `msnswitch-1.mostardesigns.com` | `10.0.10.254` | MSNSwitch |
| `printer` | `172.16.90.113` | IoT printer |

Full static map is in the sanitized `.rsc`.

---

## Notes / drift from older docs

- Proxmox direct comment is now `10.0.10.11` (watchdog target), not the older `10.0.10.230` note in earlier docs.  
- Perimeter DHCP pool exists but the perimeter DHCP server is **disabled**.  
- AWS site-to-site IPsec/BGP templates remain in config but **disabled**.  
- Do not commit raw `.backup` / unscrubbed `.rsc` under `infrastructure/configs/` (gitignored).
