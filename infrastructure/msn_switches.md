# 🔌 Infrastructure: MSN Switch Watchdogs

## **Overview**
The infrastructure utilizes three **MSN Switch 2** units to provide automated, hardware-level power management. These devices serve as the "physical layer watchdog," monitoring the health of critical systems and performing hard power cycles if a device becomes unresponsive.



## **Operational Logic**
Each MSN Switch is configured with **UIS (Uninterrupted Internet System)** rules:
- **Health Check:** Continuous ICMP Ping to target IPs.
- **Threshold:** 5 consecutive failures trigger a power cycle.
- **Independence:** Outlets can be managed and reset individually.

## **Hardware Deployment**

### **1. WAN Watchdog (WAN MSN Switch)**
- **IP Address:** `10.0.10.254`
- **Connection:** MikroTik Port 3
- **Targets:**
  - **Outlet 1:** MikroTik Router (`10.0.10.1`)
  - **Outlet 2:** Verizon Fios Gateway (**`8.8.8.8`** via Google DNS)

### **2. Surveillance Watchdog (NVR MSN Switch)**
- **Target:**
  - **Outlet 1:** NVR Server (`10.0.10.16`)

### **3. Data & Comms Watchdog (NAS MSN Switch)**
- **Targets:**
  - **Outlet 1:** NAS1 Server (`10.0.10.3`)
  - **Outlet 2:** MQTT Broker (`192.168.89.26`)

## **Integration**
While the switches act autonomously, they are integrated into [Home Assistant](../homeassistant/README.md) via REST API for status monitoring and manual overrides.