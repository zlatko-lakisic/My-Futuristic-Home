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

## ⚠️ Custom Port Configuration
The standard port `8080` was conflicted or restricted, so the controller has been migrated to `8880` for device communication.

**Impact:**
- Any new AP adoption must use the manual command: 
  `set-inform http://192.168.89.6:8880/inform`
- This ensures traffic stays on the **House LAN (192.168.89.6)** and avoids hitting the **MikroTik hAP ac** CPU for routing.

### `docker-compose.yml` (Snippet)
```yaml
services:
  unifi-network-application:
    image: lscr.io/linuxserver/unifi-network-application:latest
    container_name: unifi-network-application
    restart: unless-stopped
    depends_on:
      unifi-db:
        condition: service_healthy
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
      - MONGO_USER=unifi
      - MONGO_PASS=unifi_db_password_change_me  # Sanitize this in production
      - MONGO_HOST=unifi-db
      - MONGO_PORT=27017
      - MONGO_DBNAME=unifi
      - MEM_LIMIT=1024
      - MEM_STARTUP=1024
    volumes:
      - /var/unifi-network-application/data:/config
    ports:
      - "10.0.10.6:8443:8443"       # Web UI (Perimeter IP)
      - "192.168.89.6:8880:8880"    # NEW: Device Inform (House LAN IP)
      - "3478:3478/udp"             # STUN
      - "10001:10001/udp"           # Discovery
      - "6789:6789"                 # Speed Test (Optional)
      - "5514:5514/udp"             # Remote Syslog (Optional)

  unifi-db:
    image: mongo:4.4
    container_name: unifi-db
    restart: unless-stopped
    environment:
      - MONGO_INITDB_ROOT_USERNAME=admin
      - MONGO_INITDB_ROOT_PASSWORD=admin_password_change_me
      - MONGO_USER=unifi
      - MONGO_PASS=unifi_db_password_change_me
      - MONGO_DBNAME=unifi
    volumes:
      - /var/unifi-network-application/mongodb/data:/data/db
      - /var/unifi-network-application/mongodb/init-mongo.sh:/docker-entrypoint-initdb.d/init-mongo.sh:ro
    healthcheck:
      test: ["CMD", "mongo", "--eval", "db.adminCommand('ping')"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s