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
Checked live 2026-11-08 after the AP VLAN move and port rename. Ports not listed below are empty and keep their default names.

| Port | Name | Learned device | Purpose |
| :--- | :--- | :--- | :--- |
| **1** | Kuca-ether2 | Kuca `ether2` | Perimeter uplink, VLAN 1 |
| **2** | Traefik MSNSwitc | MSNSwitch `10.0.10.252` at 100M | Power switch |
| **3** | NVR-Mgmt | NVR `enp3s0` `10.0.10.16` | NVR management. Stays on VLAN 1 |
| **4** | NAS1 | NAS1 `10.0.10.3` | Storage management |
| **5** | NAS MSNSwitch | MSNSwitch `10.0.10.251` at 100M | Power switch |
| **6** | Proxmox | Proxmox `10.0.10.11` | Home Assistant bounces this port when the host stops answering |
| **9** | NAS2 | NAS2 `10.0.10.17` | Stays on VLAN 1 |
| **10** | Beelink | Beelink `10.0.10.6` | Traefik / UniFi host. Stays on VLAN 1 |
| **11** | Jetson | Jetson Ethernet `10.0.10.20`, `3C:6D:66:0C:8F:15` at 1G | Stays on VLAN 1 |
| **13** | AP-BottomFloor | Bottom Floor AP `78:45:58:80:78:EE`, `10.0.30.5` | AP on VLAN 30 |
| **14** | AP-BackYard | Backyard AP `F4:E2:C6:19:BF:A2`, `10.0.30.3` | AP on VLAN 30 |
| **15** | AP-TopFloor | Top Floor AP `78:45:58:80:7F:6C`, `10.0.30.4` | AP on VLAN 30 |
| **16** | AP-Spare | Nothing learned | Open AP port |
| **17** | NVR-Cameras | NVR `enp8s0` `10.0.20.2/28` at 1G | Camera ingest on VLAN 20 |
| **18** | Kuca-ether4 | Kuca `ether4` at 1G | Camera DHCP uplink `10.0.20.1/28` |
| **19–20** | Cam-Spare1, Cam-Spare2 | Nothing learned | Open camera drops. The CSS326 is not PoE |
| **21** | Driveway | Driveway `B8:A4:4F:3D:5F:B9` at 100M | Axis P3375-VE, `10.0.20.8` |
| **22** | FrontDoor | Front Door `D0:21:F9:97:6D:18` at 100M | UniFi G3 Flex, `10.0.20.4` |
| **23** | WestSide | West Side `B8:A4:4F:3D:5F:C3` at 100M | Axis P3375-VE, `10.0.20.7` |
| **24** | BackYard | Back Yard `B8:A4:4F:3D:5C:96` at 100M | Axis P3375-VE, `10.0.20.3` |
| **SFP+ 1** | AP-Trunk | Kuca `sfp1` over a 1 m SFP copper cable at 1G | Tagged VLANs 2, 4 and 30 to the `home_lan` bridge |
| **SFP+ 2** | SFP2 | Open | Stays on VLAN 1 |

### **VLAN Settings (SwOS)**
| Ports | VLAN mode | VLAN receive | Default VLAN | Port Isolation can reach |
| :--- | :--- | :--- | :--- | :--- |
| 1–12, SFP2 | `optional` | `any` | 1 | Each other |
| 13–16 (APs) | `strict` | `any` | 30 | Each other and SFP1 |
| SFP1 (AP trunk) | `strict` | `only tagged` | 1 | 13–16 |
| 17 (NVR), 18 (Kuca camera) | `strict` | `only untagged` | 20 | Each other and 19–24 |
| 19–24 (cameras) | `strict` | `only untagged` | 20 | 17 and 18 only |

| VLAN | Name | Members | VLAN-level Port Isolation |
| :--- | :--- | :--- | :--- |
| 1 | (none) | 1–12, SFP2 | Off |
| 2 | `home_wifi` | 13–16, SFP1 | On |
| 4 | `iot` | 13–16, SFP1 | On |
| 20 | `cam` | 17–24 | On |
| 30 | `ap_mgmt` | 13–16, SFP1 | On |

AP ports send their own management traffic untagged, which lands on VLAN 30. Wi-Fi client traffic arrives from the AP already tagged 2 or 4.

SFP1 must stay out of VLAN 1. If it joins VLAN 1, the `perimiter` and `home_lan` bridges get joined through the switch. APs stay in the same isolation group so Wi-Fi clients on different APs can reach each other.

The CSS326 has no PoE. Camera and AP power stays on the PoE Texas midspan; only the data-side patch moves onto these ports.

---

## **House LAN Switch: TP-Link TL-SG1024**
* **Type:** Unmanaged Gigabit
* **Role:** Distribution for the 192.168.89.x subnet and IoT traffic.
* **Uplink:** Connected to hAP ac (Port 5).

### **High-Traffic Port Mapping**
| Port | Connected Device | Role |
| :--- | :--- | :--- |
| **6** | Beelink EQ14 (NIC 2) | UniFi Inform (ports 8080 and 8880) |
| **10** | Pine64 | MQTT Broker (192.16