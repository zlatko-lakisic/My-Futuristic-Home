# 🚀 My Futuristic Home

![My Futuristic Home Banner](./assets/banner.png)

Welcome to the central documentation for my smart home ecosystem. This repository tracks the configuration, hardware inventory, and infrastructure layout for a high-performance, locally-controlled automation environment.

## 📂 Documentation Directory

### **1. Infrastructure (The Foundation)**
* [**Networking**](infrastructure/networking.md): VLANs, subnets, and the specialized NAS2 bridge.
* [**Hardware Inventory**](infrastructure/hardware.md): Beelink EQ14 and Proxmox Cluster specs.
* [**Security Cameras**](infrastructure/cameras.md): IP camera inventory and stream paths.
* [**NVR & AI Stack**](infrastructure/nvr.md): Frigate, TensorRT, and NVIDIA RTX A4000 logic.
* [**Proxmox Virtualization**](infrastructure/proxmox.md): VM/LXC strategy and backup logic.
* [**MSN Switch Watchdogs**](infrastructure/msn_switches.md): Automated power-cycle logic ([hacs-msnswitch](https://github.com/zlatko-lakisic/hacs-msnswitch)).
* [**Jetson Agentic Orchestration**](infrastructure/jetson_agentic_orchestration.md): Omega Jetson Orin k3s edge AI (`172.16.90.20`).

### **2. Services (The Workloads)**
* [**Traefik Edge Proxy**](services/traefik.md): Ingress, SSL extraction, and certificate distribution (`ai-orchestrator.mostardesigns.com`).
* [**UniFi Controller**](services/unifi.md): WiFi SSIDs, Radio settings, and device adoption.
* [**mDNS Repeater**](services/mdns_repeater.md): Cross-subnet device discovery for IoT and Media.
* [**Home Assistant**](homeassistant/README.md): Core automation engine.
* [**Garden Agentic Watering**](homeassistant/docs_ha/garden_agentic_watering.md): LLM dusk/dawn irrigation via [hacs-agentic-watering](https://github.com/zlatko-lakisic/hacs-agentic-watering).
* [**Frigate NVR**](services/frigate.md): **(Primary)** AI detection and `config.yml`.
* [**Frigate Environment**](services/frigate.env): Sanitized `.env` template for local deployment.
* [**CodeProject.AI**](services/codeproject-ai.md): Dedicated AI inference server (Object/Face/ALPR).

### **2b. Device Networks (The Senses)**
* [**Z-Wave Network**](homeassistant/docs_ha/zwave_network.md): Z-Wave JS mesh, lighting inventory, and mesh notes.
* [**Zigbee Lighting and Sensors**](homeassistant/docs_ha/zigbee_lighting_sensors.md): ZHA coordinator, IKEA drivers, Aqara presence, motion-to-light patterns.
* [**LoRa Perimeter (YoLink Gates)**](homeassistant/docs_ha/lorawan_perimeter.md): YoLink gate contacts and gate-open to AI camera summary workflow.
* [**NFC Entry and Yale Locks**](homeassistant/docs_ha/nfc_entry.md): Tap-to-enter architecture (no operational secrets) and Yale/August lock inventory.
* [**Integrations Catalog**](homeassistant/docs_ha/integrations_catalog.md): Every HA integration/domain and what it is used for.
* [**Unified Climate Control**](homeassistant/docs_ha/unified_climate_control.md): Nest heat + Midea AC behind one living-room thermostat.
* [**Automations Catalog**](homeassistant/docs_ha/automations_catalog.md): Live automations by architecture role.
* [**Scripts Catalog**](homeassistant/docs_ha/scripts_catalog.md): Scripts, sources, and callers.
* [**HACS Plugins**](homeassistant/docs_ha/hacs_plugins.md): Installed HACS integrations and Lovelace cards.

### **3. Related GitHub / Git repos**
| Repo | URL |
|------|-----|
| This project | https://github.com/zlatko-lakisic/My-Futuristic-Home |
| Project wiki | https://github.com/zlatko-lakisic/My-Futuristic-Home/wiki |
| Agentic Orchestration (Jetson) | https://github.com/zlatko-lakisic/agentic-orchestration |
| Agentic Watering (HACS) | https://github.com/zlatko-lakisic/hacs-agentic-watering |
| MSNSwitch (HACS) | https://github.com/zlatko-lakisic/hacs-msnswitch |
| Docker / Traefik stacks | https://git.omega-it.solutions/omegait/docker-infrastructure.git |

## 🗄️ Storage
* [**NAS2**](storage/nas2.md): 10GbE Network Attached Storage for NVR recordings and backups.

## 🏗 Physical Infrastructure (9U Rack)
All core equipment is housed in a **Tecmojo 9U Wall Mount Server Cabinet** featuring active cooling and integrated cable management.

### **Rack Elevation**
| Unit | Device | Role |
| :--- | :--- | :--- |
| **U9** | MikroTik hAP ac | Primary Gateway (3D Printed Left Mount) / Cooling Fan (Right) |
| **U8** | MikroTik CSS326 | Perimeter Switch (10G SFP+ Backbone) |
| **U7** | Rapink 48-Port | Cat6 Patch Panel (House-wide Termination) |
| **U6** | PoE Texas Injector | 12-Port Passive PoE Midspan (APs & IoT) |
| **U5** | TP-Link TL-SG1024 | House LAN Switching |
| **U4** | Shelf: Mixed | Beelink (Network Controller), Pine64 (MQTT), NAS1 |
| **U1-3** | Storage/Video | NAS2 (Left), NVR (Right), **The Home Assistant Server** |

---

## 🌐 Network Architecture
The network is split into two primary physical and logical segments to ensure that high-bandwidth server traffic does not interfere with standard house operations.

### **Subnet Strategy**
- **Perimeter (10.0.10.x):** Secured server management, storage (NAS), and surveillance (NVR).
- **House LAN (192.168.89.x):** General wired devices, Access Points, and the dedicated MQTT broker.
- **House WLAN (192.168.90.x):** Home wifi devices.
- **IOT WLAN (172.16.90.x):** Home iot wifi devices.

---

## 🛠 Tech Stack
| Category | Component |
| :--- | :--- |
| **Automation** | **The Home Assistant Server** (i7-7700T) |
| **Irrigation AI** | [Agentic Watering](https://github.com/zlatko-lakisic/hacs-agentic-watering) + Orbit BHyve |
| **Edge LLM** | Jetson Orin k3s + [Agentic Orchestration](https://github.com/zlatko-lakisic/agentic-orchestration) + Ollama |
| **Z-Wave** | Z-Wave JS + Silicon Labs 700/800 Series controller |
| **Zigbee** | ZHA + SONOFF Zigbee 3.0 USB Dongle Plus V2 (EZSP) |
| **LoRa perimeter** | YoLink DoorSensors (LoRa-family radio) via YoLink hub/cloud |
| **Smart entry** | Yale locks via August HA integration + HA NFC tags |
| **Climate** | Nest heat + Midea AC LAN unified via `climate_template` |
| **Routing** | RouterOS (MikroTik hAP ac) |
| **Switching** | SwOS (CSS326) + Unmanaged (TP-Link) |
| **Messaging** | Mosquitto MQTT (Pine64) |
| **Controller** | UniFi Network Application (Docker on Beelink) |
| **Storage** | Custom NAS1 & NAS2 |
| **Power watchdogs** | MSNSwitch ([HACS](https://github.com/zlatko-lakisic/hacs-msnswitch)) |

---

## 📁 Repository Structure
- `/infrastructure`: Networking, Switching, and PoE documentation.
- `/services`: Docker Compose files and server configurations.
- `/storage`: Detailed hardware and filesystem specs for NAS units. (In Progress)
- `/automation`: Home Assistant configuration and YAML scripts.
- `/docs`: Guides for firewall rules and disaster recovery.

---

## ⚡ Quick Links
- [Detailed Networking Topology](./infrastructure/networking.md)
- [Switch Port Mapping](./infrastructure/switching.md)
- [UniFi Controller Setup](./infrastructure/unifi.md)