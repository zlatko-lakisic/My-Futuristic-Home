# Sanitized NYC/Home (Kuca) RouterOS export (credentials/usernames/keys/serials/MACs redacted)
# 2026-07-27 06:36:08 by RouterOS 7.23.2
# software id = <REDACTED_SOFTWARE_ID>
#
# model = RB962UiGS-5HacT2HnT
# serial number = <REDACTED_SERIAL>
/interface bridge
add admin-mac=<REDACTED_MAC> auto-mac=no comment=defconf name=Lan \
    port-cost-mode=short
add name=home_lan port-cost-mode=short
add name=perimiter port-cost-mode=short
/interface ethernet
set [ find default-name=ether1 ] comment=WAN l2mtu=1598 mac-address=\
    <REDACTED_MAC> name="ether1 - WAN"
set [ find default-name=ether2 ] comment=10.0.10.1 l2mtu=1598 mac-address=\
    <REDACTED_MAC>
set [ find default-name=ether3 ] comment="MSNSwitch - 10.0.10.254" l2mtu=1598 \
    mac-address=<REDACTED_MAC>
set [ find default-name=ether4 ] comment="proxmox - direct 10.0.10.11" l2mtu=\
    1598 mac-address=<REDACTED_MAC>
set [ find default-name=ether5 ] arp=local-proxy-arp comment=192.168.89.1 \
    l2mtu=1598 mac-address=<REDACTED_MAC>
set [ find default-name=sfp1 ] advertise=\
    10M-baseT-half,10M-baseT-full,100M-baseT-half,100M-baseT-full
/interface wireless
set [ find default-name=wlan1 ] band=2ghz-b/g/n frequency=2437 mode=ap-bridge \
    name=wlan2 ssid="Kuca 2g" station-roaming=enabled wireless-protocol=\
    802.11
set [ find default-name=wlan2 ] band=5ghz-a/n/ac channel-width=\
    20/40/80mhz-Ceee disabled=no frequency=auto hide-ssid=yes mode=ap-bridge \
    name=wlan3 ssid=router_maintinence station-roaming=enabled \
    wireless-protocol=802.11
/interface wireguard
add comment="Mostar WireGuard" disabled=yes listen-port=51820 mtu=1420 name=\
    wg-mostar private-key="<REDACTED_WIREGUARD_PRIVATE_KEY>"
/interface vlan
add arp=proxy-arp interface=home_lan name=home_wifi_vlan vlan-id=2
add arp=proxy-arp interface=home_lan name=iot_vlan vlan-id=4
/interface ethernet switch port
set ether5 default-vlan-id=0
set ether4 default-vlan-id=0
set ether3 default-vlan-id=0
set ether2 default-vlan-id=0
set "ether1 - WAN" default-vlan-id=0
set switch1-cpu default-vlan-id=0
/interface list
add comment=defconf name=WAN
add comment=defconf name=LAN
add name="NBI VPN"
add name=homelan
/interface lte apn
set [ find default=yes ] ip-type=ipv4 use-network-apn=no
/interface wireless security-profiles
set [ find default=yes ] authentication-types=wpa2-psk eap-methods="" \
    group-ciphers=tkip,aes-ccm mode=dynamic-keys supplicant-identity=MikroTik \
    unicast-ciphers=tkip,aes-ccm wpa-pre-shared-key=<REDACTED_WIFI_PSK> \
    wpa2-pre-shared-key=<REDACTED_WIFI_PSK>
add authentication-types=wpa2-psk eap-methods="" mode=dynamic-keys name=\
    "The Dark Side AP" supplicant-identity="" wpa2-pre-shared-key=<REDACTED_WIFI_PSK>
add name="No Auth" supplicant-identity=MikroTik
add authentication-types=wpa-psk,wpa2-psk mode=dynamic-keys name=\
    "Zlatko Iphone AP" supplicant-identity=MikroTik wpa-pre-shared-key=\
    <REDACTED_WIFI_PSK> wpa2-pre-shared-key=<REDACTED_WIFI_PSK>
/interface wireless
add mac-address=<REDACTED_MAC> master-interface=wlan2 name=NBI_Hackathon \
    security-profile="No Auth" ssid=NBI_Hackathon wds-default-bridge=Lan \
    wps-mode=disabled
/ip ipsec profile
set [ find default=yes ] dpd-interval=2m dpd-maximum-failures=5
add dh-group=modp1024 dpd-interval=10s dpd-maximum-failures=3 enc-algorithm=\
    aes-128 lifetime=8h name="AWS Profile 2" nat-traversal=no
add dh-group=modp1024 dpd-interval=10s dpd-maximum-failures=3 enc-algorithm=\
    aes-128 lifetime=8h name="AWS Profile 1" nat-traversal=no
/ip ipsec peer
add address=34.206.170.18/32 disabled=yes local-address=<REDACTED_WAN_IP> name=\
    "Omega AWS Peer 1" profile="AWS Profile 1"
add address=34.199.7.183/32 disabled=yes local-address=<REDACTED_WAN_IP> name=\
    "Omega AWS Peer 2" profile="AWS Profile 2"
add address=18.221.211.110/32 disabled=yes local-address=<REDACTED_WAN_IP> name=\
    "AWS Peer 2" profile="AWS Profile 2"
add address=3.13.174.117/32 disabled=yes local-address=<REDACTED_WAN_IP> name=\
    "AWS Peer 1" profile="AWS Profile 1"
/ip ipsec proposal
add comment="AWS PROPOSAL" disabled=yes enc-algorithms=aes-128-cbc lifetime=\
    1h name="Aws 1"
