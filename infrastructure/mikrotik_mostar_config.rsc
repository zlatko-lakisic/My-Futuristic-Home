# Sanitized Mostar RouterOS export (credentials/usernames/keys/serials redacted)
# Original export: 2026-07-27 06:31:51 by RouterOS 7.23.2
# model = RB951G-2HnD
# software id = <REDACTED_SOFTWARE_ID>
# serial number = <REDACTED_SERIAL>
/interface bridge
add admin-mac=<REDACTED_MAC> auto-mac=no name=nyc_bridge port-cost-mode=\
    short
add name=telemach_bridge
/interface ethernet
set [ find default-name=ether1 ] l2mtu=1598 name="ether1 - wan"
set [ find default-name=ether2 ] l2mtu=1598 name="ether2 - telemach bridge"
set [ find default-name=ether3 ] comment="Living room TV" l2mtu=1598
set [ find default-name=ether4 ] comment="Office Computer" l2mtu=1598
set [ find default-name=ether5 ] comment="Bedroom TV" l2mtu=1598
/interface l2tp-client
add add-default-route=yes allow=mschap2 allow-fast-path=yes connect-to=\
    nyc.mostardesigns.com disabled=no ipsec-secret=<REDACTED_IPSEC_SECRET> name=\
    mikrotik-kuca-l2tp password=<REDACTED_PASSWORD> use-ipsec=yes use-peer-dns=\
    exclusively user=<REDACTED_USER>
/interface wireguard
add comment="NYC WireGuard" listen-port=13231 mtu=1420 name=wg-nyc \
    private-key="<REDACTED_WIREGUARD_PRIVATE_KEY>"
/interface list
add comment=defconf name=WAN
add comment=defconf name=LAN
add name=OK-To-Route
/interface lte apn
set [ find default=yes ] ip-type=ipv4 use-network-apn=no
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
add authentication-types=wpa2-psk mode=dynamic-keys name=kuca-sp \
    supplicant-identity=MikroTik wpa2-pre-shared-key=<REDACTED_WIFI_PSK>
/interface wireless
set [ find default-name=wlan1 ] band=2ghz-b/g/n channel-width=20/40mhz-XX \
    country=etsi1 disabled=no distance=indoors frequency=auto installation=\
    indoor mode=ap-bridge name=wlan_mostar security-profile=kuca-sp ssid=\
    Kuca-Mostar wireless-protocol=802.11
add disabled=no mac-address=<REDACTED_MAC> master-interface=wlan_mostar \
    name=wlan_nyc security-profile=kuca-sp ssid=Kuca-NYC wps-mode=disabled
/ip pool
add name=default-dhcp ranges=192.168.88.10-192.168.88.254
/ip dhcp-server
add address-pool=default-dhcp interface=nyc_bridge lease-time=10m name=\
    defconf
/interface ovpn-client
add add-default-route=yes certificate=mikrotik-kuca-ovpn-client-crt cipher=\
    aes128-cbc connect-to=nyc.mostardesigns.com disabled=yes mac-address=\
    <REDACTED_MAC> name=mikrotik-kuca-ovpn-client password=<REDACTED_PASSWORD> \
    profile=default-encryption user=<REDACTED_USER>
/routing table
add disabled=no fib name=torrent_over_mostar
add fib name=via_nyc
/system script
add dont-require-permissions=no name=hacs-public-wan-ip owner=admin policy=\
    read,write,policy,test source="\
    \n    :global PublicIP\
    \n\
    \n    :do {\
    \n        /ip cloud force-update\
    \n        :delay 3s\
    \n\
    \n        :local discovered [:tostr [/ip cloud get public-address]]\
    \n        :if (([:len \$discovered] = 0) or (\$discovered = \"0.0.0.0\")) \
    do={\
    \n            :error \"IP Cloud did not return a public IPv4 address\"\
    \n        }\
    \n\
    \n        :if (\$PublicIP != \$discovered) do={\
    \n            :set PublicIP \$discovered\
    \n            :log info (\"hacs-public-wan-ip: PublicIP=\" . \$discovered)\
    \n        }\
    \n    } on-error={\
    \n        :log warning \"hacs-public-wan-ip: public IPv4 discovery failed\
    \"\
    \n    }\
    \n"
/interface bridge port
add bridge=telemach_bridge comment=defconf ingress-filtering=no interface=\
    "ether2 - telemach bridge" internal-path-cost=10 path-cost=10
add bridge=telemach_bridge comment=defconf ingress-filtering=no interface=\
    ether3 internal-path-cost=10 path-cost=10
add bridge=telemach_bridge comment=defconf ingress-filtering=no interface=\
    ether4 internal-path-cost=10 path-cost=10
