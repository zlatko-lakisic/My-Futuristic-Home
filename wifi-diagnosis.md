# Wi‑Fi slow-download diagnosis

Date: 2026-11-03  
Scope: read-only diagnostics on Mac (wifi + wired), MikroTik, UniFi. No config changes applied.

## 1. Summary

The “wifi download much worse than upload” symptom did **not** reproduce in this session. On 5 GHz (AP Bottom Floor, ch 157/80), internet download was ~380–455 Mbps while upload was the weak side (~32–58 Mbps). LAN iperf3 to the NVR showed the air link can do ~120–315 Mbps depending on direction/streams. The strongest **structural** RF issue found is that the stacked indoor APs (and the backyard AP) share the **same 5 GHz 80 MHz block** (157/161), with auto TX power and Radio AI on — a durable co-channel / sticky-client risk that can explain intermittent slowdowns and the high retry counters you saw earlier. MikroTik is **not** sending general wifi clients through Mostar, and there is no simple queue limiting `home_wifi`.

## 2. Ranked hypotheses

### H1 — Co-channel 5 GHz between stacked APs (likely, structural)
**For**
- Bottom Floor 5 GHz: channel **157 / 80 MHz**; Top Floor: **161 / 80 MHz**; Back Yard: **157 / 80 MHz**. At 80 MHz these occupy the same 149–161 block.
- APs are one floor apart; Mac scan saw multiple strong BSS on 157.
- Top Floor short-window radio stats: ~35% TX retries on 5 GHz; Bottom ~13%.
- TX power mode **auto** on all radios; Radio AI channel optimization enabled but still landed overlapping.
- User-reported retries (Top 12.4% 5 GHz; Bottom 31.5% 2.4 GHz) fit a contended RF picture even if today’s absolute speeds are fine.

**Against**
- This session’s Mac had excellent RSSI (−39 to −41 dBm), CCA 9%, PHY 1170–1300 Mbps, and ~400 Mbps internet down.
- So overlap is a latent / intermittent risk, not a hard ceiling right now.

### H2 — Intermittent RF or load (not steady-state path failure) (likely for original symptom)
**For**
- Prior measurements: phone ~5/95, Mac wifi ~23/71; this session: Mac wifi ~400/35–55.
- Torrents were idle (~1 KiB/s); WAN idle during checks.
- Same AP/band can deliver high throughput when the medium is clean.

**Against**
- Does not by itself explain a persistent down≪up pattern if it returns under load.

### H3 — WAN/ISP asymmetry or upstream loss (likely for *current* upload weakness)
**For**
- Wifi `networkQuality` upload ~32–58 Mbps vs download ~380–455.
- Wired `networkQuality` upload ~117 vs download ~302 — upload still below a symmetric gig link, download not wifi-limited.
- ICMP to 1.1.1.1: **42% loss on wifi**, **34% on wired** (gateway loss 0% both). Points upstream of the AP, though ICMP filtering can inflate loss.

**Against**
- Wired internet down (~302) was *lower* than wifi internet down (~400) in this run — odd for a pure ISP story; may be test variance or concurrent load.

### H4 — MikroTik policy routing / Mostar catching wifi (ruled out for general traffic)
**For**
- Torrent mark-routing and living-room-over-Mostar machinery exist.

**Against**
- Exit IP country **US** (Verizon) on both wifi and wired.
- Traceroute looks like normal WAN, not the tunnel.
- Active torrent mark is **one specific src-address** only; living-room-over-Mostar rules are **disabled**.
- WireGuard Mostar interface is **disabled**; L2TP Mostar has low traffic.

### H5 — Simple queues / shaping on wifi subnet (ruled out)
**For**
- PCQ queue types exist.

**Against**
- Only simple queue: “Usage Counter - iot Wifi” on `iot_vlan`, `max-limit=0/0` (accounting only).
- No queue tree entries. `home_wifi_vlan` not targeted.

### H6 — Fasttrack bypass / router CPU starving wifi download (unlikely as primary now)
**For**
- hAP ac is single-core 720 MHz; CPU observed 15–53%.
- Wifi and wired clients are on **different** L3 interfaces (`192.168.90.0/24` VLAN2 vs `192.168.89.0/24`).

**Against**
- Fasttrack rule present (`connection-mark=no-mark`).
- Wifi internet download reached ~400 Mbps through this router in-session.
- No wifi-specific mangle marks.

### H7 — UniFi QoS policy hurting downloads (unconfirmed)
**For**
- Client attribute `qos_policy_applied: true` on Mac and phones.

**Against**
- No evidence of a low rate limit in the numbers (~400 Mbps down). Needs UI confirmation of what policy is attached (may be a default no-op).

### H8 — Sticky client to Top AP through the floor (not active for this Mac now)
**For**
- Classic risk with auto TX power and stacked APs.

**Against**
- Current MacBookPro association: **AP Bottom Floor**, 5 GHz. (Other “Mac” hostnames on Top Floor are different/randomized clients.)

### H9 — MSS/MTU on tunnel hurting wifi (unlikely for general wifi)
**For**
- `change-mss clamp-to-pmtu` exists on forward.

