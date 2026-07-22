# Unified Climate Control

Living-room climate is exposed as one thermostat that drives Nest heat and Midea AC cool, with mutual exclusion so both never heat and cool together.

Wiki mirror: [Home Assistant Unified Climate Control](https://github.com/zlatko-lakisic/My-Futuristic-Home/wiki/Home-Assistant-Unified-Climate-Control).

## Purpose

Give dashboards, Google Assistant, and people a single entity (`climate.new_livingroom_climate`) instead of juggling Nest and Midea separately.

## How It Works

```
UI / voice / automation
        |
        v
climate.new_livingroom_climate  (HACS climate_template)
        |
        +-- set_hvac_mode / set_temperature --> script.control_climate
        |         |
        |         +-- off  -> Nest off + Midea climate/power off
        |         +-- cool -> Nest heat off, Midea power on, cool + setpoint
        |         +-- heat -> Midea off, Nest heat + setpoint
        |
        +-- fan / swing / preset --> Midea only
        |
        +-- templates mirror live Nest + Midea state back into the virtual climate
        |
        v
Automations in 04_living_room_climate_exclusivity.yaml
        |
        +-- Nest heating  -> force Midea off
        +-- Midea cooling -> force Nest off
```

### Hardware and integrations

| Role | Integration | Entity (as wired in YAML) |
| :--- | :--- | :--- |
| Heat | Google Nest (`nest`) | `climate.living_room` |
| Cool | Midea AC LAN (`midea_ac_lan`) | `climate.150633094697190_climate`, `switch.150633094697190_power`, swing/boost switches |
| Room feel | Sensors referenced by template | `sensor.living_room_temperature`, `sensor.living_room_humidity` |
| Unified face | `climate_template` (HACS) | `climate.new_livingroom_climate` (friendly name Livingroom Climate Control) |

Virtual climate modes exposed to the UI: `off`, `cool`, `heat`. Fan, swing, and presets are AC-only and mirrored from Midea.

### Control path

1. Changing mode or setpoint on `climate.new_livingroom_climate` calls `script.control_climate` with `operation_mode` and `temperature`.
2. The script (`homeassistant/scripts/control_climate.yaml`, `mode: single`) branches:
   - **off:** turn off Midea climate and power switch, turn Nest off.
   - **cool:** if Nest is heating, turn Nest off. Turn Midea power on. Set Midea temperature with `hvac_mode: cool`.
   - **heat:** turn Midea power/climate off. Set Nest to heat with the requested temperature.
3. Fan / swing / preset setters on the template call Midea climate services directly (Nest has no equivalent).

### State mirroring

Templates on the climate_template platform decide what the virtual entity shows:

- **Mode:** `heat` if Nest is heating (including Nest `auto` with `hvac_action: heating`). Else `cool` if Midea power is on or Midea mode is cool/dry/fan_only. Else `off`.
- **Action:** `heating` / `cooling` / `idle` from Nest and Midea `hvac_action`.
- **Target temperature:** Nest setpoint while heating, Midea setpoint while cooling, average of both when off.
- **Current temperature / humidity:** from living-room sensors (when those entities exist).

Manual changes on Nest or Midea therefore update the unified card without a separate sync script.

### Exclusivity automations

File: `homeassistant/automations/04_living_room_climate_exclusivity.yaml`

| Automation | Trigger idea | Action |
| :--- | :--- | :--- |
| Living room heat disables AC | Nest enters heat / heating | Turn Midea climate and power off |
| Living room AC disables Nest heating | Midea power on or cool/dry/fan_only | Turn Nest off |

These catch panel and app changes that bypass `script.control_climate`.

## Source files

| Path | Role |
| :--- | :--- |
| `homeassistant/configuration.yaml` (`climate:` block) | Template climate definition |
| `homeassistant/scripts/control_climate.yaml` | Off / cool / heat actuation |
| `homeassistant/automations/04_living_room_climate_exclusivity.yaml` | Mutual exclusion |
| Home Control dashboard | Thermostat card bound to `climate.new_livingroom_climate` |

## Live status notes (Jul 2026)

- Unified entity `climate.new_livingroom_climate` is present (`off`, action `idle`).
- Midea AC entity and power switch are present and controllable.
- Exclusivity automations are **on**.
- Nest thermostat entity `climate.living_room` and `sensor.living_room_temperature` / `_humidity` were **not** in the live registry at this snapshot. Nest Protect integration is in `setup_error`. Heat path and current-temp templates will not work until Nest thermostat and room sensors are restored or the YAML is pointed at replacement entities.
- Google Assistant still exposes the `climate` domain. Prefer the unified entity on dashboards.

## Troubleshooting

| Symptom | Direction |
| :--- | :--- |
| Cool works, heat does nothing | Confirm `climate.living_room` exists and Nest integration can set heat |
| Heat and cool fight | Confirm both exclusivity automations are on. Check for UI cards still targeting Nest or Midea directly |
| Unified card shows wrong mode | Compare Nest/Midea real states. Templates prefer Nest heating over Midea cooling |
| Current temp blank / unknown | Restore `sensor.living_room_temperature` or retarget `current_temperature_template` |
| Fan/swing ignored in heat | Expected. Those controls only apply to Midea |

## Related

- [Integrations Catalog](integrations_catalog.md)
- Nest / Midea rows in the climate section of that catalog
- [Home Assistant README](../README.md) runtime notes
