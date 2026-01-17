# 🏗 Physical Hardware & Rack Elevation

## **Enclosure: Tecmojo 9U Wall Mount Cabinet**
All core networking and compute hardware is rack-mounted in a secured 9U cabinet (17.7" depth) with active cooling and a lockable glass door.

### **Rack Elevation (Top to Bottom)**
| Unit | Device | Role / Configuration |
| :--- | :--- | :--- |
| **U9** | **MikroTik hAP ac** | Gateway (Left: [Custom 3D Printed Mount](https://www.printables.com/model/524223)) |
| **U9** | **Exhaust Fan** | Thermal Management (Right Side) |
| **U8** | **MikroTik CSS326** | Perimeter Switching (10G SFP+ Backbone) |
| **U7** | **Rapink 48-Port** | Cat6 Patch Panel (House-wide Termination) |
| **U6** | **PoE Texas Injector**| 12-Port Passive PoE Midspan (48V 60W) |
| **U5** | **TP-Link TL-SG1024** | House LAN Switching (192.168.89.x) |
| **U4** | **Shelf: Beelink** | Networking Server (UniFi Controller) |
| **U4** | **Shelf: Pine64** | MQTT Broker (192.168.89.26 - PoE Powered) |
| **U4** | **Shelf: NAS1** | Primary Storage Server |
| **U1-3**| **NAS2** | Secondary Storage Server (Mounted Left) |
| **U1-3**| **NVR** | Surveillance Server (Mounted Right) |
| **U1-3**| **The HA Server** | **The Home Assistant Server** (SFF i7-7700T) |

---

## **Compute & Server Specifications**

### **The Home Assistant Server**
- **Model:** Small Form Factor (SFF) PC
- **CPU:** Intel Core i7-7700T
- **OS:** Home Assistant OS (Bare Metal)
- **Role:** Central automation engine for all Zigbee, Z-Wave, and Dashboard logic.
- **Placement:** U1-3 shared space.

### **Networking Server: Beelink EQ14**
- **OS:** Docker / Linux
- **NIC 1:** Connected to CSS326 (10.0.10.6) - Management UI.
- **NIC 2:** Connected to TP-Link (192.168.89.6) - UniFi Inform (Port 8880).
- **Role:** Hosting UniFi Network Application & local management tools.

### **Messaging Broker: Pine64**
- **Hardware:** ARM64 Single Board Computer.
- **Power:** Powered via PoE (from U6 Injector).
- **IP:** 192.168.89.26
- **Role:** Dedicated Mosquitto MQTT broker for smart home telemetry.

---

## **Networking Hardware**

### **MikroTik hAP ac (Gateway)**
- **Mounting:** Uses a PETG 3D-printed 1U rack ear system to sit beside the rack exhaust fan in U9.
- **Interface 2:** Trunk to Perimeter Switch (CSS326).
- **Interface 5:** Link to House LAN Switch (TP-Link).

### **MikroTik CSS326-24G-2S+RM**
- **OS:** SwOS
- **IP:** 10.0.10.2
- **Features:** 24 Gigabit ports and 2 SFP+ 10G ports for high-speed storage backbone.

### **PoE Texas 12-Port Midspan Injector**
- **Type:** Passive 10/100/1000 Gigabit.
- **Output:** 48V 60W Shared.
- **Targets:** UniFi nanoHD APs and Pine64.

---

## **Power Management**
- **MSNSwitch (NC):** Remote power control for the Beelink Networking Server.
- **MSNSwitch (NAS1):** Remote power control for the Primary NAS.