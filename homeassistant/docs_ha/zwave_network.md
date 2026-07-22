# Z-Wave Network

Site documentation for the Z-Wave JS mesh: controller, lighting and switch inventory, door and environmental sensors, and how the mesh supports house lighting.

Wiki mirror: [Home Assistant Z-Wave Network](https://github.com/zlatko-lakisic/My-Futuristic-Home/wiki/Home-Assistant-Z-Wave-Network).

## Purpose

Provide a live-verified inventory of Z-Wave devices and mesh notes so lighting, fans, and contact sensors can be maintained without guessing models or areas.

## How It Works

1. Home Assistant runs the **Z-Wave JS** integration against a Silicon Labs **700/800 Series** controller (device name `Zwave Controller`, basement).
2. Mains-powered wall switches and dimmers act as mesh repeaters. Dedicated Aeotec range extenders thicken the mesh between floors.
3. Battery nodes (door sensors, environmental sensor, and one unnamed front-door node) rely on nearby mains nodes for routing.
4. Entities surface mainly as `light.*`, `switch.*`, and `binary_sensor.*` / `sensor.*` under Z-Wave JS.

Related radio overview: [Radio and Network Topology](radio_topology.md).

## Inventory

Live snapshot from the Home Assistant device registry (Jul 2026): **32** Z-Wave JS devices including the controller.

### Controller

| Field | Value |
| :--- | :--- |
| Integration | Z-Wave JS |
| Name | Zwave Controller |
| Manufacturer | Silicon Labs |
| Model | 700/800 Series |
| Firmware | 7.0 |
| Area | Basement |

### Lighting and switches (mains / repeater capable)

| Area | Name | Manufacturer | Model | SW |
| :--- | :--- | :--- | :--- | :--- |
| Back Yard | Flood Lights | GE/Enbrighten | 46201 / ZW4008 | 5.54 |
| Back Yard | Porch Light | GE/Enbrighten | 46201 / ZW4008 | 5.54 |
| Basement | Basement Light | Enbrighten | 52252 / ZW3012 | 7.6.5 |
| Bedroom Hallway | House Fan | GE/Enbrighten | 46201 / ZW4008 | 5.54 |
| Bedroom Hallway | Light Switch | GE/Enbrighten | 26933 / ZW3008 | 5.32 |
| Bottom Hallway | Garage Hallway Light Switch | GE/Enbrighten | 26933 / ZW3008 | 5.32 |
| Bottom Hallway | Kitchenette Light | Enbrighten | 52252 / ZW3012 | 7.6.5 |
| Dining Room | Light Switch | GE/Enbrighten | 46201 / ZW4008 | 5.54 |
| Driveway | Flood Lights | Enbrighten | 52252 / ZW3012 | 7.6.5 |
| Front yard | Flood Lights | GE/Enbrighten | 46201 / ZW4008 | 5.54 |
| Front yard | Front Door Light | GE/Enbrighten | 46201 / ZW4008 | 5.54 |
| Front yard | Walkway Light | Eaton | RF9601 | 2.20 |
| Garage | Garage Light | Enbrighten | 52252 / ZW3012 | 7.6.5 |
| Guest Bathroom | Light Switch | GE/Enbrighten | 46201 / ZW4008 | 5.54 |
| Guest Bedroom | Light Switch | GE/Enbrighten | 46201 / ZW4008 | 5.54 |
| Hallway | Light Switch | Enbrighten | 52252 / ZW3012 | 7.6.5 |
| Kitchen | Light Switch | GE/Enbrighten | 26931 / ZW4006 | 5.39 |
| Living Room | Light Switch | GE/Enbrighten | 46201 / ZW4008 | 5.54 |
| Master Bedroom | Master bedroom light switch | GE/Enbrighten | 46201 / ZW4008 | 5.54 |
| Master Bedroom | Vanity | Minoston | MP21Z / MP31Z | 1.0.0 |
| Middle Bedoom | Middle room light switch | Enbrighten | 52252 / ZW3012 | 7.6.5 |
| Office | Light switch | Enbrighten | 52252 / ZW3012 | 7.6.5 |
| Office | Steps Light Switch | GE/Enbrighten | 46201 / ZW4008 | 5.54 |

### Range extenders

| Area | Name | Manufacturer | Model | SW |
| :--- | :--- | :--- | :--- | :--- |
| Kitchen | Range Extender 2 | Aeotec Ltd. | ZW189-C15 | 1.5.0 |
| Bottom Hallway | Range Extender | Aeotec Ltd. | ZW189-C15 | 1.5.0 |

### Battery sensors

| Area | Name | Manufacturer | Model | SW | Role |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Kitchen | Back Door | HomeSeer Technologies | HS-DS100+ | 2.3.0 | Door/contact |
| Office | Office Door | HomeSeer Technologies | HS-DS100+ | 2.3.0 | Door/contact |
| Hallway | Front Door | (generic / incomplete registry) | | | Door-related node |
| Basement | Environmental Sensor | Aeotec Ltd. | ZWA019 | 2.3.1 | Environment |
| Basement | Node 35 | | | | Incomplete node |
| Garage | Node 34 | | | | Incomplete node |

## Mesh topology notes

- **Controller** in the basement is the sole Z-Wave JS primary.
- **Repeaters:** wall switches/dimmers plus two Aeotec `ZW189-C15` extenders (Kitchen, Bottom Hallway) for inter-floor RF.
- **Battery count:** four devices currently expose Z-Wave battery entities (two HomeSeer doors, environmental sensor, Front Door node). Incomplete `Node 34` / `Node 35` entries should be healed or excluded if they never finish interview.
- Primary manufacturers: GE/Enbrighten, Aeotec, HomeSeer, Eaton, Minoston.

## Automations

Z-Wave devices are mostly actuation targets rather than exclusive triggers:

| Automation | Role |
| :--- | :--- |
| `automation.sunset_turn_on_lights` / `automation.sunrise_turn_off_lights` | Exterior and common-area lighting schedule |
| `automation.basement_light_motion_sensor` | Basement light from presence (ZHA sensor) onto Z-Wave basement light |
| `automation.dim_bedroom_hallway_light` | Hallway light behavior |
| Driveway / front door / back yard motion light automations | Often Frigate motion into Z-Wave flood/porch lights (several currently **off**) |

## Inclusion / exclusion

Use Z-Wave JS UI (or HA Z-Wave JS panels) for include/exclude. Prefer mains devices included first so battery nodes have neighbors. After moving a repeater, run a network heal and confirm battery nodes still report.

## Troubleshooting

| Symptom | Direction |
| :--- | :--- |
| Dead wall switch | Confirm breaker, then Z-Wave JS node status and last heard |
| Battery door sensor stale | Check extender placement and heal routes toward Kitchen / Bottom Hallway |
| `Node 34` / `Node 35` with empty model | Re-interview or exclude if unused |
| Inventory drift | Refresh from HA device registry. Older `zwave_inventory.md` is a compact table mirror |

## Related

- Compact table: [zwave_inventory.md](../zwave_inventory.md)
- [Zigbee Lighting and Sensors](zigbee_lighting_sensors.md)
- [Radio and Network Topology](radio_topology.md)
- Wiki: [Home Assistant Device Inventories](https://github.com/zlatko-lakisic/My-Futuristic-Home/wiki/Home-Assistant-Device-Inventories)