add bridge=telemach_bridge comment=defconf ingress-filtering=no interface=\
    ether5 internal-path-cost=10 path-cost=10
add bridge=telemach_bridge comment=defconf ingress-filtering=no interface=\
    wlan_mostar internal-path-cost=10 path-cost=10
add bridge=nyc_bridge interface=wlan_nyc
/ip firewall connection tracking
set udp-timeout=10s
/ip neighbor discovery-settings
set discover-interface-list=LAN
/ip settings
set max-neighbor-entries=8192
/ipv6 settings
set disable-ipv6=yes max-neighbor-entries=8192
/interface list member
add comment=defconf interface=nyc_bridge list=LAN
add comment=defconf interface="ether1 - wan" list=WAN
add interface=mikrotik-kuca-l2tp list=OK-To-Route
add interface=nyc_bridge list=OK-To-Route
/interface ovpn-server server
add auth=sha1,md5 mac-address=<REDACTED_MAC> name=ovpn-server1
/interface wireguard peers
add allowed-address=0.0.0.0/0 disabled=yes endpoint-address=\
    nyc.mostardesigns.com endpoint-port=51820 interface=wg-nyc name=peer1 \
    persistent-keepalive=25s public-key=\
    "<REDACTED_WIREGUARD_PUBLIC_KEY>"
/ip address
add address=192.168.88.1/24 comment=defconf interface=nyc_bridge network=\
    192.168.88.0
add address=192.168.100.100/24 comment="WAN - STATIC" interface=\
    "ether1 - wan" network=192.168.100.0
add address=172.16.91.2/30 interface=wg-nyc network=172.16.91.0
/ip cloud
set ddns-enabled=yes
/ip dhcp-client
add comment=defconf disabled=yes interface="ether1 - wan" name="ether1 - wan" \
    use-peer-dns=no use-peer-ntp=no
/ip dhcp-server lease
add address=192.168.88.224 address-lists="TV Filter List" client-id=\
    <REDACTED_CLIENT_ID> comment="Room Tv Samsung Wifi" mac-address=\
    <REDACTED_MAC> server=defconf
add address=192.168.88.220 client-id=<REDACTED_CLIENT_ID> comment=\
    "Room Tv Samsung LAN" mac-address=<REDACTED_MAC> server=defconf
/ip dhcp-server network
add address=192.168.88.0/24 comment=defconf dns-server=192.168.88.1 gateway=\
    192.168.88.1 ntp-server=192.168.88.1
/ip dns
set allow-remote-requests=yes servers=10.0.10.10,8.8.8.8
/ip dns static
add address=192.168.88.1 comment=defconf name=router.lan type=A
/ip firewall filter
add action=accept chain=input comment="remote management" dst-port=80 \
    protocol=tcp
add action=accept chain=forward comment="Allow tunnel to breakout" \
    in-interface-list=OK-To-Route
add action=accept chain=input comment=Winbox dst-port=80 in-interface=all-ppp \
    protocol=tcp
add action=accept chain=input dst-port=8728 in-interface=all-ppp protocol=tcp
add action=accept chain=input dst-port=8291 in-interface="ether1 - wan" \
    protocol=tcp
add action=accept chain=input dst-port=8291 in-interface=all-ppp protocol=tcp
add action=accept chain=input comment=\
    "defconf: accept established,related,untracked" connection-state=\
    established,related,untracked
add action=drop chain=input comment="defconf: drop invalid" connection-state=\
    invalid
add action=accept chain=input comment="defconf: accept ICMP" protocol=icmp
add action=accept chain=input comment=\
    "defconf: accept to local loopback (for CAPsMAN)" dst-address=127.0.0.1
add action=drop chain=input comment="defconf: drop all not coming from LAN" \
    in-interface-list=!OK-To-Route
add action=accept chain=forward comment="defconf: accept in ipsec policy" \
    ipsec-policy=in,ipsec
add action=accept chain=forward comment="defconf: accept out ipsec policy" \
    ipsec-policy=out,ipsec
add action=fasttrack-connection chain=forward comment="defconf: fasttrack" \
    connection-state=established,related
add action=accept chain=forward comment=\
    "defconf: accept established,related, untracked" connection-state=\
    established,related,untracked
add action=drop chain=forward comment="defconf: drop invalid" \
    connection-state=invalid
add action=drop chain=forward comment=\
    "defconf: drop all from WAN not DSTNATed" connection-nat-state=!dstnat \
    connection-state=new in-interface-list=WAN
add action=accept chain=input comment="WireGuard - NYC" dst-port=13231 \
    in-interface-list=WAN protocol=udp
add action=drop chain=forward comment="Block QUIC - force TCP fallback" \
    dst-port=443 protocol=udp
