# 🛰 MikroTik RouterOS Configuration (hAP ac)

**Device Model:** RB962UiGS-5HacT2HnT 
**Software Version:** RouterOS 7.21 
**Serial Number:** `<REDACTED_SERIAL>` 

---

## 🏗 Bridge & Interface Assignments
The system is logically segmented into three primary bridges and several VLANs for isolation.

```routeros
/interface bridge
add admin-mac=<REDACTED_MAC> arp=proxy-arp auto-mac=no comment=defconf name=Lan port-cost-mode=short
add arp=proxy-arp name=home_lan port-cost-mode=short
add name=perimiter port-cost-mode=short

/interface ethernet
set [ find default-name=ether1 ] comment=WAN name="ether1 - WAN"
set [ find default-name=ether2 ] comment=10.0.10.1 name=ether2
set [ find default-name=ether3 ] comment="MSNSwitch - 10.0.10.254" name=ether3
set [ find default-name=ether4 ] comment="proxmox - direct 10.0.10.230" name=ether4
set [ find default-name=ether5 ] arp=local-proxy-arp comment=192.168.89.1 name=ether5

/interface vlan
add arp=proxy-arp interface=home_lan name=home_wifi_vlan vlan-id=2
add arp=proxy-arp interface=home_lan name=iot_vlan vlan-id=4

/interface list
add comment=defconf name=WAN
add comment=defconf name=LAN
add name=homelan

```

---

## 🌐 IP Services & DHCP

### **IP Address Assignments**

Gateways are established for each subnet, including the Perimeter, House LAN, and IoT VLANs.

```routeros
/ip address
add address=192.168.89.1/24 interface=home_lan network=192.168.89.0
add address=10.0.10.1/24 interface=perimiter network=10.0.10.0
add address=172.16.100.1/24 interface=Lan network=172.16.100.0
add address=172.16.90.1/24 interface=iot_vlan network=172.16.90.0
add address=192.168.90.1/24 interface=home_wifi_vlan network=192.168.90.0
add address=<REDACTED_WAN_IP> interface="ether1 - WAN" network=<REDACTED_WAN_NET>

```

### **DHCP Pools & Networks**

```routeros
/ip pool
add name=home_dhcp_pool ranges=192.168.89.10-192.168.89.254
add name=iot_dhcp_pool ranges=172.16.90.100-172.16.90.254
add name=home_wifi_dhcp_pool ranges=192.168.90.100-192.168.90.200
add name=perimiter_pool ranges=10.0.10.200-10.0.10.210

/ip dhcp-server network
add address=10.0.10.0/24 comment=Perimiter dns-server=10.0.10.1 gateway=10.0.10.1
add address=192.168.89.0/24 comment=Kuca dns-server=10.0.10.10 gateway=192.168.89.1
add address=172.16.90.0/24 dns-server=10.0.10.1 gateway=172.16.90.1

```

---

## 🛡 Firewall & Security

The firewall is configured with a robust "Drop All" default policy on the input chain and active protections against common attacks.

```routeros
/ip firewall address-list
add address=10.0.10.0/24 list=support
add address=192.168.89.0/24 list=support
add address=127.0.0.0/8 comment="Loopback [RFC 3330]" list=bogons

/ip firewall filter
add action=fasttrack-connection chain=forward comment="defconf: fasttrack" connection-state=established,related
add action=accept chain=input dst-port=1701,500,4500 protocol=udp
add action=add-src-to-address-list address-list=Port_Scanner address-list-timeout=1w chain=input comment="Port Scanner Detect" protocol=tcp psd=21,3s,3,1
add action=drop chain=input comment="Drop Winbox from outside" dst-port=8291 protocol=tcp src-address-list=!support
add action=drop chain=input comment="Drop all other input"

```

---

## ⚙️ Scripts & Automation

Includes logic for monitoring the Proxmox stack and resetting specific network interfaces if unreachable.

```routeros
/system script
add name=disable_enable_ether2 source="/interface disable ether2; /interface enable ether2;"
add name=ping_proxmox_stack source=":local pingtarget \"10.0.10.230\"; :local interfacetotoggle \"ether4\"; :local pingcount 5; :local pingresult [/ping \$pingtarget count=\$pingcount]; :if (\$pingresult = 0) do={ /log info \"Ping to \$pingtarget failed, disabling \$interfacetotoggle\"; /system script run disable_enable_ether2; }"

```

---

## 🏷 Static DNS

Critical internal services are mapped to their respective Perimeter and LAN IPs.

| Hostname | IP Address | Purpose |
| --- | --- | --- |
| `ha.mostardesigns.com` | `10.0.10.6` | **The Home Assistant Server** |
| `mqtt.mostardesigns.com` | `192.168.89.26` | Pine64 MQTT Broker |
| `proxmox.mostardesigns.com` | `10.0.10.230` | Virtualization Host |
| `nas.mostardesigns.com` | `10.0.10.6` | Primary Storage |
| `ps.mostardesigns.com` | `10.0.10.254` | MSNSwitch |