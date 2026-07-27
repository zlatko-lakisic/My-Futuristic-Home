# Network Topology & VLANs

## Architecture overview

Security-first segmentation on the NYC MikroTik (`Kuca`), plus a remote Mostar site (`Kuca-Mostar`) linked by L2TP/IPsec. High-bandwidth storage and media paths use direct-attach / macvlan links so they do not overload inter-VLAN routing.

Multi-homed management hosts (Beelink, NAS2, NVR) sit on more than one subnet to keep UniFi, Traefik, NFS, and media stacks off the house LAN where possible.

Canonical diagrams: [`networking.md`](networking.md). RouterOS detail: [`mikrotik_config.md`](mikrotik_config.md), [`mikrotik_mostar_config.md`](mikrotik_mostar_config.md).

---

## Subnet definitions (NYC MikroTik)

| Subnet | Name | Interface | Purpose |
| :--- | :--- | :--- | :--- |
| `192.168.89.0/24` | **home_lan** | `home_lan` (ether5 + maint WLAN) | APs, MQTT, house wall jacks, HA SMB |
| `192.168.90.0/24` | **home_wifi_vlan** | VLAN 2 on `home_lan` | Trusted wireless clients |
| `172.16.90.0/24` | **iot_vlan** | VLAN 4 on `home_lan` | Isolated IoT (Jetson `172.16.90.20`, printer, etc.) |
| `10.0.10.0/24` | **perimiter** | `perimiter` (ether2–4) | Servers, NAS, switches, Traefik/UniFi |
| `172.16.55.0/29` | **torrent-vlan** | Address on `perimiter` | qBittorrent breakout (`172.16.55.2` → Mostar) |
| `172.16.91.0/27` | **VPN pool** | Bridge `Lan` + dynamic L2TP/OVPN | Remote VPN clients / Mostar tunnel endpoints |
| `172.16.91.0/30` | **wg-mostar** | `wg-mostar` (**disabled**) | Standby WireGuard addressing |

WAN: DHCP on `ether1 - WAN` (live public IPv4 is dynamic; not documented as a fixed address).

---

## Mostar subnets

| Subnet | Interface | Purpose |
| :--- | :--- | :--- |
| `192.168.100.0/24` | `ether1 - wan` | Link to ISP CPE (`Mostar` = `.100`, gw = `.1`) |
| `192.168.88.0/24` | `nyc_bridge` | Local clients meant to egress via NYC (`via_nyc` mark) |
| `172.16.91.30/32` | `mikrotik-kuca-l2tp` | Dynamic L2TP address toward NYC |
| `172.16.91.2/30` | `wg-nyc` | Standby WireGuard address (peer disabled) |

Public-facing IPv4 is on the **ISP CPE**, not on Mostar ether1. Discovered every 5 minutes into `:global PublicIP` for Home Assistant.

---

## Host / Docker overlays

| Subnet | Where | Purpose |
| :--- | :--- | :--- |
| `172.16.100.0/24` | NAS2 `br0` ↔ NVR | Direct NFS storage backplane |
| `172.16.101.0/24` | NAS2 `plex-network` | Arr / Plex / qBittorrent WebUI adjacency |
| `172.20.0.0/24` | NVR `box-network` | Frigate / AI / metrics containers |
| `172.16.110.0/24` | NAS2 `enp10s0` | Additional NAS2 NIC segment (host-local) |

---

## Storage backplane & direct-attach

### NAS2 storage bridge

- **Bridge IP:** `172.16.100.1/24`
- **Members:** NAS2 ports bridged for DAS-style clients
- **Direct link:** NAS2 Port 2 ↔ NVR Ethernet Port 7 (`172.16.100.2`)
- **Protocol:** NFS v4.1 for NVR recordings

### Torrent macvlan

- Docker network `torrent-vlan` → `172.16.55.2` on NAS2 qBittorrent
- Gateway `172.16.55.1` is the NYC MikroTik perimeter address
- Policy-routed over L2TP to Mostar (see [`networking.md`](networking.md))

---

## Internal Docker networks (NVR AI stack)

### box-network

- **Subnet:** `172.20.0.0/24`
- **Gateway:** `172.20.0.1`

| Assigned IP | Service | Role |
| :--- | :--- | :--- |
| `172.20.0.3` | Frigate | Core NVR & detection |
| `172.20.0.4` | Double-Take | Facial recognition logic |
| `172.20.0.6` | CodeProject.AI | CUDA inference |
| `172.20.0.8` | InfluxDB 2 | Metrics |
| `172.20.0.10` | Grafana | Analytics |
| `172.20.0.11-14` | CompreFace | Face backend |

---

## Physical hardware connectivity

### Gateway: MikroTik hAP ac (`Kuca`)

- Primary L3 router / firewall / VPN concentrator for NYC
- Watchdogs: `ping_proxmox_stack` (ether4), Traefik recreate webhook, CloudNS DDNS, DNS failover vs FreeIPA

### Perimeter: MikroTik CSS326-24G-2S+

- Management `10.0.10.2`
- Fed from hAP ac ether2

### House: TP-Link TL-SG1024

- Unmanaged distribution for `home_lan`
- Fed from hAP ac ether5

### Remote: MikroTik RB951G (`Kuca-Mostar`)

- Behind ISP CPE NAT; L2TP client to `nyc.mostardesigns.com`
- Dual WLAN: `Kuca-Mostar` (local) / `Kuca-NYC` (via NYC)

---

## Management strategy

- **Beelink EQ14:** multi-homed Traefik + UniFi (`10.0.10.6` / house NIC)
- **Home Assistant:** house LAN reachability for SMB/config; Traefik hostnames often map to Beelink VIP `10.0.10.6`
- **FreeIPA / DNS:** `10.0.10.10` — primary DHCP DNS for house/IoT/Wi‑Fi pools
- Validate MikroTik NAT/firewall when adding IoT devices that need MQTT (`1883` failover DNAT exists toward `192.168.89.26`)
