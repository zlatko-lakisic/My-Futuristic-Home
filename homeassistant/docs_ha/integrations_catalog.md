# Home Assistant Integrations Catalog

Catalog of integrations configured on the live Home Assistant instance, grouped by purpose. Titles and states come from the HA config entry registry (Jul 2026 snapshot). Secrets and account emails are omitted.

Wiki mirror: [Home Assistant Integrations Catalog](https://github.com/zlatko-lakisic/My-Futuristic-Home/wiki/Home-Assistant-Integrations-Catalog).

## Purpose

Answer "what is connected, and what is it for?" without dumping entity lists. For mesh and perimeter device inventories see Device Networks docs. For living-room Nest+Midea unification see [Unified Climate Control](unified_climate_control.md).

## Snapshot summary

| Metric | Value |
| :--- | :--- |
| Config entries | 91 |
| Domains | 62 |
| HACS / custom_components present on host | See Custom / HACS section |

Entries marked **ignored** or **not_loaded** are discovery leftovers or intentionally unused. **setup_error** needs attention.

## Local radio and sensors

| Integration | Title / instance | State | What it is used for |
| :--- | :--- | :--- | :--- |
| `zwave_js` | Z-Wave JS | loaded | Wall switches, dimmers, fans, door contacts, Aeotec environmental sensor. See [Z-Wave Network](zwave_network.md). |
| `zha` | SONOFF Zigbee 3.0 USB Dongle Plus V2 | loaded | IKEA TRADFRI lighting, RODRET remotes, Aqara FP1E presence. See [Zigbee Lighting and Sensors](zigbee_lighting_sensors.md). |
| `yolink` | YoLink | loaded | Outdoor gate contact sensors (LoRa-family). See [LoRa Perimeter](lorawan_perimeter.md). |
| `ibeacon` | iBeacon Tracker | loaded | BLE beacon / phone presence tracking. |
| `bluetooth` path | (via iBeacon and ignored SwitchBot BLE) | | Physical dongle presence. SwitchBot Meter BLE entry is ignored. |

## Access and locks

| Integration | Title / instance | State | What it is used for |
| :--- | :--- | :--- | :--- |
| `august` | household August account | loaded | Yale smart locks (`lock.front_door`, `lock.back_door`, `lock.door_to_garage`, `lock.office_door`). Primary lock path for NFC entry. See [NFC Entry](nfc_entry.md). |
| `yalexs_ble` | Front Door / Back Door / Door to Garage / LF0001R | not_loaded (ignored) | BLE discovery of Yale locks. Not used. August/cloud path preferred. |
| `homekit_controller` | LF009W4 Door Lock, Smart Bridge 2 | not_loaded (ignored) | Unused HomeKit lock/bridge discovery. |

## Climate, irrigation, weather

| Integration | Title / instance | State | What it is used for |
| :--- | :--- | :--- | :--- |
| `nest` | Kuca | loaded | Google Nest account (speakers / Nest ecosystem). Thermostat entity expected by unified climate as `climate.living_room` was missing at this snapshot. |
| `midea_ac_lan` | Air Conditioning | loaded | Living-room Midea mini-split LAN control. Feeds unified climate cool path. |
| `climate_template` (HACS) | (YAML platform) | | Virtual `climate.new_livingroom_climate` and BHyve manual watering climate. See [Unified Climate Control](unified_climate_control.md). |
| `bhyve` | Orbit B-hyve account | loaded | Irrigation valves and zones for agentic / manual watering. |
| `agentic_watering` (HACS) | Agentic Watering | loaded | LLM dusk/dawn sequential watering. See [Garden Agentic Watering](garden_agentic_watering.md). |
| `ecowitt` | Ecowitt | loaded | Weather station / outdoor environmental data. |
| `met` | Home | loaded | Norwegian Met weather (onboarding default). |
| `open_meteo` | Home | loaded | Forecast / history inputs (also used by watering REST packages). |
| `co2signal` | CO2 Signal | loaded | Grid carbon intensity awareness. |
| `sun` | Sun | loaded | Sunrise/sunset triggers for lighting and irrigation windows. |

## Cameras, vision, AI

| Integration | Title / instance | State | What it is used for |
| :--- | :--- | :--- | :--- |
| `frigate` | `192.168.89.37:5000/` | loaded | NVR cameras, occupancy, detection entities, dashboard cards. |
| `go2rtc` | go2rtc | loaded | Stream proxy used with Frigate / Lovelace. |
| `axis` | Five Axis cameras (P1448-LE / P3375-VE) | loaded | Native Axis camera devices alongside Frigate. |
| `generic` | `192_168_89_14` | loaded | Generic camera / IP endpoint. |
| `llmvision` | LLM Vision Settings + Custom OpenAI compatible Provider | loaded | Gate-open multi-frame people classification and event summaries. |
| `mcp_server` | Assist | loaded | Expose Assist / MCP tooling to agents. |

## Networking and infrastructure monitoring

| Integration | Title / instance | State | What it is used for |
| :--- | :--- | :--- | :--- |
| `mqtt` | mqtt.mostardesigns.com | loaded | Mosquitto broker for Frigate, watering snapshots, and other MQTT devices. |
| `mikrotik_router` | Mikrotik-Home, Mikrotik-Mostar | loaded | RouterOS sensors (ports, traffic, system). Fork HACS `hacs-mikrotik_router` v2.3.0. |
| `mikrotik_switchos` | Mikrotik `http://10.0.10.2/` | loaded | CSS / SwitchOS metrics. |
| `unifi` | Home | loaded | UniFi Network Application clients/APs. |
| `glances` | NVR `10.0.10.16`, HA localhost, garden speaker `192.168.89.27`, Jetson `172.16.90.20` | loaded (Jetson may retry) | Host CPU/mem/disk. Dashboard also uses package `infra_glances_hosts` as a direct API fallback. |
| `systemmonitor` | System Monitor | loaded | HA host OS metrics. |
| `cpuspeed` | CPU Speed | loaded | Host CPU frequency. |
| `local_ip` | local_ip | loaded | HA host IP helper. |
| `speedtestdotnet` | SpeedTest | loaded | WAN speed checks. |
| `proxmoxve` | proxmox.mostardesigns.com | loaded | Proxmox VE VMs/LXCs. |
| `portainer` | `http://10.0.10.17:9000` | loaded | Docker container status on infra hosts (Frigate, Traefik, etc.). |
| `openmediavault` | NAS1, NAS2 | loaded | NAS health / storage. |
| `msnswitch` | Three UIS PDUs (`.251` `.252` `.254`) | loaded | Power watchdogs for router/modem, Traefik/NAS1, NAS2/Jetson. |
| `influxdb` | homeassistant @ localhost:8086 | loaded | Long-term metrics sink. |
| `backup` | Backup | loaded | HA backup subsystem. |
| `hassio` | Supervisor | loaded | HAOS supervisor / add-ons. |
| `analytics` | Analytics | loaded | Optional HA analytics. |

## Media and voice

| Integration | Title / instance | State | What it is used for |
| :--- | :--- | :--- | :--- |
| `cast` | Google Cast | loaded | Nest/Chromecast speakers and displays. |
| `music_assistant` | Music Assistant | loaded | Multi-room music orchestration (HA add-on). |
| `forked_daapd` | Garden speaker | loaded | OwnTone / forked-daapd on garden speaker host. |
| `plex` | plex.mostardesigns.com | loaded | Plex media server. |
| `dlna_dms` | Plex Home | loaded | DLNA media server discovery for Plex. |
| `radio_browser` | Radio Browser | loaded | Internet radio directory. |
| `google_assistant` | home-assistant-1142 | loaded | Cloud voice exposure of selected lights/locks/climate. Older project entry disabled by user. |
| `apple_tv` | Garden speaker | not_loaded (ignored) | Unused discovery. |
| `samsungtv` / `dlna_dmr` | Living room / Master Bedroom TVs | not_loaded (ignored) | TV discovery ignored. SmartThings used instead for TVs. |

## Cloud brands and appliances

| Integration | Title / instance | State | What it is used for |
| :--- | :--- | :--- | :--- |
| `smartthings` | Kuca | loaded | Samsung TVs and related SmartThings devices. |
| `tuya` / `localtuya` | Tuya cloud + LocalTuya | loaded | Tuya devices. Prefer local where configured. |
| `govee` | govee | loaded | Govee lighting / sensors. |
| `switchbot_cloud` | SwitchBot Cloud | loaded | SwitchBot cloud devices. |
| `switchbotremote` | Office Hub Mini | loaded | IR remote via SwitchBot hub (office). |
| `lutron_caseta` | `192.168.89.32` | loaded | Lutron Caseta bridge lighting. |
| `ipp` | HP DeskJet 2700 | loaded | Network printer. |
| `qbittorrent` | qBittorrent | loaded | Download client status on infra. |
| `nest_protect` | Nest Protect | setup_error | Smoke/CO detectors. Currently failing setup. Entities largely unavailable. |
| `smartthinq_sensors` | LGE Devices | not_loaded (disabled by user) | LG ThinQ. Installed but disabled. |

## Mobile apps

Ten `mobile_app` entries (phones, tablets, kiosk iPad) for presence, notifications, and Companion NFC tag scans. Used by gate AI alerts and NFC entry automations.

## Custom / HACS components on the host

Present under `/config/custom_components` (not every folder has an active config entry):

| Component | Version (manifest) | Role |
| :--- | :--- | :--- |
| `hacs` | 2.0.5 | Custom store |
| `agentic_watering` | 1.2.0 | Irrigation LLM pipeline |
| `msnswitch` | 1.0.6 | PDU watchdogs |
| `mikrotik_router` | 2.3.0 | RouterOS (fork) |
| `mikrotik_switchos` | 0.0.9 | SwitchOS |
| `frigate` | 5.15.4 | Frigate HA integration |
| `llmvision` | 1.7.0 | Vision LLM actions |
| `climate_template` | 1.4.0 | Unified climate + helpers |
| `bhyve` | 4.1.2 | Orbit irrigation |
| `midea_ac_lan` | 0.6.12 | Midea AC LAN (active) |
| `midea_ac` / `midea_dehumidifier_lan` | various | Alternate Midea packages present |
| `localtuya` | 5.2.3 | Local Tuya |
| `govee` | 2025.1.1 | Govee |
| `nest_protect` | 0.4.4 | Nest Protect (setup_error) |
| `proxmoxve` | 4.0.2 | Proxmox |
| `openmediavault` | 0.0.0 | NAS |
| `switchbotremote` | 1.3.7 | IR hub |
| `browser_mod` | 3.1.0 | Browser / kiosk UI helpers |
| `webrtc` | v3.6.1 | WebRTC camera card support |
| `moonraker` | 1.13.4 | 3D printer (if used) |
| `watersmart` | v0.1.9 | Water utility |
| `whistle` | 0.2.0 | Pet tracker |
| `ookla_speedtest` | 3.0.5 | Speedtest helper |
| `openweathermap_all` | 0.0.1 | Extra weather API |
| `hpprinter` | 2.0.6 | HP printer extras |
| `smartthinq_sensors` | 0.43.0 | LG ThinQ (disabled entry) |

## Platform YAML still in configuration

Not always a UI "integration," but part of the stack:

- `climate:` `climate_template` living-room control
- `google_assistant:` service account exposure
- `influxdb:` / `recorder:` retention
- `device_tracker:` Google Maps trackers
- Packages: Glances host metrics, irrigation, Frigate gauges, etc.

## Related

- [Unified Climate Control](unified_climate_control.md)
- [Z-Wave Network](zwave_network.md)
- [Zigbee Lighting and Sensors](zigbee_lighting_sensors.md)
- [LoRa Perimeter](lorawan_perimeter.md)
- [NFC Entry](nfc_entry.md)
- [Garden Agentic Watering](garden_agentic_watering.md)
- [Radio and Network Topology](radio_topology.md)