**Against**
- General wifi traffic not on the tunnel; exit IP US.

## 3. Results table

Speeds in Mbps. IPs/hostnames redacted. Exit location = country only.

| Device | Connection | AP | Band | Channel | Signal | Retries (notes) | Down (inet) | Up (inet) | iperf3 down (NVR→client) | iperf3 up (client→NVR) | Exit |
|---|---|---|---|---|---|---|---|---|---|---|---|
| MacBookPro | Wi‑Fi `en0` | Bottom Floor | 5 GHz | 157/80 | −39 dBm (wdutil) | Client TX retries high over session; AP 5G short-window ~13% | 455 / 379 / 406 (`networkQuality` ×3) | 35 / 58 / 32 | ~121 (4-stream) / ~280 (1-stream) | ~315 (4-stream) / ~150 (1-stream) | US |
| MacBookPro | Wired `en7` 1G FD | — | — | — | — | — | 302 | 117 | ~841 (4-stream) / ~870 (1-stream) | ~73 (4-stream) / ~38 (1-stream)* | US |
| Phone (prior) | Wi‑Fi | (unk, likely 2.4) | ? | ? | ? | Bottom 2.4 retries were high in UI | ~5 | ~95 | — | — | — |
| Mac (prior) | Wi‑Fi bottom | ? | 5 GHz | ? | ? | — | ~23 | ~71 | — | — | — |
| Wired PC (baseline note) | Wired | — | — | — | — | — | ~500 (prior) | — | — | — | — |

\*Wired Mac→NVR upload had thousands of TCP retrains despite 1G link — suspicious for dock USB NIC or L3 path Mac(`home_lan`)→NVR(`perimiter`); out of primary wifi scope but recorded.

### Association / RF detail (this session)

| Item | Value |
|---|---|
| Wifi iface | `en0` |
| Wifi IP / VLAN | `192.168.90.106` / VLAN 2 (`home_wifi_vlan`) |
| Wired IP | `192.168.89.11` on `en7` (dock) |
| SSID | Kuca |
| PHY | 802.11ac, MCS 9, NSS 3, GI 400 |
| Noise / CCA | −92 dBm / 9% |
| Gateway ping wifi | 0% loss, avg 6.8 ms, max 94 ms |
| Gateway ping wired | 0% loss, avg 0.66 ms |
| 1.1.1.1 ping wifi | 42% loss |
| 1.1.1.1 ping wired | 34% loss |
| Mac VPN/proxy | none (`scutil --nc` empty; proxy defaults only) |
| qBittorrent during tests | ~1 KiB/s down; proxied via Mostar path as designed |

## 4. Raw command output that matters (trimmed, redacted)

### Exit IP (wifi and wired)
```
country: US
org: AS701 Verizon Business
```

### networkQuality (wifi) — 3 runs summary
```
Run1: down 454.6 / up 34.9  responsiveness medium
Run2: down 379.0 / up 58.0  responsiveness medium
Run3: down 406.5 / up 32.3  responsiveness high
Interface: en0  endpoints: aaplimg.com (US NYC)
```

### networkQuality (wired)
```
down 301.9 / up 117.3  Interface: en7
```

### wdutil (wifi)
```
RSSI -39 dBm  Noise -92 dBm  CCA 9%
Tx Rate 1300 Mbps  PHY 11ac  MCS 9  NSS 3
Channel 5g157/80
Faults/Recoveries last hour: None
```

### system_profiler (current network)
```
PHY Mode: 802.11ac
Channel: 157 (5GHz, 80MHz)
Signal / Noise: -41 dBm / -93 dBm
Transmit Rate: 1170
```

### iperf3 Mac wifi ↔ NVR
```
4-stream up (Mac→NVR):   SUM ~315 Mbits/sec  (many Retr)
4-stream down (NVR→Mac): SUM ~121 Mbits/sec
1-stream up:             ~150 Mbits/sec
1-stream down:           ~280 Mbits/sec
```

### iperf3 Mac wired ↔ NVR
```
4-stream up:   SUM ~73 Mbits/sec   Retr thousands
4-stream down: SUM ~841 Mbits/sec  Retr 0
1-stream up:   ~38 Mbits/sec
1-stream down: ~870 Mbits/sec
```

### MikroTik
```
board: hAP ac (RB962UiGS-5HacT2HnT)  ROS 7.25  cpu-count 1 @ 720MHz
simple queue: only iot_vlan usage counter, max-limit 0/0
queue tree: empty
fasttrack: forward established,related connection-mark=no-mark
mangle mark-routing torrent_over_mostar: single src-address, dst-address-list=!Local
livingroom-over-mostar mangle: DISABLED
change-mss: clamp-to-pmtu on forward SYN
home_wifi_vlan: VLAN ID 2 on home_lan
ether5 (home_lan): 1Gbps full-duplex, HW offload yes
wg-mostar: DISABLED
```

