#!/bin/sh
# Restrict HAOS host SSH to the same LAN CIDRs as packages/scrub_local_ip_bans.py.
# Applies to TCP 22222 (debug dropbear) and TCP 22 (if the SSH add-on is ever published).
# Idempotent. Persists via udev on overlay (see 99-hassos-restrict-ssh.rules).

CHAIN=HAOS-SSH
CHAIN6=HAOS-SSH6
PORTS="22222 22"
CIDRS="127.0.0.0/8 192.168.88.0/24 192.168.89.0/24 192.168.90.0/24 172.16.90.0/24 172.16.91.0/24 10.0.10.0/24"

ensure_v4() {
  iptables -nL "$CHAIN" >/dev/null 2>&1 || iptables -N "$CHAIN"
  iptables -F "$CHAIN"
  iptables -A "$CHAIN" -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
  for cidr in $CIDRS; do
    iptables -A "$CHAIN" -s "$cidr" -j ACCEPT
  done
  iptables -A "$CHAIN" -j DROP

  for port in $PORTS; do
    iptables -C INPUT -p tcp --dport "$port" -j "$CHAIN" 2>/dev/null \
      || iptables -I INPUT 1 -p tcp --dport "$port" -j "$CHAIN"
  done
}

ensure_v6() {
  # No IPv6 LAN allowlist in the ban whitelist — allow loopback/link-local only.
  ip6tables -nL "$CHAIN6" >/dev/null 2>&1 || ip6tables -N "$CHAIN6"
  ip6tables -F "$CHAIN6"
  ip6tables -A "$CHAIN6" -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
  ip6tables -A "$CHAIN6" -s ::1/128 -j ACCEPT
  ip6tables -A "$CHAIN6" -s fe80::/10 -j ACCEPT
  ip6tables -A "$CHAIN6" -j DROP

  for port in $PORTS; do
    ip6tables -C INPUT -p tcp --dport "$port" -j "$CHAIN6" 2>/dev/null \
      || ip6tables -I INPUT 1 -p tcp --dport "$port" -j "$CHAIN6"
  done
}

ensure_v4
ensure_v6
