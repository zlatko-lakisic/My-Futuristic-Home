# NFC Entry and Yale Locks

Conceptual documentation for phone NFC tap-to-enter and the Yale smart locks that secure primary doors.

Wiki mirror: [Home Assistant NFC Entry](https://github.com/zlatko-lakisic/My-Futuristic-Home/wiki/Home-Assistant-NFC-Entry).

## Purpose

Explain the high-level architecture of NFC-assisted entry and inventory the lock hardware and integration path. This page is intentionally incomplete on operational detail.

## Security notice (read first)

Operational entry details are **intentionally not documented** in this public repository or wiki.

Do not publish or ask agents to publish:

- NFC tag UIDs or tag IDs
- Physical tag placement locations
- Exact unlock conditions, schedules, or presence rules
- Auto-unlock logic
- Lock user codes, slots, or PIN policy
- Alarm arm/disarm or bypass behavior tied to entry
- Door-to-automation maps that would reproduce the entry flow

What follows is architecture and hardware inventory only.

## How It Works (architecture only)

```
Phone NFC tap on a registered HA tag
        |
        v
Home Assistant tag scanned event
        |
        v
Per-tag automation (identity / authorization checks in HA)
        |
        v
Command to the matching Yale lock entity (August integration)
        |
        v
Optional presence / arrival side effects (not detailed here)
```

Home Assistant maintains a small **tag registry** (five named tags as of Jul 2026). Each tag has a corresponding enabled automation whose alias indicates which door the tap is associated with. Automations live in the live HA automation store. Entry YAML is not mirrored into docs.

Locks are controlled as standard `lock.*` entities. Google Assistant exposure exists for selected locks and related door sensors for voice use. Exact voice unlock policy is out of scope here.

## Lock inventory

Integration path: **August** cloud integration in Home Assistant (config entry loaded for the household August account). Devices are Yale hardware presented through that integration.

| Area | Lock entity | Friendly name | Manufacturer | Model |
| :--- | :--- | :--- | :--- | :--- |
| Hallway | `lock.front_door` | Front Door | August Home Inc. | BETA211123 |
| Kitchen | `lock.back_door` | Back Door | August Home Inc. | YRD420-WF1-BSP |
| Bottom Hallway | `lock.door_to_garage` | Door to Garage | August Home Inc. | YRD420-WF1-BSP |
| Office | `lock.office_door` | Office Door | August Home Inc. | BETA211123 |

Battery attributes are exposed on the lock entities for maintenance. Codes, slots, and auto-lock timings are managed in the Yale/August apps and are not listed here.

### Related (not NFC)

- Z-Wave HomeSeer door contacts on Back Door and Office Door report open/closed independently of the locks. See [Z-Wave Network](zwave_network.md).
- A HomeKit Controller entry for `LF009W4 (Door Lock)` exists in HA but is **not_loaded**. Primary path remains August/Yale.

## NFC tags (conceptual)

Five tags are registered in HA with human-readable names that correspond to the four locks plus a garage-related tag. Tag IDs, UIDs, and where the stickers live are omitted on purpose.

Enabled automations (aliases only):

- Tag Back Door Tag is scanned
- Tag Front Door is scanned
- Tag Office Door Tag is scanned
- Tag Door to Garage Tag is scanned
- Tag Garage Door Tag is scanned

## Automations (grouped by purpose)

| Purpose | What to know |
| :--- | :--- |
| NFC entry | One automation per registered tag. Triggers on tag scan. Performs authorization and lock actions. Details not documented. |
| Presence / arrivals | May consume lock or door state elsewhere. Do not treat this page as the presence design doc. |
| Voice | Selected `lock.*` entities are exposed to Google Assistant with friendly names. |

## Troubleshooting

| Symptom | Direction |
| :--- | :--- |
| Tap does nothing | Confirm phone NFC, HA Companion tag association, and that the matching tag automation is **on** |
| Lock unavailable in HA | Check August integration status and Yale/August cloud connectivity |
| Battery warnings | Use lock entity battery attributes. Replace cells in the Yale hardware |
| Need to change entry behavior | Edit automations only on the private HA instance. Do not commit entry logic to the public repo |

## Related

- [Z-Wave Network](zwave_network.md)
- [LoRa Perimeter (YoLink Gates)](lorawan_perimeter.md)
- Wiki: [Home Assistant Automations](https://github.com/zlatko-lakisic/My-Futuristic-Home/wiki/Home-Assistant-Automations)
