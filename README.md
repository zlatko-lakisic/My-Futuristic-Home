# 🚀 My-Futuristic-Home
> A high-performance, local-first smart home ecosystem.

## 🔭 Overview
This repository documents a professional-grade home automation system. It is built on a foundation of network segmentation (MikroTik) and high-density compute (Intel i7).

## 🧠 Key Tech Stack
- **Gateway:** MikroTik RB962UiGS (hAP ac)
- **Compute:** SFF Appliance (Intel i7-7700T | 32GB RAM)
- **Engine:** Home Assistant OS (Native)
- **Protocols:** Zigbee 3.0, Z-Wave 700, BLE, and Multi-Subnet Ethernet.

| Component | Specification |
| :--- | :--- |
| **Messaging** | Pine64 (PoE Powered) | Dedicated MQTT Broker (192.168.89.26) |
| **Storage** | NAS1 & NAS2 | High-density storage (Details in /storage) |
| **Surveillance**| NVR | Dedicated Video Recording Server |
| **Power/PoE** | PoE Texas 12-Port Midspan | Gigabit / 48V 60W (Passive) |
| **Patching** | Rapink 48-Port Cat6 | Inline Keystone / 10G Pass-Thru |
| **Enclosure** | Tecmojo 9U Wall Mount Server Cabinet (17.7" Depth) |
| **Cooling** | Integrated 120mm Exhaust Fan |
| **Security** | Lockable Glass Door & Side Panels |

## **Networking Server: Beelink EQ14**
Dedicated appliance for network management and infrastructure controllers.

- **CPU:** Intel N150 (Twin Lake) up to 3.6GHz
- **RAM:** 16GB DDR4
- **Storage:** 500GB NVMe SSD
- **OS:** Ubuntu 24.04 LTS
- **Deployment:** Docker / Docker Compose
- **Network:** 10.0.10.6 (Perimeter Subnet)

| Layer | Component | Specification |
| :--- | :--- | :--- |
| **Switching (Perimeter)** | MikroTik CSS326-24G-2S+ | 24-Port GigE + 2x 10G SFP+ |
| **Switching (House)** | TP-Link TL-SG1024 | 24-Port Gigabit Rackmount |

## 📁 Quick Links
- [Networking & Subnets](./infrastructure/networking.md)
- [Compute & 6-NIC Hardware](./infrastructure/hardware.md)
- [Home Assistant Config](./homeassistant/README.md)