add disabled=yes enc-algorithms=aes-128-cbc lifetime=1h name="Aws 2"
add disabled=yes name=l2tp-mostar-proposal
/ip pool
add name=home_dhcp_pool ranges=192.168.89.10-192.168.89.254
add name=iot_dhcp_pool ranges=172.16.90.100-172.16.90.254
add name=home_wifi_dhcp_pool ranges=192.168.90.100-192.168.90.200
add name=vpn_pool ranges=172.16.91.2-172.16.91.29
add name=perimiter_pool ranges=10.0.10.200-10.0.10.210
/ip dhcp-server
add address-pool=home_dhcp_pool interface=home_lan lease-time=1d name=\
    home_dhcp
add address-pool=iot_dhcp_pool interface=iot_vlan lease-time=1d name=iot_dhcp
add address-pool=home_wifi_dhcp_pool interface=home_wifi_vlan lease-time=1d \
    name=home_wifi_dhcp
add address-pool=perimiter_pool disabled=yes interface=perimiter lease-time=\
    10m name=perimiter_dhcp
/ip smb users
set [ find default=yes ] disabled=yes
/ppp profile
add dns-server=10.0.10.10 local-address=<REDACTED_WAN_IP> name=MD-VPN \
    remote-address=vpn_pool use-encryption=yes wins-server=10.0.10.10
add dhcpv6-use-radius=yes dns-server=10.0.10.10 local-address=<REDACTED_WAN_IP> \
    name="mostardesigns.com ovpn" remote-address=vpn_pool use-encryption=yes \
    wins-server=10.0.10.10
add change-tcp-mss=yes local-address=home_dhcp_pool name=MidanMarketing \
    remote-address=home_dhcp_pool use-encryption=required
add dhcpv6-use-radius=yes dns-server=10.0.10.10 local-address=<REDACTED_WAN_IP> \
    name="mostardesigns.com l2tp" only-one=no remote-address=vpn_pool \
    use-encryption=yes wins-server=10.0.10.10
/queue type
add kind=pcq name=PCQ-Download pcq-classifier=dst-address
add kind=pcq name=PCQ-Upload pcq-classifier=src-address
/queue simple
add name="Usage Counter - iot Wifi" queue=PCQ-Upload/PCQ-Download target=\
    iot_vlan
/routing bgp template
set default disabled=yes output.network=bgp-networks
add as=65101 disabled=yes name="AWS 1" output.network=bgp-networks \
    .no-client-to-client-reflection=yes .redistribute=static,vpn,dhcp
add as=65101 disabled=yes name="AWS 2" output.network=bgp-networks \
    .no-client-to-client-reflection=yes .redistribute=static,vpn,dhcp
/routing ospf instance
add disabled=no name=default-v2
/routing ospf area
add disabled=yes instance=default-v2 name=backbone-v2
/routing table
add fib name=tv_over_vpn
add fib name=torrent_over_mostar
add fib name=toAWS
/system logging action
set 1 disk-file-name=log
/system script
add dont-require-permissions=no name=EnableDns owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="/\
    ip firewall nat enable [find comment=\"DNS Failover\"];\
    \n/ip firewall nat enable [find comment~\"NTP\"]"
add dont-require-permissions=no name=DisableDns owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="/\
    ip firewall nat disable [find comment=\"DNS Failover\"];\
    \n/ip firewall nat disable [find comment~\"NTP\"]"
add dont-require-permissions=no name=cloudns-update owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="/\
    tool fetch url=\"https://ipv4.cloudns.net/api/dynamicURL/\?q=<REDACTED_CLOUDNS_TOKEN>\"\
    \n output=none"
add dont-require-permissions=no name=disable_enable_ether4 owner=admin \
    policy=read,write,policy,test source=\
    "/interface disable ether4;\
    \n:delay 2s;\
    \n/interface enable ether4;"
add dont-require-permissions=no name=ping_proxmox_stack owner=admin policy=\
    read,write,policy,test source=":local pingtarget \"10.0.10.11\";\
    \n:local interfacetotoggle \"ether4\";\
    \n:local pingcount 5;\
    \n\
    \n:local pingresult [/ping \$pingtarget count=\$pingcount];\
    \n\
    \n:if (\$pingresult = 0) do={\
    \n  # Ping failed, disable the interface\
    \n  /log info \"Ping to \$pingtarget failed, disabling \$interfacetotoggle\
    \";\
    \n  /system script run disable_enable_ether4;\
    \n}"
add dont-require-permissions=no name=recreate-traefik-docker owner=admin \
    policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    source="# === Configuration ===\
    \n:local dockerHost \"http://10.0.10.6:2375\"\
    \n:local webhook \"http://10.0.10.6:8088\"\
    \n:local containerName \"traefik\"\
    \n\
    \n# Fetch container info directly into a variable (RouterOS v7)\
    \n:local fetchResult [/tool fetch \\\
    \n  url=(\$dockerHost . \"/containers/json\?filters={\\\"name\\\":[\\\"\" \
    . \$containerName . \"\\\"]}\") \\\
    \n  output=user \\\
    \n  as-value \\\
    \n  mode=http]\
    \n\
    \n:local fileContent (\$fetchResult->\"data\")\
    \n\
    \n# Check if the container is running\
    \n:local running false\
    \n:if ([:find \$fileContent \"\\\"State\\\":\\\"running\\\"\"] != nil) do=\
    {\
    \n  :set running true\
    \n}\
    \n\
    \n:log info (\"Traefik container running: \" . \$running)\
    \n\
    \n# If container not running, trigger the webhook\
    \n:if (\$running = false) do={\
    \n  :log warning \"Traefik container not running \E2\80\94 triggering recr\
    eate webhook\"\
    \n  :local payload \"{\\\"key\\\":\\\"<REDACTED_PASSWORD>\\\"}\"\
    \n  /tool fetch url=\$webhook http-method=post http-data=\$payload output=\
    user mode=http\
    \n}"
/user group
add name=homeassistant policy="reboot,read,write,policy,test,api,!local,!telne\
    t,!ssh,!ftp,!winbox,!password,!web,!sniff,!sensitive,!romon,!rest-api"
/interface bridge port
add bridge=perimiter comment=defconf ingress-filtering=no interface=ether4 \
    internal-path-cost=10 path-cost=10