/ip firewall mangle
add action=mark-routing chain=prerouting new-routing-mark=torrent_over_mostar \
    passthrough=no src-address=172.16.55.2
add action=change-mss chain=forward comment="Clamp MSS for Double NAT" \
    new-mss=1300 protocol=tcp tcp-flags=syn
add action=accept chain=prerouting comment=\
    "Allow local router access from nyc_bridge" dst-address-type=local \
    in-interface=nyc_bridge
add action=accept chain=prerouting comment=\
    "Allow local router access from nyc_bridge" dst-address-type=local \
    in-interface=nyc_bridge
add action=mark-routing chain=prerouting comment=\
    "Route nyc_bridge through WireGuard" in-interface=nyc_bridge \
    new-routing-mark=via_nyc passthrough=no
add action=change-mss chain=forward new-mss=clamp-to-pmtu protocol=tcp \
    tcp-flags=syn
/ip firewall nat
add action=masquerade chain=srcnat comment=FORCE_NAT_TORRENT out-interface=\
    "ether1 - wan" src-address=172.16.55.2
add action=masquerade chain=srcnat comment="TV Filter Masquerade" disabled=\
    yes ipsec-policy=out,none out-interface="ether1 - wan" src-address-list=\
    "TV Filter List"
add action=masquerade chain=srcnat comment="NAT for incoming L2TP traffic" \
    disabled=yes ipsec-policy=out,none src-address=172.16.55.2
add action=masquerade chain=srcnat comment=routerboard in-interface=lo \
    ipsec-policy=out,none out-interface="ether1 - wan"
add action=masquerade chain=srcnat disabled=yes in-interface-list=LAN \
    ipsec-policy=out,none out-interface=mikrotik-kuca-l2tp
add action=masquerade chain=srcnat comment="defconf: masquerade" disabled=yes \
    in-interface-list=LAN ipsec-policy=out,none out-interface="ether1 - wan"
add action=masquerade chain=srcnat comment="NAT nyc_bridge via WireGuard" \
    out-interface=wg-nyc
/ip ipsec profile
set [ find default=yes ] dpd-interval=2m dpd-maximum-failures=5
/ip route
add disabled=no dst-address=10.0.10.0/24 gateway=172.16.91.1 routing-table=\
    main
add disabled=no distance=1 dst-address=192.168.89.0/24 gateway=172.16.91.1 \
    routing-table=main scope=30 target-scope=10
add check-gateway=ping disabled=yes distance=1 dst-address=0.0.0.0/0 gateway=\
    172.16.91.1 routing-table=main
add disabled=no distance=1 dst-address=172.16.55.0/29 gateway=172.16.90.1 \
    routing-table=main scope=30 target-scope=10
add disabled=no distance=1 dst-address=0.0.0.0/0 gateway=192.168.100.1 \
    pref-src=192.168.100.100 routing-table=torrent_over_mostar scope=30 \
    target-scope=10
add disabled=no dst-address=192.168.100.0/24 gateway="ether1 - wan" \
    routing-table=torrent_over_mostar
add dst-address=0.0.0.0/0 gateway=172.16.91.1 routing-table=via_nyc
add disabled=no distance=2 dst-address=0.0.0.0/0 gateway=192.168.100.1 \
    routing-table=main
add comment="torrent return to NYC" dst-address=172.16.55.0/29 gateway=\
    172.16.91.1
/routing bfd configuration
add disabled=no interfaces=all min-rx=200ms min-tx=200ms multiplier=5
/system clock
set time-zone-name=America/New_York
/system identity
set name=Kuca-Mostar
/system logging
set 0 disabled=yes
add topics=ipsec
add topics=ppp
add topics=l2tp
add topics=wireguard
/system ntp client
set enabled=yes
/system ntp server
set broadcast=yes broadcast-addresses=192.168.88.255 enabled=yes \
    use-local-clock=yes
/system ntp client servers
add address=172.16.91.1
/system routerboard settings
set silent-boot=yes
/system scheduler
add comment="Daily automated reboot for system maintenance" interval=1d name=\
    daily-reboot-3am on-event="/system reboot" policy=\
    reboot,write,policy,test start-date=2026-05-19 start-time=03:00:00
add comment="Flush DNS cache every 10 minutes to clear stale entries" \
    interval=10m name=clear-dns-cache-10m on-event="/ip dns cache flush" \
    policy=write,test start-time=startup
add interval=5m name=hacs-public-wan-ip on-event=\
    "/system script run hacs-public-wan-ip" policy=read,write,policy,test \
    start-time=startup
/tool mac-server
set allowed-interface-list=LAN
/tool mac-server mac-winbox
set allowed-interface-list=LAN
