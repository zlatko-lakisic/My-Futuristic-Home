# EON split-routing investigation — handoff

Continue this from another machine. This file has no LAN addresses. Real values are in [eon-analysis.local.env](../../.cursor/secrets/eon-analysis.local.env). That one file is tracked. The rest of `.cursor/secrets/` is not, so the other laptop still needs its own copy of the router and resolver logins.

Checked 2026-10-10, about 17:36–17:46 America/New_York, on router `Kuca` (hAP ac, RouterOS 7.24.4). Nothing in this investigation has been implemented. No route, NAT, firewall, DNS, DHCP, or tunnel change was made.

## Goal

Find out whether EON traffic on two Samsung TVs can be identified apart from every other app, so that later only EON could be routed through `MOSTAR_TUNNEL` while everything else stays on the normal WAN.

This stage is investigation only. The output is a feasibility report and a proposed change plan. The first step of that future plan is one test session of a single TV through Mostar, written as a plan, not performed.

## Hard rules

- No changes to routing, DNS, DHCP, NAT, firewall, or the tunnel. Not on `Kuca`, not on the house resolver, not on Mostar.
- The only router change allowed during capture is temporary sniffer settings that stream TZSP to the PC running the test. Save the current sniffer settings first, restore them when done, write nothing to router disk.
- If the traffic cannot be seen without another change (fasttrack is the likely case), stop and say so. Do not add a fasttrack bypass.
- Do not enable DNS query logging. It is already on.
- Do not connect to Mostar until explicitly told to.
- In this handoff, TVs are `LIVING_ROOM_TV` and `MASTER_BEDROOM_TV`, and the tunnel is `MOSTAR_TUNNEL`. The addresses for those names are in [eon-analysis.local.env](../../.cursor/secrets/eon-analysis.local.env).

## Logins

| Target | Secret file | How auth worked on the first laptop |
| --- | --- | --- |
| `Kuca` | `.cursor/secrets/.router-kuca` | Password auth is disabled. SSH with the local `id_rsa` key succeeded. Host key was already trusted. |
| House resolver | `.cursor/secrets/.freeipa` | Password from that file. Host key is trusted on the first laptop only. |
| Mostar | `.cursor/secrets/.router-mostar` | File exists (host, username, password). Not used. Host key was not trusted, and connection was not approved. |

On the other laptop, `known_hosts` will not contain the resolver. Confirm these FreeIPA fingerprints before trusting it. Do not use `StrictHostKeyChecking=no`.

- RSA SHA256:`+jXzfVK40mh02cq0b+62QSz5fZNV5mRyTVVm8jrXDVY`
- ECDSA SHA256:`AfWfrhV3Q5XzXUKiN4op/2hUjdMtKYyz0uRrfvHw2bs`
- ED25519 SHA256:`KZsE+hojQEPAAKG2xTLdIMflDvDmLSeavfk1h3LNqmM`

RouterOS SSH prints wrap and the console pager can write `console-dump.txt` on the router if dumped. Avoid that. If a dump file appears, delete it. Do not leave it.

## TVs

Mapping confirmed from DHCP leases plus Home Assistant. Both are Samsung Tizen sets, hostname `Samsung`, DHCP class `udhcpc 1.21.1`, dynamic leases on `home_dhcp`, learned on the house LAN bridge. MACs are factory addresses, not randomized. A static lease is not required for MAC stability. Re-read the leases before capture anyway, because a dynamic lease can move.

- `LIVING_ROOM_TV`: 86-inch TU9010, 2020, SmartThings firmware `T-NKMAKUC-2743.0`.
- `MASTER_BEDROOM_TV`: 65-inch Q60A, 2021, SmartThings firmware `T-NKLAAKUC-2301.1`.

At 17:36 both were bound with about 23 hours left. Last DHCP traffic was tens of minutes earlier, and both had zero tracked connections, so that snapshot could not show DNS behavior. The sets do not need to be on for another lease check. They do need to be on, with EON closed, when a capture phase starts.

## What step 0 already established

**DNS path.** DHCP sends the TV subnet to `HOUSE_RESOLVER_IP` (FreeIPA on the perimeter subnet, not the TV subnet). The router has `allow-remote-requests=yes` but is not the resolver DHCP hands out. No source NAT hides a TV address on the way to that resolver. Masquerade applies to WAN egress and to the Mostar and WireGuard tunnel ranges, not to TV-to-resolver traffic.

**Resolver logs, usable now.** FreeIPA 4.13.1 on CentOS Stream 10, BIND 9.18.33. `rndc status` says query logging is on. Lines go to `/var/named/data/query.log` (world-readable, actively written), not to `journalctl`. Each line has client address, port, query name, and type. Filter that file by the TV address during each phase. Do not turn logging on or off.

**IPv6.** Disabled on `Kuca`. No global address, no DHCPv6 client, pool, or server, no IPv6 route. Capture stays IPv4.

