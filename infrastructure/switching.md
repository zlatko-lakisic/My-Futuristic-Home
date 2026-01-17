# ⚡ Switching Infrastructure

## **Core Switch: MikroTik CSS326-24G-2S+**
This device acts as the high-speed distribution layer for the **Perimeter Network (10.0.10.x)**.

### **Port Configuration**
| Port | Connected Device | Speed | Notes |
| :--- | :--- | :--- | :--- |
| **Port 1** | i7-7700T Server (NIC 1) | 1Gbps | Primary HAOS Management |
| **Port 2** | [Secondary Compute] | 1Gbps | |
| **Port 24** | MikroTik hAP ac | 1Gbps | Uplink to Gateway |
| **SFP+ 1** | Reserved | 10Gbps | Future Fiber Link to NAS/Server |

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