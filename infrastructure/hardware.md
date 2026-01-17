# 🖥 Compute Infrastructure

## **The Server: SFF Powerhouse**
The brain of the home runs on a dedicated Small Form Factor appliance.

- **CPU:** Intel i7-7700T (4C/8T)
- **RAM:** 32GB DDR4
- **Storage:** 240GB NAND SSD
- **Connectivity:** 6x Intel Gigabit Ethernet Ports

### **Radio Controllers**
- **Zigbee:** Sonoff ZBDongle-E (USB Extension used)
- **Z-Wave:** Aeotec Z-Stick 7
- **Bluetooth:** TP-Link UB400 (for presence detection)

## **Power over Ethernet (PoE)**
- **Device:** PoE Texas 12-Port Gigabit Injector
- **Specs:** 48V, 60W total budget.
- **Role:** Providing power to UniFi nanoHD APs and outdoor mesh units.

## **Networking Server: Beelink EQ14**
- **NIC 1:** Connected to MikroTik CSS326 (Port 3) -> **10.0.10.6** (Management/UI)
- **NIC 2:** Connected to TP-Link TL-SG1024 (Port 6) -> **192.168.89.6** (UniFi Device Inform/L2 Traffic)

# 🏗 Physical Hardware & Rack Elevation

## **Enclosure: Tecmojo 9U Wall Mount Cabinet**
The "Home Data Center" is housed in a locked, cooled 9U rack.

### **Rack Elevation (Top to Bottom)**
| Unit | Device | Role / Configuration |
| :--- | :--- | :--- |
| **U9** | **MikroTik hAP ac** | Gateway (Left: 3D Printed Mount) |
| **U9** | **Cooling Fan** | Thermal Exhaust (Right Side) |
| **U8** | **MikroTik CSS326** | Perimeter Switching (10G SFP+ Backbone) |
| **U7** | **Rapink 48-Port** | Cat6 Patch Panel (House Termination) |
| **U6** | **PoE Texas Injector**| 12-Port Passive PoE Midspan |
| **U5** | **TP-Link TL-SG1024** | House LAN Switching |
| **U4** | **Shelf: Beelink** | Networking Server (UniFi Controller) |
| **U4** | **Shelf: Pine64** | MQTT Broker (192.168.89.26 - PoE Powered) |
| **U4** | **Shelf: NAS1** | Primary NAS Server |
| **U1-3** | **NAS2** | Secondary Storage Server (Left side) |
| **U1-3** | **NVR** | Network Video Recorder (Right side) |

### **Specific Component Logic**
* **Pine64:** Runs as a standalone MQTT broker. By using PoE, it stays powered via the midspan injector and is physically isolated from the main compute host for maximum uptime.
* **U9 Mounting:** Uses a custom PETG [3D Printed Faceplate](https://www.printables.com/model/524223-mikrotik-hex-and-haplite-rack-mount-holder).