# HTTP IP bans — local network policy

Home Assistant **cannot** natively allowlist CIDRs for `ip_ban` (core has repeatedly declined whitelist PRs). `trusted_proxies` only controls whether `X-Forwarded-For` is trusted — it does **not** mean “never ban this address.”

## Never-ban CIDRs (this install)

| CIDR | Role |
| :--- | :--- |
| `192.168.88.0/24` | Lab / adjacent LAN |
| `192.168.89.0/24` | Home LAN (HA `192.168.89.25`, cameras, MQTT, …) |
| `192.168.90.0/24` | Adjacent home segment |
| `172.16.90.0/24` | IoT (Jetson, …) |
| `172.16.91.0/24` | IoT adjacent |
| `10.0.10.0/24` | Server / Traefik VLAN |
| `127.0.0.0/8` | Loopback (also scrubbed) |

## Enforcement

1. **UI Network → trusted proxies** (`.storage/http`): include the LAN CIDRs above so reverse proxies on those nets pass real client IPs via `X-Forwarded-For`.
2. **Package** `packages/unban_local_networks.yaml` + `packages/scrub_local_ip_bans.py`:
   - On Core start and every 10 minutes, scrub matching entries from `ip_bans.yaml`.
   - If anything was removed, restart Core (30‑minute cooldown) so the in-memory ban table clears.

Manual unban: edit `/config/ip_bans.yaml`, remove the IP, restart Core.

## Related

- Live file: `/config/ip_bans.yaml`
- Traefik edge: [services/traefik.md](../../services/traefik.md)