add bridge=perimiter comment=defconf ingress-filtering=no interface=ether3 \
    internal-path-cost=10 path-cost=10
add bridge=home_lan ingress-filtering=no interface=wlan3 internal-path-cost=\
    10 path-cost=10
add bridge=home_lan ingress-filtering=no interface=ether5 internal-path-cost=\
    10 path-cost=10
add bridge=perimiter interface=ether2 internal-path-cost=10 path-cost=10
/ip firewall connection tracking
set udp-timeout=10s
/ip neighbor discovery-settings
set discover-interface-list=!dynamic lldp-med-net-policy-vlan=1
/ip settings
set max-neighbor-entries=8192
/ipv6 settings
set disable-ipv6=yes max-neighbor-entries=8192
/interface l2tp-server server
set allow-fast-path=yes default-profile="mostardesigns.com l2tp" enabled=yes \
    ipsec-secret=<REDACTED_IPSEC_SECRET> use-ipsec=yes
/interface list member
add comment=defconf interface=Lan list=LAN
add comment=defconf interface="ether1 - WAN" list=WAN
add interface=*F00081 list="NBI VPN"
add interface=home_lan list=homelan
add interface=ether5 list=homelan
/interface ovpn-server server
add auth=sha1 certificate=server-certificate cipher=aes128-cbc \
    default-profile="mostardesigns.com ovpn" disabled=no mac-address=\
    <REDACTED_MAC> name=ovpn-server1 netmask=27 \
    require-client-certificate=yes
/interface pptp-server server
# PPTP connections are considered unsafe, it is suggested to use a more modern VPN protocol instead
set authentication=mschap2 default-profile=MD-VPN
/interface wireguard peers
add allowed-address=172.16.91.2/32,192.168.88.0/24,192.168.100.0/24,0.0.0.0/0 \
    client-allowed-address=::/0 interface=wg-mostar name=peer1 \
    persistent-keepalive=25s public-key=\
    "<REDACTED_WIREGUARD_PUBLIC_KEY>"
/ip address
add address=192.168.89.1/24 interface=home_lan network=192.168.89.0
add address=10.0.10.1/24 interface=perimiter network=10.0.10.0
add address=172.16.90.1/24 interface=iot_vlan network=172.16.90.0
add address=192.168.90.1/24 interface=home_wifi_vlan network=192.168.90.0
add address=169.254.41.168/30 disabled=yes interface=ether5 network=\
    169.254.41.168
add address=169.254.113.228/30 disabled=yes interface=ether5 network=\
    169.254.113.228
add address=172.16.91.1/27 interface=Lan network=172.16.91.0
add address=169.254.96.76/30 comment="AWS IE Tunnel 2" disabled=yes \
    interface=ether5 network=169.254.96.76
add address=169.254.249.36/30 comment="AWS IE Tunnel 1" disabled=yes \
    interface=ether5 network=169.254.249.36
add address=172.16.55.1/29 comment=torrent-vlan-network interface=perimiter \
    network=172.16.55.0
add address=172.16.91.1/30 interface=wg-mostar network=172.16.91.0
/ip dhcp-client
add default-route-tables=main interface="ether1 - WAN" name=ether1
/ip dhcp-server lease
add address=10.0.10.245 mac-address=<REDACTED_MAC> server=perimiter_dhcp
add address=192.168.89.14 client-id=<REDACTED_CLIENT_ID> mac-address=\
    <REDACTED_MAC> server=home_dhcp
add address=192.168.89.13 client-id=<REDACTED_CLIENT_ID> mac-address=\
    <REDACTED_MAC> server=home_dhcp
add address=192.168.89.10 client-id=<REDACTED_CLIENT_ID> mac-address=\
    <REDACTED_MAC> server=home_dhcp
add address=192.168.89.15 client-id=<REDACTED_CLIENT_ID> mac-address=\
    <REDACTED_MAC> server=home_dhcp
add address=192.168.89.9 client-id=<REDACTED_CLIENT_ID> mac-address=\
    <REDACTED_MAC> server=home_dhcp
add address=172.16.90.113 client-id=<REDACTED_CLIENT_ID> comment=Printer \
    mac-address=<REDACTED_MAC> server=iot_dhcp
add address=10.0.10.91 client-id=<REDACTED_CLIENT_ID> mac-address=\
    <REDACTED_MAC> server=perimiter_dhcp
add address=10.0.10.92 client-id=<REDACTED_CLIENT_ID> mac-address=\
    <REDACTED_MAC> server=perimiter_dhcp
add address=10.0.10.201 client-id=<REDACTED_CLIENT_ID> mac-address=\
    <REDACTED_MAC> server=perimiter_dhcp
add address=192.168.89.22 client-id=<REDACTED_CLIENT_ID> mac-address=\
    <REDACTED_MAC> server=home_dhcp
add address=172.16.90.20 comment=omega-jetson mac-address=<REDACTED_MAC> \
    server=iot_dhcp
add address=10.0.10.203 client-id=<REDACTED_CLIENT_ID> mac-address=\
    <REDACTED_MAC> server=perimiter_dhcp
add address=192.168.89.30 client-id=<REDACTED_CLIENT_ID> mac-address=\
    <REDACTED_MAC> server=home_dhcp
add address=192.168.89.31 client-id=<REDACTED_CLIENT_ID> mac-address=\
    <REDACTED_MAC> server=home_dhcp
add address=192.168.89.2 client-id=<REDACTED_CLIENT_ID> mac-address=\
    <REDACTED_MAC> server=home_dhcp
add address=192.168.89.27 client-id=<REDACTED_CLIENT_ID> comment=\
    garden-speaker.mostardesigns.com mac-address=<REDACTED_MAC> server=\
    home_dhcp
/ip dhcp-server network
add address=10.0.10.0/24 comment=Perimiter dns-server=10.0.10.1 gateway=\
    10.0.10.1 netmask=24
