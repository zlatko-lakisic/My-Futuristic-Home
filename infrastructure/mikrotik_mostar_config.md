# MikroTik RouterOS — Mostar (`Kuca-Mostar`)

**Device model:** RB951G-2HnD  
**Identity:** `Kuca-Mostar`  
**Software:** RouterOS 7.23.2 (export dated 2026-07-27)  
**Sanitized export:** [`mikrotik_mostar_config.rsc`](mikrotik_mostar_config.rsc)  
**Public WAN IP script:** [`mikrotik_mostar_public_wan_ip.rsc`](mikrotik_mostar_public_wan_ip.rsc)

Remote site router. Upstream is a NAT-enabled ISP CPE; Mostar WAN is `192.168.100.100/24` via gateway `192.168.100.1` on `ether1 - wan`.

---

## Role

| Interface / bridge | Role |
| --- | --- |
| `ether1 - wan` | Uplink to ISP CPE (`192.168.100.0/24`) |
| `telemach_bridge` | Local wired + `wlan_mostar` (Mostar LAN side of ISP path) |
| `nyc_bridge` | Traffic intended to egress via NYC (WLAN `wlan_nyc` + DHCP `192.168.88.0/24`) |
| `mikrotik-kuca-l2tp` | L2TP/IPsec client to `nyc.mostardesigns.com` (`add-default-route=yes`) |
| `wg-nyc` | WireGuard to NYC (present; peer often disabled) |
| `mikrotik-kuca-ovpn-client` | OpenVPN client (disabled in export) |

---

## Routing notes (relevant to public IP)

L2TP installs a preferred default toward NYC, so generic discovery (`/ip cloud`) reports the **NYC** egress IP.

Public-IP automation must force probes out the local ISP path:

- Temporary `/32` via `192.168.100.1`
- `/tool fetch` with `src-address=192.168.100.100`
- Store result in `:global PublicIP` for HACS Environment sensors

See [`mikrotik_mostar_public_wan_ip.rsc`](mikrotik_mostar_public_wan_ip.rsc).

---

## HA integration

- Instance name: **Mikrotik-Mostar** (`hacs-mikrotik_router`)  
- Enable **Environment variable sensors** to read `PublicIP`  
- Dashboard WAN line currently uses ether1 `client_ip_address` (private CPE LAN IP) unless updated to the Environment sensor
