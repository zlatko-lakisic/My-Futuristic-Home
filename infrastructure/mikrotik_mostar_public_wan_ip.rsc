# MikroTik Mostar: expose the public-facing IPv4 address to Home Assistant
#
# RouterOS 7.x import:
#   /import file-name=mikrotik_mostar_public_wan_ip.rsc
#
# The HACS MikroTik Router integration does not read /ip/cloud or /ip/address.
# With "Environment variable sensors" enabled, it exposes each
# /system/script/environment entry as a sensor whose state is the variable value.
#
# Mostar prefers NYC via L2TP/WireGuard for many flows, so /ip cloud would report
# the NYC egress IP. This script instead fetches the Internet-visible IPv4 address
# forced out the local ISP CPE (ether1 WAN) and stores it as:
#
#   :global PublicIP "<public-ipv4>"
#
# After import + HA option enable, expect roughly:
#   sensor.mikrotik_mostar_publicip
#
# WAN addressing (from Mostar backup):
#   ether1 address 192.168.100.100/24, ISP gateway 192.168.100.1
# If your CPE gateway really is 192.168.1.1, change $ispGateway / $wanSrc below.
#
# This deliberately does NOT assign the public IP to ether1. The address belongs
# to the ISP router, so assigning it locally could break or misroute traffic.
#
# Note: the detected address may be carrier-grade NAT shared by the ISP. This
# script reports the Internet-visible IPv4 address; it does not enable inbound
# connectivity or port forwarding.

/system script remove [find where name="hacs-public-wan-ip"]
/system script add name="hacs-public-wan-ip" policy=read,write,test,policy source={
    :global PublicIP

    :local ispGateway "192.168.100.1"
    :local wanSrc "192.168.100.100"
    :local checkHost "api.ipify.org"
    :local routeComment "hacs-public-wan-ip-temp"

    :do {
        /ip route remove [find where comment=$routeComment]

        :local resolved [:resolve $checkHost]
        :if ([:typeof $resolved] != "ip") do={
            :error ("failed to resolve " . $checkHost)
        }

        # Prefer ISP CPE over L2TP/NYC default for this probe only
        /ip route add dst-address=($resolved . "/32") gateway=$ispGateway \
            comment=$routeComment distance=1

        :delay 1s

        :local result [/tool fetch url=("https://" . $checkHost) \
            src-address=$wanSrc http-method=get output=user as-value]
        :local discovered [:tostr ($result->"data")]
        :set discovered [:pick $discovered 0 [:find ($discovered . "\n") "\n"]]

        /ip route remove [find where comment=$routeComment]

        :if (([:len $discovered] = 0) or ($discovered = "0.0.0.0")) do={
            :error "ISP-path fetch did not return a public IPv4 address"
        }

        :if ($PublicIP != $discovered) do={
            :set PublicIP $discovered
            :log info ("hacs-public-wan-ip: PublicIP=" . $discovered . " via " . $ispGateway)
        }
    } on-error={
        /ip route remove [find where comment=$routeComment]
        :log warning "hacs-public-wan-ip: public IPv4 discovery via ISP WAN failed"
    }
}

/system scheduler remove [find where name="hacs-public-wan-ip"]
/system scheduler add name="hacs-public-wan-ip" start-time=startup interval=5m \
    policy=read,write,test,policy on-event="/system script run hacs-public-wan-ip"

/system script run hacs-public-wan-ip
