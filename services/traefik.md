# 🛣 Service: Traefik Edge Proxy

## **Overview**
Traefik runs as a service on the [Beelink EQ14](../infrastructure/hardware.md). It handles all network ingress and manages Let's Encrypt SSL certificates.

## **Ingress Architecture**
Traefik is configured with multiple entrypoints to handle web traffic and secure mail protocols.

| Entrypoint | Port | Protocol | Purpose |
| :--- | :--- | :--- | :--- |
| **Web** | `80` | HTTP | Redirects to HTTPS (:443) |
| **WebSecure** | `443` | HTTPS | Primary SSL Ingress for all services |
| **Dashboard** | `8080` | HTTP | Admin UI (Bound to `10.0.10.6`) |
| **IMAPS** | `993` | TCP | Secure Mail Retrieval |
| **SMTPS** | `587` | TCP | Secure Mail Submission |

## **SSL & ACME Configuration**
The system uses **Let's Encrypt** for automated certificate management. 

- **Storage:** All certificate metadata is stored in `/etc/traefik/letsencrypt/acme.json`.
- **Resolvers:** Configured via command-line arguments and `traefik.yaml`.
- **API Access:** The Traefik dashboard is restricted to the internal Perimeter subnet (`10.0.10.6`) to prevent external exposure.



## **Certificate Distribution (NFS Backplane)**
A unique feature of this infrastructure is the centralized certificate distribution. Because Traefik handles the challenges, other servers (NVR, NAS, Proxmox) do not need to run their own ACME clients.

### **The Dumper Logic**
The `traefik-certs-dumper` service monitors `acme.json` and extracts the raw `.crt` and `.key` files.

1. **Extraction:** Dumper watches for changes in the JSON file.
2. **Transfer:** Extracted files are written to the NFS mount: `/nfs/publicshare2/certs`.
3. **Consumption:** Internal services mount this NFS share to stay updated with valid, non-expired certificates.

## **Static Configuration Summary**
Traefik is initialized with the following logic:
- **Docker Provider:** Enabled (`--providers.docker=true`).
- **Isolation:** `exposedbydefault=false` ensures only explicitly labeled containers are proxied.
- **Log Level:** Set to `DEBUG` for granular troubleshooting of routing matches.

## **Dynamic Routing**
The proxy monitors `/etc/traefik/dynamic` for manual file-based routing rules, allowing us to proxy non-containerized services (like the MikroTik WebFig or Proxmox UI) through the central Traefik ingress.

### **ai-orchestrator.mostardesigns.com**
Public edge for the Jetson Agentic Orchestration UI/API (`172.16.90.20:30487`). Warpgate authenticates browser sessions; LAN clients can call `/v1/*` (OpenAI-compatible chat) with Traefik IP bypass for Home Assistant watering. Authoritative Traefik compose docs live in [docker-infrastructure](https://git.omega-it.solutions/omegait/docker-infrastructure.git). Device-side detail: [infrastructure/jetson_agentic_orchestration.md](../infrastructure/jetson_agentic_orchestration.md). Irrigation consumer: [garden_agentic_watering.md](../homeassistant/docs_ha/garden_agentic_watering.md) / [hacs-agentic-watering](https://github.com/zlatko-lakisic/hacs-agentic-watering).

## **Deployment Configuration**
The following Docker Compose stack defines the Traefik edge proxy and the automated certificate extraction logic.

## **Implementation**
```yaml
volumes:
  traefik-dynamic:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /etc/traefik/dynamic
  traefik-letsencrypt:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /etc/traefik/letsencrypt
  traefik-letsencrypt-dumper:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /nfs/publicshare2/certs

services:
  traefik:
    container_name: traefik
    image: "traefik:latest"
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
      - "993:993"
      - "587:587"
      - "10.0.10.6:8080:8080"
    volumes:
      - traefik-dynamic:/etc/traefik/dynamic
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
      - "/etc/traefik/traefik.yaml:/etc/traefik/traefik.yaml:ro"
      - traefik-letsencrypt:/letsencrypt
      - "/etc/traefik/traefik.log:/etc/traefik/traefik.log"
    command:
      - "--log.level=DEBUG"
      - "--api.insecure=true"
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entryPoints.web.address=:80"
    deploy:
      replicas: 1
      restart_policy:
        condition: any
      update_config:
        parallelism: 1
        delay: 10s
        failure_action: pause
        monitor: 10s
        max_failure_ratio: 0.3
        order: start-first

  traefik-certs-dumper:
    container_name: "traefik-certs-dumper"
    image: ldez/traefik-certs-dumper:latest
    restart: unless-stopped
    entrypoint: sh -c '
      while ! [ -e /data/acme.json ]
      || ! [ `jq ".[] | .Certificates | length" /data/acme.json | jq -s "add" ` != 0 ]; do
      sleep 1
      ; done
      && traefik-certs-dumper file --version v2 --watch
      --source /data/acme.json --dest /data/certs'
    volumes:
      - "/etc/traefik/letsencrypt/acme.json:/data/acme.json:ro"
      - traefik-letsencrypt-dumper:/data/certs
    network_mode: "none"