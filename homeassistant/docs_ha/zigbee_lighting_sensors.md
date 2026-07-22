# Zigbee Lighting and Sensors

Site documentation for the ZHA mesh: SONOFF EZSP coordinator, IKEA lighting drivers and remotes, and Aqara mmWave presence sensors.

Wiki mirror: [Home Assistant Zigbee Lighting and Sensors](https://github.com/zlatko-lakisic/My-Futuristic-Home/wiki/Home-Assistant-Zigbee-Lighting-and-Sensors).

## Purpose

Document the Zigbee coordinator, lighting inventory, presence sensors, and the motion-to-light automation patterns that depend on them.

## How It Works

1. Home Assistant runs **Zigbee Home Automation (ZHA)**, not Zigbee2MQTT.
2. Coordinator: **SONOFF Zigbee 3.0 USB Dongle Plus V2** (ITEAD / EZSP), registered as `Generic Zigbee Coordinator (EZSP)` in the basement.
3. IKEA TRADFRI drivers are mains-powered Zigbee routers. RODRET remotes are battery endpoints that bind to those drivers.
4. Aqara FP1E presence sensors provide mmWave occupancy for closet and basement lighting automations.

Related radio overview: [Radio and Network Topology](radio_topology.md).

## Coordinator

| Field | Value |
| :--- | :--- |
| Integration | ZHA |
| Hardware | SONOFF Zigbee 3.0 USB Dongle Plus V2 (ITEAD) |
| HA device name | Generic Zigbee Coordinator (EZSP) |
| Area | Basement |
| IEEE | `4c:5b:b3:ff:fe:d6:97:20` |

## Inventory

Live snapshot (Jul 2026): **12** ZHA devices including the coordinator.

### Lighting (drivers and remotes)

| Area | Device | Manufacturer | Model | Role |
| :--- | :--- | :--- | :--- | :--- |
| Kitchen | Kitchen Countertop Lights | IKEA of Sweden | TRADFRI Driver 10W | Light / router |
| Kitchen | Kitchen Countertop Light Switch | IKEA of Sweden | RODRET Dimmer | Remote |
| Bottom Hallway | Kitchenette Counter Light | IKEA of Sweden | TRADFRI Driver 10W | Light / router |
| Bottom Hallway | Kitchenette Counter Light Switch | IKEA of Sweden | RODRET Dimmer | Remote |
| Master Bedroom | Master Bedroom Closet Lights Top | IKEA of Sweden | TRADFRI Driver 30W | Light / router |
| Master Bedroom | Master Bedroom Closet Light Bottom | IKEA of Sweden | TRADFRI Driver 30W | Light / router |
| Master Bedroom | Master Bedroom Closet Light Switch | IKEA of Sweden | RODRET Dimmer | Remote |
| Guest Bedroom | Closet | IKEA of Sweden | TRADFRI Driver 10W | Light / router |
| Guest Bedroom | Closet Light Switch | IKEA of Sweden | RODRET Dimmer | Remote |

### Presence / motion sensors

| Area | Device | Manufacturer | Model | Role |
| :--- | :--- | :--- | :--- | :--- |
| Master Bedroom | Master Bedroom Closet Presence Sensor | Aqara | Presence Sensor FP1E | mmWave presence |
| Basement | Basement Presence Sensor | Aqara | Presence Sensor FP1E | mmWave presence |

No Zigbee door/contact or outdoor motion sensors are on this coordinator today. Exterior motion used by lighting automations typically comes from Frigate occupancy entities instead.

## Automations

### Presence to light

| Automation | Pattern | Notes |
| :--- | :--- | :--- |
| `automation.master_bedroom_closet_motion_light` | Blueprint `homeassistant/motion_light.yaml` | FP1E motion entity to both closet TRADFRI drivers. Wait after clear: 5 s |
| `automation.basement_light_motion_sensor` | Same motion_light blueprint | Basement FP1E occupancy to Z-Wave `light.basement_light`. Wait: 30 s |

### RODRET remotes to drivers

| Automation | Role |
| :--- | :--- |
| `automation.kitchen_countertop_lights_on` / `..._off` | Kitchen countertop remote to driver |
| `automation.kitchenette_light_on` / `..._off` | Kitchenette remote to driver |
| `automation.master_bedroom_closet_light_switch_on` / `..._off` | Master closet remote |
| `automation.closet_lught_switch_on` / `automation.closet_light_ofg` | Guest closet remote (alias typos preserved in HA) |

### Schedule and other lighting

Sunset / sunrise automations and several Frigate-driven exterior motion light automations primarily target Z-Wave loads. See [Z-Wave Network](zwave_network.md).

## Troubleshooting

| Symptom | Direction |
| :--- | :--- |
| RODRET does nothing | Confirm ZHA device online, then rebind or re-pair remote near the driver |
| FP1E stuck occupied | Check ZHA interview, power, and sensitivity in device options |
| Weak mesh in a room | Prefer adding another TRADFRI driver (router) before another battery remote |
| Inventory drift | Compare with HA ZHA device list. Compact mirror: [zigbee_inventory.md](../zigbee_inventory.md) |

## Also on the network

Adjacent lighting control not on ZHA:

- **Lutron Caseta** bridge at `192.168.89.32` (separate HA integration).
- **Z-Wave** wall switches and exterior floods (primary house lighting mesh).

## Related

- [Z-Wave Network](zwave_network.md)
- [Radio and Network Topology](radio_topology.md)
- Compact table: [zigbee_inventory.md](../zigbee_inventory.md)
- Wiki: [Home Assistant Device Inventories](https://github.com/zlatko-lakisic/My-Futuristic-Home/wiki/Home-Assistant-Device-Inventories)
