# 📹 Frigate NVR: Setup & Capabilities

This document outlines the software features and integration logic for the Frigate AI NVR system within Home Assistant.

## **Core Integration Features**
The official Frigate integration (v0.16.3) connects Home Assistant to the Frigate backend via MQTT and Media APIs.

### **1. AI Object Detection**
Frigate uses real-time AI to identify specific labels. For every camera in the inventory, the integration provides:
* **Occupancy Binary Sensors:** `binary_sensor.<camera>_person_occupancy` (On when any person is in view).
* **Object Counters:** `sensor.<camera>_person_count` (Numeric value for current count).
* **Static Screenshots:** An `image` entity that displays the "Best" crop of the most recent detected object with a bounding box.

### **2. Sound Recognition**
With v0.16+, Frigate monitors audio streams for specific signatures:
* **Detection Labels:** Barking, breaking glass, sirens, and speech.
* **Entities:** Provides binary sensors that trigger when the confidence threshold for a sound is met.

### **3. Motion vs. Object Recognition**
* **Motion:** Pixel-based change detection (very fast). Used as a "trigger" for the AI.
* **Object Recognition:** Neural network analysis (requires Coral TPU/GPU). Confirms *what* moved (Person, Car, Dog).

### **4. System Controls**
The integration exposes several switches to manage the NVR dynamically:
* `switch.<camera>_detect`: Toggle AI detection.
* `switch.<camera>_recordings`: Toggle video saving.
* `switch.<camera>_snapshots`: Toggle image saving.

## **Advanced Camera Card (HACS)**
We utilize the **Advanced Camera Card** for a high-performance frontend experience:
* **Frigate-First UI:** Native support for Frigate event galleries and clip playback.
* **Low Latency:** Uses WebRTC and MSE via `go2rtc` for sub-second lag.
* **Conditional Layers:** Icons can appear on the video feed when specific objects are detected.