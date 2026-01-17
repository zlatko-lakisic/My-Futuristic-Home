# ☁️ Infrastructure: Proxmox Virtualization Environment

## **Overview**
The compute layer is hosted on a high-performance bare metal server. This node provides the horsepower for AI processing, high-speed storage, and the core management services for the entire network.



## **Hardware Specifications**
- **CPU:** Dual Intel Xeon W-11855M (12 Cores / 24 Threads total)
- **RAM:** 125GB DDR4 ECC
- **Networking:** Single onboard Ethernet connected to **MikroTik Port 4**
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
- **Virtual Machines (VM):** Used for Home Assistant OS and the NVR (Frigate) to ensure kernel isolation.
- **LXC Containers (CT):** Used for lightweight services like MQTT and Docker hosts.

## **Backup Policy**
- **Snapshots:** Taken before major updates.
- **Automated Backups:** Daily dumps to [NAS1](../storage/nas1.md).