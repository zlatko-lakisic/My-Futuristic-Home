# Network Topology & VLANs

Live reference: NYC `Kuca` (RB962UiGS-5HacT2HnT, ROS 7.23.2, checked 2026-07-27), Mostar `Kuca-Mostar` (RB951G-2HnD, ROS 7.23.2, checked 2026-07-27), and roaming `Kuca-Roaming` (RB951Ui-2HnD, ROS 7.24.5, checked 2026-10-15). Detailed RouterOS notes: [`mikrotik_config.md`](mikrotik_config.md), [`mikrotik_mostar_config.md`](mikrotik_mostar_config.md), [`mikrotik_roaming_config.md`](mikrotik_roaming_config.md). Subnet tables: [`networks.md`](networks.md).

---

## Site overview

```mermaid
flowchart TB
  Internet((Internet))

  subgraph NYC["NYC — Kuca hAP ac"]
    NYC_WAN["ether1 WAN<br/>DHCP public IPv4"]
    NYC_R["L3 firewall / NAT / VPN"]
    PER["perimiter bridge<br/>10.0.10.0/24"]
    HOME["home_lan<br/>192.168.89.0/24"]
    WIFI["home_wifi_vlan VLAN2<br/>192.168.90.0/24"]
    IOT["iot_vlan VLAN4<br/>172.16.90.0/24"]
    TOR["torrent VLAN<br/>172.16.55.0/29"]
    L2TP_SRV["L2TP/IPsec server<br/>peer 172.16.91.30"]
    NYC_WAN --- NYC_R
    NYC_R --- PER & HOME & WIFI & IOT & TOR & L2TP_SRV
  end

  subgraph MOST["Mostar — Kuca-Mostar RB951G"]
    CPE["ISP CPE<br/>public ~77.78.225.118"]
    MOST_WAN["ether1 WAN<br/>192.168.100.100/24"]
    MOST_R["L3 + policy routing"]
    NYC_BR["nyc_bridge<br/>192.168.88.0/24"]
    TEL_BR["telemach_bridge<br/>local Mostar LAN/WLAN"]
    L2TP_CLI["L2TP client<br/>mikrotik-kuca-l2tp"]
    CPE --- MOST_WAN --- MOST_R
    MOST_R --- NYC_BR & TEL_BR & L2TP_CLI
  end

  Internet --- NYC_WAN
  Internet --- CPE
  L2TP_CLI -->|"L2TP/IPsec<br/>caller = Mostar public IP"| L2TP_SRV
  TOR -->|"policy route torrent_over_mostar<br/>via 172.16.91.30"| L2TP_SRV
  L2TP_CLI -->|"FORCE_NAT_TORRENT<br/>out ether1"| MOST_WAN
```

---

## NYC logical topology

```mermaid
flowchart TB
  WAN((ISP WAN)) --> MT_WAN["ether1 - WAN"]

  subgraph MT["MikroTik Kuca"]
    MT_WAN --> R{L3 Routing & Firewall}

    R --> PER[Bridge perimiter]
    R --> HOME[Bridge home_lan]
    R --> LAN_VPN["Bridge Lan<br/>VPN pool 172.16.91.0/27"]
    HOME --> V2["VLAN 2 home_wifi"]
    HOME --> V4["VLAN 4 iot"]
    PER --> TORNET["172.16.55.1/29 torrent"]
  end

  subgraph PERZ["Perimeter 10.0.10.0/24"]
    PER --- E2[ether2 CSS326 / servers]
    PER --- E3[ether3 MSNSwitch 10.0.10.254]
    PER --- E4[ether4 Proxmox direct 10.0.10.11]
    E2 --- NAS2["NAS2 OMV 10.0.10.17"]
    E2 --- BEE[Beelink Traefik/UniFi 10.0.10.6]
    E2 --- CSS[CSS326 10.0.10.2]
    NAS2 --- QBIT["qBittorrent<br/>macvlan 172.16.55.2"]
  end

  subgraph STORE["Storage backplane 172.16.100.0/24"]
    NAS2 --- BR0["NAS2 br0 172.16.100.1"]
    BR0 --- NVR["NVR 172.16.100.2"]
  end

  subgraph HOUSE["House / IoT"]
    HOME --- E5[ether5 house jacks / APs]
    V4 --- JET["Jetson 172.16.90.20"]
    V4 --- PRINT["Printer 172.16.90.113"]
    E5 --- MQTT["MQTT 192.168.89.26"]
    E5 --- HA["HA 192.168.89.25"]
  end

  QBIT -.->|default via 172.16.55.1| TORNET
  TORNET -.->|mark torrent_over_mostar| L2TP[L2TP to Mostar]
```

---

## Torrent breakout (NYC → Mostar public IP)

qBittorrent on NAS2 is dual-homed:

| Network | Address | Role |
| --- | --- | --- |
| `torrent-vlan` (macvlan) | `172.16.55.2/29` gw `172.16.55.1` | **Default route** — BitTorrent egress |
| `plex-network` | `172.16.101.4/24` | Arr stack / WebUI adjacency |

Path when healthy:

