# 🌐 Network Topology & VLANs

## 🗺 Visual Topology
The following diagram illustrates the logical and physical connections managed by the MikroTik hAP ac gateway.

```mermaid
graph TD
    %% External and Gateway
    WAN((Internet)) --- MT_WAN[ether1: WAN]
    
    subgraph MikroTik_Core [MikroTik hAP ac Gateway]
        MT_WAN --> MT_Routing{L3 Routing & Firewall}
        
        %% Bridges & VLANs
        MT_Routing --> Bridge_Perim[Bridge: Perimiter]
        MT_Routing --> Bridge_Home[Bridge: Home_LAN]
        MT_Routing --> Bridge_Storage[Bridge: Lan/Storage]
        
        Bridge_Home --> VLAN2(VLAN 2: Home_WiFi)
        Bridge_Home --> VLAN4(VLAN 4: IoT_Isolated)
    end

    %% Perimeter Connectivity
    subgraph Perimeter_Zone [Perimeter: 10.0.10.0/24]
        Bridge_Perim --- ether2[ether2: 10.0.10.1]
        Bridge_Perim --- ether3[ether3: MSNSwitch]
        Bridge_Perim --- ether4[ether4: Proxmox Physical]
        
        %% Proxmox Virtual Layer
        subgraph Proxmox_Node [Proxmox Host: 10.0.10.230]
            ether4 --- PVE_Bridge[Linux Bridge: vmbr0]
            PVE_Bridge --- HA_VM[Home Assistant VM: 10.0.10.6]
            PVE_Bridge --- NAS1_VM[NAS1: NVMe Primary]
            PVE_Bridge --- NVR_Srv[NVR Server: Ubuntu 24.04]
        end
    end

    %% NVR and AI Docker Stack
    subgraph NVR_Docker_Stack [NVR Docker: 172.20.0.0/24]
        NVR_Srv --- Docker_Net[box-network]
        Docker_Net --- Frigate[Frigate NVR]
        Docker_Net --- AI_Inf[CodeProject.AI / CUDA]
        Docker_Net --- Face_Rec[Double-Take / CompreFace]
        Docker_Net --- DB_Stack[InfluxDB / Grafana]
    end

    %% Storage Backplane
    subgraph Storage_Backplane [Storage Link: 172.16.100.0/24]
        Bridge_Storage --- NAS2[NAS2: Enterprise SSD Array]
        NAS2 ---|Direct Attach Port 2| NVR_Srv
    end

    %% House and IoT
    subgraph House_Zone [House/IoT: 192.168.89.x / 172.16.90.x]
        Bridge_Home --- ether5[ether5: House Jacks]
        VLAN4 --- Printer[172.16.90.113: Printer]
        ether5 --- MQTT[192.168.89.26: MQTT Broker]
    end

    %% Logic Flow
    VLAN4 -.->|NAT Forward 1883| MQTT
    HA_VM -.->|Management| Bridge_Perim
    NVR_Srv -.->|NFS v4.1| NAS2