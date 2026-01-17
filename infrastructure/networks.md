# 🌐 Network Topology & VLANs

## 🔭 Architecture Overview
The network utilizes a "Security-First" philosophy, leveraging a Layer 3 gateway (MikroTik hAP ac) to enforce isolation between the high-performance Perimeter, the general House LAN, and the IoT ecosystem. 

A key design feature is the **Multi-Homed Management Plane**, where the Network Controller and NVR sit on multiple subnets to optimize traffic flow and ensure high availability without unnecessary inter-VLAN routing overhead.



## 📜 Subnet Definitions (MikroTik RouterOS)
The system is logically segmented into bridges and VLANs managed via the hAP ac Gateway.

| Subnet | Name | Interface | Purpose |
| :--- | :--- | :--- | :--- |
| `192.168.89.0/24` | **home_lan** | ether5 | APs, Pine64 MQTT, House Wall Jacks |
| `192.168.90.0/24` | **home_wifi_vlan** | VLAN 2 | Trusted wireless clients |
| `172.16.90.0/24` | **iot_vlan** | VLAN 4 | Isolated IoT devices (No LAN access) |
| `10.0.10.0/24` | **perimiter** | ether2, 3, 4 | **The HA Server**, NAS1/2, NVR, Proxmox |
| `172.16.91.0/24` | **VPN_Remote** | OVPN / L2TP | Secure remote management tunnel |

---

## 🏎️ Storage Backplane & Direct-Attach Links
To maximize throughput for video surveillance and data replication, specific high-speed direct links are established that bypass the core switch.

### **NAS2 Storage Bridge**
- **Bridge IP:** `172.16.100.1/24`
- **Configuration:** Hardware bridge on NAS2 (Ports 2, 3, 4, 5).
- **Direct Link:** NAS2 Port 2 ↔ NVR Ethernet Port 7.
- **Protocol:** NFS v4.1 (Optimized via `actimeo=1800` and `tcp`).
- **Benefit:** Allows the NVR to record 4K streams directly to the Micron Enterprise SSDs without impacting the 10.0.10.x perimeter traffic.

---

## 🐳 Internal Docker Networks
Several servers run internal virtual networks to isolate container-to-container traffic.

### **NVR AI Stack (box-network)**
- **Subnet:** `172.20.0.0/24`
- **Gateway:** `172.20.0.1`
- **Description:** Private bridge within the NVR Server for AI inference and database communication.

| Assigned IP | Service | Role |
| :--- | :--- | :--- |
| `172.20.0.3` | **Frigate** | Core NVR & Detection |
| `172.20.0.4` | **Double-Take** | Facial Recognition Logic |
| `172.20.0.6` | **CodeProject.AI** | CUDA Inference Server |
| `172.20.0.8` | **InfluxDB 2** | Metrics Database |
| `172.20.0.10` | **Grafana** | Analytics Visualization |
| `172.20.0.11-14`| **CompreFace** | Facial Recognition Backend |

---

## 🛰️ Physical Hardware Connectivity

### **Gateway: MikroTik hAP ac**
- **Role:** Primary L3 Router and Firewall.
- **Key Logic:** Runs watchdog scripts (e.g., `ping_proxmox_stack`) to reset interfaces via MSNSwitch if services hang.

### **Perimeter Distribution: MikroTik CSS326-24G-2S+**
- **Management IP:** `10.0.10.2`
- **Role:** High-speed L2 distribution for the `10.0.10.x` subnet.
- **Backbone:** Connected to hAP ac Port 2.

### **House Distribution: TP-Link TL-SG1024**
- **Role:** Unmanaged distribution for the `home_lan` bridge.
- **Connectivity:** Fed from Port 5 of the hAP ac. 



## 🛠 Management Strategy
* **UniFi Controller (Beelink EQ14):** * **NIC 1 (10.0.10.6):** Secure Web UI access.
    * **NIC 2 (192.168.89.6):** Direct L2 communication with APs to minimize latency.
* **The Home Assistant Server:** Primary logic sits on the Perimeter (`10.0