### UniFi (API login, read-only)
```
Controller: Network 10.6.109

AP Bottom Floor (U7NHD, wired 1G):
  2.4: ch 6 / 20 / tx_power auto
  5:   ch 157 / 80 / tx_power auto   short-window retry% ~13.4  clients 10

AP Top Floor (U7NHD, wired 1G):
  2.4: ch 1 / 20 / tx_power auto
  5:   ch 161 / 80 / tx_power auto   short-window retry% ~34.8  clients 10

AP Back Yard (U7MSH, wired 1G):
  2.4: ch 1 / 20
  5:   ch 157 / 80

Radio AI: enabled, optimize=[channel]
SSID Kuca: both bands, band steering none, fast_roaming false, bss_transition true
MacBookPro: AP Bottom Floor, na/ac, ch 157 width 80, signal -54 (controller), qos_policy_applied true
```

## 5. Proposed fixes (do not apply until approved)

Change one at a time; re-test wifi with ethernet unplugged and `route get default` → wifi.  
Before MikroTik edits: `/export file=pre-wifi-diag` and confirm file exists.  
Before UniFi edits: take a controller backup.

### Fix A — Split 5 GHz channels (highest priority RF fix)
**Change (UniFi):** Manually set non-overlapping 5 GHz primaries, e.g.:
- Top Floor: **36 / 80** (or 40/80 in UNII-1)
- Bottom Floor: **149 / 80** (or keep 157 but ensure Top is not in 149–161)
- Back Yard: prefer a third block or **20/40 MHz** on a non-overlapping channel; avoid 157 if Bottom uses 149–161

Turn **off** Radio AI channel optimize while validating, or pin channels so AI cannot re-merge them.

**Expected:** Lower 5 GHz retries; more stable download under multi-AP load; less through-floor contention.  
**Revert:** Re-enable Radio AI / set channels back to Auto; restore from backup.

### Fix B — Lower TX power on one or both indoor APs
**Change:** Set 5 GHz (and maybe 2.4) from Auto to Medium/Low on Top and/or Bottom.  
**Expected:** Less CCI, better roaming to the closer AP.  
**Revert:** TX power → Auto.

### Fix C — Keep 2.4 GHz clean (already partly good)
**Current:** Bottom ch 6/20, Top ch 1/20, Back Yard ch 1/20 — Top and Back Yard share 1.  
**Change:** Move Back Yard 2.4 to **11** (or Top to 11) so 1/6/11 are unique.  
**Expected:** Lower 2.4 retries for IoT/phone if they land on 2.4.  
**Revert:** previous channel.

### Fix D — Investigate UniFi `qos_policy_applied`
**Change:** none until identified. In UniFi UI, open MacBookPro → check QoS / Client rate limit / Global QoS.  
**If a rate limit exists:** disable or raise it.  
**Expected:** only matters if a limit is actually configured.  
**Revert:** re-enable prior policy.

### Fix E — Temporary MikroTik isolation tests (only if slow-down returns)
1. Confirm `/export file=pre-wifi-diag`.
2. While wifi client is slow, `/tool profile duration=15` during a download.
3. Optional temporary: disable torrent mark rule  
   `/ip firewall mangle disable [find where new-routing-mark=torrent_over_mostar]`  
   **Rollback:** `/ip firewall mangle enable [find where new-routing-mark=torrent_over_mostar]`  
   (Does not affect Mostar tunnel itself if L2TP stays up; only stops policy routing for that src.)

No queue disable needed — nothing is limiting `home_wifi` today.

### Fix F — Phone forced to 5 GHz retest
Phone was on Bottom Floor **5 GHz** during this session (good). If 2.4 slowdown returns: use a 5 GHz-only SSID (you already have disabled `Kuca 5g`) or band steering Prefer 5G.  
**Revert:** disable extra SSID / steering off.

## 6. Notes on wired ~500 Mbps baseline (later session)

- This session’s wired internet `networkQuality` was ~302 down / 117 up — below the prior ~500 down baseline and below wifi’s ~400 down in the same hour. Treat as variance or concurrent load unless it repeats.
- Dock `en7` negotiates **1000baseT full-duplex**.
- LAN download Mac←NVR ~840–870 Mbps shows the L2/L3 path *can* move near-gigabit toward the Mac.
- LAN upload Mac→NVR ~38–73 Mbps with heavy TCP Retr is abnormal and separate from wifi; next session should compare iperf3 from ZlatkoPC (wired) → NVR and Mac wired → a host on the same `192.168.89.0/24` switch to see if the dock NIC or MikroTik inter-VLAN is at fault.
- hAP ac single-core CPU and inter-VLAN hairpinning remain suspects for any wired throughput under ~500–900 Mbps once wifi is settled.

## 7. Access / artifacts

- UniFi: session API via local admin (credentials not stored in repo).
- Beelink SSH: `.cursor/secrets/.traefik` works; docker socket needs elevation.
- NVR iperf3: user-local `$HOME/bin/iperf3 -s` on port 5201 (left running for follow-up; stop with `pkill -f '$HOME/bin/iperf3 -s'` when done).
- Raw captures under `/tmp/wifi-diag/` on the Mac (not committed).

---

**Status:** Diagnosis only. Waiting for approval before any UniFi/MikroTik/Mac network change.
