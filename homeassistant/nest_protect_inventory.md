# 🛡️ Nest Protect Inventory (Smoke & CO)

This file documents the Google Nest Protect (Gen 2) ecosystem integrated into Home Assistant. These devices provide critical life-safety monitoring and supplemental occupancy data.

## **Integration Overview**
- **Integration:** [Nest Protect (HACS)](https://github.com/iMicknl/ha-nest-protect)
- **Model:** Topaz-2.33 (2nd Gen)
- **Power Type:** Battery
- **Communication:** Wi-Fi (Cloud Push)

## **Device List**

| Area | Device Name | MAC Address | Serial Number | SW Version |
| :--- | :--- | :--- | :--- | :--- |
| **Kitchen** | Nest Protect (Kitchen) | `cc:a7:c1:69:fa:07` | `06AA01AC362203QA` | 3.6rc8 |
| **Basement** | Nest Protect (Basement) | `cc:a7:c1:6a:03:af` | `06AA01AC362203QM` | 3.6rc8 |
| **Bedroom Hallway** | Nest Protect (Hallway) | `cc:a7:c1:69:e0:cc` | `06AA01AC362203VD` | 3.6rc8 |
| **Office** | Nest Protect (Office) | `44:bb:3b:9e:13:0c` | `06AA01AC1123060S` | 3.6rc8 |

## **Key Entities per Device**
- **Binary Sensors:** Smoke Status, CO Status, Battery Health.
- **Occupancy:** Motion detection (useful for "Away" logic).
- **Sensors:** Heat level, Humidity.

## **Safety Automations**
1. **Emergency Lighting:** If smoke is detected by any Protect, all Z-Wave/Zigbee lights turn on at 100% and the NVR starts priority recording.
2. **HVAC Shutdown:** If CO or Smoke is detected, the thermostat is set to "Off" to prevent circulating fumes.
3. **Voice Alert:** Google Nest speakers announce the specific room where danger is detected.