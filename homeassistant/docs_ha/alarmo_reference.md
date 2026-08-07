# Alarmo Reference

Read-only rebuild aid for the Alarmo panel. **Source of truth is** `.storage/alarmo.storage`
on the HA host (gitignored). This file documents architecture only — not codes, delays,
or bypass lists.

Status: Alarmo v1.10.18 installed; `alarm_control_panel.alarmo` operational (notify-only).

## Arm modes

| Mode | Interior sensors | Perimeter | Life safety |
| :--- | :--- | :--- | :--- |
| Armed Home | Bypassed | Trigger | Always on |
| Armed Away | Trigger (no delay) | Trigger | Always on |
| Disarmed | — | — | Always on |

Entry/exit delay durations live only in `.storage` / UI — not published here.

## Sensor tiers

### Approach — not in Alarmo

Frigate approach / outdoor person occupancy. Notification / LLM context only (Phase 3).

### Perimeter — both Home and Away

Primary doors are Yale/August `binary_sensor.*_door` contacts (not Z-Wave).
Yard gates remain YoLink.

| Entity | Source | Delay class |
| :--- | :--- | :--- |
| `binary_sensor.front_door_door` | Yale/August | Entry + exit |
| `binary_sensor.back_door_door` | Yale/August | Entry + exit |
| `binary_sensor.door_to_garage_door` | Yale/August | Entry |
| `binary_sensor.office_door_door` | Yale/August | Immediate |
| `binary_sensor.east_side_door_door` | YoLink | Immediate (gate) |
| `binary_sensor.fence_gate_door` | YoLink | Immediate (gate) |
| `binary_sensor.west_side_gate_door` | YoLink | Immediate (gate) |

Gate policy: all gates trigger immediately in **both** arm modes.

Legacy Z-Wave HomeSeer HS-DS100+ door sensors (Front/Back/Office) are disabled in the
device registry; do not re-enable them for intrusion detection.

### Interior — Away only

| Entity | Notes |
| :--- | :--- |
| `binary_sensor.master_bedroom_closet_presence_sensor_occupancy` | Aqara FP1E |
| `binary_sensor.presence_sensor_occupancy` | Basement FP1E |
| `binary_sensor.light_switch_motion_detection` | Low confidence — soak |
| `binary_sensor.light_switch_motion_detection_2` | Low confidence — soak |
| `binary_sensor.garage_hallway_light_switch_motion_detection` | Low confidence — soak |

Nest Protect `*_pir_test` entities are self-test indicators — excluded.

### Life safety — always on

Smoke/CO for basement, hallway, kitchen, office Nest Protects, plus
`binary_sensor.environmental_sensor_water_leak_detected`. Separate response path from
intrusion (Phase 3).

## Arming condition

`binary_sensor.security_arm_blocked` (on when `security_ready_to_arm` is off) is assigned
as an Alarmo sensor in both modes so arming is refused while supervision faults are active.
Do not also block on `binary_sensor.security_perimeter_open`.

## Soak-test rule

Panel notifications only until Phase 2 completes. One Alarmo notification automation fires
`notify.notify` on trigger. No siren, lock, light, or LLM actions.
