# 🏠 Home Assistant Configuration

This directory contains the logic, blueprints, and hardware-specific configurations for the "My-Futuristic-Home" OS.

## 📡 Wireless Strategy
My system follows a "Local-First" philosophy. We utilize dedicated radios for different classes of devices to minimize interference and maximize the "Wife Approval Factor" (WAF) through 100% reliability.

### **Network Topology**
For a detailed look at how the Zigbee and Z-Wave meshes are physically and logically structured, see:
👉 **[Wireless Mesh Architecture](./docs_ha/radio_topology.md)**

## **Quick Links**
* ⚡ [**Z-Wave Device Inventory**](zwave_inventory.md) - Full list of 24 devices connected via the primary Z-Wave controller.
* 🤖 [**Automations**](automations.yaml) - Core logic for lighting, security, and hardware watchdogs.

## **Deployment Details**
- **Type:** Home Assistant OS (HAOS) 
- **Network:** Home_LAN
- **Primary Integrations:**
  - **MQTT:** Connects to the broker at `192.168.89.26` to receive Frigate events.
  - **Z-Wave JS UI:** Manages the mesh network for [GE/Enbrighten and Aeotec devices](zwave_inventory.md).
  - **Frigate Proxy:** Provides the Lovelace UI cards for 24/7 camera viewing.
  - **UniFi:** For managing PoE ports and network presence.

---

## 📟 Hardware Controllers
These physical dongles are passed through directly to the HAOS environment:

| Protocol | Hardware | Integration | Role |
| :--- | :--- | :--- | :--- |
| **Zigbee 3.0** | Sonoff ZBDongle-E | ZHA | Lighting, Motion & Environment Sensors |
| **Z-Wave 700** | Aeotec Z-Stick 7 | Z-Wave JS UI | High-Security (Locks, Switches, Valves) |
| **Bluetooth** | TP-Link UB400 | Bluetooth | Presence Tracking (BLE) |

## 🛠 Software Environment
- **Core:** Home Assistant OS (Bare Metal)
- **Database:** MariaDB (Local)
- **Add-ons:** Zigbee Home Automation (ZHA), Z-Wave JS UI, Mosquitto MQTT, Samba Share.

## 📂 Directory Map
* `/blueprints`: Reusable automation templates.
* `/dashboards`: YAML and screenshots of the UI.
* `/docs_ha`: Deep dives into specific radio protocols and mesh health.