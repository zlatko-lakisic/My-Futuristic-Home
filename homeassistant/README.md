# 🏠 Home Assistant Configuration

This directory contains the logic, blueprints, and hardware-specific configurations for the "My-Futuristic-Home" OS.

## 📡 Wireless Strategy
My system follows a "Local-First" philosophy. We utilize dedicated radios for different classes of devices to minimize interference and maximize the "Wife Approval Factor" (WAF) through 100% reliability.

### **Network Topology**
For a detailed look at how the Zigbee and Z-Wave meshes are physically and logically structured, see:
👉 **[Wireless Mesh Architecture](./docs_ha/radio_topology.md)**

## **Quick Links**
* ⚡ [**Z-Wave Device Inventory**](zwave_inventory.md) - Mesh lighting and switches.
* 🐝 [**Zigbee Device Inventory**](zigbee_inventory.md) - Sensors and drivers.
* 🛡️ [**Nest Protect Inventory**](nest_protect_inventory.md) - Smoke & CO detectors.
* ☁️ [**SmartThings Inventory**](smartthings_inventory.md) - Samsung Smart TV integrations.
* 🗣️ [**Google Nest Inventory**](google_nest_inventory.md) - Voice control and Gemini interface.
* 📩 [**Messaging Infrastructure**](../../infrastructure/messaging.md) - MQTT broker details.

## **Deployment Details**
- **Type:** Home Assistant OS (HAOS) 
- **Voice Control:** Integrated with **Google Home / Gemini** for mobile, automotive, and in-home control.
- **Primary Integrations:**
  - **MQTT:** Utilizes the [Messaging Infrastructure](../../infrastructure/messaging.md) at `192.168.89.26`.
  - **Z-Wave JS UI & ZHA:** Local mesh radio management.
  - **Google Cast:** Manages [Nest Speakers](google_nest_inventory.md) for TTS and media.
  - **SmartThings:** Cloud integration for Samsung TVs.
- **Voice Control:** Integrated with **Google Home / Gemini** for mobile and automotive control.
- **Safety System:** [Nest Protect](nest_protect_inventory.md) provides whole-home smoke/CO monitoring via cloud-push.

---

## **📹 Camera & NVR Infrastructure**

To keep the setup organized, all camera-related documentation is split into two parts:

* **[Camera Inventory](frigate_inventory.md):** A master list of all 14 cameras, their locations (Basement, Driveway, Garden), and direct links to their Frigate streams.
* **[Frigate Setup & Capabilities](docs_ha/frigate_setup.md):** Detailed technical documentation on AI object detection, sound recognition (v0.16.3), and HACS dashboard configuration.

---

## **🛠️ Key Features**
* **AI Detection:** Real-time tracking for people, cars, and pets.
* **Smart Alerts:** Critical notifications sent via Telegram/Mobile App.
* **Dashboard:** High-performance viewing using the Advanced Camera Card.

---

## 📟 Hardware Controllers
These physical dongles are passed through directly to the HAOS environment:

| Protocol | Hardware | Integration | Role |
| :--- | :--- | :--- | :--- |
| **Zigbee 3.0** | Sonoff ZBDongle-E | ZHA | Lighting, Motion & Environment Sensors |
| **Z-Wave 700** | Aeotec Z-Stick 7 | Z-Wave JS UI | High-Security (Locks, Switches, Valves) |
| **Bluetooth** | TP-Link UB400 | Bluetooth | Presence Tracking (BLE) |

## 🛠 Software Environment
- **Core:** Home Assistant OS (Bare Metal)
- **Database:** MariaDB (Local)
- **Add-ons:** Zigbee Home Automation (ZHA), Z-Wave JS UI, Mosquitto MQTT, Samba Share.

## 📂 Directory Map
* `/blueprints`: Reusable automation templates.
* `/dashboards`: YAML and screenshots of the UI.
* `/docs_ha`: Deep dives into specific radio protocols and mesh health.
* `/packages`: Optional YAML merged into configuration when `homeassistant.packages: !include_dir_named packages` is set. Files here must be copied to **`/config/packages/`** on the HA machine (the repo copy is not used automatically).

**Deploy dashboards + packages to the live Samba share:** from the repository root run `powershell -ExecutionPolicy Bypass -File scripts/sync_homeassistant_config.ps1` (default target `\\192.168.89.25\config`). Override with `-ConfigRoot` if needed.

The same script also pushes **root-level YAML** and the **`automations/`** tree from this repo to `/config`: `configuration.yaml`, `scripts.yaml`, `automations.yaml`, `templates.yaml`, `scenes.yaml`, `mqtt.yaml`, plus `automations/`, `dashboards/`, `packages/`, `www/`, and `blueprints/` when those folders exist here.

### Runtime config in Git (2026-04 sync)
The repository now tracks the live HA bundle under `homeassistant/` so changes can be reviewed in Git before deploy. Highlights from the consolidated sync:

- **Living room climate:** `climate.new_livingroom_climate` (`climate_template`) combines Nest `climate.living_room` and Midea `climate.150633094697190_climate` / `switch.150633094697190_power`; templates mirror manual changes; `hvac_action_template` exposes idle / heating / cooling from underlying `hvac_action` attributes.
- **`script.control_climate`:** Entity-based actions, `mode: single`, off/cool/heat branches aligned with the template logic and mutual exclusion.
- **Automations:** Split under `automations/` with `automation: !include_dir_merge_list automations/`; includes `04_living_room_climate_exclusivity.yaml` so heat and AC cannot run together (including manual changes).
- **BHyve manual watering:** `input_select` / `input_number` in `configuration.yaml`, `packages/bhyve_manual_zone_resolve.yaml` (`sensor.bhyve_zone_entity`), and script fixes in `scripts.yaml`.
- **Home Control dashboard:** Living room thermostat entity updated to `climate.new_livingroom_climate`.

Secrets stay on the HA host only: `secrets.yaml` and `service_account.json` are gitignored; copy or create them on new installs.

### NVR top processes (Glances) sensor
The infrastructure dashboard expects **`sensor.nvr_glances_top_processes`**, defined by [`packages/nvr_top_processes.yaml`](packages/nvr_top_processes.yaml) plus [`packages/nvr_glances_top_processes.py`](packages/nvr_glances_top_processes.py). The setup uses a **`command_line`** sensor (not `rest:`): Home Assistant’s **`rest`** integration does not support **`json_attributes_template`**, so you cannot build a sorted top‑10 list from Glances’ JSON array with YAML alone.

Deploy **both** files to **`/config/packages/`** on the HA host. If you use a named include, paths must sit next to `configuration.yaml` as usual.

Then **Developer tools → YAML → Reload all YAML configuration** (or restart) and check **Settings → System → Logs** if the entity is missing — look for **command_line** or Python errors.
