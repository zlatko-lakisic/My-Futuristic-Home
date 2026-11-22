# ☁️ Infrastructure: Proxmox Virtualization Environment

## **Overview**
The compute layer is hosted on a high-performance bare metal server. This node provides the horsepower for AI processing, high-speed storage, and the core management services for the entire network.



## **Hardware Specifications**
- **CPU:** Dual Intel Xeon W-11855M (12 Cores / 24 Threads total)
- **RAM:** 125GB DDR4 ECC
- **Networking:** Dual 1G Ethernet in Linux **active-backup** bond (details below). Host IP stays `10.0.10.11`.
- **IP Address:** `10.0.10.11`
- **UI:** `https://proxmox.mostardesigns.com` via Traefik on Beelink (`10.0.10.6`) → host `:8006`

## **Networking (active-backup bond)**

Cut over live 2026-11-22. Single address; no second management IP.

| Role | Interface | CSS326 | SwOS name | Notes |
| :--- | :--- | :--- | :--- | :--- |
| Bond primary | `enp0s13f0u2` (USB Realtek `0bda:8156`, driver `r8152`) | Port 7 | `Proxmox-USB` | Preferred active slave |
| Bond backup | `enp0s31f6` (onboard `e1000e`) | Port 6 | `Proxmox-onboard` | Standby; takes over on link loss |
| Bond | `bond0` | — | — | `mode active-backup`, `miimon 100`, `bond-primary enp0s13f0u2` |
| Bridge | `vmbr0` | — | — | `bridge-ports bond0`; `10.0.10.11/24`, GW `10.0.10.1` |

`/etc/network/interfaces` shape (host-managed; backup copy kept under `/root/interfaces.bak-*` on the node):

```
auto bond0
iface bond0 inet manual
	bond-slaves enp0s13f0u2 enp0s31f6
	bond-miimon 100
	bond-mode active-backup
	bond-primary enp0s13f0u2

auto vmbr0
iface vmbr0 inet static
	address 10.0.10.11/24
	gateway 10.0.10.1
	bridge-ports bond0
	bridge-stp off
	bridge-fd 0
```

Verify with `cat /proc/net/bonding/bond0` (active slave should be USB when port 7 is up). Failover was tested by bouncing CSS326 port 7; traffic moved to onboard and returned to USB after restore.

### Link watchdog

Home Assistant package [`homeassistant/packages/proxmox_link_watchdog.yaml`](../homeassistant/packages/proxmox_link_watchdog.yaml): five failed pings to `10.0.10.11` → bounce CSS326 **port 7 then port 6** (2s each). Covers a soft-hung active bond member on either path.

### Auth (LDAP realm)

Proxmox realm `mostardesigns.com` is LDAP against FreeIPA (`10.0.10.10`, bind `uid=proxmox,...`). Synced userids are **lowercase** (e.g. `zlatko.lakisic@mostardesigns.com`). The UI userid is case-sensitive: `Zlatko.Lakisic@...` fails with `no such user`. Use the realm dropdown + lowercase uid, or `root@pam` for local break-glass.

## **Storage Configuration**
The server utilizes four **Western Digital SN810 2TB NVMe** drives, optimized for high-IOPS virtualization workloads.

| Drive | Role | Filesystem | Capacity |
| :--- | :--- | :--- | :--- |
| **NVMe 0** | Proxmox Host OS | ext4/LVM | 2TB (Raw) |
| **NVMe 1** | VM Storage Pool | ZFS (RAIDZ1) | 2TB (Usable/Redundant) |
| **NVMe 2** | VM Storage Pool | ZFS (RAIDZ1) | 2TB (Usable/Redundant) |
| **NVMe 3** | VM Storage Pool | ZFS (RAIDZ1) | 2TB (Usable/Redundant) |

> **Note on Redundancy:** The three-disk ZFS RAIDZ1 pool provides a "Source of Truth" for virtual disks. This configuration allows for the failure of any one of the three data drives without losing VM data.

## **Virtualization Strategy**
We utilize a hybrid approach to balance security and performance.
- **Virtual Machines (VM):** Used for Home Assistant OS and the NVR (Frigate) to ensure kernel isolation. Remaining tracked QEMU guests include nginx-prod (100), gitlab (102), and freeipa (106). QEMU kubernetes-test (104) was removed.
- **LXC Containers (CT):** Used for lightweight services (tourguide LEMP CTs 190–193, AO Quill worker) and **MariaDB (CT 194)** on `10.0.10.207` (formerly QEMU VM 101). Home Assistant ProxmoxVE tracks CT 194 for infra dashboards.

### MariaDB (CT 194)
- **VMID:** 194 · **hostname:** `mariadb` · **IP:** `10.0.10.207` (unchanged for WordPress clients)
- **Stack:** Ubuntu 24.04 · MariaDB 12.3 LTS · unprivileged LXC on `vm-store` / `vmbr0`
- **QEMU 101:** Kept **stopped** after cutover for soak/rollback; destroy only after retire gate (48–72h + operator confirm). Snapshot `pre-lxc-194` exists on the old VM disk.

## **Backup Policy**
- **Snapshots:** Taken before major updates.
- **Automated Backups:** Weekly vzdump (Sun 01:00) to `backups-ps3` for VMIDs including 100–102, 190–194. Daily dumps to [NAS1](../storage/nas1.md) where configured.