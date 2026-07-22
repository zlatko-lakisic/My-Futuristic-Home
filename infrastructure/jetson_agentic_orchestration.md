# Omega Jetson Orin — Agentic Orchestration

Edge AI host for the smart-home LLM endpoint used by garden watering and the Agentic Orchestration chat UI.

## Identity

| Item | Value |
|------|--------|
| Hostname | `omega-jetson-orin.mostardesigns.com` |
| LAN IP | `172.16.90.20` (IoT WLAN `wlP1p1s0`) |
| SSH | `zlatko.lakisic@172.16.90.20` |
| Hardware | NVIDIA Jetson Orin (arm64, ~61 GiB RAM, 12 cores) |
| Power | Basement MSNSwitch outlet **Omega Jetson** ([hacs-msnswitch](https://github.com/zlatko-lakisic/hacs-msnswitch)) |

## Source repo

- GitHub: [zlatko-lakisic/agentic-orchestration](https://github.com/zlatko-lakisic/agentic-orchestration)
- On-device checkout: `/var/projects/agentic-orchestration`
- Routine deploy (on device):

```bash
bash /var/projects/agentic-orchestration/agentic-orchestration-tool/scripts/jetson-deploy.sh
```

That script **git pulls** `origin/main`, applies env, rolls the coordinator, syncs the k8s secret, and reapplies web/tool hotfixes. Do not SCP application trees onto the device.

## Runtime stack (verified Jul 2026)

| Layer | Detail |
|-------|--------|
| OS | Ubuntu 22.04, kernel `5.15.148-tegra` |
| k3s | Single-node control-plane, `v1.36.2+k3s1`, Docker runtime |
| Namespace | `agentic-orchestration` |
| Coordinator | `ghcr.io/zlatko-lakisic/agentic-orchestrator-coordinator:v1.12.0` — NodePort **30487** → container `3847` |
| Warm pool | `…-worker:v1.12.0` (2 replicas; may crash-loop if hotfix ConfigMaps drift from image — see ops notes) |
| Delegation broker | Running |
| Git HEAD | tracks `main` (e.g. `v1.14.0` tag line + later commits) |
| Ollama | `ollama.service` active, listen `*:11434`, OpenAI-compat `/v1/models` |
| Execution backend | `AGENTIC_EXECUTION_BACKEND=kubernetes` |
| Edge flag | `AGENTIC_EDGE_PLATFORM=jetson`, `AGENTIC_ASSUME_GPU=1`, planner `ollama/llama3.2:3b` |

### Useful checks

```bash
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
kubectl get pods,svc,deploy -n agentic-orchestration -o wide
curl -sS http://127.0.0.1:30487/api/host-metrics
curl -sS http://127.0.0.1:30487/api/ping
curl -sS http://127.0.0.1:11434/api/tags
curl -sS http://127.0.0.1:11434/v1/models
```

## Ingress

| URL | Path |
|-----|------|
| `https://ai-orchestrator.mostardesigns.com` | Traefik → Warpgate (UI) / IP-bypass for `/v1/*` → `172.16.90.20:30487` |
| LAN | `http://172.16.90.20:30487/` |

Auth and LDAP header injection for the UI are documented in the Traefik stack:

- Homelab compose: [docker-infrastructure Traefik README](https://git.omega-it.solutions/omegait/docker-infrastructure) (`ai-orchestrator.mostardesigns.com`)
- Local mirror notes: [services/traefik.md](../services/traefik.md)

Home Assistant watering uses:

```text
https://ai-orchestrator.mostardesigns.com/v1/chat/completions
```

(see [homeassistant/docs_ha/garden_agentic_watering.md](../homeassistant/docs_ha/garden_agentic_watering.md)).

## HostPath / Jetson overlays

Coordinator mounts (among others):

- `/var/projects/agentic-orchestration/agentic-orchestration-tool/config/mcp_providers` — includes Home Assistant MCP YAML
- `…/extras/plant-knowledge-mcp/config` — plant knowledge MCP
- `…/config/rag_sources`, `…/config/agent_skills_jetson`, `…/mcp_servers`
- OpenClaw workspace + MCP provider dirs under `~/.openclaw/`
- Hotfix ConfigMaps for web + orchestration Python (applied by `jetson-hotfix-web.sh`)

Env highlights (non-secret): `HOME_ASSISTANT_URL=https://ha.mostardesigns.com`, `OLLAMA_API_BASE=http://host.k3s.internal:11434`, `PLANT_KNOWLEDGE_MCP_URL=http://plant-knowledge-mcp.plant-knowledge.svc.cluster.local:8080/mcp`.

## Ops notes

- **Warm pool crash-loop:** if workers fail with `ModuleNotFoundError: orchestration.crewai_mcp_normalize`, the hotfix ConfigMap `runner.py` (or related) is ahead of modules inside the `v1.12.0` worker image. Re-run deploy after aligning image tag with git, or temporarily disable warm pool / pin hotfix set. Coordinator can still serve the UI while warm pool is unhealthy.
- **Model inventory:** pull the models HA expects (`input_select.ai_dusk_watering_ollama_model`) onto this host’s Ollama before dusk irrigation relies on them. As of Jul 2026 interrogation, tags showed primarily `llama3.2:3b`.
- **Glances:** HA infrastructure dashboard entities `sensor.omega_jetson_orin_*` — may show unavailable if the Glances agent is down; k3s host-metrics API remains authoritative for the orchestrator UI.
- **Never commit** `.env` / `agentic-orchestrator-env` secret values into My-Futuristic-Home.

## Related

- [agentic-orchestration](https://github.com/zlatko-lakisic/agentic-orchestration) — product README, k8s manifests, Jetson scripts
- [hacs-agentic-watering](https://github.com/zlatko-lakisic/hacs-agentic-watering) — HA consumer of `/v1/chat/completions`
- [infrastructure/msn_switches.md](msn_switches.md) — power path for this host
