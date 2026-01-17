# 🌐 Network Infrastructure

## 🔭 Architecture Overview
The network utilizes a "Security-First" philosophy, leveraging a Layer 3 gateway (MikroTik hAP ac) to enforce isolation between the high-performance Perimeter, the general House LAN, and the IoT ecosystem. 

A key design feature is the **Multi-Homed Management Plane**, where the Network Controller sits on both the Perimeter and House LANs to optimize traffic flow and ensure high availability for UniFi devices.

## 📊 Global Topology Diagram
This diagram visualizes the flow from the Gateway through the distribution switches to the end-point clients and the cross-subnet management plane.

```mermaid
graph TD
    %% Core Gateway
    Router[MikroTik hAP ac Gateway]
    
    %% Perimeter/Server Side (CSS326 - 10.0.10.x)
    subgraph "Perimeter Subnet (10.0.10.x)"
        CSS326[MikroTik CSS326 Switch - 10.0.10.2]
        Beelink_P[Beelink NIC 1: Management]
        NAS1[Primary Storage]
        NAS2[Secondary Storage]
        NVR[Video Recorder]
        HA_Srv[The Home Assistant Server]
        MSN_NC[MSNSwitch: Network Controller]
        MSN_NAS[MSNSwitch: NAS1]
    end

    %% House Side (TP-Link - 192.168.89.x)
    subgraph "House & IoT (Bridge: home_lan)"
        TPSwitch[TP-Link TL-SG1024]
        PoE[PoE Texas Injector]
        Pine64[Pine64: MQTT Broker - 192.168.89.26]
        Beelink_H[Beelink NIC 2: UniFi Inform]
        
        subgraph "Wireless APs (192.168.89.x)"
            AP1[Basement]
            AP2[Office]
            AP3[Hallway]
            AP4[Backyard]
        end
    end

    %% Physical Links
    Router -- "Port 2" --- CSS326
    Router -- "Port 5" --- TPSwitch
    
    %% Perimeter Connections
    CSS326 ---|Port 2| MSN_NC
    CSS326 ---|Port 3| Beelink_P
    CSS326 ---|Port 4| NAS1
    CSS326 ---|Port 5| MSN_NAS
    CSS326 ---|Port 13| NAS2
    CSS326 ---|Port 23| NVR
    CSS326 ---|Port X| HA_Srv

    %% House Connections
    TPSwitch ---|Port 6| Beelink_H
    TPSwitch --- PoE
    PoE --- AP1 & AP2 & AP3 & AP4
    TPSwitch --- Pine64

    %% Management & Messaging Flow
    Beelink_H -.->|Direct L2 Inform| AP1 & AP2 & AP3 & AP4
    Pine64 <==>|Port 1883| HA_Srv