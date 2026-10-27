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
Checked live 2026-10-27 after the camera VLAN change. Ports not listed below keep their previous names.

| Port | Name | Learned device | Purpose |
| :--- | :--- | :--- | :--- |
| **1** | Mikrotik | hAP ac | Uplink to Kuca ether2, VLAN 1 |
| **3** | Frigate | NVR `enp3s0` `10.0.10.16` | NVR management. Stays on VLAN 1 |
| **4** | (unnamed) | NAS1 `10.0.10.3` | Storage management |
| **6** | Proxmox | Proxmox `10.0.10.11` | Home Assistant bounces this port when the host stops answering |
| **9** | Port9 | NAS2 `10.0.10.17` | Moved off port 13. Stays on VLAN 1 |
| **10** | Port10 | Beelink `10.0.10.6` | Traefik / UniFi host. Stays on VLAN 1 |
| **13** | NVR | NVR `enp8s0` `10.0.20.2/28` at 1G | Camera ingest on VLAN 20 |
| **14** | Kuca | Kuca `ether4` at 1G | Camera DHCP uplink `10.0.20.1/28` |
| **15–20** | Port15–Port20 | Nothing learned | Open camera drops. The CSS326 is not PoE |
| **21** | Driveway | Driveway `B8:A4:4F:3D:5F:B9` at 100M | Axis P3375-VE |
| **22** | BackYard | Back Yard `B8:A4:4F:3D:5C:96` at 100M | Axis P3375-VE, `10.0.20.3` |
| **23** | WestSide | West Side `B8:A4:4F:3D:5F:C3` at 100M | Axis P3375-VE, `10.0.20.7` |
| **24** | FrontDoor | Link at 100M, MAC not in the table | Front Door lease is `10.0.20.4` |
| **SFP+ 1–2** | SFP1, SFP2 | Open | Stay on VLAN 1 |

### **VLAN Settings (SwOS)**
Ports 1–12 and both SFP ports stay VLAN mode `optional`, VLAN receive `any`, default VLAN ID `1`.

Ports 13–24 are the camera access VLAN:

* **VLAN mode:** `strict`
* **VLAN receive:** `only untagged`
* **Default VLAN ID:** `20`
* **VLAN 20 members:** ports 13–24 only (`mbr 0x00fff000`)
* **VLAN 1 members:** ports 1–12 and both SFPs (`mbr 0x03000fff`)

Port forwarding masks match that split, so a camera port cannot exchange frames with a VLAN 1 port. The CSS326 has no PoE. Camera power stays on the PoE Texas midspan; only the data-side patch moves onto the open VLAN 20 ports. Kuca `ether4` goes to port 14 and NVR `enp8s0` goes to port 13.

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