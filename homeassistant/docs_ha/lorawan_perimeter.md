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
   - Send the still set to **LLM Vision** `image_analyzer` (model currently `gpt-4o-mini`).
   - Parse a three-line reply: classification (`PEOPLE` / `NOPEOPLE`), home log line, short phone line.
   - If vision output is unusable, optionally fall back to a Frigate person occupancy entity.
   - On `PEOPLE`, notify mobile app devices and write helpers under `input_text.gate_ai_*` / `input_datetime.gate_ai_last_analysis_time`.
4. Older standalone "Gate Open Notification" automations that call `script.process_ai_analysis_and_notification` exist but are largely **off** or superseded by the blueprint instances.

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
LLM Vision image_analyzer (gpt-4o-mini)
        |
        +--> Line 1: PEOPLE or NOPEOPLE
        +--> Line 2: home log summary
        +--> Line 3: short phone alert text
        |
        +--(optional)--> Frigate person occupancy fallback
        |
        v
If PEOPLE: notify.mobile_app_* (+ person-linked devices)
        |
        v
Helpers: gate_ai_last_gate / classification / summary / analysis_time
        |
        v
Notification tap opens backyard dashboard path for that camera
```

### Live automation instances

| Automation | Gate sensor | Camera | Status (Jul 2026) |
| :--- | :--- | :--- | :--- |
| `automation.east_gate_open_ai_analysis_2` | `binary_sensor.east_side_door_door` | `camera.east_side` | **on** |
| `automation.west_gate_open_ai_analysis` | `binary_sensor.west_side_gate_door` | `camera.west_side_2` | **on** |
| `automation.back_yard_gate_open_ai_analysis` | `binary_sensor.fence_gate_door` | `camera.back_yard_2` | **on** |

Source instances: `homeassistant/automations/02_ai_and_notifications.yaml`. Blueprint: `homeassistant/blueprints/automation/gate_open_llm_vision_people.yaml`.

Helpers in `configuration.yaml`: `input_text.gate_ai_last_gate`, `gate_ai_last_classification`, `gate_ai_last_summary`, `input_datetime.gate_ai_last_analysis_time`.

### Inference path

Vision analysis uses the **LLM Vision** integration provider configured in the blueprint (OpenAI-compatible / cloud vision model `gpt-4o-mini`), not the Jetson Ollama watering endpoint. Frigate supplies the camera feed and optional person occupancy fallback. Notifications go to the configured mobile notify service and person entities.

## Troubleshooting

| Symptom | Direction |
| :--- | :--- |
| Gate stuck closed/open in HA | Check YoLink app/cloud, battery %, and HA YoLink integration |
| AI automation runs but no phone alert | Classification may be `NOPEOPLE`, or notify service / person devices misconfigured |
| Vision fails / junk tool-call text | Blueprint falls back to Frigate person sensor when configured |
| Legacy notification automations fire twice | Keep superseded `East/West Gate Open Notification` automations **off** |
| MQTT / Frigate occupancy unavailable | Camera stills can still work over HTTP. Occupancy fallback needs Frigate MQTT healthy |

## Related

- [Frigate Setup](frigate_setup.md)
- [Z-Wave Network](zwave_network.md) (interior door contacts are Z-Wave, not YoLink)
- Automations file: `homeassistant/automations/02_ai_and_notifications.yaml`
- Wiki: [Services Frigate](https://github.com/zlatko-lakisic/My-Futuristic-Home/wiki/Services-Frigate)
