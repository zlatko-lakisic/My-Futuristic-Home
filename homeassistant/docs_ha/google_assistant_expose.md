# Google Home expose policy

Manual Google Assistant (`google_assistant:` in YAML, project `home-assistant-1142`) is the only publish path. Nabu Casa `cloud.google_assistant` is unused (no entity-registry exposes).

Config: [`includes/google_assistant.yaml`](../includes/google_assistant.yaml), included from `configuration.yaml`.

## Auto-exposed domains

New entities in these domains are published unless listed with `expose: false`:

| Domain | Use |
| :--- | :--- |
| `light` | Household lights (not AP LEDs or camera IR) |
| `cover` | Garage door |
| `lock` | Door locks |
| `climate` | Living-room climate only |
| `valve` | BHyve watering **zones** |

`switch` is **not** in `exposed_domains`. That keeps MSN outlets, MikroTik ports, torrents, Docker/k8s containers, Frigate options, Nest Protect settings, and BHyve rain-delay/program switches off Google Home.

## Explicit allowlist (`expose: true`)

- Household light switches and `switch.house_fan`
- Door/gate contact sensors (`binary_sensor.*_door`)
- Friendly names for locks and the garage cover

## Explicit denylist (`expose: false`)

- UniFi AP LEDs: `light.ap_*_led`
- Camera IR: `light.garden_*_ir_light_0`
- `climate.bhyve_manual_watering` and raw Midea `climate.150633094697190_climate` (voice uses `climate.new_livingroom_climate`)
- TVs (`switch.living_room_tv`, `switch.master_bedroom_tv`, `switch.tv`)

## After YAML changes

1. Push with `scripts/sync_homeassistant_config.ps1`
2. Restart Home Assistant (Google Assistant YAML is not reloadable)
3. In Google Home: “sync my devices”
