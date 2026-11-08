# 📶 Wireless Infrastructure (UniFi)

The wireless layer is powered by Ubiquiti UniFi Access Points, managed by a self-hosted controller.

## **Access Point Inventory**
All APs are wired to CSS326 ports 13–16 on AP management VLAN 30 (`10.0.30.0/28`), with reservations on the MikroTik hAP ac. Wi-Fi client traffic stays tagged on VLANs 2 and 4 and reaches the router over the SFP1 trunk. The CSS326 has no PoE, so AP power stays on the midspan.

| AP | MAC | Address | CSS326 port |
| :--- | :--- | :--- | :--- |
| **Bottom Floor** | `78:45:58:80:78:EE` | `10.0.30.5` | 13 |
| **Backyard** | `F4:E2:C6:19:BF:A2` | `10.0.30.3` | 14 |
| **Top Floor** | `78:45:58:80:7F:6C` | `10.0.30.4` | 15 |

Port 16 is open for another AP. An older inventory listed nanoHDs in the Basement, Office and Top Hallway, plus a UAP-AC-M-US in the Backyard. Only the three APs above were on the network on 2026-11-08.

## **Controller Configuration**
The UniFi Controller runs as a Docker container on the **Networking Server (10.0.10.6)**.

## ⚠️ Custom Port Configuration
The controller answers inform on both `8080` and `8880`. The three current APs use `8080`; the Kuca `ap-inform` firewall rule allows both.

**Impact:**
- APs on VLAN 30 reach the controller at `192.168.89.6` through the MikroTik hAP ac, so inform traffic is routed. It is small, and Wi-Fi client traffic does not take this path to the controller.
- New APs on ports 13–16 get a VLAN 30 address. Adopt them with:
  `set-inform http://192.168.89.6:8080/inform`

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
      - "192.168.89.6:8880:8880"    # Device Inform (House LAN IP). 8080 also answers live; check the running compose file
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