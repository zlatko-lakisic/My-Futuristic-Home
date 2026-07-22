# HACS Plugins and Custom Components

Installed HACS integrations and Lovelace plugins on the live Home Assistant host (Jul 2026), with architecture placement and what each is used for.

Wiki mirror: [Home Assistant HACS Plugins](https://github.com/zlatko-lakisic/My-Futuristic-Home/wiki/Home-Assistant-HACS-Plugins).

## Purpose

Separate the custom stack from core integrations. Core/UI integrations are in [Integrations Catalog](integrations_catalog.md). This page is the HACS-installed set from `.storage/hacs.repositories` plus how each piece is used.

## Architecture placement

```
HACS store
  |
  +-- Integrations (custom_components/) ---- entities, services, packages
  |         |
  |         +-- radios / climate / NVR / infra / watering / locks helpers
  |
  +-- Lovelace plugins (www/community/) ---- dashboard cards
  |
  +-- Themes / templates (if any)
```

Owner-maintained forks used in production:

| Repo | Role |
| :--- | :--- |
| [hacs-agentic-watering](https://github.com/zlatko-lakisic/hacs-agentic-watering) | Irrigation LLM pipeline + blueprint + packages |
| [hacs-msnswitch](https://github.com/zlatko-lakisic/hacs-msnswitch) | PDU power watchdogs |
| [hacs-mikrotik_router](https://github.com/zlatko-lakisic/hacs-mikrotik_router) | RouterOS integration fork (login fix / sync) |

## Integrations (custom_components)

### Automation and AI

| Package | Version | Used for | Architecture slot |
| :--- | :--- | :--- | :--- |
| `hacs/integration` | 2.0.5 | HACS itself | Store |
| `zlatko-lakisic/hacs-agentic-watering` | v1.2.0 | Dusk/dawn sequential watering scripts, REST, blueprint | Irrigation AI |
| `valentinfrlch/ha-llmvision` | v1.7.0 | Gate/camera vision analysis actions | Vision / notify |
| `blakeblackshear/frigate-hass-integration` | v5.15.4 | Frigate cameras and MQTT entities in HA | NVR |
| `AlexxIT/WebRTC` | v3.6.1 | Low-latency camera streams in Lovelace | NVR UI |

### Climate and home comfort

| Package | Version | Used for | Architecture slot |
| :--- | :--- | :--- | :--- |
| `jcwillox/hass-template-climate` | v1.4.0 | `climate_template` platform for unified living-room climate | Climate facade |
| `wuwentao/midea_ac_lan` | v0.6.12 | Living-room Midea mini-split over LAN | Cool path |
| `mac-zhou/midea-ac-py` | v0.2.3 | Alternate Midea integration present on disk | Spare / legacy |
| `nbogojevic/homeassistant-midea-air-appliances-lan` | v0.9.6 | Midea dehumidifier / appliance LAN | Spare / optional |

### Irrigation and water

| Package | Version | Used for | Architecture slot |
| :--- | :--- | :--- | :--- |
| `sebr/bhyve-home-assistant` | 4.1.2 | Orbit BHyve valves and zones | Actuation |
| `wbyoung/watersmart` | v0.1.9 | Water utility / usage data | Metering |

### Networking and infrastructure

| Package | Version | Used for | Architecture slot |
| :--- | :--- | :--- | :--- |
| `zlatko-lakisic/hacs-mikrotik_router` | v2.3.0 | MikroTik Home + Mostar RouterOS sensors | Network monitoring |
| `probert94/ha-switchos` | 0.0.9 | MikroTik SwitchOS | Switching metrics |
| `zlatko-lakisic/hacs-msnswitch` | v1.0.6 | UIS PDU outlet watchdogs | Power recovery |
| `dougiteixeira/proxmoxve` | 4.0.2 | Proxmox VMs/LXCs | Hypervisor |
| `tomaae/homeassistant-openmediavault` | v1.4.2 | NAS1 / NAS2 | Storage health |
| `soulripper13/hass-speedtest-ookla` | v3.0.5 | WAN speedtest helper | Network ops |

### Brands, local IoT, misc devices

| Package | Version | Used for | Architecture slot |
| :--- | :--- | :--- | :--- |
| `rospogrigio/localtuya` | v5.2.5 | Local Tuya devices | Local IoT |
| `LaggAt/hacs-govee` | 2025.7.1 | Govee lights/sensors | Lighting |
| `KiraPC/ha-switchbot-remote` | 1.3.7 | Office Hub Mini IR remotes | IR control |
| `iMicknl/ha-nest-protect` | v0.4.4 | Nest Protect smoke/CO (entry currently setup_error) | Safety |
| `ollo69/ha-smartthinq-sensors` | v0.43.0 | LG ThinQ (config entry disabled) | Appliances |
| `thomasloven/hass-browser_mod` | v3.1.0 | Browser/kiosk helpers | UI |
| `elad-bar/ha-hpprinter` | v2.0.6 | HP printer extras | Print |
| `marcolivierarsenault/moonraker-home-assistant` | 1.13.4 | 3D printer Moonraker | Workshop |
| `RobertD502/home-assistant-whistle` | 0.2.0 | Whistle pet tracker | Pets |
| `viktak/ha-cc-openweathermap_all` | d2f52ca | Extra OpenWeatherMap API surface | Weather |

## Lovelace plugins (frontend)

Used by dashboards under `homeassistant/dashboards/` (especially infrastructure, backyard, home control).

| Package | Version | Used for |
| :--- | :--- | :--- |
| `dermotduffy/advanced-camera-card` | v7.27.4 | Frigate / camera cards |
| `custom-cards/button-card` | v7.0.1 | Custom buttons and status tiles |
| `custom-cards/stack-in-card` | 0.2.0 | Nested card stacks |
| `ofekashery/vertical-stack-in-card` | v1.0.1 | Vertical stacking inside a card |
| `thomasloven/lovelace-auto-entities` | v1.16.1 | Dynamic entity lists |
| `thomasloven/lovelace-layout-card` | v2.4.7 | Grid / layout |
| `cataseven/Statistics-Graph-Chart-Card` | v3.30 | Irrigation / history charts |
| `selvalt7/modern-circular-gauge` | v0.14.1 | Gauge visuals |
| `nutteloost/simple-swipe-card` | v3.1.0 | Swipeable card groups |
| `NemesisRE/kiosk-mode` | v14.0.1 | Wall tablet / kiosk chrome hiding |

## Packages shipped by HACS integrations

| Include (from `configuration.yaml`) | Origin |
| :--- | :--- |
| `custom_components/agentic_watering/packages/rest_command_ai_watering.yaml` | Agentic Watering |
| `custom_components/agentic_watering/packages/smart_sequential_watering_script.yaml` | Agentic Watering |

Site-owned packages stay in `homeassistant/packages/` (Glances hosts, irrigation instance, BHyve helpers, etc.). See wiki Packages page.

## Related

- [Integrations Catalog](integrations_catalog.md)
- [Automations Catalog](automations_catalog.md)
- [Scripts Catalog](scripts_catalog.md)
- [Garden Agentic Watering](garden_agentic_watering.md)
- [Unified Climate Control](unified_climate_control.md)
