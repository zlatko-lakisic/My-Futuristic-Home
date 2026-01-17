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
NAS2 utilizes a dual-homed approach with a custom bridge for direct client access.

| Interface | IP Address | Purpose |
| :--- | :--- | :--- |
| **NIC 1** | `10.0.10.17` | Perimeter Network Access (Management/Updates) |
| **Bridge 1** | `172.16.100.1/24` | Internal Storage Backplane |

### **Direct-Attach Logic (The Storage Bridge)**
To reduce latency and overhead on the MikroTik CSS326, NAS2 acts as a virtual switch for storage clients:
- **Member Ports:** Ports 2, 3, 4, and 5 are bridged.
- **Direct Link:** **Port 2** is physically connected to the **NVR Server**.
- **Result:** The NVR records video directly to NAS2 at line speed without passing through the core perimeter switch.

## **Services & Access**
- **NFS/SMB:** Served over the 172.16.100.x subnet for NVR recording.
- **Rsync:** Target for NAS1-to-NAS2 replication.