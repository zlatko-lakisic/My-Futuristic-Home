# Security System

Self-monitored intrusion detection on Home Assistant using Alarmo as the arm-state
machine and Git-tracked packages/automations for supervision and response logic.

This is **not** a monitored alarm. No central station, no police dispatch. The design
goal is detection quality and evidence capture (including LLM camera verification before
escalation), not professional response.

Wiki mirror: (add when published).

## Purpose

Document architecture, sensor tiers, supervision health, notification targets, and
presence prerequisites. Operational parameters that would reproduce arm/disarm or entry
behaviour are omitted — see [NFC Entry](nfc_entry.md) publication boundary.

## Architecture

```
Perimeter / interior / life-safety sensors
        |
        v
Supervision package (security_ready_to_arm + fault sensors)
        |
        v
Alarmo panel (arm modes Home / Away; config in .storage)
        |
        +-- Phase 2: silent soak (notify only)
        |
        v
Phase 3+: response automations (LLM verify, locks, siren) — not yet built
```

## Supervision (Phase 0)

Package: `packages/security_supervision.yaml`

| Entity | Role |
| :--- | :--- |
| `binary_sensor.security_perimeter_open` | Any perimeter contact open; `open_list` |
| `binary_sensor.security_tamper_detected` | Placeholder (always off — Yale does not expose tamper) |
| `binary_sensor.security_low_battery` | Yale / YoLink numeric battery &lt; 20%; `low_list` |
| `binary_sensor.security_sensor_unavailable` | Watched sensors unavailable/unknown |
| `binary_sensor.security_sensor_stale` | Perimeter contact unchanged &gt; 48h (tunable) |
| `binary_sensor.security_ready_to_arm` | All of the above faults clear (excludes open doors) |

Open perimeter contacts are **not** folded into `security_ready_to_arm`. Alarmo handles
open-sensor arming per mode; duplicating that block makes refusals ambiguous.

## Zones and presence

`zone.home` is the presence anchor for occupancy-based arming. Radius is **150 m**
(configured under `homeassistant:` in `configuration.yaml` and `.storage/core.config`) to
absorb GPS drift so presence-based arming does not phantom-depart while someone is home.

### Residents for occupancy

| Person | Role |
| :--- | :--- |
| `person.zlatko_lakisic` | Resident |
| `person.adna_zujo_lakisic` | Resident |
| `person.ibrica_lakisic` | Resident |
| `person.md_admin` | System / service account — **exclude** from occupancy |
| `person.google_home` | System / service account — **exclude** from occupancy |

Do **not** use MikroTik MAC `device_tracker` entities for presence — they track devices on
the LAN, not people.

## Notification targets and tiers

Live companion notify entities (HA entity notify domain — not `notify.mobile_app_*`):

| Target | Person | Use for alarm |
| :--- | :--- | :--- |
| `notify.zlatko_galaxy` | Zlatko | Yes |
| `notify.ada_samsung` | Adna | Yes |
| `notify.ibrica_samsung` | Ibrica | Yes |
| `notify.adna_s24_ultra` | Adna (second phone) | Optional / confirm ownership |
| `notify.kiosk_ipad` | Wall kiosk | **Never** — visible from outside |

Routine automations still use `notify.notify` (fan-out). Intrusion paths should target the
three phones above explicitly.

| Tier | Use | Delivery |
| :--- | :--- | :--- |
| Informational | Gate opened, system disarmed | Normal priority |
| Warning | Supervision fault, tamper while disarmed | Normal, persistent |
| Alarm | Verified intrusion | High priority, Android doze bypass |

Alarm-tier Android payload requirements: dedicated `channel`, `importance: high`,
`priority: high`, `ttl: 0`. Channel settings are user-controlled — keep alarm traffic on a
dedicated channel so DND exemptions stay independent of routine notifications.

All confirmed household phones are Android. No iOS critical-push path is required unless a
new companion device appears.

## Sensor tier model (concept)

| Tier | Armed Home | Armed Away | Notes |
| :--- | :--- | :--- | :--- |
| Approach | notify only | notify only | Frigate approach zones — not Alarmo sensors |
| Perimeter | trigger | trigger | Gates immediate in both modes |
| Interior | bypassed | trigger | Lighting PIR expected noisy in soak |
| Life safety | always | always | Separate response path from intrusion |

Delay durations, codes, bypass lists, and auto-arm schedules are not published here.

## Related

- [NFC Entry](nfc_entry.md) — publication boundary for entry / arm behaviour
- [HACS Plugins](hacs_plugins.md) — Alarmo listing after install
- `packages/security_supervision.yaml` — health sensors
- `docs_ha/alarmo_reference.md` — panel rebuild aid (after Phase 1)
