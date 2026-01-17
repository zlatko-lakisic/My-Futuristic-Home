# 📡 Wireless Mesh Architecture

To ensure 100% reliability, the system uses two distinct mesh networks. This prevents 2.4GHz congestion and provides redundancy for critical infrastructure.

## 📊 Mesh Topology Diagram
```mermaid
graph TD
    %% Controllers connected to Server
    subgraph "SFF Server (i7-7700T)"
        HA[Home Assistant OS]
        USB[USB 2.0 Bus]
    end

    %% Zigbee Mesh
    subgraph "Zigbee 3.0 (2.4GHz)"
        DongleE[Sonoff ZBDongle-E]
        ZRouter[Mains-Powered Bulbs/Plugs]
        ZEnd[Battery Sensors/Buttons]
        
        DongleE --- ZRouter
        ZRouter --- ZEnd
        DongleE -.-> ZEnd
    end

    %% Z-Wave Mesh
    subgraph "Z-Wave 700 (Sub-GHz)"
        ZStick[Aeotec Z-Stick 7]
        ZW_Switch[Mains Switches/Repeaters]
        ZW_Lock[Door Locks/Security]
        
        ZStick --- ZW_Switch
        ZW_Switch --- ZW_Lock
        ZStick -.-> ZW_Lock
    end

    %% Physical Connections
    HA --> USB
    USB -- 2m Extender --- DongleE
    USB -- 2m Extender --- ZStick