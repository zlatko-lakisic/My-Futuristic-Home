# 📹 Surveillance: NVR Server

## **Overview**
The NVR server runs a containerized stack centered around **Frigate** for video analytics. It utilizes the NVIDIA RTX A4000 for TensorRT-accelerated object detection and facial recognition.

## **Hardware Specifications**
- **CPU:** Intel Core i7-8700T (6-core/12-thread)
- **RAM:** 16GB DDR4
- **GPU:** **NVIDIA RTX A4000 (16GB GDDR6)** — Dedicated to AI inference and hardware transcoding.
- **Internal Storage:** 450GB Boot Drive (OS & Docker Configs).
- **External Storage:** NAS1 & NAS2 via Network File System (NFS).

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