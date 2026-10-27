# 📷 Infrastructure: Security Cameras

## **Overview**
The surveillance network consists of 8 high-definition IP cameras. They are still patched through the PoE Texas midspan into the house LAN switch. The data side of that midspan is what moves onto CSS326 VLAN 20. All video feeds are ingested by Frigate on the [NVR Server](../services/nvr.md).



## **Network Configuration**
The cameras are still on the house LAN and still answer at the addresses below. A separate camera segment is already configured and waiting for the data patches to move.

- **Current subnet:** `192.168.89.0/24` (`home_dhcp` on Kuca). Every live camera is a DHCP client. A MikroTik reservation only pins the address; it is not a static address configured on the camera.
- **Prepared subnet:** `10.0.20.0/28` on Kuca `ether4` (`10.0.20.1/28`). DHCP pool `10.0.20.3–10.0.20.12`. CSS326 ports 13–24 are VLAN 20 access ports. Port 14 is the uplink from `ether4`. Port 13 is NVR `enp8s0` at `10.0.20.2/28`.
- **Ingest today:** Frigate, on bridge `br-cam` (`192.168.89.37`), pulls the RTSP URLs below. `enp11s0` is also a member of `br-cam` and must stay off the new subnet.

## **Camera Inventory**

| ID | Location | Model | IP Address | MAC | Primary Stream Path (RTSP) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **CAM-01** | Driveway | AXIS P3375-VE | `10.0.20.8` | `B8:A4:4F:3D:5F:B9` | `/axis-media/media.amp` |
| **CAM-02** | Garden North | AXIS P1448-LE | `192.168.89.12` | `B8:A4:4F:42:64:7E` | `/axis-media/media.amp` |
| **CAM-03** | East Side | UniFi Video (G3 Flex) | `192.168.89.14` | `D0:21:F9:97:6E:DA` | `:554/s2` |
| **CAM-04** | Front Door | UniFi Video (G3 Flex) | `10.0.20.4` | `D0:21:F9:97:6D:18` | `:554/s2` |
| **CAM-05** | Garden South | AXIS P1448-LE | `192.168.89.20` | `B8:A4:4F:42:66:6E` | `/axis-media/media.amp` |
| **CAM-06** | Basement | UniFi Video (G3 Flex) | `192.168.89.22` | `D0:21:F9:97:6D:9F` | `:554/s2` (go2rtc only) |
| **CAM-07** | Back Yard | AXIS P3375-VE | `10.0.20.3` | `B8:A4:4F:3D:5C:96` | `/axis-media/media.amp` |
| **CAM-08** | West Side | AXIS P3375-VE | `10.0.20.7` | `B8:A4:4F:3D:5F:C3` | `/axis-media/media.amp` |

## **Integration Logic**

### **1. Axis Cameras (Domes & Bullets)**
The Axis units utilize the VAPIX API. Frigate is configured to pull H.264/H.265 streams using the `media.amp` endpoint. These units are highly reliable and handle the majority of the perimeter detection.

### **2. UniFi Video cameras (standalone)**
Front Door, East Side, and Basement serve a UniFi Video page and a direct RTSP stream on port 554 (`/s2`). They are not adopted to UniFi Protect. Front Door is `192.168.89.9`. `192.168.89.17` is NAS2’s house address, not a camera. Basement is defined in go2rtc and is not a Frigate `cameras:` entry. Two older UniFi reservations, `Back-Yard` `192.168.89.10` and `West-Side` `192.168.89.15`, have been offline for months and are not part of the move.

### **3. NVR Ingest**
The [NVR Server](../services/nvr.md) uses its [NVIDIA RTX A4000](../infrastructure/nvr.md) to decode these 8 streams simultaneously. 
- **Detection:** Performed on sub-streams to reduce GPU load.
- **Recording:** 24/7 high-resolution storage is sent to [NAS2](../storage/nas2.md).