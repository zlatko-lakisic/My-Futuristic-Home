# MikroTik RouterOS — NYC / Home (`Kuca`)

**Device model:** RB962UiGS-5HacT2HnT (hAP ac)  
**Identity:** `Kuca`  
**Software:** RouterOS 7.23.2 (re-verified live 2026-07-27)  
**Serial / software id:** redacted  
**Sanitized export:** [`mikrotik_home_config.rsc`](mikrotik_home_config.rsc)

Primary NYC gateway. Mostar (`Kuca-Mostar`) dials back over **L2TP/IPsec** (primary). WireGuard / OpenVPN remain configured as standby. Diagrams: [`networking.md`](networking.md).

---

## Role

| Role | Detail |
| --- | --- |
| WAN | `ether1 - WAN` via DHCP (`/ip dhcp-client`) |
| Perimeter | Bridge `perimiter` — mgmt / servers / switches (`10.0.10.0/24`) |
| House LAN | Bridge `home_lan` — trusted wired (`192.168.89.0/24`) |
| Home Wi‑Fi VLAN | `home_wifi_vlan` (VLAN 2) — `192.168.90.0/24` |
| IoT VLAN | `iot_vlan` (VLAN 4) — `172.16.90.0/24` |
| VPN pool | `172.16.91.0/27` on bridge `Lan` (L2TP / OVPN / WG peer addressing) |
| Torrent breakout | `172.16.55.0/29` on perimeter; marked `torrent_over_mostar` toward Mostar |

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

**Bridge membership:**

- `perimiter`: ether2, ether3, ether4  
- `home_lan`: ether5, wlan3 (5 GHz maint SSID)  
- Wireless SSIDs include `Kuca 2g`, hidden maintenance SSID, plus virtual APs  

**Interface lists:** `WAN` (`ether1 - WAN`), `LAN` (`Lan`), `homelan` (`home_lan`, `ether5`), `NBI VPN` (legacy).

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

WAN uses DHCP on `ether1 - WAN` (public IPv4 is dynamic). Disabled AWS/link-local tunnel addresses remain in config but unused.

### DHCP

| Server | Interface | Notes |
| --- | --- | --- |
| `home_dhcp` | `home_lan` | DNS/WINS → FreeIPA `10.0.10.10`, domain `mostardesigns.com` |
| `home_wifi_dhcp` | `home_wifi_vlan` | Same DNS pattern |
| `iot_dhcp` | `iot_vlan` | Includes Jetson `172.16.90.20`, printer `172.16.90.113` |
| `perimiter_dhcp` | `perimiter` | **Server disabled**; static leases retained historically |

---

## Mostar / remote site VPN

| Path | Status | Notes |
| --- | --- | --- |
| **L2TP/IPsec server** | **Enabled / active** | Secret `l2tp-mostar-kuca` → remote `172.16.91.30`; live caller-id = Mostar public IP |
| **OpenVPN server** | Enabled | Client secret `ovpn-mostar-kuca` remote `172.16.91.29` (Mostar client disabled) |
| **WireGuard `wg-mostar`** | Interface **disabled** | Listen `51820`; peer allowed Mostar LAN / CPE / `172.16.91.2` |

```routeros
/ip route
add dst-address=192.168.88.0/24 gateway=172.16.91.30
add dst-address=192.168.100.0/24 gateway=172.16.91.30
```

### Torrent policy routing

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

Gateway **must** be the L2TP peer `172.16.91.30` while WireGuard is down. Other routing tables present: `tv_over_vpn`, `toAWS` (unused/legacy).

`Local` address-list excludes RFC1918 house/perimeter/VPN/torrent prefixes so only Internet destinations take the Mostar path.

NAT: masquerade Mostar L2TP (`192.168.88.0/24`) and WG (`172.16.91.0/24`) clients out WAN when they break out through NYC; general WAN masquerade for local clients. Torrent packets themselves are **not** NATed on NYC — Mostar applies `FORCE_NAT_TORRENT`.

Related files:

- [`mikrotik_mostar_config.rsc`](mikrotik_mostar_config.rsc) / [`mikrotik_mostar_config.md`](mikrotik_mostar_config.md)  
- [`mikrotik_mostar_public_wan_ip.rsc`](mikrotik_mostar_public_wan_ip.rsc)

---

## Firewall highlights

- FastTrack + established/related accept  
- Winbox (`8291`) restricted to `support` address-list  
- L2TP/IPsec (`1701` / `500` / `4500`), OpenVPN (`1194`), WireGuard (`51820`) accepted on WAN  
- Port-scan / SYN-flood / bogon / spam protections  
- Public HTTP/HTTPS/mail ports DNAT to Traefik host `10.0.10.6`  
- MQTT failover DNAT IoT → `192.168.89.26:1883`  
- Filter log `TRACE-TORRENT` + accept for `172.16.55.0/29`  
- `homeassistant` API user group for HACS MikroTik (API-only policies)

---

## Scripts & schedulers

| Name | Purpose |
| --- | --- |
| `cloudns-update` | Hourly dynamic DNS (credentials redacted in scrubbed export) |
| `EnableDns` / `DisableDns` | Toggle DNS/NTP failover NAT toward `10.0.10.1` |
| `DNS Fialover Scheduler` | Every 30s health-check of `10.0.10.10` |
| `ping_proxmox_stack` | Ping `10.0.10.11`; bounce `ether4` if down |
| `recreate-traefik-docker` | Watch Docker API on `10.0.10.6:2375`; webhook recreate if Traefik stopped |
| `Daily Reboot` | 03:00 daily reboot |

---

## Static DNS (selected)

| Hostname | IP | Purpose |
| --- | --- | --- |
| `ha.mostardesigns.com` | `10.0.10.6` | HA / shared services via Traefik host |
| `mqtt.mostardesigns.com` | `192.168.89.26` | MQTT broker |
| `proxmox.mostardesigns.com` | `10.0.10.6` | Proxmox UI (Traefik) |
| `traefik.mostardesigns.com` | `10.0.10.6` | Edge proxy |
| `frigate.mostardesigns.com` | `10.0.10.6` | NVR |
| `qbittorrent.mostardesigns.com` | `10.0.10.6` | qBittorrent WebUI (Traefik) |
| `freeipa.mostardesigns.com` | `10.0.10.10` | FreeIPA / DNS |
| `msnswitch-1.mostardesigns.com` | `10.0.10.254` | MSNSwitch |
| `printer` | `172.16.90.113` | IoT printer |

Full static map is in the sanitized `.rsc`.

---

## Notes / drift

- Proxmox direct comment / watchdog target is `10.0.10.11` (not older `10.0.10.230` notes).  
- Perimeter DHCP server is **disabled**.  
- AWS site-to-site IPsec/BGP templates remain **disabled**.  
- qBittorrent lives on NAS2 (`10.0.10.17`) with macvlan `172.16.55.2` — see [`../storage/nas2.md`](../storage/nas2.md).  
- Do not commit raw `.backup` / unscrubbed `.rsc` under `infrastructure/configs/` (gitignored).  
