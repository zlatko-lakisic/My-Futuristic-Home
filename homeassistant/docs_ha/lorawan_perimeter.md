# LoRa Perimeter (YoLink Gates)

Site documentation for the long-range gate contact sensors and the gate-open to AI camera summary workflow.

Wiki mirror: [Infrastructure LoRaWAN Perimeter](https://github.com/zlatko-lakisic/My-Futuristic-Home/wiki/Infrastructure-LoRaWAN-Perimeter).

## Purpose

Describe how perimeter gate contacts reach Home Assistant, which entities exist, and how a gate-open event becomes a phone notification with an AI people classification.

## Important naming note

These sensors are **YoLink DoorSensor** devices on the HA **YoLink** integration. YoLink uses a proprietary LoRa-family radio to a YoLink hub/cloud path, then into Home Assistant. There is no ChirpStack / TTN / DIY LoRaWAN network server in this install. This page keeps the "LoRa perimeter" title for the long-range outdoor contacts while documenting the live YoLink path.

## How It Works

1. Each gate has a YoLink door/contact sensor.
2. YoLink reports open/closed into HA as `binary_sensor.*_door` (device class door) plus battery and signal entities.
3. Enabled automations use blueprint `gate_open_llm_vision_people.yaml`:
   - Trigger: gate sensor goes to open (`on`).
   - Capture several JPEG stills from the paired Frigate/go2rtc camera entity.
   - Send the still set to **Comstar Vision** `image_analyzer` (AO Reach on ADA).
   - Parse a three-line reply: classification (`PEOPLE` / `DOG` / `NOPEOPLE`), home log line, short phone line.
   - Latch Frigate person and dog occupancy during the still burst. A dog must not be notified as a person.
   - If vision output is unusable, fall back to those Frigate occupancy entities.
   - On `PEOPLE` or `DOG`, notify mobile app devices and write helpers under `input_text.gate_ai_*` / `input_datetime.gate_ai_last_analysis_time`.
4. Older standalone "Gate Open Notification" automations that called `script.process_ai_analysis_and_notification` were **removed** (broken device conditions; superseded by blueprint instances). On vision failure the gate blueprint still notifies with a short FALLBACK “{gate} opened” message plus GIF.

## Gateway path into HA

```
YoLink DoorSensor (LoRa-family radio)
        |
        v
YoLink hub / cloud
        |
        v
Home Assistant integration: yolink
        |
        +--> binary_sensor.<gate>_door
        +--> sensor.<gate>_battery
        +--> sensor.<gate>_signal_strength
```

Config entry title in HA: **YoLink** (loaded).

## Gate sensor inventory

Live snapshot (Jul 2026). Area assignment for all three: Back Yard. Physical placement maps are intentionally omitted.

| Friendly name | Device | Contact entity | Battery | Notes |
| :--- | :--- | :--- | :--- | :--- |
| East Side Gate | East Side Door (YoLink DoorSensor) | `binary_sensor.east_side_door_door` | `sensor.east_side_door_battery` | Active AI analysis automation |
| West Gate | West Gate (YoLink DoorSensor) | `binary_sensor.west_side_gate_door` | `sensor.west_side_gate_battery` | Active AI analysis automation |
| Fence Gate Door | Fence Gate (YoLink DoorSensor) | `binary_sensor.fence_gate_door` | `sensor.fence_gate_battery` | Back yard / fence gate AI analysis |

Signal strength entities exist per sensor. Values fluctuate with radio conditions.

## Gate to AI camera summary workflow

```
Gate contact opens (YoLink binary_sensor -> on)
        |
        v
Automation (blueprint gate_open_llm_vision_people)
        |
        +--> Snapshot N still JPEGs from paired camera entity
        |         (Frigate / go2rtc camera.*, short interval)
        |
        v
Comstar Vision image_analyzer (AO Reach ADA, appId comstar-vision)
        |
        +--> Line 1: PEOPLE or DOG or NOPEOPLE
        +--> Line 2: home log summary
        +--> Line 3: short phone alert text
        |
        +--(optional)--> Frigate person / dog occupancy fallback
        |
        v
If PEOPLE or DOG: notify.mobile_app_* (+ person-linked devices)
        |
        v
Helpers: gate_ai_last_gate / classification / summary / analysis_time
        |
        v
Notification tap opens backyard dashboard path for that camera
```

### Live automation instances

| Automation | Gate sensor | Camera | Status (Aug 2026) |
| :--- | :--- | :--- | :--- |
| `automation.east_gate_open_ai_analysis` | `binary_sensor.east_side_door_door` | `camera.east_side` | **on** |
| `automation.west_gate_open_ai_analysis` | `binary_sensor.west_side_gate_door` | `camera.west_side_2` | **on** |
| `automation.back_yard_gate_open_ai_analysis` | `binary_sensor.fence_gate_door` | `camera.back_yard_2` | **on** |

Source instances: `homeassistant/automations/02_ai_and_notifications.yaml`. Blueprint: `homeassistant/blueprints/automation/gate_open_llm_vision_people.yaml`.

Helpers in `configuration.yaml`: `input_text.gate_ai_last_gate`, `gate_ai_last_classification`, `gate_ai_last_summary`, `input_datetime.gate_ai_last_analysis_time`.

### Inference path

Vision analysis uses **Comstar Vision** (`comstar_vision.image_analyzer`) over **AO Reach** to the ADA engine:

`https://10.0.10.16:8765` (WSS `/ws`, `appId: comstar-vision`)

Mint API + mTLS enrollment tokens separately — see [ao_api_tokens.md](ao_api_tokens.md). Multimodal `images` on Reach chat is required ([handoff](https://github.com/zlatko-lakisic/hacs-comstar-vision/blob/main/docs/AO_REACH_MULTIMODAL_HANDOFF.md)). AO selects the vision model; configure agents / MCPs / skills / harness in the Comstar Vision options. This is separate from Jetson watering and from Comstar Assist (`comstar-ha`). Frigate supplies the camera feed and optional person/dog occupancy fallback.

## Troubleshooting

| Symptom | Direction |
| :--- | :--- |
| Gate stuck closed/open in HA | Check YoLink app/cloud, battery %, and HA YoLink integration |
| AI automation runs but no phone alert | Classification may be `NOPEOPLE`, or notify service / person devices misconfigured |
| GIF shows a dog but notify says person | LLM must classify `DOG`; Frigate dog occupancy demotes PEOPLE when no person was latched |
| Vision fails / junk tool-call text | Blueprint falls back to Frigate person/dog sensors when configured |
| Duplicate gate notifications | Legacy `East/West Gate Open Notification` automations were removed; only blueprint AI analysis instances should remain |
| MQTT / Frigate occupancy unavailable | Camera stills can still work over HTTP. Occupancy fallback needs Frigate MQTT healthy |

## Related

- [Frigate Setup](frigate_setup.md)
- [Zone Activity AI](zone_activity_ai.md) (driveway / front-steps zone alerts)
- [Z-Wave Network](zwave_network.md) (Z-Wave is lighting/mesh; primary doors are Yale/August)
- Automations file: `homeassistant/automations/02_ai_and_notifications.yaml`
- Wiki: [Services Frigate](https://github.com/zlatko-lakisic/My-Futuristic-Home/wiki/Services-Frigate)
