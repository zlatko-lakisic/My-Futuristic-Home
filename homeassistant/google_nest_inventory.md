# 🗣️ Google Nest & Gemini Integration

This inventory tracks the voice interfaces and media cast devices used to control "My Futuristic Home" via Google Home and Gemini.

## **Integration Strategy**
The system uses the **Google Cast** integration for local media control and the **Google Assistant / Home** cloud-to-cloud integration to expose Home Assistant entities to Gemini-enabled devices (Phone, Car, Speakers).

## **Device List**

| Area | Device Name | Model | Manufacturer | Identifier (Cast ID) |
| :--- | :--- | :--- | :--- | :--- |
| **Living Room** | Living Room Speaker | Google Nest Mini | Google Inc. | `2c7efc6935f6e6c3d241d06e...` |
| **Office** | Office Speaker | Google Nest Mini | Google Inc. | `1a66acdfbf573a5d0617a68...` |
| **Master Bedroom** | Master Bedroom Speaker | Google Home Mini | Google Inc. | `c3dd1aea1c33055bdb1c949...` |

## **Use Cases**
* **Voice Commands:** Controlling Z-Wave lights and Zigbee closet drivers via Gemini.
* **TTS Notifications:** Sending spoken alerts (e.g., "Person detected at the Driveway") to specific speakers.
* **On-the-Go Control:** Accessing Home Assistant scenes via the Google Assistant integration in the car.