# 📨 Messaging Infrastructure

## **Device: Pine64 MQTT Broker**
To ensure high availability for the smart home, the MQTT broker runs on dedicated Pine64 hardware. This isolation ensures that if the main Home Assistant server or Proxmox cluster undergoes maintenance, the messaging bus (the "nervous system" of the house) remains operational.

### **Hardware Specifications**
- **Model:** Pine64 (ARM64 Quad-Core)
- **Power:** PoE (via PoE Texas Injector in U6)
- **Storage:** SanDisk Industrial eMMC (Selected for high endurance and reliability against power cycles/frequent writes).
- **Enclosure:** [Custom 3D Printed Screwless Case](https://www.printables.com/model/347073-screwless-case-pine64-pa642gb-schraubenloses-gehau) (Printed in PETG).

### **Software Stack**
- **OS:** Armbian 23.11.1
- **Broker:** Mosquitto version 2.0.11
- **Service:** Systemd managed `mosquitto.service`

### **Configuration Details**
- **IP Address:** `192.168.89.26` (Static DNS: `mqtt.mostardesigns.com`)
- **Port:** `1883` (Unencrypted) / `8883` (SSL - Internal)
- **Persistence:** Enabled (Database stored on Industrial MMC)

### **Client Connectivity**
| Client | Subnet | Access |
| :--- | :--- | :--- |
| **The HA Server** | 10.0.10.x | Cross-Subnet (Allowed via Mikrotik Firewall) |
| **Zigbee2MQTT** | 10.0.10.x | Cross-Subnet |
| **IoT Devices** | 172.16.90.x | Cross-Subnet (Restricted to Port 1883) |

### **Reliability Notes**
The use of the SanDisk Industrial MMC card is critical for this node, as Mosquitto's persistence engine frequently writes to the disk. Standard SD cards are prone to failure in this role; the industrial MMC ensures long-term uptime.