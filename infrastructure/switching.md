# ⚡ Switching Infrastructure

## **Device: MikroTik CSS326-24G-2S+RM**
* **Management IP:** `10.0.10.2` (Static)
* **Subnet:** Perimeter (10.0.10.x)
* **OS:** SwOS

### **Port Name & Device Mapping**
| Port | Name | Connected Device | Purpose |
| :--- | :--- | :--- | :--- |
| **1** | Mikrotik | hAP ac (Port 2) | Primary Uplink / Gateway |
| **2** | NC MSN Switch | MSNSwitch Device | Power Mgmt: Network Controller |
| **3** | NC | Beelink EQ14 (NIC 1) | Network Controller Management |
| **4** | NAS1 | Custom NAS Server | Primary Storage Data Link |
| **5** | NAS1 MSNSwitch| MSNSwitch Device | Power Mgmt: NAS1 |
| **13** | NAS2 | Secondary NAS | Backup Storage Data Link |
| **23** | NVR | Surveillance Server | Video Feed / Recording Link |

### **SwOS Features Enabled**
* **VLAN Tagging:** Ensuring only Perimeter traffic (10.0.10.x) flows through specific ports.
* **Port Isolation:** Preventing certain compute boxes from seeing each other at Layer 2.

---

## **Layer 2 Access: TP-Link TL-SG1024**
This 24-port unmanaged switch handles the physical distribution for all wired endpoints in the residence. 

### **Logical Configuration**
Because this switch is unmanaged, all VLAN separation for the `home_wifi_vlan` and `iot_vlan` is handled upstream by the **MikroTik hAP ac** via 802.1Q tagging. The switch acts as a transparent conduit for these packets to reach Access Points and hardwired wall jacks.

### **Deployment Usage**
* **Primary Uplink:** Connected to MikroTik hAP ac (Port 5).
* **Downstream Devices:** Smart TVs, Desktop PCs, Gaming Consoles, and Wireless APs.
* **Capacity:** 24x 10/100/1000Mbps ports with 48Gbps switching capacity.