# ☁️ Infrastructure: Proxmox Virtualization Environment

## **Overview**
The compute layer is hosted on a high-performance bare metal server. This node provides the horsepower for AI processing, high-speed storage, and the core management services for the entire network.



## **Hardware Specifications**
- **CPU:** Dual Intel Xeon W-11855M (12 Cores / 24 Threads total)
- **RAM:** 125GB DDR4 ECC
- **Networking:** Single onboard Ethernet on **CSS326 port 6** (SwOS name `Proxmox`, 1G). Address stays `10.0.10.11`. A failed ping bounces that port from Home Assistant.
- **IP Address:** `10.0.10.11`

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