# Unified Climate Control

Living-room climate is exposed as one thermostat with a Nest / Air Conditioner picker. Mutual exclusion keeps both from running together.

Wiki mirror: [Home Assistant Unified Climate Control](https://github.com/zlatko-lakisic/My-Futuristic-Home/wiki/Home-Assistant-Unified-Climate-Control).

## Purpose

Give dashboards, Google Assistant, and people a single entity (`climate.new_livingroom_climate`) plus a thermostat list (`input_select.livingroom_climate_thermostat`): **Home Heating**, **Living Room**, **Master Bedroom**, and **Air Conditioner**.

## How It Works

```
UI / voice / automation
        |
        v
input_select.livingroom_climate_thermostat
  (Home Heating | Living Room | Master Bedroom | Air Conditioner)
        |
        v
climate.new_livingroom_climate  (HACS climate_template)
        |
        +-- set_hvac_mode / set_temperature --> script.control_climate
        |         |
        |         +-- off  -> Nest off + Midea climate/power off
        |         +-- cool -> select Air Conditioner, Nest off, Midea cool
        |         +-- heat -> Nest options: Nest heat; Air Conditioner: Midea heat
        |
        +-- fan / swing / preset --> Midea only
        |
        +-- templates mirror Nest or AC; current temp follows picker sensor
        |
        v
Automations in 04_living_room_climate_exclusivity.yaml
        |
        +-- Nest heating  -> leave Nest room picks, else leave Home Heating; force Midea off
        +-- Midea active  -> select Air Conditioner, force Nest off
        +-- Nest↔AC picker change -> turn off the other equipment
```

### Hardware and integrations

| Role | Integration | Entity (as wired in YAML) |
| :--- | :--- | :--- |
| Thermostat picker | `input_select` | `input_select.livingroom_climate_thermostat` |
| Home Heating (Nest thermostat) | Google Nest (`nest`) | `climate.living_room_home_heating`, `sensor.living_room_home_heating_temperature` |
| Living Room Nest sensor | `nest_protect` (temp sensors) | `sensor.nest_temperature_sensor_living_room_temperature` |
| Master Bedroom Nest sensor | `nest_protect` (temp sensors) | `sensor.nest_temperature_sensor_master_bedroom_temperature` |
| Air Conditioner | Midea AC LAN (`midea_ac_lan`) | `climate.150633094697190_climate`, `switch.150633094697190_power`, swing/boost switches |
| Room humidity | Nest thermostat | `sensor.living_room_home_heating_humidity` |
| Unified face | `climate_template` (HACS) | `climate.new_livingroom_climate` (friendly name Livingroom Climate Control) |

Note: Nest SDM cannot change which remote sensor is Nest’s *active* control sensor; that stays in the Google Home / Nest app. Picking Living Room or Master Bedroom here changes the unified card’s current-temperature reading and still heats via `climate.living_room_home_heating`.

Virtual climate modes exposed to the UI: `off`, `cool`, `heat`. Fan, swing, and presets are AC-only and mirrored from Midea.

### Control path

1. Changing mode or setpoint on `climate.new_livingroom_climate` calls `script.control_climate` with `operation_mode` and `temperature`.
2. The script (`homeassistant/scripts/control_climate.yaml`, also mirrored in `scripts.yaml`) reads the picker and branches:
   - **off:** turn off Midea climate and power switch, turn Nest off.
   - **cool:** select Air Conditioner, turn Nest off, turn Midea power on, set cool + setpoint.
   - **heat:** if Air Conditioner is selected, Nest off + Midea heat; otherwise (Home Heating / Living Room / Master Bedroom) Midea off + Nest heat.
3. Fan / swing / preset setters on the template call Midea climate services directly (Nest has no equivalent).

### State mirroring

Templates on the climate_template platform decide what the virtual entity shows, based on the picker:

- **Home Heating / Living Room / Master Bedroom:** mode/action/setpoint from Nest (`heat` / `off`).
- **Air Conditioner:** mode/action/setpoint from Midea (`heat` / `cool` / `off`).
- **Current temperature:** Nest thermostat sensor, Nest Living Room sensor, Nest Master Bedroom sensor, or AC indoor temp (falls back to Nest thermostat sensor if the pick is unavailable).
- **Humidity:** Nest thermostat humidity.

Manual changes on Nest or Midea update the picker via exclusivity automations and refresh the unified card.

### Exclusivity automations

File: `homeassistant/automations/04_living_room_climate_exclusivity.yaml`

| Automation | Trigger idea | Action |
| :--- | :--- | :--- |
| Living room heat disables AC | Nest enters heat / heating | If picker was AC, select Home Heating; turn Midea off |
| Living room AC disables Nest heating | Midea power on or cool/dry/fan_only/heat | Select Air Conditioner; turn Nest off |
| Living room thermostat selection turns off other | Nest↔AC picker change | Turn off the other equipment (Nest room↔room is display-only) |

These catch panel and app changes that bypass `script.control_climate`.

## Source files

| Path | Role |
| :--- | :--- |
| `homeassistant/input_select.yaml` | Thermostat picker options |
| `homeassistant/configuration.yaml` (`climate:` block) | Template climate definition |
| `homeassistant/scripts/control_climate.yaml` | Off / cool / heat actuation (keep in sync with `scripts.yaml`) |
| `homeassistant/automations/04_living_room_climate_exclusivity.yaml` | Mutual exclusion + picker sync |
| Climate / Home Control dashboards | Picker + thermostat card on `climate.new_livingroom_climate` |

## Live status notes (Nov 2026)

- Unified entity `climate.new_livingroom_climate` is present.
- Thermostat picker `input_select.livingroom_climate_thermostat` options: Home Heating, Living Room, Master Bedroom, Air Conditioner.
- Nest Living Room / Master Bedroom temperature sensors are currently unavailable until Nest Protect reauth succeeds.
- Midea AC entity and power switch are present and controllable.
- Exclusivity automations are **on** (including picker sync).
- Nest thermostat is `climate.living_room_home_heating` (Google name Home Heating) with `sensor.living_room_home_heating_temperature` / `_humidity`.
- Google Assistant exposes the `climate` domain. Voice should use the unified entity; raw Nest and Midea climates are denylisted.

## Troubleshooting

| Symptom | Direction |
| :--- | :--- |
| Cool works, heat does nothing | Confirm `climate.living_room_home_heating` exists and Nest integration can set heat |
| Heat and cool fight | Confirm both exclusivity automations are on. Check for UI cards still targeting Nest or Midea directly |
| Unified card shows wrong mode | Compare Nest/Midea real states. Templates prefer Nest heating over Midea cooling |
| Current temp blank / unknown | Confirm `sensor.living_room_home_heating_temperature` or retarget `current_temperature_template` |
| Fan/swing ignored in heat | Expected. Those controls only apply to Midea |

## Related

- [Integrations Catalog](integrations_catalog.md)
- Nest / Midea rows in the climate section of that catalog
- [Home Assistant README](../README.md) runtime notes
