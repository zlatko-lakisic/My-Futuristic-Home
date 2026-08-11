# HAOS host SSH (port 22222)

Debug SSH on the Home Assistant OS host is Dropbear on **TCP 22222** (`root`, key-only). It is **not** the Terminal & SSH add-on.

## Enable / refresh keys

USB stick labeled `CONFIG` (FAT) with `authorized_keys`, then import:

```text
python3 /config/packages/ha_os_config_sync.py
```

Or Settings → System → Hardware → ⋮ → Import from USB. Connect:

```bash
ssh -p 22222 root@192.168.89.25
```

## Source IP allowlist

Same CIDRs as the HTTP IP-ban never-ban list (`packages/scrub_local_ip_bans.py`):

| CIDR | Role |
| :--- | :--- |
| `192.168.88.0/24` | Lab / adjacent LAN |
| `192.168.89.0/24` | Home LAN |
| `192.168.90.0/24` | Adjacent home segment |
| `172.16.90.0/24` | IoT |
| `172.16.91.0/24` | IoT adjacent |
| `10.0.10.0/24` | Server / Traefik VLAN |
| `127.0.0.0/8` | Loopback |

Host iptables/ip6tables jump SSH (22 and 22222) through `HAOS-SSH` / `HAOS-SSH6` and drop everything else. IPv6 SSH is loopback/link-local only.

Deploy from this repo:

- `infrastructure/haos/hassos-restrict-ssh.sh` → `/etc/default/hassos-restrict-ssh.sh`
- `infrastructure/haos/99-hassos-restrict-ssh.rules` → `/etc/udev/rules.d/99-hassos-restrict-ssh.rules`

Do **not** dst-nat or Traefik-expose 22222 from WAN.
