# ⚡ Switching Infrastructure

## **Overview**
The switching fabric is divided into two distinct tiers:
1. **Perimeter (Tier 1):** Managed via SwOS on the MikroTik CSS326 for high-bandwidth server and management traffic.
2. **House LAN (Tier 2):** High-density distribution via the TP-Link 24-port switch and Rapink Patch Panel for general connectivity and PoE delivery.

---

## **Perimeter Switch: MikroTik CSS326-24G-2S+RM**
* **Management IP:** `10.0.10.2`
* **Operating System:** SwOS
* **Role:** Core distribution for the 10.0.10.x subnet.

### **SwOS Port Configuration**
| Port | Name | Connected Device | Purpose |
| :--- | :--- | :--- | :--- |
| **1** | Mikrotik | hAP ac (Port 2) | Primary Gateway Uplink |
| **2** | NC MSN Switch | MSNSwitch Device | Power Management for Beelink |
| **3** | NC | Beelink EQ14 (NIC 1) | UniFi Controller Management |
| **4** | NAS1 | Custom NAS Server | Primary Storage Data Link |
| **5** | NAS1 MSNSwitch | MSNSwitch Device | Power Management for NAS1 |
| **13** | NAS2 | Custom NAS Server | Secondary Storage Data Link |
| **23** | NVR | Surveillance Server | Video Processing Link |
| **SFP+ 1** | [Open] | Future 10G Link | Reserved for NAS1 |
| **SFP+ 2** | [Open] | Future 10G Link | Reserved for NAS2 |

### **VLAN Settings (SwOS)**
* **VLAN Mode:** `Enabled`
* **VLAN Receive:** `Any`
* **Default VLAN ID:** `10`

---

## **House LAN Switch: TP-Link TL-SG1024**
* **Type:** Unmanaged Gigabit
* **Role:** Distribution for the 192.168.89.x subnet and IoT traffic.
* **Uplink:** Connected to hAP ac (Port 5).

### **High-Traffic Port Mapping**
| Port | Connected Device | Role |
| :--- | :--- | :--- |
| **6** | Beelink EQ14 (NIC 2) | UniFi Inform (Port 8880) |
| **10** | Pine64 | MQTT Broker (192.16