add address=172.16.90.0/24 dns-server=10.0.10.10 domain=mostardesigns.com \
    gateway=172.16.90.1 netmask=24 wins-server=10.0.10.10
add address=192.168.89.0/24 comment=Kuca dns-server=10.0.10.10 domain=\
    mostardesigns.com gateway=192.168.89.1 ntp-server=10.0.10.1 wins-server=\
    10.0.10.10
add address=192.168.90.0/24 dns-server=10.0.10.10 domain=mostardesigns.com \
    gateway=192.168.90.1 netmask=24 wins-server=10.0.10.10
/ip dns
set allow-remote-requests=yes servers=8.8.8.8
/ip dns static
add address=10.0.10.1 name=router.lan type=A
add address=10.0.10.254 name=ps.mostardesigns.com type=A
add address=172.16.90.113 name=printer type=A
add address=10.100.30.219 name=aws2.cormactagging.ie type=A
add cname=ct-wp-lb-1765808897.eu-west-1.elb.amazonaws.com disabled=yes name=\
    staging.dev.ct.omega-it.solutions ttl=1m type=CNAME
add address=192.168.89.27 name=02.dev.ct.omega-it.solutions ttl=1m type=A
add address=192.168.89.12 name=03.dev.ct.omega-it.solutions ttl=1m type=A
add address=10.0.10.200 name=zts.dev.ct.omega-it.solutions ttl=1m type=A
add address=10.0.10.6 name=ha.mostardesigns.com type=A
add address=192.168.89.26 name=mqtt.mostardesigns.com type=A
add address=10.0.10.6 name=unifi.mostardesigns.com type=A
add address=10.0.10.6 name=proxmox.mostardesigns.com type=A
add address=10.0.10.6 name=git.omega-it.solutions type=A
add address=10.0.10.6 name=grafana.mostardesigns.com type=A
add address=10.0.10.205 name=01.dev.omegait.omega-it.solutions type=A
add address=10.0.10.6 name=staging.dev.tgm.omega-it.solutions type=A
add address=10.0.10.6 name=tourguidemostar.com type=A
add address=10.0.10.190 name=mikrotik_perimiter_switch.mostardesigns.com \
    type=A
add address=10.0.10.6 name=frigate.mostardesigns.com type=A
add address=10.0.10.6 name=traefik.mostardesigns.com type=A
add address=10.0.10.6 name=nas.mostardesigns.com type=A
add address=10.0.10.6 name=nas2.mostardesigns.com type=A
add address=10.0.10.6 name=ai.mostardesigns.com type=A
add address=10.0.10.6 name=perimiter.switch.mostardesigns.com type=A
add address=10.0.10.178 name=openldap.mostardesigns.com type=A
add address=10.0.10.6 name=mail.mostardesigns.com type=A
add address=10.0.10.6 name=imap.mostardesigns.com type=A
add address=10.0.10.6 name=smtp.mostardesigns.com type=A
add cname=nyc.mostardesigns.com name=api.double-take.io type=CNAME
add address=10.0.10.6 name=plex.mostardesigns.com type=A
add address=10.0.10.6 name=radarr.mostardesigns.com type=A
add address=10.0.10.6 name=sonarr.mostardesigns.com type=A
add address=10.0.10.6 name=qbittorrent.mostardesigns.com type=A
add address=10.0.10.6 name=prowlarr.mostardesigns.com type=A
add address=10.0.10.6 name=jackett.mostardesigns.com type=A
add address=10.0.10.10 name=freeipa.mostardesigns.com type=A
add address=10.0.10.254 comment=msnswitch-1 name=\
    msnswitch-1.mostardesigns.com type=A
add address=10.0.10.252 comment=msnswitch-2 name=\
    msnswitch-2.mostardesigns.com type=A
add address=10.0.10.252 comment=msnswitch-3 name=\
    msnswitch-3.mostardesigns.com type=A
/ip firewall address-list
add address=192.168.89.0/24 disabled=yes list=bgp-networks
add address=10.0.10.0/24 list=support
add address=0.0.0.0/8 comment="Self-Identification [RFC 3330]" list=bogons
add address=10.0.0.0/8 comment="Private[RFC 1918] - CLASS A # Check if you nee\
    d this subnet before enable it" disabled=yes list=bogons
add address=127.0.0.0/8 comment="Loopback [RFC 3330]" list=bogons
add address=169.254.0.0/16 comment="Link Local [RFC 3330]" list=bogons
add address=172.16.0.0/12 comment="Private[RFC 1918] - CLASS B # Check if you \
    need this subnet before enable it" disabled=yes list=bogons
add address=192.168.0.0/16 comment="Private[RFC 1918] - CLASS C # Check if you\
    \_need this subnet before enable it" disabled=yes list=bogons
add address=192.0.2.0/24 comment="Reserved - IANA - TestNet1" list=bogons
add address=192.88.99.0/24 comment="6to4 Relay Anycast [RFC 3068]" list=\
    bogons
add address=198.18.0.0/15 comment="NIDB Testing" list=bogons
add address=198.51.100.0/24 comment="Reserved - IANA - TestNet2" list=bogons
add address=203.0.113.0/24 comment="Reserved - IANA - TestNet3" list=bogons
add address=224.0.0.0/4 comment=\
    "MC, Class D, IANA # Check if you need this subnet before enable it" \
    disabled=yes list=bogons
