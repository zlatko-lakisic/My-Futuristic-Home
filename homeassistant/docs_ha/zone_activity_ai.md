# Zone Activity AI Notifications

Frigate zone occupancy → snapshot GIF → **Comstar Vision** (AO Reach on ADA) → phone notify for driveway and front steps.

Wiki mirror: [Home Assistant Automations](https://github.com/zlatko-lakisic/My-Futuristic-Home/wiki/Home-Assistant-Automations) (catalog section), blueprint notes on [Home Assistant Blueprints](https://github.com/zlatko-lakisic/My-Futuristic-Home/wiki/Home-Assistant-Blueprints).

## Purpose

Document the `zone_activity_llm_vision` blueprint and live instances that replace older driveway-car / script-based notify paths with coalesced, zone-scoped AI alerts.

## How it works

1. Frigate reports person and/or car occupancy in a named zone (`driveway_zone`, `near_front_door`).
2. On a car-first visit, capture starts immediately (live still + Frigate detection snapshot as frame 1). Person-wait happens **after** those early frames so the vehicle is not already gone. Remaining stills can still pick up a driver.
3. Automation waits for Frigate LPR (`sensor.driveway_last_recognized_plate`) to update from the AI server, then asks Comstar Vision to describe.
4. Frigate face sub-labels for the visit are resolved when configured.
5. Comstar Vision (`comstar_vision.image_analyzer` → ADA AO Reach `:8765`, `appId: comstar-vision`) analyzes the **first few** frames (GIF keeps the full burst) so empty late frames do not force `CLEAR`/junk. AO picks the vision model from the engine catalog (plugin overlays agents / MCPs / skills / harness — no model pin). Multimodal Reach: [hacs-comstar-vision handoff](https://github.com/zlatko-lakisic/hacs-comstar-vision/blob/main/docs/AO_REACH_MULTIMODAL_HANDOFF.md).
6. Reply must be three plain lines: classification (`PERSON` / `CAR` / `DOG` / `OTHER` / `CLEAR`), home log (≤160), phone line (≤100).
   - Family Car (LPR known plate): say Family Car — no grey Hyundai SUV / color / make / model.
   - Unknown vehicle: color + make/model, and a plate if LPR or the stills clearly show one.
7. Notify only for confirmed activity:
   - Driveway: `PERSON` or `CAR` (or Frigate latch fallback if vision junk).
   - Front steps: `PERSON` only (`people_only: true`).
8. Event holds until trigger sensors stay clear for `event_clear_seconds` (default 180) so one visit does not spam.

Occupancy used for fallback is **latched** during the visit (trigger + capture), including optional dog occupancy for “with dog” fallback text. Checking live Frigate state after a long capture+LLM window was dropping real alerts.

Driveway capture is tuned for cars that cross the apron quickly: settle 0 on car-first, 8 frames @ 1s (first 4 immediately, then up to 12s for a person before the rest). LPR wait is 15s before the vision description.

## Live instances

Source: `homeassistant/automations/02_ai_and_notifications.yaml`. Blueprint: `homeassistant/blueprints/automation/zone_activity_llm_vision.yaml`.

| Automation | Triggers | Camera | Mode |
| :--- | :--- | :--- | :--- |
| `automation.near_driveway_zone_ai_analysis` | `binary_sensor.driveway_zone_person_occupancy`, `…_car_occupancy` | `camera.driveway` (Frigate `driveway`) | Person + car; wait for LPR; Family Car vs unknown plate |
| `automation.near_front_door_zone_ai_analysis` | `binary_sensor.near_front_door_person_occupancy` | `camera.front_door` (Front Yard / Frigate `front_door`) | People only |

Shared helpers (`input_text.gate_ai_last_*`, `input_datetime.gate_ai_last_analysis_time`) store the latest analysis for dashboard/debug (shared with gate AI).

### Driveway vehicle context

Optional blueprint input `known_vehicle_hint` is **name-only** (e.g. Family Car) — never put plate digits in the LLM prompt (models echo them into every CAR notify).

Notify titles / `Plate:` lines use Frigate LPR via `recognized_plate_sensor` (`sensor.driveway_last_recognized_plate`). Household plate **KXS-9837** is configured in Frigate `known_plates` as Family Car. The automation waits for that sensor to change, then the LLM is told the LPR result: Family Car is named, not described as a grey Hyundai SUV; any other plate is included and the model may also read characters that are clearly visible. It still must not invent plates.

### Notification length caps

| Surface | Cap |
| :--- | :--- |
| Push title | ≤ 50 characters (Frigate plate/name may appear when LPR matched) |
| Push body | ≤ 100 characters |
| HA persistent home log | ≤ 160 characters |

## Frigate zones

| Camera | Zone id | HA occupancy examples |
| :--- | :--- | :--- |
| `driveway` | `driveway_zone` (friendly: Near Driveway) | `binary_sensor.driveway_zone_person_occupancy`, `…_car_occupancy` |
| `front_door` | `near_front_door` | `binary_sensor.near_front_door_person_occupancy` |

Driveway review alerts require `driveway_zone`. Detect is **1280×720**. Aug 2026 cleanup tightened the zone (cut road + parked pad), added person/car `min_area` / score filters, and extended the top-road motion mask. Older MQTT/docs that said `near_driveway` are obsolete for this install.

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
| “Name with dog at …” fallback | Frigate face + latched dog occupancy; LLM still failed but notify is useful |
| Same plate on every car notify | Was LLM hint-echo of plate digits in `known_vehicle_hint`; titles now use Frigate LPR only |
| Grey Hyundai SUV for the household car | LPR must finish first; Family Car should replace color/make/model in the body |
| Car barely in the first GIF frame | Car-first used to wait 12s for a person before any still; capture now starts immediately |
| Empty driveway notifies | Check Frigate `driveway_zone` occupancy history first (zone/filters/masks); HA only follows occupancy |
| Good Frigate event, empty/late GIF | Driveway burst should start at occupancy; first frame is the Frigate event snapshot when available |
| Wrong camera in GIF | Front steps use `camera.front_door` (Front Yard); driveway uses `camera.driveway` |
| Duplicate notifies | Confirm event coalesce (`event_clear_seconds`) and that legacy notify automations are gone |

## Related

- [Cross-camera tracking](cross_camera_tracking.md)
- [Frigate Setup](frigate_setup.md)
- [Automations Catalog](automations_catalog.md)
- [LoRa Perimeter](lorawan_perimeter.md) (gate-open AI path)
- Config: `homeassistant/blueprints/automation/zone_activity_llm_vision.yaml`
- Live Frigate config (zones): docker-infrastructure NVR `frigate/config.yml`
