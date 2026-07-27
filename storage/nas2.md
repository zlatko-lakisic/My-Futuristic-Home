# 🗄 Storage: NAS2 (SATA Enterprise Array)

## **Overview**
NAS2 is a high-density, x86-based storage server providing secondary capacity and dedicated high-speed storage access for the NVR. Its primary feature is a multi-port NIC configuration that allows for direct-attach storage (DAS) logic, bypassing the perimeter switch for high-bandwidth video streams.

## **Hardware Specifications**
- **CPU:** Intel Core i7-7700T (Low-power Quad-core)
- **RAM:** 16GB DDR4
- **OS Storage:** 240GB mSATA SSD
- **Data Storage:** 4x Micron 5400 Enterprise SATA SSDs (1.92TB class)
- **Networking:** 16 Total Network Interfaces (Multi-port NIC expansion)
- **Form Factor:** Shared U1-3 space in 9U Rack.

## **Software & Filesystem**
- **Operating System:** OpenMediaVault (OMV) v7.7
- **Storage Configuration:** RAID 5 (Micron Array)
- **Filesystem:** ext4
- **Role:** High-endurance storage for video surveillance and general backups.

## **Network Configuration**
NAS2 is multi-homed: perimeter management, storage DAS bridge, and Docker macvlan/bridge overlays for media.

| Interface / network | IP Address | Purpose |
| :--- | :--- | :--- |
| **enp1s0** | `10.0.10.17/24` | Perimeter management / updates |
| **enp2s0** | `192.168.89.17/24` | House LAN adjacency |
| **br0** | `172.16.100.1/24` | Storage backplane (NVR NFS) |
| **enp10s0** | `172.16.110.1/24` | Extra host NIC segment |
| **plex-network** | `172.16.101.0/24` | Docker Arr / Plex / WebUI bridge |
| **torrent-vlan** | macvlan `172.16.55.0/29` | qBittorrent Internet egress |

### **Direct-Attach Logic (The Storage Bridge)**
To reduce latency and overhead on the MikroTik CSS326, NAS2 acts as a virtual switch for storage clients:
- **Member Ports:** Ports 2, 3, 4, and 5 are bridged.
- **Direct Link:** **Port 2** is physically connected to **NVR Ethernet Port 7**.
- **Network:** `172.16.100.1` (NAS2 Side) to `172.16.100.2` (NVR Side).
- **Service:** NFS v4.1 Share exported specifically for NVR Docker volumes.

### **qBittorrent egress**
Container `qbittorrent` is dual-attached:

- `torrent-vlan` → **`172.16.55.2`**, gateway `172.16.55.1` (**default route**)
- `plex-network` → `172.16.101.4` (local stack / WebUI)

NYC policy-routes `172.16.55.2` over L2TP to Mostar so the announced external IP is Mostar’s ISP public address (not the NYC WAN). See [Networking — torrent breakout](../infrastructure/networking.md).

## **Services & Access**
- **NFS/SMB:** Served over the 172.16.100.x subnet for NVR recording.
- **Rsync:** Target for NAS1-to-NAS2 replication.
- **Media stack:** qBittorrent, Radarr, Sonarr, Prowlarr, Jackett, Plex (Docker on OMV).