add address=10.0.0.0/24 list=Mostar
add address=10.0.1.0/24 list=Mostar
add address=10.0.2.0/24 list=Mostar
add address=192.168.1.0/24 list=Mostar
add address=10.0.10.0/24 list=Local
add address=192.168.89.0/24 list=Local
add address=192.168.100.0/24 list=support
add address=192.168.42.0/24 list=support
add address=172.16.100.0/24 list=Local
add address=54.204.36.75 list="Shiny Server"
add address=172.16.90.0/24 list=Local
add address=172.16.90.0/24 list=support
add address=192.168.90.0/24 list=Local
add address=192.168.90.0/24 list=support
add address=34.203.76.245 list="Shiny Server"
add address=172.16.91.0/27 list=Local
add address=172.16.91.0/27 list=support
add address=10.0.10.0/24 disabled=yes list=bgp-networks
add address=192.168.89.0/24 list=support
add address=10.90.0.0/16 list="AWS CIDR"
add address=10.100.0.0/16 list="AWS CIDR"
add address=192.168.88.0/24 list=support
add address=192.168.91.0/24 list=support
add address=192.168.77.0/24 list=support
add address=94.100.180.31 comment=mxs.mail.ru list=bogons
add address=91.224.92.26 list=bogons
add address=172.16.55.0/29 list=Local
add address=172.16.55.0/29 list=support
/ip firewall filter
add action=accept chain=input comment="Accept established and related" \
    connection-state=established,related
add action=log chain=forward log-prefix=TRACE-TORRENT src-address=172.16.55.2
add action=accept chain=forward comment="Allow Torrent Subnet to Forward" \
    src-address=172.16.55.0/29
add action=fasttrack-connection chain=forward comment=\
    "FastTrack to established connections" connection-state=\
    established,related
add action=drop chain=forward in-interface-list=WAN src-address=91.224.92.26
add action=log chain=forward log-prefix=WG-TEST src-address=172.16.91.2
add action=accept chain=forward src-address=172.16.91.29
add action=accept chain=input src-address=172.16.91.29
add action=accept chain=forward comment=\
    "Allow WireGuard tunnel traffic to forward" src-address=172.16.91.0/24
add action=accept chain=input dst-port=1701,500,4500 log=yes protocol=udp
add action=accept chain=input comment="AWS 1" in-interface-list=WAN protocol=\
    ipsec-esp src-address=34.199.7.183
add action=accept chain=input dst-address=<REDACTED_WAN_IP> dst-port=500 \
    in-interface-list=WAN protocol=udp src-address=34.199.7.183 src-port=500
add action=accept chain=input dst-address=169.254.41.170 in-interface-list=\
    WAN protocol=tcp src-address=169.254.41.169 src-port=179
add action=accept chain=input comment="AWS 2" protocol=ipsec-esp src-address=\
    34.206.170.18
add action=accept chain=input dst-address=<REDACTED_WAN_IP> dst-port=500 \
    in-interface-list=WAN protocol=udp src-address=34.206.170.18 src-port=500
add action=accept chain=input dst-address=169.254.113.230 in-interface-list=\
    WAN protocol=tcp src-address=169.254.113.229 src-port=179
add action=accept chain=forward comment="AWS Forward" in-interface-list=WAN \
    src-address-list="AWS CIDR"
add action=accept chain=forward dst-address-list="AWS CIDR"
add action=accept chain=input comment=OVPN dst-port=1194 protocol=tcp
add action=accept chain=input dst-port=1194 protocol=udp
add action=accept chain=input comment=L2TP dst-port=500 in-interface-list=WAN \
    protocol=udp
add action=accept chain=input dst-port=4500 in-interface-list=WAN protocol=\
    udp
add action=accept chain=input dst-port=1701 in-interface-list=WAN protocol=\
    udp
add action=accept chain=input in-interface-list=WAN protocol=ipsec-esp
add action=accept chain=input dst-port=8728 in-interface=Lan protocol=tcp
add action=accept chain=input in-interface=all-ppp
add action=drop chain=input comment="Block Spam" in-interface-list=WAN \
    src-address=185.232.67.13
add action=accept chain=input disabled=yes dst-port=3389 in-interface-list=\
    WAN protocol=tcp
add action=add-src-to-address-list address-list=Syn_Flooder \
    address-list-timeout=30m chain=input comment=\
    "Add Syn Flood IP to the list" connection-limit=30,32 protocol=tcp \
    tcp-flags=syn
add action=drop chain=input comment="Drop to syn flood list" \
    src-address-list=Syn_Flooder
add action=add-src-to-address-list address-list=Port_Scanner \
    address-list-timeout=1w chain=input comment="Port Scanner Detect" \
    protocol=tcp psd=21,3s,3,1
add action=drop chain=input comment="Drop to port scan list" \
    src-address-list=Port_Scanner
add action=jump chain=input comment="Jump for icmp input flow" jump-target=\
    ICMP protocol=icmp
add action=drop chain=input comment="Block all access to the winbox - except t\
    o support list # DO NOT ENABLE THIS RULE BEFORE ADD YOUR SUBNET IN THE SUP\
    PORT ADDRESS LIST" dst-port=8291 protocol=tcp src-address-list=!support
add action=jump chain=forward comment="Jump for icmp forward flow" \
    jump-target=ICMP protocol=icmp
add action=drop chain=forward comment="Drop to bogon list" dst-address-list=\
    bogons
add action=add-src-to-address-list address-list=spammers \
    address-list-timeout=3h chain=forward comment=\
    "Add Spammers to the list for 3 hours" connection-limit=30,32 dst-port=\
    25,587 limit=30/1m,0:packet protocol=tcp
add action=drop chain=forward comment="Avoid spammers action" dst-port=25,587 \
    protocol=tcp src-address-list=spammers
add action=accept chain=input dst-port=1723 protocol=tcp
add action=accept chain=input protocol=gre
add action=accept chain=input comment="Accept DNS - UDP" in-interface=Lan \
    port=53 protocol=udp
add action=accept chain=input comment="Accept DNS - TCP" in-interface=Lan \
    port=53 protocol=tcp
add action=accept chain=forward comment="FastTrack to related connections" \
    connection-state=established,related
add action=accept chain=input comment="Full access to SUPPORT address list" \
    src-address-list=support
add action=accept chain=input comment="WireGuard - Mostar" dst-port=51820 \
    in-interface-list=WAN protocol=udp