1. NYC mangle: `src=172.16.55.2` + `dst !Local` → routing-mark `torrent_over_mostar`
2. NYC route table `torrent_over_mostar`: `0.0.0.0/0` → **`172.16.91.30`** (Mostar L2TP peer; `check-gateway=ping`)
3. Mostar mangle: same src → table `torrent_over_mostar` → ISP gw `192.168.100.1` with `pref-src=192.168.100.100`
4. Mostar NAT `FORCE_NAT_TORRENT` masquerades out `ether1 - wan`
5. ISP CPE NATs to public IPv4 (tracked in HA as `sensor.mikrotik_mostar_environment_publicip`)

**Do not** point the NYC marked default at `172.16.91.2` (WireGuard) while `wg-mostar` / Mostar `wg-nyc` peer are disabled — that route goes inactive and torrent traffic falls back to the NYC WAN.

```mermaid
sequenceDiagram
  participant Q as qBittorrent 172.16.55.2
  participant N as NYC Kuca
  participant L as L2TP 172.16.91.30
  participant M as Mostar
  participant I as Internet

  Q->>N: Internet traffic
  N->>N: mark torrent_over_mostar
  N->>L: forward via L2TP
  L->>M: arrive as 172.16.55.2
  M->>M: NAT out ether1 / CPE
  M->>I: src = Mostar public IP
  I-->>M: reply
  M-->>N: return via L2TP to 172.16.55.0/29
  N-->>Q: reply
```

---

## Mostar site

| Piece | Live state |
| --- | --- |
| WAN | Static `192.168.100.100/24`, gw `192.168.100.1` (behind ISP CPE NAT) |
| Preferred default | ISP `192.168.100.1` distance 1, `pref-src=192.168.100.100` (router-originated internet) |
| Backup default | L2TP `mikrotik-kuca-l2tp` distance 2 (`add-default-route=yes`) |
| `nyc_bridge` | `192.168.88.1/24` + SSID `Kuca-NYC` — clients policy-routed toward NYC (`via_nyc`) |
| `telemach_bridge` | Local Mostar wired + SSID `Kuca-Mostar` |
| WireGuard `wg-nyc` | Interface up, **peer disabled** (standby) |
| Public IP script | `hacs-public-wan-ip` every 5m → `:global PublicIP` |

---

## VPN summary

| Path | NYC | Mostar | Addressing |
| --- | --- | --- | --- |
| **L2TP/IPsec** | Server enabled | Client running | Mostar `172.16.91.30` ↔ NYC `172.16.91.1` |
| OpenVPN | Server enabled | Client **disabled** | Reserved `172.16.91.29` |
| WireGuard | `wg-mostar` **disabled** | `wg-nyc` peer **disabled** | Would be `172.16.91.1/30` ↔ `172.16.91.2/30` |

NYC static routes: `192.168.88.0/24` and `192.168.100.0/24` → `172.16.91.30`. `192.168.86.0/24` → `172.16.91.25` (roaming).

---

## Roaming device

`Kuca-Roaming` is a travel router, not a third site. Detail: [`mikrotik_roaming_config.md`](mikrotik_roaming_config.md).

| Piece | Live state |
| --- | --- |
| Preferred WAN | `ether1 - wan` DHCP, distance 2 |
| Fallback WAN | `wlan_uplink` virtual station, DHCP distance 3, only when ether1 is down |
| `nyc_bridge` | `192.168.86.1/24`, ether2–5, SSID `Kuca-Roaming-NYC` |
| `roaming lan bridge` | SSID `Kuca-Roaming` only |
| Home uplink | `192.168.89.0/24`, `10.0.10.0/24`, or `172.16.90.0/24`: VPN stays down, LAN masquerades out the uplink |
| Away uplink | L2TP/IPsec to NYC at `172.16.91.25`. OpenVPN `172.16.91.24` stays disabled |
| Radio | Hidden 2.4 GHz master. `frequency=auto`. `roaming-wifi-channel` follows the upstream SSID |
| Open Wi-Fi | Security profile `default`. `uplink-sp` is WPA2 and will not join a network with no passphrase |
| Captive portal | Hotel login must be completed as the `wlan_uplink` MAC, with L2TP still down. The away script currently brings L2TP up first, so the form does not load |

```mermaid
flowchart LR
  Hotel((Hotel or other WAN))
  ETH["ether1 DHCP distance 2"]
  WIFI["wlan_uplink DHCP distance 3"]
  R["Kuca-Roaming"]
  NYCBR["nyc_bridge 192.168.86.0/24"]
  LOCAL["roaming lan bridge Kuca-Roaming"]
  NYC["NYC L2TP 172.16.91.25"]
  Hotel --- ETH & WIFI
  ETH --> R
  WIFI --> R
  R --- NYCBR & LOCAL
  R -->|"only when uplink is not a home LAN"| NYC
```

---

## Related docs

- [`networks.md`](networks.md) — subnet inventory  
- [`mikrotik_config.md`](mikrotik_config.md) / [`mikrotik_mostar_config.md`](mikrotik_mostar_config.md) / [`mikrotik_roaming_config.md`](mikrotik_roaming_config.md)  
- [`switching.md`](switching.md) — CSS326 / house switch  
- [`../storage/nas2.md`](../storage/nas2.md) — OMV + torrent macvlan  
- [`../homeassistant/docs_ha/radio_topology.md`](../homeassistant/docs_ha/radio_topology.md) — Z-Wave / Zigbee / cloud radios  
