# Zone Activity AI Notifications

Frigate zone occupancy → snapshot GIF → LLM Vision → phone notify for driveway and front steps.

Wiki mirror: [Home Assistant Automations](https://github.com/zlatko-lakisic/My-Futuristic-Home/wiki/Home-Assistant-Automations) (catalog section), blueprint notes on [Home Assistant Blueprints](https://github.com/zlatko-lakisic/My-Futuristic-Home/wiki/Home-Assistant-Blueprints).

## Purpose

Document the `zone_activity_llm_vision` blueprint and live instances that replace older driveway-car / script-based notify paths with coalesced, zone-scoped AI alerts.

## How it works

1. Frigate reports person and/or car occupancy in a named zone (`driveway_zone`, `near_front_door`).
2. Automation settles briefly, optionally waits for a person after a car trigger (driveway), then captures a still burst and stitches a GIF under `/config/www/tmp/`.
3. Frigate face sub-labels for the visit are resolved when configured.
4. LLM Vision (`gpt-4o-mini`, temperature `0.1`) analyzes a **subsampled** frame set (GIF keeps the full burst).
5. Reply must be three plain lines: classification (`PERSON` / `CAR` / `DOG` / `OTHER` / `CLEAR`), home log (≤160), phone line (≤100).
6. Notify only for confirmed activity:
   - Driveway: `PERSON` or `CAR` (or Frigate latch fallback if LLM junk).
   - Front steps: `PERSON` only (`people_only: true`).
7. Event holds until trigger sensors stay clear for `event_clear_seconds` (default 180) so one visit does not spam.

Occupancy used for fallback is **latched** during the visit (trigger + capture). Checking live Frigate state after a long capture+LLM window was dropping real alerts.

## Live instances

Source: `homeassistant/automations/02_ai_and_notifications.yaml`. Blueprint: `homeassistant/blueprints/automation/zone_activity_llm_vision.yaml`.

| Automation | Triggers | Camera | Mode |
| :--- | :--- | :--- | :--- |
| `automation.near_driveway_zone_ai_analysis` | `binary_sensor.driveway_zone_person_occupancy`, `…_car_occupancy` | `camera.driveway` (Frigate `driveway`) | Person + car; vehicle color/make/plate when readable |
| `automation.near_front_door_zone_ai_analysis` | `binary_sensor.near_front_door_person_occupancy` | `camera.front_door` (Front Yard / Frigate `front_door`) | People only |

Shared helpers (`input_text.gate_ai_last_*`, `input_datetime.gate_ai_last_analysis_time`) store the latest analysis for dashboard/debug (shared with gate AI).

### Driveway vehicle context

Optional blueprint input `known_vehicle_hint` lists household plates for the model to name only on a clear match (e.g. Family Car / `KXS-9837`). Plates are never invented; unreadable plates are omitted.

### Notification length caps

| Surface | Cap |
| :--- | :--- |
| Push title | ≤ 50 characters (plate may appear in title when parsed) |
| Push body | ≤ 100 characters |
| HA persistent home log | ≤ 160 characters |

## Frigate zones

| Camera | Zone id | HA occupancy examples |
| :--- | :--- | :--- |
| `driveway` | `driveway_zone` (friendly: Near Driveway) | `binary_sensor.driveway_zone_person_occupancy`, `…_car_occupancy` |
| `front_door` | `near_front_door` | `binary_sensor.near_front_door_person_occupancy` |

Driveway review alerts require `driveway_zone`. Older MQTT/docs that said `near_driveway` are obsolete for this install.

## Anti-hallucination notes

- Prompt is factual (light wit OK); no invented pets, plots, or dialogue.
- Junk detection rejects label-list echoes, quote-dialogue, and known garbage patterns → plain Frigate fallback text instead of spicy fiction.
- Prefer lower unique person counts when frames are ambiguous.

## Related exterior lighting

Frigate zone occupancy also drives flood lights when outdoor day/night sensors report dark:

| Automation | Trigger | Load |
| :--- | :--- | :--- |
| `automation.driveway_motion_activated_lights` | Driveway zone person/car | `light.flood_lights` |
| `automation.front_yard_motion_activated_flood_lights` | Near front door person | `light.flood_lights` (coordinated clear with driveway) |
| `automation.west_gate_flood_lights` | West gate open + dark | `switch.flood_lights_2` until closed + 2 min |

Removed: dusk-only driveway flood automation that fought camera day/night and stayed on all night.

## Superseded paths

- Legacy `East/West Gate Open Notification` YAML automations **removed** (broken device_tracker conditions; superseded by gate LLM blueprint).
- `automation.driveway_car_notification` retired (invalid / missing occupancy entity).

## Troubleshooting

| Symptom | Direction |
| :--- | :--- |
| Automation ran, no phone alert | LLM may have returned `CLEAR`/`OTHER`, or junk with no latched Frigate occupancy |
| Bland “Person/Vehicle at …” text | LLM marked unusable → intentional fallback |
| Invented pets/plots in text | Should be rejected as junk after Aug 2026 prompt harden; check helpers + reload automations |
| Wrong camera in GIF | Front steps use `camera.front_door` (Front Yard); driveway uses `camera.driveway` |
| Duplicate notifies | Confirm event coalesce (`event_clear_seconds`) and that legacy notify automations are gone |

## Related

- [Frigate Setup](frigate_setup.md)
- [Automations Catalog](automations_catalog.md)
- [LoRa Perimeter](lorawan_perimeter.md) (gate-open AI path)
- Config: `homeassistant/blueprints/automation/zone_activity_llm_vision.yaml`
- Live Frigate config (zones): docker-infrastructure NVR `frigate/config.yml`
