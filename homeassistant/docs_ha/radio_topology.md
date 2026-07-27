# 📡 Radio & Network Topology

This document maps the wireless protocols and communication paths used by **My Futuristic Home**. It serves as a guide for troubleshooting interference and understanding device dependencies.

IP VLANs, Mostar L2TP, and torrent breakout live in [`../../infrastructure/networking.md`](../../infrastructure/networking.md) — this page covers radio/cloud paths into Home Assistant.

## System architecture

```mermaid
flowchart TD
    subgraph Cloud["Cloud / External"]
        ST[SmartThings Cloud]
        NP[Nest Cloud]
        G[Google Gemini / Home]
        YL[YoLink Cloud]
    end

    subgraph IPNet["IP fabric"]
        MT[NYC MikroTik Kuca]
        HA[Home Assistant]
        MQTT[Mosquitto Broker]
        FRIGATE[Frigate NVR]
    end

    subgraph Radio["Local radio mesh"]
        ZW_JS[Z-Wave JS]
        ZHA[ZHA / Zigbee]
        ZW_STICK((Z-Wave stick))
        ZB_STICK((EZSP Zigbee stick))
        ZW_DEVICES[Z-Wave mesh]
        ZB_DEVICES[Zigbee mesh]
    end

    HA <--> ZW_JS
    HA <--> ZHA
    HA <--> MQTT
    MT --- HA
    ZW_JS --- ZW_STICK
    ZHA --- ZB_STICK
    ZW_STICK -- "908.4 MHz" --- ZW_DEVICES
    ZB_STICK -- "2.4 GHz" --- ZB_DEVICES
    ST -- API --- HA
    NP -- API --- HA
    G -- Voice --- HA
    YL -- API --- HA
    MQTT <--> FRIGATE
```
