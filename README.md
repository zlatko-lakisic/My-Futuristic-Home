# 🏠 Home Data Center & Automation Framework

This repository serves as the single source of truth for the physical and logical infrastructure of my home network and automation environment. The setup is designed for high availability, security through segmentation, and local-first reliability.

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

---

## 🛠 Tech Stack
| Category | Component |
| :--- | :--- |
| **Automation** | **The Home Assistant Server** (i7-7700T) |
| **Routing** | RouterOS (MikroTik hAP ac) |
| **Switching** | SwOS (CSS326) + Unmanaged (TP-Link) |
| **Messaging** | Mosquitto MQTT (Pine64) |
| **Controller** | UniFi Network Application (Docker on Beelink) |
| **Storage** | Custom NAS1 & NAS2 |

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