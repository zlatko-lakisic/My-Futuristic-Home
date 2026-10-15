# MikroTik RouterOS — Roaming (`Kuca-Roaming`)

**Device model:** RB951Ui-2HnD  
**Identity:** `Kuca-Roaming`  
**Serial:** 628105BB1449  
**Software:** RouterOS 7.24.5 (live 2026-10-15)  
**Admin login:** `.cursor/secrets/.roaming-kuca` (gitignored)

Travel router cloned from Mostar, with its own LAN. It is not in the NYC rack. Upstream Wi-Fi name and password stay on the router (`wlan_uplink` and security profile `uplink-sp`). The clone bundle under `infrastructure/configs/clone/` is gitignored because it contains secrets.

Site diagrams: [`networking.md`](networking.md). NYC peer: [`mikrotik_config.md`](mikrotik_config.md).

---

## Role

| Interface / bridge | Role |
| --- | --- |
| `ether1 - wan` | Preferred WAN. DHCP client, default-route distance 2, `check-gateway=ping` |
| `wlan_uplink` | Fallback WAN. Virtual station, DHCP distance 3, same gateway check. Used when ether1 is down |
| `nyc_bridge` | `192.168.86.1/24`. ether2–5 and `wlan_nyc` SSID `Kuca-Roaming-NYC`. Away from home, this bridge is marked `via_nyc` |
| `roaming lan bridge` | `wlan_kuca` SSID `Kuca-Roaming` only. Local SSID, not the NYC path |
| `wlan_roaming` | Hidden physical AP (`kuca-radio`, `hide-ssid=yes`). Master for the virtual interfaces |
| `mikrotik-kuca-l2tp` | L2TP/IPsec client → `nyc.mostardesigns.com`. Enabled only when the uplink is not a home LAN. Address `172.16.91.25` |
| `mikrotik-kuca-ovpn-client` | OpenVPN client. Stays disabled. Reserved address `172.16.91.24` |
| `wg-nyc` | WireGuard interface left over from the Mostar clone (`172.16.91.2/30`). Peer stays disabled. Do not enable it while Mostar still owns that standby |

ether2 is named `ether2 - roaming bridge` and is a port on `nyc_bridge`, same as ether3–5.

DHCP on `nyc_bridge` serves `192.168.86.10–192.168.86.254`. DNS offered to clients is the router (`192.168.86.1`). The router’s own resolvers are `10.0.10.10` and `8.8.8.8`. DHCP clients do not take peer DNS or NTP.

`roaming lan bridge` is not a member of the `LAN` interface list. Home masquerade and the away `via_nyc` mark apply to `nyc_bridge`.

---

## Wireless

This radio is 2.4 GHz only (legacy `/interface wireless`, not wifiwave2). The physical interface has to stay `ap-bridge` so the virtual APs can beacon. One virtual station shares that radio. The station only hears the channel the master has already selected. `frequency` stays `auto`. Channel width is 20 MHz.

`roaming-wifi-channel` runs every minute. While `wlan_uplink` is connected it does nothing. When the station is searching, it scans and narrows `scan-list` to the channel of the configured SSID. A fixed frequency is not stored.

| Interface | Mode | SSID | Bridge |
| --- | --- | --- | --- |
| `wlan_roaming` | `ap-bridge`, hidden | `kuca-radio` | none (radio master) |
| `wlan_nyc` | virtual AP | `Kuca-Roaming-NYC` | `nyc_bridge` |
| `wlan_kuca` | virtual AP | `Kuca-Roaming` | `roaming lan bridge` |
| `wlan_uplink` | virtual station | set on the router | WAN |

### Passphrase and open networks

`uplink-sp` is WPA2-PSK. Use it for an upstream network that has a password. Put the name on `wlan_uplink` and the passphrase on `uplink-sp`.

An open hotel network will not associate on `uplink-sp`. Point `wlan_uplink` at security profile `default` (`mode=none`) and set the hotel SSID. Switch it back to `uplink-sp` for a WPA2 network.

### Captive portal

Association and DHCP succeed before the hotel login form is submitted. The hotel then authorizes the MAC of `wlan_uplink`, not the laptop.

To reach the form, a PC on `nyc_bridge` (ether2–5 or `Kuca-Roaming-NYC`) has to open a plain HTTP page (`http://neverssl.com` or `http://1.1.1.1`) while LAN traffic is masqueraded straight out `wlan_uplink` and L2TP is still down. Phone captive-portal popups miss it, because this router does not use the hotel’s DNS.

That order is not what the router does today. A hotel address is outside the home ranges below, so `roaming-isp-routes` turns L2TP on immediately and sends `nyc_bridge` into the tunnel. The tunnel cannot connect until the form is done, so the form never loads. Hold the VPN and keep masquerade on `wlan_uplink` until the portal accepts the station MAC, then let L2TP come up.

---

## Home versus away

`roaming-isp-routes` runs from both DHCP clients. It uses ether1 when that client is bound and the interface is running. Otherwise it uses `wlan_uplink` the same way. If neither is up, L2TP and OpenVPN stay down.

The check compares the chosen uplink’s `/24` with `roaming-home-lan`:

| Address | Comment |
| --- | --- |
| `192.168.89.0/24` | NYC LAN |
| `10.0.10.0/24` | NYC perimeter |
| `172.16.90.0/24` | 172.16.90 LAN |

**Home** (uplink is one of those ranges): L2TP and OpenVPN disabled, `roaming-away-only` routes disabled, `via_nyc` mangle disabled, `roaming-home-masquerade` enabled out the chosen uplink.

**Away:** L2TP enabled (OpenVPN stays disabled), away routes and `via_nyc` mangle enabled, home masquerade disabled. L2TP’s default route is distance 1, so it wins over the DHCP defaults (ether1 distance 2, Wi-Fi distance 3).

NYC static route back to this LAN is `192.168.86.0/24` via `172.16.91.25`. On NYC, `www`, `api`, and `api-ssl` `available-from` include `192.168.86.0/24`. SSH `available-from` does not. `support` and `Local` include this subnet, and NYC masquerades it when it breaks out through the NYC WAN.

---

## Schedulers

| Name | Interval | Purpose |
| --- | --- | --- |
| `roaming-wifi-channel` | 1m | Follow the upstream SSID’s channel while `frequency` stays `auto` |
| `hacs-public-wan-ip` | 5m | Refresh `:global PublicIP` using the same ether1-then-Wi-Fi uplink |
| `clear-dns-cache-10m` | 10m | `/ip dns cache flush` |
| `daily-reboot-3am` | daily 03:00 | Maintenance reboot |

`silent-boot` is not applied. This board’s device mode rejects it.

---

## Related

- [`networking.md`](networking.md) — multi-site diagrams
- [`networks.md`](networks.md) — subnet inventory
- [`mikrotik_config.md`](mikrotik_config.md) — NYC peer side
- [`hardware.md`](hardware.md) — this board is a roaming device, not a rack unit
