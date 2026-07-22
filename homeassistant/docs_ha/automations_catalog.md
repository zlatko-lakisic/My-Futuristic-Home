# Automations Catalog

Catalog of Home Assistant automations on the live system (Jul 2026), grouped by architecture role. Aliases only for entry-related automations. Operational unlock logic is not documented.

Wiki mirror: [Home Assistant Automations](https://github.com/zlatko-lakisic/My-Futuristic-Home/wiki/Home-Assistant-Automations).

## Purpose

Show what each automation does and where it sits in the stack: lighting, perimeter AI, irrigation, climate, entry, garage/presence, maintenance.

## How automations are loaded

```
configuration.yaml
  automation: !include_dir_merge_list automations/
        |
        +-- 01_core_automations.yaml
        +-- 02_ai_and_notifications.yaml
        +-- 03_operations_and_presence.yaml
        +-- 03_bhyve_ai_dusk_watering.yaml
        +-- 03b_ai_lawns_dawn_watering.yaml
        +-- 04_living_room_climate_exclusivity.yaml
        +-- 04_www_tmp_image_cleanup.yaml
        |
        +-- (UI / package-defined automations also appear live)
```

`homeassistant/automations.yaml` is empty (`[]`). Prefer the split files under `automations/`.

## Architecture map

```
Sensors / tags / sun / Frigate / YoLink / ZHA / Z-Wave
        |
        v
Automations (this catalog)
        |
        +--> Scripts (control_climate, process_ai_*, ai_sequential_watering, BHyve helpers)
        +--> Lights / locks / covers / notify / containers
        +--> Helpers (gate_ai_*, watering run state)
```

## Irrigation and AI watering

| Entity | State | Role |
| :--- | :--- | :--- |
| `automation.ai_sequential_watering` | on | Dusk sequential watering via HACS blueprint → `script.ai_sequential_watering` |
| `automation.ai_sequential_watering_east_kitchen_lawns_dawn` | on | Dawn lawns (seasonal) via same blueprint |
| `automation.ai_sequential_watering_resume_after_restart` | on | Resume in-progress run from MQTT snapshot after HA restart |
| `automation.watering` | off | Legacy watering automation |
| `automation.ai_dusk_sequential_watering` | unavailable | Legacy pre-HACS |
| `automation.ai_dusk_watering_refresh_ollama_model_list` | unavailable | Legacy |
| `automation.ai_dusk_watering_resume_after_restart` | unavailable | Legacy |
| `automation.bhyve_ai_dusk_sequential_watering` | unavailable | Legacy |

Docs: [Garden Agentic Watering](garden_agentic_watering.md).

## Perimeter gate AI and camera notifications

| Entity | State | Role |
| :--- | :--- | :--- |
| `automation.east_gate_open_ai_analysis_2` | on | YoLink east gate → snapshot + LLM Vision people alert |
| `automation.west_gate_open_ai_analysis` | on | West gate → same blueprint |
| `automation.back_yard_gate_open_ai_analysis` | on | Fence / back yard gate → same blueprint |
| `automation.east_gate_open_ai_analysis` | unavailable | Superseded duplicate |
| `automation.east_gate_open_notification` | off | Older path via `script.process_ai_analysis_and_notification` |
| `automation.west_side_gate_notification` | off | Older west gate notify path |
| `automation.driveway_car_notification` | off | Driveway car occupancy → AI notify script |
| `automation.east_side_motion` | off | Frigate/event summary blueprint when east motion |
| `automation.llm_testing` | off | Manual LLM Vision test harness |
| `automation.test` | off | Scratch event_summary blueprint test |

Docs: [LoRa Perimeter](lorawan_perimeter.md), blueprint `gate_open_llm_vision_people.yaml`.

## Unified climate

| Entity | State | Role |
| :--- | :--- | :--- |
| `automation.living_room_heat_disables_ac` | on | Nest heating forces Midea off |
| `automation.living_room_ac_disables_nest_heating` | on | Midea cooling forces Nest off |
| `automation.turn_on_ac` / `automation.turn_off_ac` | off | Older AC helpers |
| `automation.turn_on_heat` | unavailable | Older heat helper |

Docs: [Unified Climate Control](unified_climate_control.md).

## Zigbee / Z-Wave lighting and motion

| Entity | State | Role |
| :--- | :--- | :--- |
| `automation.sunset_turn_on_lights` | on | Evening exterior / common lights on |
| `automation.sunrise_turn_off_lights` | on | Morning lights off |
| `automation.master_bedroom_closet_motion_light` | on | FP1E → closet TRADFRI drivers |
| `automation.basement_light_motion_sensor` | on | Basement FP1E → Z-Wave basement light |
| `automation.master_bedroom_closet_light_switch_on` / `_off` | on | RODRET remote |
| `automation.kitchen_countertop_lights_on` / `_off` | on | Kitchen RODRET → driver |
| `automation.kitchenette_light_on` / `_off` | on | Kitchenette RODRET → driver |
| `automation.closet_lught_switch_on` / `closet_light_ofg` | on | Guest closet remote (alias typos preserved) |
| `automation.dim_bedroom_hallway_light` | on | Hallway dimming behavior |
| `automation.back_yard_motion` | off | Frigate motion → yard lights |
| `automation.driveway_motion_activated_lights` | off | Driveway motion lights |
| `automation.front_door_motion` | off | Front door motion lights |
| `automation.ping_z_wave_devices_4` | on | Periodic Z-Wave ping / keep-alive |

Docs: [Zigbee Lighting and Sensors](zigbee_lighting_sensors.md), [Z-Wave Network](zwave_network.md).

## NFC entry (aliases only)

| Entity | State | Role (conceptual) |
| :--- | :--- | :--- |
| `automation.tag_front_door_is_scanned` | on | NFC tap → entry flow for front door |
| `automation.tag_back_door_tag_is_scanned` | on | NFC tap → back door |
| `automation.tag_office_door_tag_is_scanned` | on | NFC tap → office door |
| `automation.tag_door_to_garage_tag_is_scanned` | on | NFC tap → door to garage |
| `automation.tag_garage_door_tag_is_scanned` | on | NFC tap → garage-related entry |

Details intentionally omitted. See [NFC Entry](nfc_entry.md).

## Doors, garage, presence

| Entity | State | Role |
| :--- | :--- | :--- |
| `automation.front_door_closed` | on | Front door closed side effects |
| `automation.back_door_closed` | off | Back door closed |
| `automation.front_door_open` / `back_door_open` / `office_door_open` / `office_door_closed` | unavailable | Legacy / broken door open-close |
| `automation.garage_door_opening_automation` | on | Garage door open workflow |
| `automation.open_garage_car_arrived` | off | Auto-open when car arrives |
| `automation.close_garage_car_left` | off | Auto-close when car leaves |
| `automation.boiler_bucket_full_notificatiin` | on | Boiler condensate / bucket alert |

## Infrastructure maintenance

| Entity | State | Role |
| :--- | :--- | :--- |
| `automation.restart_frigate_and_codeproject_ai_on_high_inference_speed` | on | Restart Frigate + CodeProject AI containers if inference speed stays high |
| `automation.maintenance_delete_www_tmp_images_older_than_2_weeks` | on | Clean gate/AI snapshot tmp files under `www/tmp` |

## Related

- [Scripts Catalog](scripts_catalog.md)
- [HACS Plugins](hacs_plugins.md)
- [Integrations Catalog](integrations_catalog.md)
- File layout: `homeassistant/automations/`
