# MikroTik Mostar: expose the public-facing IPv4 address to Home Assistant
#
# RouterOS 7.x import:
#   /import file-name=mikrotik_mostar_public_wan_ip.rsc
#
# The HACS MikroTik Router integration does not read /ip/cloud or /ip/address.
# With "Environment variable sensors" enabled, it exposes each
# /system/script/environment entry as a sensor whose state is the variable value.
#
# Mostar prefers NYC via L2TP for the main default route, so hostname-based
# fetches (and /ip cloud) report the NYC egress IP. This script:
#   1) resolves api.ipify.org once (via explicit public DNS — FreeIPA/L2TP DNS
#      can be flaky when use-peer-dns=exclusively)
#   2) installs a temporary /32 via the ISP CPE gateway (192.168.100.1)
#   3) fetches by that IP with a Host header (avoids a second DNS lookup to a
#      different CDN address that would again follow the L2TP default)
#   4) stores the result as:
#
#   :global PublicIP "<public-ipv4>"
#
# After import + HA option enable, expect:
#   sensor.mikrotik_mostar_environment_publicip
#
# WAN addressing (from Mostar backup / live):
#   ether1 address 192.168.100.100/24, ISP gateway 192.168.100.1
#
# Policy note (RouterOS 7.13+): /tool fetch requires the "ftp" policy when writing
# files. Scheduler-invoked runs only get the policies listed on the script and
# scheduler entries — without ftp, fetch fails silently from the scheduler while
# the same script still works when run interactively as admin.
#
# This deliberately does NOT assign the public IP to ether1. The address belongs
# to the ISP router, so assigning it locally could break or misroute traffic.
#
# Note: the detected address may be carrier-grade NAT shared by the ISP. This
# script reports the Internet-visible IPv4 address; it does not enable inbound
# connectivity or port forwarding.

/system script remove [find where name="hacs-public-wan-ip"]
/system script add name="hacs-public-wan-ip" policy=ftp,read,write,test,policy source={
    :global PublicIP

    :local ispGateway "192.168.100.1"
    :local checkHost "api.ipify.org"
    :local routeComment "hacs-public-wan-ip-temp"
    :local dnsA "8.8.8.8"
    :local dnsB "1.1.1.1"
    :local stage "start"

    :do {
        :set stage "cleanup-route"
        /ip route remove [find where comment=$routeComment]

        :local resolved
        :set stage "resolve-a"
        :do {
            :set resolved [:resolve $checkHost server=$dnsA]
        } on-error={}
        :if ([:typeof $resolved] != "ip") do={
            :set stage "resolve-b"
            :do {
                :set resolved [:resolve $checkHost server=$dnsB]
            } on-error={}
        }
        :if ([:typeof $resolved] != "ip") do={
            :error ("failed to resolve " . $checkHost)
        }

        # Prefer ISP CPE over L2TP/NYC default for this probe only
        :set stage ("route-add-" . $resolved)
        /ip route add dst-address=($resolved . "/32") gateway=$ispGateway \
            comment=$routeComment distance=1

        :delay 1s

        # Fetch by IP + Host header so /tool fetch does not re-resolve to another
        # CDN address that would still follow the L2TP default route.
        :set stage "fetch"
        /file remove [find where name="hacs-public-wan-ip.txt"]
        /tool fetch url=("http://" . $resolved . "/") \
            http-header-field=("Host:" . $checkHost) \
            dst-path=hacs-public-wan-ip.txt
        :delay 2s

        :set stage "read"
        :local discovered [/file get hacs-public-wan-ip.txt contents]
        :set discovered [:tostr $discovered]
        :set discovered [:pick $discovered 0 [:find ($discovered . "\n") "\n"]]
        /file remove [find where name="hacs-public-wan-ip.txt"]

        /ip route remove [find where comment=$routeComment]

        :if (([:len $discovered] = 0) or ($discovered = "0.0.0.0")) do={
            :error "ISP-path fetch did not return a public IPv4 address"
        }

        # Always write so HA environment sensors refresh even when IP is unchanged
        :set PublicIP $discovered
        :log info ("hacs-public-wan-ip: PublicIP=" . $discovered . " via " . $ispGateway)
    } on-error={
        /ip route remove [find where comment=$routeComment]
        /file remove [find where name="hacs-public-wan-ip.txt"]
        :log warning ("hacs-public-wan-ip: FAIL stage=" . $stage . " err=" . $error)
    }
}

/system scheduler remove [find where name="hacs-public-wan-ip"]
/system scheduler add name="hacs-public-wan-ip" start-time=startup interval=5m \
    policy=ftp,read,write,test,policy on-event="/system script run hacs-public-wan-ip"

/system script run hacs-public-wan-ip
