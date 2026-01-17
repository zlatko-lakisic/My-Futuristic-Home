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

#### **3. `infrastructure/networking.md` (Updated Mermaid Diagram)**
We now show the management flow from the Beelink server to the APs across subnets.

## 📊 Visual Infrastructure Map
```mermaid
graph TD
    %% Core Gateway
    Router[MikroTik hAP ac Gateway]
    
    %% Perimeter/Server Side
    subgraph "Perimeter Subnet (10.0.10.x)"
        CSS326[MikroTik CSS326 Switch]
        Beelink[Beelink EQ14: UniFi Controller]
        SFF[i7-7700T: Home Assistant OS]
    end

    %% House Side
    subgraph "House & IoT (Bridge: home_lan)"
        TPSwitch[TP-Link TL-SG1024]
        subgraph "Wireless APs (192.168.89.x)"
            AP1[nanoHD: Basement]
            AP2[nanoHD: Office]
            AP3[nanoHD: Hallway]
            AP4[UAP-AC-M: Backyard]
        end
    end

    %% Physical Links
    Router -- Port 2 (Perimeter) --- CSS326
    Router -- Port 5 (House Trunk) --- TPSwitch
    
    CSS326 --- Beelink
    CSS326 --- SFF
    
    TPSwitch --- AP1 & AP2 & AP3 & AP4

    %% Management Flow
    Beelink -.->|L3 Adoption| AP1 & AP2 & AP3 & AP4
    Router -- VPN --- Remote[172.16.91.x Clients]