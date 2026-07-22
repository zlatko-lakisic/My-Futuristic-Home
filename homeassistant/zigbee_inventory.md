# 🐝 Zigbee Device Inventory

Compact table mirror. Narrative docs: [docs_ha/zigbee_lighting_sensors.md](docs_ha/zigbee_lighting_sensors.md).

This network is managed via **Zigbee Home Automation (ZHA)** using a **SONOFF Zigbee 3.0 USB Dongle Plus V2** (Generic Zigbee Coordinator EZSP).

## Infrastructure

* **Coordinator:** Generic Zigbee Coordinator (EZSP) / SONOFF Zigbee 3.0 USB Dongle Plus V2
* **Location:** Basement
* **IEEE:** `4c:5b:b3:ff:fe:d6:97:20`
* **Device count (Jul 2026):** 12 including coordinator

## Device List

| Area | Device Name | Model | Manufacturer |
| :--- | :--- | :--- | :--- |
| Master Bedroom | Master Bedroom Closet Presence Sensor | Presence Sensor FP1E | Aqara |
| Master Bedroom | Master Bedroom Closet Lights Top | TRADFRI Driver 30W | IKEA of Sweden |
| Master Bedroom | Master Bedroom Closet Light Bottom | TRADFRI Driver 30W | IKEA of Sweden |
| Master Bedroom | Master Bedroom Closet Light Switch | RODRET Dimmer | IKEA of Sweden |
| Kitchen | Kitchen Countertop Lights | TRADFRI Driver 10W | IKEA of Sweden |
| Kitchen | Kitchen Countertop Light Switch | RODRET Dimmer | IKEA of Sweden |
| Bottom Hallway | Kitchenette Counter Light | TRADFRI Driver 10W | IKEA of Sweden |
| Bottom Hallway | Kitchenette Counter Light Switch | RODRET Dimmer | IKEA of Sweden |
| Guest Bedroom | Closet | TRADFRI Driver 10W | IKEA of Sweden |
| Guest Bedroom | Closet Light Switch | RODRET Dimmer | IKEA of Sweden |
| Basement | Basement Presence Sensor | Presence Sensor FP1E | Aqara |

## Technical Notes

* **Aqara FP1E:** mmWave presence for master closet and basement motion-to-light automations.
* **IKEA TRADFRI drivers:** act as Zigbee routers for the kitchen, kitchenette, and bedroom closets.
