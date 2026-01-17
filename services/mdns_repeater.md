# 📡 Service: mDNS Repeater

## **Overview**
The mDNS Repeater (also known as an Avahi reflector or mDNS proxy) is a critical service for cross-subnet device discovery. In a segmented network like this one, Multicast DNS (mDNS) packets—used by services like AirPlay, Chromecast, and local printer discovery—are typically restricted to a single subnet.

This service allows the [Beelink EQ14](../infrastructure/hardware.md) to "repeat" these discovery packets across different network interfaces, enabling devices on the **Home WiFi** or **IoT VLAN** to be seen and controlled by devices on the **Perimeter** or **Home LAN**.

## **Operational Logic**
The container operates in `privileged` mode with `host` networking to gain direct access to the physical and virtual network interfaces of the Beelink EQ14. It listens for mDNS traffic on one interface and re-broadcasts it to the others.

| Interface | Alias in Command | Subnet/Role |
| :--- | :--- | :--- |
| **enp1s0** | NIC 1 | Perimeter (10.0.10.x) |
| **enp2s0** | NIC 2 | House LAN (192.168.89.x) |
| **vlan_wifi** | VLAN 2 | Home WiFi (192.168.90.x) |
| **vlan_iot** | VLAN 4 | IoT Isolated (172.16.90.x) |

## **Deployment Configuration**

```yaml
services:
  mdns_repeater:
    image: monstrenyatko/mdns-repeater
    restart: unless-stopped
    command: mdns-repeater-app -f enp1s0 enp2s0 vlan_wifi vlan_iot
    network_mode: "host"
    privileged: true
    env_file:
      - ./envs/mdns-repeater