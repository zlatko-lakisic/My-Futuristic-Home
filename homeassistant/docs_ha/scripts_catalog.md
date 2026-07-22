# Scripts Catalog

Catalog of Home Assistant scripts on the live system and how they fit the architecture.

Wiki mirror: [Home Assistant Scripts and Templates](https://github.com/zlatko-lakisic/My-Futuristic-Home/wiki/Home-Assistant-Scripts-and-Templates).

## Purpose

Scripts are the reusable action engines called by automations, blueprints, dashboards, and the climate template. This page lists each script, its source, and its callers.

## How scripts are loaded

```
configuration.yaml
  script: !include scripts.yaml
        |
        +-- process_ai_analysis_and_notification
        +-- control_climate
        +-- bhyve_start_selected_zone / stop / toggle

homeassistant.packages:
  smart_sequential_watering_script:
    !include custom_components/agentic_watering/packages/smart_sequential_watering_script.yaml
        |
        +-- script.ai_sequential_watering   (HACS)

  smart_sequential_watering_instance:
    !include packages/smart_sequential_watering_instance.yaml
        |
        +-- script.ai_watering_simulate_test
```

Split copies under `homeassistant/scripts/*.yaml` mirror pieces of `scripts.yaml` for readability. Live HA loads **`scripts.yaml`** plus HACS/site packages above.

## Architecture map

```
Automations / Lovelace / climate_template
        |
        v
Scripts
        |
        +-- control_climate ----------> Nest + Midea entities
        +-- process_ai_* -------------> llmvision + notify.mobile_app_*
        +-- ai_sequential_watering ---> REST (weather/LLM) + BHyve services
        +-- bhyve_*_selected_zone ----> bhyve.start_watering / stop_watering
```

## Active scripts

| Entity | Source | Role | Typical callers |
| :--- | :--- | :--- | :--- |
| `script.control_climate` | `scripts.yaml` / `scripts/control_climate.yaml` | Off / cool / heat with Nest+Midea mutual exclusion | `climate.new_livingroom_climate` setters |
| `script.process_ai_analysis_and_notification` | `scripts.yaml` / `scripts/process_ai_analysis_and_notification.yaml` | LLM Vision stream/image analysis, clean text, fan-out mobile notifications | Older gate/driveway notify automations; manual tests |
| `script.ai_sequential_watering` | HACS package | Full dusk/dawn irrigation pipeline (weather, history, LLM minutes, sequential BHyve) | `automation.ai_sequential_watering*`, blueprint |
| `script.ai_watering_simulate_test` | site instance package | Dry-run watering with `simulate: true` | Manual / dashboard test |
| `script.bhyve_start_selected_zone` | `scripts.yaml` | Start zone from `input_select.bhyve_manual_zone` + duration helper | Backyard manual UI |
| `script.bhyve_stop_selected_zone` | `scripts.yaml` | Stop selected zone | Backyard manual UI |
| `script.bhyve_toggle_selected_zone` | `scripts.yaml` | Toggle selected zone open/closed | Backyard manual UI |

## Legacy / unavailable scripts

| Entity | Notes |
| :--- | :--- |
| `script.ai_dusk_sequential_watering` | Pre-HACS monolith. Replaced by `script.ai_sequential_watering` |
| `script.bhyve_ai_dusk_sequential_watering` | Legacy alias path. Unavailable after cutover |

Keep them out of new automations. Safe to ignore on the entity list.

## Script details

### `script.control_climate`

Fields: `temperature`, `operation_mode` (`off` / `cool` / `heat`). Mode `single`.

- **off:** Midea climate off, Midea power off, Nest off.
- **cool:** Nest heat off if needed, Midea power on, set Midea cool + setpoint.
- **heat:** Midea off, Nest heat + setpoint.

Paired with exclusivity automations. See [Unified Climate Control](unified_climate_control.md).

### `script.process_ai_analysis_and_notification`

Fields include camera entity, prompt, notification title, click URL, notify people, persistent notification flag. Mode `parallel`.

Uses `llmvision` analysis, normalizes response text, resolves `notify.mobile_app_*` for selected people, and sends the push (with fallback). Gate blueprint instances prefer `llmvision.image_analyzer` inline, so this script is mainly the older notification path and driveway-style flows.

### `script.ai_sequential_watering`

Shipped by [hacs-agentic-watering](https://github.com/zlatko-lakisic/hacs-agentic-watering). Calls REST commands for OpenWeatherMap, Open-Meteo, HA history, and Jetson OpenAI-compatible chat completions, then runs BHyve zones sequentially. See [Garden Agentic Watering](garden_agentic_watering.md).

### BHyve manual scripts

Resolve the selected zone via `packages/bhyve_manual_zone_resolve.yaml` (`sensor.bhyve_zone_entity`) and call Orbit BHyve services with integer minutes from `input_number.bhyve_manual_duration_minutes`.

## Templates (related)

`homeassistant/templates.yaml` and package templates define sensors/helpers consumed by dashboards and automations (not scripts themselves). MQTT binary sensors live in `mqtt.yaml`. Climate virtual entity is YAML `climate_template`, not a script.

## Related

- [Automations Catalog](automations_catalog.md)
- [HACS Plugins](hacs_plugins.md)
- [Unified Climate Control](unified_climate_control.md)
- [Garden Agentic Watering](garden_agentic_watering.md)
