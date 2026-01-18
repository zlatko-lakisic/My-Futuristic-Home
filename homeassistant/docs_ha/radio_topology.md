# 📡 Radio & Network Topology

This document maps the wireless protocols and communication paths used by **My Futuristic Home**. It serves as a guide for troubleshooting interference and understanding device dependencies.

## **System Architecture**



```mermaid
graph TD
    subgraph "Cloud / External"
        ST[SmartThings Cloud]
        NP[Nest Cloud]
        G[Google Gemini / Home]
    end

    subgraph "Infrastructure (192.168.89.x)"
        HA[Home Assistant OS]
        MQTT[Mosquitto Broker]
    end

    subgraph "Local Radio Mesh"
        ZW_JS[Z-Wave JS UI]
        ZHA[Zigbee Home Automation]
        
        ZW_STICK((Zooz 800 Stick))
        ZB_STICK((EZSP Zigbee Stick))
    end

    %% Connections
    HA <--> ZW_JS
    HA <--> ZHA
    HA <--> MQTT
    
    ZW_JS --- ZW_STICK
    ZHA --- ZB_STICK
    
    %% Device Links
    ZW_STICK -- "908.4 MHz" --- ZW_DEVICES[Z-Wave Mesh]
    ZB_STICK -- "2.4 GHz" --- ZB_DEVICES[Zigbee Mesh]
    
    ST -- "API" --- HA
    NP -- "API" --- HA
    G -- "Voice" --- HA
    
    %% MQTT Consumers
    MQTT <--> FRIGATE[Frigate NVR]