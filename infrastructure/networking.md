# 🌐 Network Topology & Subnets

## 🛰 Core Router: MikroTik hAP ac
The house is managed via **RouterOS**, providing enterprise-level firewalling and VLAN segmentation.

### **Subnet Architecture**
| Subnet | Name | Role |
| :--- | :--- | :--- |
| `192.168.89.0/24` | **LAN_Wired** | Physical ports throughout the house (Eth5). |
| `192.168.90.0/24` | **Home_WiFi** | Trusted wireless clients via `home_wifi_lan` VLAN. |
| `172.16.90.0/24` | **IoT_VLAN** | Untrusted/Isolated smart devices. |
| `10.0.10.0/24` | **Perimeter** | High-performance servers, NAS, and compute. |
| `172.16.91.0/24` | **VPN_Remote** | Secure access via OpenVPN / L2TP. |

### **The Bridge Logic**
The `home_lan` bridge aggregates the physical Ethernet 5 trunk with the Home WiFi and IoT VLANs, allowing for granular firewall control between wireless and wired house clients.

## 📊 Visual Infrastructure Map
```mermaid
graph TD
    %% Define the Router
    Router[MikroTik hAP ac]
    
    %% Define the Trunk
    Router -- Ethernet 5 Trunk --> House[House Bridge]
    
    %% Define Subnets
    subgraph "Subnets & VLANs"
        House --> LAN[192.168.89.x - Wired LAN]
        House --> WiFi[192.168.90.x - Home WiFi]
        House --> IoT[172.16.90.x - IoT VLAN]
    end
    
    %% Define Perimeter
    Router -- Dedicated Link --> Perimeter[10.0.10.x - Perimeter Zone]
    
    %% Define the Server
    subgraph "Compute Core"
        Perimeter --> Server[i7-7700T Server]
        Server --- HA[Home Assistant OS]
    end

    %% Define Remote Access
    Router -- L2TP/OVPN --> VPN[172.16.91.x - VPN Clients]