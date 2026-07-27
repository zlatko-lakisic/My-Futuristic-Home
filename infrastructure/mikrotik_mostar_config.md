# MikroTik RouterOS — Mostar (`Kuca-Mostar`)

**Device model:** RB951G-2HnD  
**Identity:** `Kuca-Mostar`  
**Software:** RouterOS 7.23.2 (re-verified live 2026-07-27)  
**Sanitized export:** [`mikrotik_mostar_config.rsc`](mikrotik_mostar_config.rsc)  
**Public WAN IP script:** [`mikrotik_mostar_public_wan_ip.rsc`](mikrotik_mostar_public_wan_ip.rsc)

Remote-site router behind a NAT-enabled ISP CPE. Site diagrams: [`networking.md`](networking.md).

---

## Role

| Interface / bridge | Role |
| --- | --- |
| `ether1 - wan` | Uplink to ISP CPE — static `192.168.100.100/24`, gateway `192.168.100.1` |
| `telemach_bridge` | Local Mostar wired (ether2–5) + `wlan_mostar` SSID `Kuca-Mostar` |
| `nyc_bridge` | `192.168.88.1/24` + `wlan_nyc` SSID `Kuca-NYC`; clients marked `via_nyc` |
| `mikrotik-kuca-l2tp` | L2TP/IPsec client → `nyc.mostardesigns.com` (`add-default-route=yes`, distance 1) |
| `wg-nyc` | WireGuard interface present; **peer disabled** (standby) |
| `mikrotik-kuca-ovpn-client` | OpenVPN client (**disabled**) |

DHCP on `nyc_bridge` serves `192.168.88.0/24` (incl. reserved TV leases). WAN DHCP-client is disabled (static WAN).

---

## Routing

| Table / route | Behavior |
| --- | --- |
| main default | Dynamic via L2TP (distance 1); static ISP `192.168.100.1` distance 2 |
| `via_nyc` | Default → `172.16.91.1` for `nyc_bridge` traffic |
| `torrent_over_mostar` | Default → `192.168.100.1` with `pref-src=192.168.100.100` |
| NYC LAN reachability | `10.0.10.0/24`, `192.168.89.0/24` → `172.16.91.1` |
| Torrent return | `172.16.55.0/29` → `172.16.91.1` (comment `torrent return to NYC`) |

An older static `172.16.55.0/29` via `172.16.90.1` exists but is **inactive** (wrong next hop); the L2TP return route is the active path.

### Torrent NAT / mangle

```routeros
/ip firewall mangle
add action=mark-routing chain=prerouting new-routing-mark=torrent_over_mostar \
    passthrough=no src-address=172.16.55.2

/ip firewall nat
add action=masquerade chain=srcnat comment=FORCE_NAT_TORRENT \
    out-interface="ether1 - wan" src-address=172.16.55.2
```

MSS clamp (`new-mss=1300`) on forward helps double-NAT TCP.

---

## Public WAN IP → Home Assistant

L2TP installs a preferred default toward NYC, so `/ip cloud` and naive HTTPS fetches report the **NYC** egress IP.

Live automation (`hacs-public-wan-ip`, every 5m):

1. Resolve `api.ipify.org` once  
2. Temporary `/32` via `192.168.100.1`  
3. HTTP fetch **by that IP** with `Host: api.ipify.org` (avoids CDN re-resolve via L2TP)  
4. Store `:global PublicIP`

HA: enable **Environment variable sensors** on instance **Mikrotik-Mostar** → `sensor.mikrotik_mostar_environment_publicip`. Infrastructure dashboard WAN line uses that entity.

Import: `/import file-name=mikrotik_mostar_public_wan_ip.rsc`

---

## Firewall highlights

- `OK-To-Route` interface-list gates breakout / management  
- Winbox / API accepted from PPP and selected WAN paths  
- WireGuard listen accept UDP `13231` on WAN (standby)  
- QUIC (UDP/443) dropped on forward to force TCP fallback  
- Standard defconf established/related + drop invalid / undstnat WAN

---

## Schedulers / scripts

| Name | Interval | Purpose |
| --- | --- | --- |
| `hacs-public-wan-ip` | 5m | Refresh `:global PublicIP` |
| `clear-dns-cache-10m` | 10m | `/ip dns cache flush` |
| `daily-reboot-3am` | daily 03:00 | Maintenance reboot |

---

## Config hygiene note

Live config currently has **duplicated** mangle / NAT / route / filter entries (import applied more than once). Behavior still works because rules are equivalent, but counters and ECMP “+” flags are noisy. Cleaning duplicates is safe maintenance when convenient; prefer export → dedupe → import over hand-deleting while tunnels are live.

---

## Related

- [`networking.md`](networking.md) — multi-site diagrams  
- [`mikrotik_config.md`](mikrotik_config.md) — NYC peer side  
- [`mikrotik_mostar_public_wan_ip.rsc`](mikrotik_mostar_public_wan_ip.rsc)  
