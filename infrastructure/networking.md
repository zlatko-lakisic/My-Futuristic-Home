# 🌐 Network Topology & VLANs

## 🗺 Visual Topology
The following diagram illustrates the logical and physical connections managed by the MikroTik hAP ac gateway.

```mermaid
graph TD
    %% Internet Connection
    WAN((Internet)) --- ether1[ether1 - WAN]

    %% MikroTik Core
    subgraph MikroTik_hAP_ac [MikroTik hAP ac Gateway]
        ether1
        
        %% Bridges
        subgraph Bridges
            perim_bridge[Bridge: perimiter]
            home_bridge[Bridge: home_lan]
            lan_bridge[Bridge: Lan]
        end

        %% VLANs
        home_bridge --> vlan2(VLAN 2: home_wifi_vlan)
        home_bridge --> vlan4(VLAN 4: iot_vlan)
    end

    %% Physical Port Mappings
    perim_bridge --- ether2[ether2: 10.0.10.1]
    perim_bridge --- ether3[ether3: MSNSwitch]
    perim_bridge --- ether4[ether4: Proxmox Stack]
    
    home_bridge --- ether5[ether5: 192.168.89.1]
    home_bridge --- wlan3[wlan3: Maintinence SSID]

    lan_bridge --- wlan2[wlan2: Kuca 2g]
    lan_bridge --- nbi_hack[NBI_Hackathon SSID]

    %% Subnet Attachments
    vlan4 --- printer[172.16.90.113 - Printer]
    ether4 --- proxmox[10.0.10.230 - Proxmox]
    ether5 --- mqtt[192.168.89.26 - MQTT Broker]
    
    %% VPN & Remote
    lan_bridge --- vpn_pool[172.16.91.x - VPN Pool]