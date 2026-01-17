###############################################################################
# MikroTik Initial Setup Script (Generalized from mostardesigns production)
# Role: L3 Gateway with Segmented Perimeter, LAN, and IoT VLANs
###############################################################################

#------------------------------------------------------------------------------
# 1. Connectivity & Interfaces
#------------------------------------------------------------------------------
/interface bridge
add comment="Primary House Bridge" name=home_lan port-cost-mode=short
add comment="Isolated Perimeter Bridge" name=perimiter port-cost-mode=short

/interface ethernet
set [ find default-name=ether1 ] comment="Internet Uplink" name="ether1-WAN"
set [ find default-name=ether2 ] comment="Perimeter Switch Link"
set [ find default-name=ether3 ] comment="Management Interface"
set [ find default-name=ether4 ] comment="High-Trust Server Link"
set [ find default-name=ether5 ] comment="House LAN Switch Link"

/interface vlan
add comment="Trusted WiFi" interface=home_lan name=vlan2-home-wifi vlan-id=2
add comment="Isolated IoT" interface=home_lan name=vlan4-iot vlan-id=4

/interface list
add name=WAN
add name=LAN
/interface list member
add interface="ether1-WAN" list=WAN
add interface=home_lan list=LAN
add interface=perimiter list=LAN

#------------------------------------------------------------------------------
# 2. IP Addressing & DHCP
#------------------------------------------------------------------------------
/ip address
add address=10.0.10.1/24 comment="Perimeter Gateway" interface=perimiter
add address=192.168.89.1/24 comment="House LAN Gateway" interface=home_lan
add address=192.168.90.1/24 comment="WiFi VLAN Gateway" interface=vlan2-home-wifi
add address=172.16.90.1/24 comment="IoT VLAN Gateway" interface=vlan4-iot

/ip pool
add name=pool-perimeter ranges=10.0.10.100-10.0.10.200
add name=pool-home-lan ranges=192.168.89.100-192.168.89.254
add name=pool-iot ranges=172.16.90.100-172.16.90.254

/ip dhcp-server
add address-pool=pool-perimeter interface=perimiter name=dhcp-perimeter
add address-pool=pool-home-lan interface=home_lan name=dhcp-home-lan
add address-pool=pool-iot interface=vlan4-iot name=dhcp-iot

/ip dhcp-server network
add address=10.0.10.0/24 dns-server=10.0.10.1 gateway=10.0.10.1
add address=192.168.89.0/24 dns-server=10.0.10.1 gateway=192.168.89.1
add address=172.16.90.0/24 dns-server=10.0.10.1 gateway=172.16.90.1

/ip dhcp-client
add interface="ether1-WAN" comment="Get IP from ISP"

#------------------------------------------------------------------------------
# 3. Security & Firewall
#------------------------------------------------------------------------------
/ip firewall address-list
add address=10.0.10.0/24 list=authorized_admin
add address=192.168.89.0/24 list=authorized_admin

/ip firewall filter
add action=fasttrack-connection chain=forward connection-state=established,related
add action=accept chain=input connection-state=established,related,untracked
add action=accept chain=input protocol=icmp comment="Allow Ping"
add action=drop chain=input in-interface-list=WAN comment="Drop all WAN input"
add action=drop chain=input dst-port=8291 protocol=tcp src-address-list=!authorized_admin comment="Restrict Winbox"

/ip firewall nat
add action=masquerade chain=srcnat out-interface-list=WAN comment="Internet Access"

#------------------------------------------------------------------------------
# 4. Local Services & DNS
#------------------------------------------------------------------------------
/ip dns
set allow-remote-requests=yes servers=8.8.8.8,1.1.1.1

/ip dns static
add address=10.0.10.1 name=router.local