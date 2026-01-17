# 📷 Infrastructure: Security Cameras

## **Overview**
The surveillance network consists of 8 high-definition IP cameras. These are physically wired through a central patch panel into the **Home_LAN Switch**. All video feeds are ingested directly by a **Frigate NVR** container running on the [NVR Server](../services/nvr.md).



## **Network Configuration**
- **VLAN:** 2 (Home LAN)
- **Subnet:** `192.168.89.x`
- **Ingest Method:** RTSP streams are pulled directly into Docker via the host network.

## **Camera Inventory**

| ID | Location | Model | IP Address | Primary Stream Path (RTSP) |
| :--- | :--- | :--- | :--- | :--- |
| **CAM-01** | Driveway | AXIS P3375-VE | `192.168.89.11` | `/axis-media/media.amp` |
| **CAM-02** | Garden North | AXIS P1448-LE | `192.168.89.12` | `/axis-media/media.amp` |
| **CAM-03** | East Side | UniFi G3 Flex | `192.168.89.14` | `/s0` (Standalone Mode) |
| **CAM-04** | Front Door | UniFi G3 Flex | `192.168.89.17` | `/s0` (Standalone Mode) |
| **CAM-05** | Garden South | AXIS P1448-LE | `192.168.89.20` | `/axis-media/media.amp` |
| **CAM-06** | Basement | UniFi G3 Flex | `192.168.89.22` | `/s0` (Standalone Mode) |
| **CAM-07** | Back Yard | AXIS P3375-VE | `192.168.89.30` | `/axis-media/media.amp` |
| **CAM-08** | West Side | AXIS P3375-VE | `192.168.89.31` | `/axis-media/media.amp` |

## **Integration Logic**

### **1. Axis Cameras (Domes & Bullets)**
The Axis units utilize the VAPIX API. Frigate is configured to pull H.264/H.265 streams using the `media.amp` endpoint. These units are highly reliable and handle the majority of the perimeter detection.

### **2. UniFi G3 Flex (Standalone Mode)**
Since these cameras are used without a UniFi Protect NVR, they are set to **Standalone Mode** via their web interface. This enables a direct RTSP stream on port 554, allowing Frigate to treat them as standard IP cameras.

### **3. NVR Ingest**
The [NVR Server](../services/nvr.md) uses its [NVIDIA RTX A4000](../infrastructure/nvr.md) to decode these 8 streams simultaneously. 
- **Detection:** Performed on sub-streams to reduce GPU load.
- **Recording:** 24/7 high-resolution storage is sent to [NAS2](../storage/nas2.md).