add action=drop chain=input comment="Drop anything else! # DO NOT ENABLE THIS \
    RULE BEFORE YOU MAKE SURE ABOUT ALL ACCEPT RULES YOU NEED"
add action=accept chain=ICMP comment="Echo request - Avoiding Ping Flood" \
    icmp-options=8:0 limit=1,5:packet protocol=icmp
add action=accept chain=ICMP comment="Echo reply" icmp-options=0:0 protocol=\
    icmp
add action=accept chain=ICMP comment="Time Exceeded" icmp-options=11:0 \
    protocol=icmp
add action=accept chain=ICMP comment="Destination unreachable" icmp-options=\
    3:0-1 protocol=icmp
add action=accept chain=ICMP comment=PMTUD icmp-options=3:4 protocol=icmp
add action=drop chain=ICMP comment="Drop to the other ICMPs" protocol=icmp
add action=jump chain=output comment="Jump for icmp output" jump-target=ICMP \
    protocol=icmp
add action=drop chain=forward disabled=yes dst-port=25 protocol=tcp \
    src-address=192.168.89.1
/ip firewall mangle
add action=mark-routing chain=prerouting dst-address-list=!Local \
    new-routing-mark=torrent_over_mostar passthrough=no src-address=\
    172.16.55.2
add action=change-mss chain=forward new-mss=clamp-to-pmtu protocol=tcp \
    tcp-flags=syn
/ip firewall nat
add action=dst-nat chain=dstnat comment="Printer Port Forward" dst-port=9100 \
    in-interface=home_lan protocol=tcp to-addresses=172.16.90.113
add action=dst-nat chain=dstnat comment="DNS Failover" disabled=yes \
    dst-address=10.0.10.10 dst-port=53 protocol=udp to-addresses=10.0.10.1 \
    to-ports=53
add action=dst-nat chain=dstnat disabled=yes dst-address=10.0.10.10 dst-port=\
    123 protocol=udp to-addresses=10.0.10.1 to-ports=123
add action=dst-nat chain=dstnat comment=\
    "freeipa.mostardesigns.com to traefik" disabled=yes dst-address=\
    10.0.10.10 dst-port=80 in-interface-list=homelan protocol=tcp \
    to-addresses=10.0.10.6 to-ports=80
add action=dst-nat chain=dstnat disabled=yes dst-address=10.0.10.10 dst-port=\
    443 in-interface-list=homelan protocol=tcp to-addresses=10.0.10.6 \
    to-ports=443
add action=dst-nat chain=dstnat comment="MQTT Failover" dst-address=\
    10.0.10.23 dst-port=1883 in-interface=iot_vlan protocol=tcp to-addresses=\
    192.168.89.26 to-ports=1883
add action=accept chain=dstnat comment="AWS Omega NAT" src-address-list=\
    "AWS CIDR"
add action=accept chain=srcnat dst-address-list="AWS CIDR" src-address=\
    192.168.89.0/24 to-addresses=192.168.89.0/24
add action=accept chain=srcnat dst-address-list="AWS CIDR" src-address=\
    10.0.10.0/24 to-addresses=10.0.10.0/24
add action=accept chain=srcnat dst-address-list="AWS CIDR" src-address=\
    192.168.90.0/24 to-addresses=10.0.10.0/24
add action=accept chain=srcnat dst-address-list="AWS CIDR" src-address=\
    172.16.90.0/24 to-addresses=10.0.10.0/24
add action=accept chain=srcnat dst-address-list="AWS CIDR" src-address=\
    172.16.91.0/27 to-addresses=10.0.10.0/24
add action=dst-nat chain=dstnat comment="ha.mostardesigns.com NAT" disabled=\
    yes dst-port=8123 in-interface=ether5 log=yes protocol=tcp to-addresses=\
    10.0.10.5 to-ports=8123
add action=dst-nat chain=dstnat dst-address=10.0.10.6 dst-port=3000 \
    in-interface=home_lan protocol=tcp to-addresses=10.0.10.6 to-ports=443
add action=dst-nat chain=dstnat dst-port=3000 in-interface-list=WAN protocol=\
    tcp to-addresses=10.0.10.6 to-ports=443
add action=dst-nat chain=dstnat disabled=yes dst-address=10.0.10.10 dst-port=\
    443 in-interface-list=homelan protocol=tcp to-addresses=10.0.10.6 \
    to-ports=443
add action=dst-nat chain=dstnat comment="Public Traefik Access" dst-port=80 \
    in-interface-list=WAN protocol=tcp to-addresses=10.0.10.6 to-ports=80
add action=dst-nat chain=dstnat dst-port=443 in-interface-list=WAN protocol=\
    tcp to-addresses=10.0.10.6 to-ports=443
add action=dst-nat chain=dstnat dst-port=993 in-interface-list=WAN protocol=\
    tcp to-addresses=10.0.10.6 to-ports=993
add action=dst-nat chain=dstnat dst-port=587 in-interface-list=WAN protocol=\
    tcp to-addresses=10.0.10.6 to-ports=587
add action=dst-nat chain=dstnat dst-port=25 in-interface-list=WAN protocol=\
    tcp to-addresses=10.0.10.6 to-ports=25
add action=dst-nat chain=dstnat comment="HomeAssistant MCP Agent" disabled=\
    yes dst-port=8099 in-interface-list=WAN protocol=tcp to-addresses=\
    192.168.89.25 to-ports=8099
add action=dst-nat chain=dstnat comment="Cyberpower UPS" dst-address=\
    10.0.10.245 dst-port=80 protocol=tcp to-ports=3052
add action=masquerade chain=srcnat comment=VPN disabled=yes log=yes \
    log-prefix=openvpn src-address=172.16.91.0/27
add action=masquerade chain=srcnat disabled=yes dst-address=192.168.88.0/24 \
    out-interface=*F0000A
