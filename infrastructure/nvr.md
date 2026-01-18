# 📹 Surveillance: NVR Server

## **Overview**
The NVR server runs a containerized stack centered around **Frigate** for video analytics. It utilizes the NVIDIA RTX A4000 for TensorRT-accelerated object detection and facial recognition.

## **Hardware Specifications**
- **CPU:** Intel Core i7-8700T (6-core/12-thread)
- **RAM:** 16GB DDR4
- **GPU:** **NVIDIA RTX A4000 (16GB GDDR6)** — Dedicated to AI inference and hardware transcoding.
- **Internal Storage:** 450GB Boot Drive (OS & Docker Configs).
- **External Storage:** NAS1 & NAS2 via Network File System (NFS).

## **GPU Setup & Verification**
The GPU is passed directly from the host to Docker containers using the NVIDIA Container Toolkit.
- **Verification Command:** `nvidia-smi`
- **Official Driver Link:** [NVIDIA RTX A4000 Drivers](https://www.nvidia.com/en-us/drivers/)
- **Official CUDA Link:** [CUDA Toolkit Documentation](https://developer.nvidia.com/cuda-toolkit)

## **Software Stack**
- **OS:** Ubuntu 24.04 LTS
- **Engine:** Docker (Containerized NVR software)

## **Network Configuration**
The NVR uses three distinct physical interfaces to optimize traffic flow:

| Interface | Connection | IP Address | Role |
| :--- | :--- | :--- | :--- |
| **Eth 3** | Perimeter Switch | `10.0.10.6` | Web UI / Management |
| **Eth 4** | House LAN Switch | `192.168.89.37` | Camera Ingestion (VLAN 4) |
| **Eth 7** | **NAS2 Port 2** | `172.16.100.2` | **Direct-Attach Storage (NFS)** |

## **Remote Storage Configuration (`/etc/fstab`)**
To ensure the NVR consistently mounts storage from both NAS units without stalling the boot process, the following entries are used. This configuration leverages `systemd` automount logic and the high-speed direct-attach link to NAS2.

### **Production FSTAB Entries**
```text
# NAS2 Direct-Attach Storage (NVR Video Files)
172.16.100.1:/export/nvr    /nfs/nvr    nfs x-systemd,auto,nofail,noatime,nolock,intr,tcp,actimeo=1800 0 0

# NAS1 Perimeter Storage (General Share/Backups)
10.0.10.3:/export/PublicShare2    /nfs/publicshare2    nfs x-systemd,auto,nofail,noatime,nolock,intr,tcp,actimeo=1800 0 0
```

## **Service Mapping**
This infrastructure hosts the [Frigate Service](../services/frigate.md), which manages the application-level logic, AI detection, and recording rules.

## **Docker Infrastructure**
- **Internal Network:** `box-network` (`172.20.0.0/24`)
- **Base Directory:** `/var/docker/` (for local configs)
- **Data Directory:** `/nfs/nvr/data/` (Remote mount on NAS2 via Direct-Link)

### **Container Inventory**

| Service | Container Name | Internal IP | Role |
| :--- | :--- | :--- | :--- |
| **Frigate** | `frigate` | `172.20.0.3` | Core NVR, TensorRT Detection |
| **Double Take** | `double-take` | `172.20.0.4` | Unified AI facial recognition logic |
| **CompreFace** | `compreface-ui` | `172.20.0.5` | Facial Recognition API & UI |
| **CodeProject.AI**| `codeproject-ai-server` | `172.20.0.6` | General AI inference (CUDA) |
| **InfluxDB** | `influx-db2` | `172.20.0.8` | Time-series data storage |
| **Grafana** | `grafana` | `172.20.0.10` | Analytics Dashboards |
| **Mosquitto** | `mqtt5` | `Dynamic` | Message broker for system events |

## **AI Configuration (NVIDIA A4000)**
The stack is configured to leverage the 16GB VRAM of the A4000:
- **Frigate:** Uses `stable-tensorrt` image with GPU reservations for `compute,utility,video`.
- **CodeProject.AI:** Uses `cuda12_2` for hardware acceleration.
- **Shared Memory:** `shm_size: 512mb` for high-resolution stream processing.


## **Volume Mapping Logic**
Data is logically split between the local internal drive (configs) and the NAS2 array (heavy data).

| Local Path (`/var/docker/`) | Container Path | Purpose |
| :--- | :--- | :--- |
| `./frigate` | `/config` | Frigate YAML and Database |
| `./mosquitto` | `/mosquitto/config` | MQTT auth and config |
| `./influxdb2` | `/etc/influxdb2` | DB configuration |

| NAS Path (`/nfs/nvr/data/`) | Container Path | Purpose |
| :--- | :--- | :--- |
| `./frigate/recordings` | `/media/frigate/recordings` | 24/7 Video Archive |
| `./compreface/data` | `/var/lib/postgresql/data` | Facial DB |
| `./grafana` | `/var/lib/grafana` | Persistent Dashboards |

## **Security & Secrets**
The stack utilizes Docker Secrets for sensitive credentials located at `/var/docker/<service>/.env.*`:
- `influxdb2-admin-token`
- `frigate-rtsp-password` (for camera authentication)
- `telegraf-mqtt-password`

## **Software Stack (Docker Compose)**
The stack is deployed using a custom `box-network` to isolate AI inference traffic from the rest of the management plane.

```yaml
version: "3.9"

networks:
  box-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/24

services:
  frigate:
    container_name: frigate
    image: ghcr.io/blakeblackshear/frigate:stable-tensorrt
    privileged: true
    restart: unless-stopped
    shm_size: "128mb"
    devices:
      - /dev/nvidia0:/dev/nvidia0
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /var/docker/frigate/config:/config
      - /nfs/nas2_storage/frigate:/media/frigate
      - type: tmpfs
        target: /tmp/cache
        tmpfs:
          size: 1000000000
    ports:
      - "5000:5000"
      - "8554:8554" # RTSP feeds
    environment:
      - FRIGATE_RTSP_PASSWORD=password
      - NVIDIA_VISIBLE_DEVICES=all
      - NVIDIA_DRIVER_CAPABILITIES=all
    networks:
      box-network:
        ipv4_address: 172.20.0.3

  codeproject-ai:
    container_name: codeproject-ai
    image: codeproject/ai-server:cuda12_2
    restart: unless-stopped
    environment:
      - TZ=America/New_York
    volumes:
      - /var/docker/codeproject/etc:/etc/codeproject/ai
      - /var/docker/codeproject/opt:/opt/codeproject/ai
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
    networks:
      box-network:
        ipv4_address: 172.20.0.6

  double-take:
    container_name: double-take
    image: skrashevich/double-take:latest
    restart: unless-stopped
    volumes:
      - /var/docker/double-take://.storage
    ports:
      - "3001:3001"
    networks:
      box-network:
        ipv4_address: 172.20.0.4

  influxdb:
    container_name: influxdb
    image: influxdb:latest
    restart: unless-stopped
    volumes:
      - /var/docker/influxdb/data:/var/lib/influxdb2
    networks:
      box-network:
        ipv4_address: 172.20.0.8

  grafana:
    container_name: grafana
    image: grafana/grafana:latest
    restart: unless-stopped
    volumes:
      - /var/docker/grafana/data:/var/lib/grafana
    ports:
      - "3000:3000"
    networks:
      box-network:
        ipv4_address: 172.20.0.10