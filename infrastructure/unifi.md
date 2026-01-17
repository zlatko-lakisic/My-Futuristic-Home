# 📶 Wireless Infrastructure (UniFi)

The wireless layer is powered by Ubiquiti UniFi Access Points, managed by a self-hosted controller.

## **Access Point Inventory**
All APs are hardwired to the TP-Link TL-SG1024 and assigned static IPs via the MikroTik hAP ac.

| Location | Model | Subnet | Status |
| :--- | :--- | :--- | :--- |
| **Basement** | UniFi nanoHD | 192.168.89.x | Wired |
| **Office** | UniFi nanoHD | 192.168.89.x | Wired |
| **Top Hallway** | UniFi nanoHD | 192.168.89.x | Wired |
| **Backyard** | UAP-AC-M-US | 192.168.89.x | Outdoor/Wired |

## **Controller Configuration**
The UniFi Controller runs as a Docker container on the **Networking Server (10.0.10.6)**.

### `docker-compose.yml` (Snippet)
```yaml
services:
  unifi-controller:
    image: lscr.io/linuxserver/unifi-controller:latest
    container_name: unifi-controller
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
    volumes:
      - /path/to/config:/config
    ports:
      - 8443:8443 # GUI
      - 3478:3478/udp # STUN
      - 8080:8080 # Device Inform
    restart: unless-stopped