add action=masquerade chain=srcnat comment=\
    "NAT Mostar L2TP tunnel traffic to internet" out-interface-list=WAN \
    src-address=192.168.88.0/24
add action=masquerade chain=srcnat comment=\
    "NAT WireGuard tunnel traffic to internet" out-interface-list=WAN \
    src-address=172.16.91.0/24
add action=masquerade chain=srcnat comment="WAN Masquerade" \
    out-interface-list=WAN
/ip firewall raw
add action=notrack chain=prerouting disabled=yes dst-address-list=\
    10.100.0.0/16 src-address-list=192.168.89.0/24
add action=notrack chain=prerouting disabled=yes dst-address-list=\
    192.168.89.0/24 src-address-list=10.100.0.0/16
/ip ipsec identity
add disabled=yes peer="AWS Peer 1" secret=<REDACTED_IPSEC_SECRET>
add disabled=yes peer="AWS Peer 2" secret=<REDACTED_IPSEC_SECRET>
add disabled=yes peer="Omega AWS Peer 1" secret=<REDACTED_IPSEC_SECRET>
add disabled=yes peer="Omega AWS Peer 2" secret=<REDACTED_IPSEC_SECRET>
# can't add identity to dynamic peer
add peer=l2tp-in-server secret=<REDACTED_IPSEC_SECRET>
# Peer does not exist
add peer=*7 secret=<REDACTED_IPSEC_SECRET>
/ip ipsec policy
add disabled=yes dst-address=10.90.0.0/16 peer="Omega AWS Peer 1" proposal=\
    "Aws 1" src-address=10.0.10.0/24 tunnel=yes
add disabled=yes dst-address=10.90.0.0/16 peer="Omega AWS Peer 1" proposal=\
    "Aws 1" src-address=192.168.89.0/24 tunnel=yes
add disabled=yes dst-address=10.90.0.0/16 peer="Omega AWS Peer 1" proposal=\
    "Aws 1" src-address=192.168.90.0/24 tunnel=yes
add disabled=yes dst-address=10.90.0.0/16 peer="Omega AWS Peer 1" proposal=\
    "Aws 1" src-address=172.16.91.0/27 tunnel=yes
add disabled=yes dst-address=10.90.0.0/16 peer="Omega AWS Peer 1" proposal=\
    "Aws 1" src-address=172.16.90.0/24 tunnel=yes
add disabled=yes dst-address=34.199.7.183/32 peer="Omega AWS Peer 2" \
    proposal="Aws 2" src-address=100.37.100.177/32 tunnel=yes
/ip route
add check-gateway=ping disabled=no distance=1 dst-address=0.0.0.0/0 gateway=\
    172.16.91.30 routing-table=torrent_over_mostar scope=30 target-scope=10
add check-gateway=ping disabled=yes dst-address=0.0.0.0/0 gateway=\
    192.168.42.129
add check-gateway=ping disabled=yes distance=1 dst-address=192.168.100.0/24 \
    gateway=172.16.91.30 routing-table=main scope=30 target-scope=10
add check-gateway=ping disabled=no distance=1 dst-address=192.168.88.0/24 \
    gateway=172.16.91.30 routing-table=main scope=30 target-scope=10
add check-gateway=ping disabled=no distance=1 dst-address=192.168.100.0/24 \
    gateway=172.16.91.30 routing-table=main scope=30 target-scope=10
/ip service
set ftp disabled=yes
set ssh address="10.0.10.0/24,192.168.89.0/24,192.168.90.0/24,172.16.90.0/24,1\
    72.16.91.0/32"
set telnet disabled=yes
set www address="10.0.10.0/24,192.168.89.0/24,192.168.90.0/24,172.16.90.0/24,1\
    72.16.91.0/24,192.168.88.0/24"
set api address="10.0.10.0/24,192.168.89.0/24,192.168.90.0/24,172.16.90.0/24,1\
    72.16.91.0/24,192.168.88.0/24"
set api-ssl address="10.0.10.0/24,192.168.89.0/24,192.168.90.0/24,172.16.90.0/\
    24,172.16.91.0/24,192.168.88.0/24"
/ip smb shares
set [ find default=yes ] directory=/pub
/ipv6 nd
set [ find default=yes ] advertise-dns=yes
/ppp aaa
set use-radius=yes
/ppp profile
add local-address=<REDACTED_WAN_IP> name="nbi ovpn" remote-address=*2 \
    use-encryption=yes
/ppp secret
add disabled=yes name=<REDACTED_USER> password=<REDACTED_PASSWORD>
add disabled=yes name=<REDACTED_USER> password=<REDACTED_PASSWORD>
add name=<REDACTED_USER> password=<REDACTED_PASSWORD> profile="mostardesigns.com ovpn" \
    service=ovpn
add disabled=yes name=<REDACTED_USER> password=<REDACTED_PASSWORD> profile=\
    "mostardesigns.com ovpn" service=ovpn
add disabled=yes name=<REDACTED_USER> password=<REDACTED_PASSWORD> profile=\
    "mostardesigns.com ovpn" service=ovpn
add disabled=yes name=<REDACTED_USER> password=<REDACTED_PASSWORD> profile=\
    "mostardesigns.com ovpn" service=ovpn
add disabled=yes name=<REDACTED_USER> password=<REDACTED_PASSWORD> profile=\
    "mostardesigns.com ovpn" service=ovpn
add disabled=yes name=<REDACTED_USER> password=<REDACTED_PASSWORD> profile=\
    "mostardesigns.com ovpn" service=ovpn
add disabled=yes name=<REDACTED_USER> password=<REDACTED_PASSWORD> profile=\
    "mostardesigns.com ovpn" service=ovpn
add disabled=yes name=<REDACTED_USER> password=<REDACTED_PASSWORD> profile=\
    "mostardesigns.com ovpn" service=ovpn
add disabled=yes name=<REDACTED_USER> password=<REDACTED_PASSWORD> profile="nbi ovpn" service=ovpn
add disabled=yes name=<REDACTED_USER> password=<REDACTED_PASSWORD> profile=\
    "mostardesigns.com ovpn" service=ovpn