**DNS Failover, still armed.** Scheduler `DNS Fialover Scheduler` runs every 30 seconds. It pings `HOUSE_RESOLVER_IP` and resolves `google.com` through it. After 3 failures it runs `EnableDns`, which enables the dstnat rule comment `DNS Failover` (UDP/53 toward the house resolver, redirected to `FAILOVER_RESOLVER_IP`). Recovery runs `DisableDns`. A second line in those scripts looks for a NAT comment matching `NTP`. No such rule exists, so that line does nothing.

At check time the failover rule was **disabled** and `DnsFailoverCount` was **0**. `EnableDns` last ran 2026-10-10 09:16, `DisableDns` at 09:17, five runs each. The scheduler was not stopped. Re-read the rule at the start and end of every capture phase. It can flip mid-test.

**Fasttrack.** One IPv4 forward rule, `established,related`, comment `FastTrack to established connections`. No IPv6 fasttrack rule. No `hw-offload` property. It is in use. Do not insert a bypass. If a later sniffer misses fasttracked packets, stop and report that.

**`tv_over_vpn`.** The routing table exists and is empty. No route and no mangle rule uses it. Do not touch it. A later plan must account for it so a new design does not collide with the name.

**Sniffer, stopped.** Restore these settings after any test. The address value is `SNIFFER_RESTORE_FILTER` in the env file.

- `running` no
- `streaming-enabled` no, `streaming-server` `0.0.0.0:37008`
- `file-name` empty, `file-limit` 1000KiB, `memory-limit` 100KiB, `memory-scroll` yes
- `only-headers` no, `max-packet-size` 2048, `filter-stream` no
- `filter-interface` all, `filter-direction` any, `filter-operator-between-entries` or
- `filter-ip-address` = `SNIFFER_RESTORE_FILTER`
- MAC, port, and protocol filters empty

Free disk on the router is about 2.7 MiB of 16 MiB. Do not write a pcap on the router. Stream only.

**This PC.** Wireshark and tshark are not installed, and they are not required. The router can send TZSP as ordinary UDP to the PC. A short Python listener (stdlib only) can unwrap it and read TLS and QUIC hostnames. Python 3.12 is already installed. Do not vendor Wireshark into the repo. Npcap is a machine-wide driver and is not needed if the PC listens on the UDP port instead of sniffing the interface. Windows may prompt to allow that inbound UDP when capture starts.

**Mostar.** Not connected. Home Assistant has a live sensor login to `Mikrotik-Mostar` (RB951G-2HnD, RouterOS 7.24.4). That integration cannot run `:resolve`. A GeoDNS check needs an approved session using `.cursor/secrets/.router-mostar`, after the host key is accepted.

## What is left

1. **Capture, one TV at a time, only after an explicit go-ahead.** Other TV stays out of EON. Operator switches phases when told.

   | Phase | What the operator does | Duration |
   | --- | --- | --- |
   | a | TV on, home screen, EON closed | 10 min |
   | b | Open EON, stay on the main menu | 5 min |
   | c | Play a live channel | 5 min |
   | d | Play one on-demand title | 5 min |
   | e | Close EON | 5 min |
   | f | Netflix | 5 min |
   | g | YouTube | 5 min |

   The operator will also say which EON channels work and any region or availability messages.

   Per phase, record:

   - Resolver log lines for that TV (name, answer if present, time).
   - TZSP stream filtered to that TV: TCP and UDP 443 (TLS and QUIC SNI), plus 53 and 853 (DNS that bypassed the resolver). Headers only after the handshakes if volume is a problem.
   - `/ip firewall connection` every 30 seconds: destination, port, protocol, bytes.
   - Whether the `DNS Failover` rule is disabled at phase start and end.

2. **Analysis.** EON candidates are names and SNI present in b–d and absent or near zero in a, e, f, and g. Categorize as backend, CDN/media, DRM/license, analytics, or unknown. List every candidate that also appears in a, f, or g (those would drag other apps into the tunnel). Explain any EON-phase connection with no matching DNS query, or mark it unknown. Report how much EON traffic is QUIC. Compare the 2020 and 2021 sets.

3. **GeoDNS, only if Mostar access is approved.** Resolve candidate names from the house resolver and from Mostar. Report which answers differ by location.

4. **Report and stop.** Answer, with a verdict:

   1. Does EON map to a bounded, stable set of hostnames?
   2. Is overlap with other apps small or absent?
   3. Is all EON traffic explained by DNS (no hardcoded IPs or DoH)?
   4. Which names are geo-sensitive?
   5. Is split routing feasible, partly feasible (with the tradeoffs listed), or not feasible?

   Then a proposed change plan, in order, with rollback for each step. First step: one TV routed through Mostar, as a test plan only, to see if EON plays from Bosnia at all.

## Do not do on resume

- Do not start a capture, change the sniffer, or connect to Mostar until asked.
- Do not add fasttrack bypass rules, DNS redirects, or resolver logging changes.
- Do not commit the rest of `.cursor/secrets/`. Only [eon-analysis.local.env](../../.cursor/secrets/eon-analysis.local.env) is meant to be tracked.
