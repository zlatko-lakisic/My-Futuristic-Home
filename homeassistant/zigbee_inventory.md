# 🐝 Zigbee Device Inventory

This network is managed via the **Zigbee Home Automation (ZHA)** integration using a Generic EZSP Coordinator.

## **Infrastructure**
* **Coordinator:** Generic Zigbee Coordinator (EZSP)
* **Location:** Basement
* **IEEE:** `4c:5b:b3:ff:fe:d6:97:20`

## **Device List**

| Area | Device Name | Model | Manufacturer | IEEE Address |
| :--- | :--- | :--- | :--- | :--- |
| **Master Bedroom** | Closet Presence Sensor | Presence Sensor FP1E | Aqara | `54:ef:44:10:00:db:73:ba` |
| **Master Bedroom** | Closet Lights Top | TRADFRI Driver 30W | IKEA of Sweden | `7c:c6:b6:ff:fe:44:32:97` |
| **Master Bedroom** | Closet Light Bottom | TRADFRI Driver 30W | IKEA of Sweden | `70:54:64:ff:fe:2e:74:3f` |
| **Master Bedroom** | Closet Light Switch | RODRET Dimmer | IKEA of Sweden | `8c:6f:b9:ff:fe:ac:32:44` |
| **Kitchen** | Countertop Lights | TRADFRI Driver 10W | IKEA of Sweden | `70:54:64:ff:fe:2c:71:fa` |
| **Kitchen** | Countertop Light Switch | RODRET Dimmer | IKEA of Sweden | `6c:5c:b1:ff:fe:14:47:c3` |
| **Bottom Hallway** | Kitchenette Counter Light | TRADFRI Driver 10W | IKEA of Sweden | `60:b6:47:ff:fe:7a:ff:5f` |
| **Bottom Hallway** | Kitchenette Counter Light Switch | RODRET Dimmer | IKEA of Sweden | `8c:6f:b9:ff:fe:b4:0f:b6` |
| **Guest Bedroom** | Closet | TRADFRI Driver 10W | IKEA of Sweden | `28:76:81:ff:fe:fc:bf:cd` |
| **Guest Bedroom** | Closet Light Switch | RODRET Dimmer | IKEA of Sweden | `6c:5c:b1:ff:fe:14:3c:2c` |

## **Technical Notes**
* **Aqara FP1E:** Utilizes mmWave technology for high-fidelity presence detection in the Master Closet.
* **IKEA Drivers:** These act as Zigbee routers, significantly strengthening the mesh network across the kitchen and bedrooms.