add name=<REDACTED_USER> password=<REDACTED_PASSWORD> profile=\
    "mostardesigns.com ovpn" remote-address=172.16.91.29 service=ovpn
add name=<REDACTED_USER> password=<REDACTED_PASSWORD> profile=\
    "mostardesigns.com l2tp" remote-address=172.16.91.30 service=l2tp
/radius
add address=10.0.10.10 realm=mostardesigns.com secret=<REDACTED_RADIUS_SECRET> service=ppp timeout=3s
/radius incoming
set accept=yes
/routing bfd configuration
add disabled=no
/system clock
set time-zone-name=America/New_York
/system identity
set name=Kuca
/system leds
set 0 type=interface-activity
set 1 type=interface-activity
set 2 leds=""
add interface=ether2 leds="" type=interface-activity
add interface="ether1 - WAN" leds="" type=interface-activity
add interface=*6 leds="" type=wireless-status
/system logging
set 0 disabled=yes
set 1 action=disk
set 2 action=disk
add disabled=yes topics=l2tp
add topics=ipsec
add disabled=yes topics=ovpn
add disabled=yes topics=radius
add disabled=yes topics=wireless
add disabled=yes topics=route
add disabled=yes topics=ipsec,!packet
add disabled=yes topics=radius
add disabled=yes prefix=openvpn
add action=disk topics=critical
add topics=l2tp
add disabled=yes prefix=TRACE-TORRENT
add disabled=yes topics=wireguard
/system ntp client
set enabled=yes
/system ntp server
set broadcast=yes enabled=yes manycast=yes multicast=yes use-local-clock=yes
/system ntp client servers
add address=pool.ntp.org
add address=time.google.com
add address=time.windows.com
add address=time.aws.com
add address=time.cloudflare.com
/system routerboard settings
set auto-upgrade=yes force-backup-booter=yes
/system scheduler
add interval=1h name="Dynamic DNS Update" on-event=\
    "/system script run cloudns-update" policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-time=startup
add interval=1d name="Daily Reboot" on-event=\
    "/log warning \"Daily scheduled reboot\"; /system reboot" policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-date=2019-07-10 start-time=03:00:00
add interval=30s name="DNS Fialover Scheduler" on-event=":local PingTarget \"1\
    0.0.10.10\"\
    \n:local DnsTestHost \"google.com\"\
    \n:local FailThreshold 3\
    \n:global DnsFailoverCount\
    \n\
    \n:if ([:typeof \$DnsFailoverCount] = \"nothing\") do={:set DnsFailoverCou\
    nt 0}\
    \n\
    \n# --- Check 1: Ping (2 attempts, at least 1 must succeed) ---\
    \n:local PingResult [ping \$PingTarget count=2]\
    \n\
    \n# --- Check 2: DNS resolution via backup server ---\
    \n:local DnsOk 0\
    \n:do {\
    \n  :resolve \$DnsTestHost server=\$PingTarget\
    \n  :set DnsOk 1\
    \n} on-error={\
    \n  :set DnsOk 0\
    \n}\
    \n\
    \n# --- Combined health: both must pass ---\
    \n:local IsHealthy 0\
    \n:if (\$PingResult > 0 && \$DnsOk = 1) do={ :set IsHealthy 1 }\
    \n\
    \n:log info (\"DNS backup check \E2\80\94 ping=\" . \$PingResult . \" dns=\
    \" . \$DnsOk . \" failCount=\" . \$DnsFailoverCount)\
    \n\
    \n# --- Unhealthy path ---\
    \n:if (\$IsHealthy = 0) do={\
    \n  :if (\$DnsFailoverCount < (\$FailThreshold + 2)) do={\
    \n    :set DnsFailoverCount (\$DnsFailoverCount + 1)\
    \n\
    \n    :if (\$DnsFailoverCount = \$FailThreshold) do={\
    \n      :log warning \"DNS backup unhealthy \E2\80\94 enabling fallback DN\
    S\"\
    \n      /system script run EnableDns\
    \n    }\
    \n  }\
    \n}\
    \n\
    \n# --- Healthy path ---\
    \n:if (\$IsHealthy = 1) do={\
    \n  :if (\$DnsFailoverCount > 0) do={\
    \n    :set DnsFailoverCount (\$DnsFailoverCount - 1)\
    \n\
    \n    :if (\$DnsFailoverCount = (\$FailThreshold - 1)) do={\
    \n      :log warning \"DNS backup recovered \E2\80\94 disabling fallback D\
    NS\"\
    \n      /system script run DisableDns\
    \n    }\
    \n  }\
    \n}" policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-date=2019-10-07 start-time=00:00:00
add interval=1m name=ping_proxmox_stack_scheduler on-event=ping_proxmox_stack \
    policy=read,write,policy,test start-time=startup
add interval=5m name=traefik-watchdog on-event=\
    "/system script run recreate-traefik-docker" policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-date=2026-02-16 start-time=15:29:16
/system watchdog
set watchdog-timer=no
/tool bandwidth-server
set allowed-addresses4=192.168.88.0/24,172.16.91.0/24
/tool graphing interface
add interface=ether5
add interface=ether2
add interface="ether1 - WAN"
add interface=iot_vlan
/tool graphing queue
add simple-queue="Usage Counter - iot Wifi"
/tool mac-server
set allowed-interface-list=LAN
/tool mac-server mac-winbox
set allowed-interface-list=LAN
/tool netwatch
add disabled=no down-script="log info \"Netwatch missed a ping to 8.8.8.8 - st\
    arting timeout auto reboot script\" ; /system script run NetWatchBoot-8.8.\
    8.8" host=8.8.8.8 interval=1m timeout=1s type=simple
/tool sniffer
set filter-interface=all filter-ip-address=172.16.91.0/27
