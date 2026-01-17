# 🌐 Network Infrastructure

## 🔭 Architecture Overview
The network utilizes a "Security-First" philosophy, leveraging a Layer 3 gateway (MikroTik hAP ac) to enforce isolation between the high-performance Perimeter, the general House LAN, and the IoT ecosystem.

## 📊 Global Topology Diagram
This diagram visualizes the flow from the Gateway through the distribution switches to the end-point clients and the cross-subnet management plane.

```mermaid
graph TD
    %% Core Gateway
    Router[MikroTik hAP ac Gateway]
    
    %% Perimeter/Server Side (U8/U4/U1-3)
    subgraph "Perimeter Subnet (10.0.10.x)"
        CSS326[MikroTik CSS326 Switch]
        Beelink[Beelink EQ14: UniFi Controller]
        NAS1[Primary Storage]
        NAS2[Secondary Storage]
        NVR[Video Recorder]
        SFF[i7-7700T: HAOS Host]
    end

    %% House Side (U5/U6/U7)
    subgraph "House & IoT (Bridge: home_lan)"
        TPSwitch[TP-Link TL-SG1024]
        PoE[PoE Texas Injector]
        Pine64[Pine64: MQTT Broker - 192.168.89.26]
        
        subgraph "Wireless APs (192.168.89.x)"
            AP1[Basement]
            AP2[Office]
            AP3[Hallway]
            AP4[Backyard]
        end
    end

    %% Physical Links
    Router -- Port 2 --- CSS326
    Router -- Port 5 --- TPSwitch
    
    CSS326 --- Beelink & SFF & NAS1 & NAS2 & NVR
    
    TPSwitch --- PoE
    PoE --- AP1 & AP2 & AP3 & AP4
    TPSwitch --- Pine64

    %% Management & Messaging Flow
    Beelink -.->|L3 Adoption| AP1 & AP2 & AP3 & AP4
    Pine64 <==>|Port 1883| SFF
    Router -- VPN --- Remote[172.16.91.x Clients]