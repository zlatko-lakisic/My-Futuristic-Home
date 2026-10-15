# 🏗 Physical Hardware & Rack Elevation

## **Enclosure: Tecmojo 9U Wall Mount Cabinet**
All core networking and compute hardware is rack-mounted in a secured 9U cabinet (17.7" depth) with active cooling and a lockable glass door.

### **Rack Elevation (Top to Bottom)**
| Unit | Device | Role / Configuration |
| :--- | :--- | :--- |
| **U9** | **MikroTik hAP ac** | Gateway (Left: Custom 3D Printed Mount) / Fan (Right) |
| **U8** | **MikroTik CSS326** | Perimeter Switching (10G SFP+ Backbone) |
| **U7** | **Rapink 48-Port** | Cat6 Patch Panel (House-wide Termination) |
| **U6** | **PoE Texas Injector**| 12-Port Passive PoE Midspan (48V 60W) |
| **U5** | **TP-Link TL-SG1024** | House LAN Switching (192.168.89.x) |
| **U4** | **Shelf: Beelink** | Networking Server (UniFi Controller) |
| **U4** | **Shelf: Pine64** | MQTT Broker (192.168.89.26 - PoE Powered) |
| **U4** | **Shelf: NAS1** | Primary NVMe Storage (FriendlyElec CM3588) |
| **U1-3**| **NAS2** | Secondary Storage Server (Mounted Left) |
| **U1-3**| **NVR** | Surveillance Server (Mounted Right) |
| **U1-3**| **The HA Server** | The Home Assistant Server (SFF i7-7700T) |

---

## **Compute & Server Specifications**

### **The Home Assistant Server**
- **Model:** SFF PC (i7-7700T / 16GB RAM)
- **CPU:** Intel Core i7-7700T
- **OS:** Home Assistant OS (Bare Metal)
- **Role:** Primary Automation Engine.

### **NVR Server**
- **CPU:** Intel Core i7-8700T
- **GPU:** NVIDIA RTX A4000
- **Networking:** Triple-Homed (10G Management, 1G Camera, Direct-Attach Storage)
- **OS:** Ubuntu 24.04
- **Role:** Primary Surveillance & AI Processing.

### **Storage Server: NAS1**
- **Hardware:** FriendlyElec CM3588 NAS Kit
- **Enclosure:** [3D Printed 10" Rack Case](https://www.printables.com/model/826870)
- **Storage:** 4x 3.8TB Team NVMe (RAID 5)
- **Boot Media:** 120GB Industrial MMC
- **OS:** OpenMediaVault 6.9
- **IP:** 10.0.10.3

### **Storage Server: NAS2**
- **CPU:** Intel Core i7-7700T
- **Storage:** 4x Micron 5400 Enterprise SATA SSDs (RAID 5)
- **Boot Media:** 240GB mSATA SSD
- **OS:** OpenMediaVault 7.7
- **NIC Count:** 16 Interfaces
- **Special Config:** Bridged Port 2 to NVR for direct storage access.
- **Role:** High-speed NFS target for NVR video files.

### **Networking Server: Beelink EQ14**
The Beelink EQ14 is the backbone for management services.
- **OS:** Docker / Linux
- **Role:** Physical host for Traefik and UniFi.
- **Connectivity:** 
  - **eth0:** 10.0.10.6 (Perimeter Management)
  - **eth1:** 192.168.89.6 (House LAN Adoption)

### **Messaging Broker: Pine64**
- **Hardware:** ARM64 Single Board Computer
- **Case:** [3D Printed Screwless Case](https://www.printables.com/model/347073)
- **Storage:** SanDisk Industrial MMC
- **OS:** Armbian 23.11.1
- **IP:** 192.168.89.26

---

## **Roaming devices**

These boards are not mounted in the 9U cabinet.

### **MikroTik RB951Ui-2HnD (`Kuca-Roaming`)**
- **Serial:** 628105BB1449
- **OS:** RouterOS 7.24.5
- **Role:** Travel router. LAN `192.168.86.1/24` on `nyc_bridge`. L2TP to NYC (`172.16.91.25`) only when the uplink is outside the NYC home ranges.
- **Radios:** Hidden 2.4 GHz master, SSID `Kuca-Roaming-NYC` (via NYC), SSID `Kuca-Roaming` (local), `wlan_uplink` as the Wi-Fi WAN.
- **Notes:** [`mikrotik_roaming_config.md`](mikrotik_roaming_config.md)