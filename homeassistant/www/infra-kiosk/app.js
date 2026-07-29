(function () {
  "use strict";

  var cfg = window.INFRA_KIOSK || {};
  var STORAGE_KEY = "infra_kiosk_token";
  var states = {};
  var ws = null;
  var msgId = 1;
  var reconnectTimer = null;
  var paintTimer = null;

  var ENTITIES = [
    "binary_sensor.mikrotik_home_ether1_connection",
    "update.mikrotik_home_hap_ac_routeros_update",
    "sensor.mikrotik_home_hap_ac_uptime",
    "sensor.mikrotik_home_hap_ac_cpu_load",
    "sensor.mikrotik_home_hap_ac_memory_usage",
    "sensor.mikrotik_home_ether1_rx",
    "sensor.mikrotik_home_ether1_tx",
    "sensor.mikrotik_home_ether3_rx",
    "sensor.mikrotik_home_ether3_tx",
    "sensor.mikrotik_home_home_wifi_vlan_rx",
    "sensor.mikrotik_home_home_wifi_vlan_tx",
    "sensor.mikrotik_home_iot_vlan_rx",
    "sensor.mikrotik_home_iot_vlan_tx",
    "binary_sensor.mikrotik_mostar_ether1_connection",
    "sensor.mikrotik_mostar_rb951g_2hnd_cpu_load",
    "sensor.mikrotik_mostar_rb951g_2hnd_memory_usage",
    "sensor.mikrotik_mostar_ether1_rx",
    "sensor.mikrotik_mostar_ether1_tx",
    "sensor.perimiter_switch_cpu_temperature",
    "sensor.perimeter_switch_total_rx",
    "sensor.perimeter_switch_total_tx",
    "sensor.perimeter_switch_link_capacity",
    "sensor.ap_back_yard_clients",
    "sensor.ap_back_yard_cpu_utilization",
    "sensor.ap_back_yard_memory_utilization",
    "sensor.ap_bottom_floor_clients",
    "sensor.ap_bottom_floor_cpu_utilization",
    "sensor.ap_bottom_floor_memory_utilization",
    "sensor.ap_top_floor_clients",
    "sensor.ap_top_floor_cpu_utilization",
    "sensor.ap_top_floor_memory_utilization",
    "switch.basement_msnswitch_router_modem_uis_auto_reset",
    "switch.basement_msnswitch_router_modem_router",
    "switch.basement_msnswitch_router_modem_modem",
    "binary_sensor.basement_msnswitch_router_modem_router",
    "binary_sensor.basement_msnswitch_router_modem_google_dns_2",
    "switch.basement_msnswitch_traefik_nas1_uis_auto_reset",
    "switch.basement_msnswitch_traefik_nas1_traefik",
    "switch.basement_msnswitch_traefik_nas1_nas1",
    "binary_sensor.basement_msnswitch_traefik_nas1_traefik",
    "binary_sensor.basement_msnswitch_traefik_nas1_nas1",
    "switch.basement_msnswitch_nas2_omega_jetson_uis_auto_reset",
    "switch.basement_msnswitch_nas2_omega_jetson_nas2",
    "switch.basement_msnswitch_nas2_omega_jetson_omega_jetson",
    "binary_sensor.basement_msnswitch_nas2_omega_jetson_nas2",
    "binary_sensor.basement_msnswitch_nas2_omega_jetson_jetson",
    "sensor.homeassistant_cpu_usage",
    "sensor.homeassistant_memory_usage",
    "sensor.homeassistant_memory_use",
    "sensor.homeassistant_data_disk_usage",
    "sensor.homeassistant_enp1s0_rx",
    "sensor.homeassistant_enp1s0_tx",
    "sensor.qemu_nginx_prod_100_cpu_used",
    "sensor.infra_garden_speaker_cpu_usage",
    "sensor.infra_jetson_cpu_usage",
    "sensor.nvr_mostardesigns_com_cpu_usage",
    "sensor.nvr_mostardesigns_com_nvidia_rtx_4000_sff_ada_generation_gpu_nvidia0_processor_usage",
    "sensor.nvr_mostardesigns_com_nvidia_rtx_4000_sff_ada_generation_gpu_nvidia0_memory_usage",
    "binary_sensor.codeproject_ai_server_status",
    "sensor.nvr_mostardesigns_com_enp3s0_rx",
    "sensor.nvr_mostardesigns_com_enp3s0_tx",
    "sensor.back_yard_pipeline_cpu",
    "sensor.back_yard_frigate_fps",
    "sensor.garden_north_pipeline_cpu",
    "sensor.garden_north_frigate_fps",
    "sensor.west_side_pipeline_cpu",
    "sensor.west_side_frigate_fps",
    "sensor.driveway_pipeline_cpu",
    "sensor.driveway_frigate_fps",
    "sensor.garden_south_pipeline_cpu",
    "sensor.garden_south_frigate_fps",
    "sensor.nas1_filesystem_md0",
    "sensor.nas1_filesystem_mmcblk0p8",
    "sensor.nas1_system_cpu_load",
    "sensor.nas1_system_memory",
    "sensor.nas1_disk_nvme0n1",
    "sensor.nas1_disk_nvme1n1",
    "sensor.nas1_disk_nvme2n1",
    "sensor.nas1_disk_nvme3n1",
    "binary_sensor.nas1_services_smb_cifs_service",
    "binary_sensor.nas1_services_ssh_service",
    "binary_sensor.nas1_services_nfs_service",
    "sensor.nas2_filesystem",
    "sensor.nas2_filesystem_2",
    "sensor.nas2_disk",
    "sensor.nas2_disk_2",
    "sensor.nas2_disk_3",
    "sensor.nas2_disk_4",
    "sensor.nas2_disk_5"
  ];

  function $(id) { return document.getElementById(id); }

  function getToken() {
    if (cfg.token) return String(cfg.token).trim();
    try { return (localStorage.getItem(STORAGE_KEY) || "").trim(); } catch (e) { return ""; }
  }

  function setToken(t) {
    try { localStorage.setItem(STORAGE_KEY, t); } catch (e) {}
  }

  function haBase() {
    if (cfg.haUrl) return String(cfg.haUrl).replace(/\/$/, "");
    return location.origin;
  }

  function wsUrl() {
    var base = haBase();
    if (base.indexOf("https:") === 0) return base.replace(/^https/, "wss") + "/api/websocket";
    return base.replace(/^http/, "ws") + "/api/websocket";
  }

  function st(id) { return states[id] || null; }

  function bad(v) {
    if (v == null) return true;
    var s = String(v).toLowerCase();
    return s === "" || s === "unknown" || s === "unavailable" || s === "none";
  }

  function num(id) {
    var s = st(id);
    if (!s || bad(s.state)) return null;
    var n = parseFloat(s.state);
    return isFinite(n) ? n : null;
  }

  function attr(id, key) {
    var s = st(id);
    if (!s || !s.attributes) return null;
    return s.attributes[key];
  }

  function fmt(n, d) {
    if (n == null || !isFinite(n)) return "—";
    var x = Number(n);
    if (d == null) d = 1;
    return String(parseFloat(x.toFixed(d)));
  }

  function clampPct(n) {
    if (n == null || !isFinite(n)) return 0;
    return Math.min(100, Math.max(0, n));
  }

  function wanIp(id) {
    var raw = attr(id, "client_ip_address");
    if (bad(raw)) return "—";
    var s = String(raw);
    return s.indexOf("/") >= 0 ? s.split("/")[0] : s;
  }

  function uptime(id) {
    var iso = st(id) && st(id).state;
    if (bad(iso)) return "—";
    var t = new Date(iso).getTime();
    if (!isFinite(t)) return String(iso);
    var sec = Math.floor((Date.now() - t) / 1000);
    if (sec < 0) sec = 0;
    var d = Math.floor(sec / 86400);
    var h = Math.floor((sec % 86400) / 3600);
    var m = Math.floor((sec % 3600) / 60);
    if (d > 0) return d + "d " + h + "h";
    if (h > 0) return h + "h " + m + "m";
    return m + "m";
  }

  function rateText(id) {
    var s = st(id);
    if (!s || bad(s.state)) return "—";
    var v = parseFloat(s.state);
    if (!isFinite(v)) return "—";
    var u = (s.attributes && s.attributes.unit_of_measurement) || "";
    return fmt(v, 2) + (u ? " " + u : "");
  }

  function metric(label, pct, fillClass, val) {
    return (
      '<div class="metric">' +
        '<span class="metric-label">' + label + "</span>" +
        '<div class="metric-track"><div class="metric-fill ' + fillClass + '" style="width:' + clampPct(pct) + '%"></div></div>' +
        '<span class="metric-val">' + val + "</span>" +
      "</div>"
    );
  }

  function ring(pct, label, color) {
    var p = clampPct(pct);
    var c = color || ringColor(p);
    return (
      '<div class="card gauge-card">' +
        '<div class="ring" style="--pct:' + p + ";--ring:" + c + '"><div class="ring-val">' +
          (pct == null ? "—" : Math.round(p) + "%") +
        "</div></div>" +
        '<div class="gauge-label">' + label + "</div>" +
      "</div>"
    );
  }

  function ringColor(p) {
    if (p >= 95) return "#c62828";
    if (p >= 85) return "#fb8c00";
    if (p >= 70) return "#fbc02d";
    if (p >= 45) return "#7cb342";
    return "#378e3c";
  }

  function memRingColor(p) {
    if (p >= 78) return "#ffb300";
    if (p >= 62) return "#42a5f5";
    if (p >= 45) return "#1e88e5";
    if (p >= 28) return "#1565c0";
    return "#0d47a1";
  }

  function setConn(mode, text) {
    var el = $("conn");
    el.className = "conn " + mode;
    el.textContent = text;
  }

  function tickClock() {
    var d = new Date();
    var hh = String(d.getHours()).padStart(2, "0");
    var mm = String(d.getMinutes()).padStart(2, "0");
    $("clock").textContent = hh + ":" + mm;
  }

  function renderGateway() {
    var onlineSt = st("binary_sensor.mikrotik_home_ether1_connection");
    var online = onlineSt && onlineSt.state === "on";
    var unknown = !onlineSt || bad(onlineSt.state);
    $("card-gateway-hero").innerHTML =
      '<div class="card-title">MikroTik Basement</div>' +
      '<div class="card-sub">Main gateway</div>' +
      '<div class="mono">WAN IP · ' + wanIp("binary_sensor.mikrotik_home_ether1_connection") + "</div>" +
      '<img src="/local/mikrotik-hap-router.png" alt="MikroTik hAP" loading="lazy" />';

    var upd = st("update.mikrotik_home_hap_ac_routeros_update");
    var fw = (upd && (upd.attributes && upd.attributes.installed_version)) || (upd && upd.state) || "—";
    var pillClass = unknown ? "pill-muted" : (online ? "pill-ok" : "pill-bad");
    var pillText = unknown ? "Gateway —" : (online ? "Gateway Online" : "Gateway Offline");
    $("card-gateway-status").innerHTML =
      '<div class="pills">' +
        '<span class="pill ' + pillClass + '">' + pillText + "</span>" +
        '<span class="pill">F/W: ' + fw + "</span>" +
        '<span class="pill">Uptime: ' + uptime("sensor.mikrotik_home_hap_ac_uptime") + "</span>" +
      "</div>";
  }

  function deviceCard(opts) {
    return (
      '<div class="card card-alt">' +
        '<div class="card-title"><span class="dot ' + opts.dot + '">●</span> ' + opts.title + "</div>" +
        '<div class="card-sub">' + opts.sub + "</div>" +
        (opts.extra || "") +
        opts.body +
      "</div>"
    );
  }

  function renderNetworkDevices() {
    var mostarOnline = st("binary_sensor.mikrotik_mostar_ether1_connection");
    var mBad = !mostarOnline || bad(mostarOnline.state);
    var mOn = mostarOnline && mostarOnline.state === "on";
    var mCpu = num("sensor.mikrotik_mostar_rb951g_2hnd_cpu_load");
    var mMem = num("sensor.mikrotik_mostar_rb951g_2hnd_memory_usage");
    var mRx = num("sensor.mikrotik_mostar_ether1_rx") || 0;
    var mTx = num("sensor.mikrotik_mostar_ether1_tx") || 0;
    var capBps = 125000000;
    var mostar =
      deviceCard({
        title: "Mikrotik-Mostar",
        sub: "RB951G · remote · " + (mBad ? "—" : (mOn ? "Online" : "Offline")),
        dot: mBad ? "dot-unk" : (mOn ? "dot-ok" : "dot-bad"),
        extra: '<div class="mono">WAN IP · ' + wanIp("binary_sensor.mikrotik_mostar_ether1_connection") + "</div>",
        body:
          metric("CPU", mCpu, "fill-cpu", mCpu == null ? "—" : Math.round(mCpu) + "%") +
          metric("Memory", mMem, "fill-mem", mMem == null ? "—" : Math.round(mMem) + "%") +
          '<div class="card-sub" style="margin-top:6px">Throughput</div>' +
          metric("Download", (mRx / capBps) * 100, "fill-rx", fmt(mRx, 1) + " kB/s") +
          metric("Upload", (mTx / capBps) * 100, "fill-tx", fmt(mTx, 1) + " kB/s")
      });

    var swCpu = num("sensor.perimiter_switch_cpu_temperature");
    var swRx = num("sensor.perimeter_switch_total_rx") || 0;
    var swTx = num("sensor.perimeter_switch_total_tx") || 0;
    var capMbps = num("sensor.perimeter_switch_link_capacity") || 1000;
    var portsUp = attr("sensor.perimeter_switch_link_capacity", "ports_up");
    var portsTotal = attr("sensor.perimeter_switch_link_capacity", "ports_total");
    if (portsTotal == null) portsTotal = 26;
    var linksOk = portsUp != null && Number(portsUp) > 0;
    var swBad = swCpu == null && portsUp == null;
    var perimeter =
      deviceCard({
        title: "CSS326 · perimeter",
        sub: "SwitchOS · " + (swBad ? "—" : (linksOk ? (portsUp + "/" + portsTotal + " up") : "No links")),
        dot: swBad ? "dot-unk" : (linksOk ? "dot-ok" : "dot-bad"),
        body:
          metric("CPU", swCpu, "fill-cpu", swCpu == null ? "—" : Math.round(swCpu) + "°") +
          '<div class="card-sub" style="margin-top:4px">Throughput (all ports)</div>' +
          metric("RX", (swRx / capMbps) * 100, "fill-rx", fmt(swRx, 1) + " Mb/s") +
          metric("TX", (swTx / capMbps) * 100, "fill-tx", fmt(swTx, 1) + " Mb/s")
      });

    function apCard(name, model, clientsId, cpuId, memId) {
      var cli = num(clientsId);
      var cpu = num(cpuId);
      var mem = num(memId);
      return deviceCard({
        title: name,
        sub: model + " · UniFi",
        dot: "dot-ok",
        body:
          metric("CPU", cpu, "fill-cpu", cpu == null ? "—" : Math.round(cpu) + "%") +
          metric("Mem", mem, "fill-mem", mem == null ? "—" : Math.round(mem) + "%") +
          metric("Clients", cli == null ? 0 : Math.min(100, cli), "fill-clients", cli == null ? "—" : String(Math.round(cli)))
      });
    }

    $("card-network-devices").innerHTML =
      mostar +
      perimeter +
      apCard("AP Back Yard", "U7MSH", "sensor.ap_back_yard_clients", "sensor.ap_back_yard_cpu_utilization", "sensor.ap_back_yard_memory_utilization") +
      apCard("AP Bottom Floor", "U7NHD", "sensor.ap_bottom_floor_clients", "sensor.ap_bottom_floor_cpu_utilization", "sensor.ap_bottom_floor_memory_utilization") +
      apCard("AP Top Floor", "U7NHD", "sensor.ap_top_floor_clients", "sensor.ap_top_floor_cpu_utilization", "sensor.ap_top_floor_memory_utilization");
  }

  function trafficCard(title, rxId, txId) {
    var rx = num(rxId);
    var tx = num(txId);
    var rxN = rx == null ? 0 : Math.max(0, rx);
    var txN = tx == null ? 0 : Math.max(0, tx);
    /* Approximate visual fill vs a 1 Gbps-ish ceiling in common HA rate units. */
    var ceil = Math.max(rxN + txN, 100);
    return (
      '<div class="card traffic-card">' +
        '<div class="card-title">' + title + "</div>" +
        metric("RX", (rxN / ceil) * 100, "fill-rx", rateText(rxId)) +
        metric("TX", (txN / ceil) * 100, "fill-tx", rateText(txId)) +
        '<div class="traffic-meta">live · no sparkline</div>' +
      "</div>"
    );
  }

  function renderGaugesAndTraffic() {
    var cpu = num("sensor.mikrotik_home_hap_ac_cpu_load");
    var mem = num("sensor.mikrotik_home_hap_ac_memory_usage");
    $("card-gateway-gauges").innerHTML =
      ring(cpu, "Gateway CPU", ringColor(clampPct(cpu))) +
      '<div class="card gauge-card"><div class="ring" style="--pct:' + clampPct(mem) + ";--ring:" + memRingColor(clampPct(mem)) +
        '"><div class="ring-val">' + (mem == null ? "—" : Math.round(clampPct(mem)) + "%") +
        '</div></div><div class="gauge-label">Gateway Memory</div></div>' +
      trafficCard("WAN (ISP)", "sensor.mikrotik_home_ether1_rx", "sensor.mikrotik_home_ether1_tx") +
      trafficCard("LAN", "sensor.mikrotik_home_ether3_rx", "sensor.mikrotik_home_ether3_tx") +
      trafficCard("Home WLAN", "sensor.mikrotik_home_home_wifi_vlan_rx", "sensor.mikrotik_home_home_wifi_vlan_tx") +
      trafficCard("IoT WLAN", "sensor.mikrotik_home_iot_vlan_rx", "sensor.mikrotik_home_iot_vlan_tx") +
      trafficCard("Perimeter", "sensor.perimeter_switch_total_rx", "sensor.perimeter_switch_total_tx");
  }

  function watchdogCard(opts) {
    var rows = opts.outlets.map(function (o) {
      var sw = st(o.sw);
      var chk = st(o.chk);
      var pwr = !sw || bad(sw.state) ? '<span class="dot-unk">●</span>' :
        (sw.state === "on" ? '<span class="on">ON</span>' : '<span class="off">OFF</span>');
      var ping = !chk || bad(chk.state) ? '<span class="dot-unk">●</span>' :
        (chk.state === "on" ? '<span class="dot-ok">●</span>' : '<span class="dot-bad">●</span>');
      return (
        '<div class="watch-row"><span>' + o.label + '</span><span class="watch-cols">' +
          pwr + ping + "</span></div>"
      );
    }).join("");
    var uis = st(opts.uis);
    var uisOn = uis && uis.state === "on";
    return (
      '<div class="card">' +
        '<div class="watch-head">' +
          '<div class="watch-icon ' + opts.iconClass + '">' + opts.iconText + "</div>" +
          "<div><div class=\"card-title\">" + opts.title + "</div>" +
          '<div class="card-sub">' + opts.sub + "</div></div>" +
        "</div>" +
        '<div class="card-sub" style="display:flex;justify-content:space-between;margin-bottom:2px"><span>Outlet</span><span>Checker</span></div>' +
        rows +
        '<div class="watch-foot"><span>UIS auto-reset</span><span class="' +
          (uisOn ? "on" : "dot-unk") + '">' + (uisOn ? "Enabled" : "Disabled") + "</span></div>" +
      "</div>"
    );
  }

  function renderWatchdogs() {
    $("card-watchdogs").innerHTML =
      watchdogCard({
        title: "WAN Watchdog",
        sub: "Perimeter · MikroTik ether3",
        iconClass: "wan",
        iconText: "W",
        uis: "switch.basement_msnswitch_router_modem_uis_auto_reset",
        outlets: [
          { label: "Router", sw: "switch.basement_msnswitch_router_modem_router", chk: "binary_sensor.basement_msnswitch_router_modem_router" },
          { label: "Modem", sw: "switch.basement_msnswitch_router_modem_modem", chk: "binary_sensor.basement_msnswitch_router_modem_google_dns_2" }
        ]
      }) +
      watchdogCard({
        title: "Perimeter & NAS1",
        sub: "Edge proxy · primary storage",
        iconClass: "edge",
        iconText: "P",
        uis: "switch.basement_msnswitch_traefik_nas1_uis_auto_reset",
        outlets: [
          { label: "Traefik", sw: "switch.basement_msnswitch_traefik_nas1_traefik", chk: "binary_sensor.basement_msnswitch_traefik_nas1_traefik" },
          { label: "NAS1", sw: "switch.basement_msnswitch_traefik_nas1_nas1", chk: "binary_sensor.basement_msnswitch_traefik_nas1_nas1" }
        ]
      }) +
      watchdogCard({
        title: "NAS2 & Jetson",
        sub: "Secondary NAS · edge compute",
        iconClass: "nas",
        iconText: "N",
        uis: "switch.basement_msnswitch_nas2_omega_jetson_uis_auto_reset",
        outlets: [
          { label: "NAS2", sw: "switch.basement_msnswitch_nas2_omega_jetson_nas2", chk: "binary_sensor.basement_msnswitch_nas2_omega_jetson_nas2" },
          { label: "Omega Jetson", sw: "switch.basement_msnswitch_nas2_omega_jetson_omega_jetson", chk: "binary_sensor.basement_msnswitch_nas2_omega_jetson_jetson" }
        ]
      });
  }

  function hostCard(opts) {
    var body = opts.bars.map(function (b) {
      return metric(b.label, b.pct, b.fill, b.val);
    }).join("");
    return (
      '<div class="card">' +
        '<div class="host-head">' +
          '<div class="host-badge">' + opts.badge + "</div>" +
          "<div><div class=\"card-title\">" + opts.title + "</div>" +
          '<div class="card-sub">' + opts.sub + "</div></div>" +
        "</div>" +
        '<div style="margin-top:8px">' + body + "</div>" +
        (opts.footer || "") +
      "</div>"
    );
  }

  function renderServers() {
    var cpu = num("sensor.homeassistant_cpu_usage");
    var mem = num("sensor.homeassistant_memory_usage");
    var disk = num("sensor.homeassistant_data_disk_usage");
    var memMiB = num("sensor.homeassistant_memory_use");
    $("card-servers").innerHTML =
      hostCard({
        badge: "HA",
        title: "Home Assistant host",
        sub: "Glances · homeassistant",
        bars: [
          { label: "CPU", pct: cpu, fill: "fill-ha-cpu", val: cpu == null ? "—" : fmt(cpu, 1) + "%" },
          { label: "Memory", pct: mem, fill: "fill-ha-mem", val: mem == null ? "—" : fmt(mem, 1) + "%" },
          { label: "Disk", pct: disk, fill: "fill-disk", val: disk == null ? "—" : fmt(disk, 1) + "%" }
        ],
        footer:
          (memMiB != null ? '<div class="card-sub" style="margin-top:-2px">' + fmt(memMiB, 0) + " MiB in use</div>" : "") +
          '<div class="host-net"><div class="card-sub" style="margin-bottom:6px;font-weight:600;opacity:0.85">Network (enp1s0)</div>' +
          '<div class="host-net-row"><span style="color:#4fc3f7">Download</span><span>' + rateText("sensor.homeassistant_enp1s0_rx") + "</span></div>" +
          '<div class="host-net-row"><span style="color:#81c784">Upload</span><span>' + rateText("sensor.homeassistant_enp1s0_tx") + "</span></div></div>"
      }) +
      hostCard({
        badge: "VM",
        title: "nginx-prod",
        sub: "QEMU · CPU",
        bars: [{ label: "CPU", pct: num("sensor.qemu_nginx_prod_100_cpu_used"), fill: "fill-cpu", val: (function () {
          var n = num("sensor.qemu_nginx_prod_100_cpu_used");
          return n == null ? "—" : Math.round(n) + "%";
        })() }]
      }) +
      hostCard({
        badge: "GS",
        title: "Garden speaker",
        sub: "Infra host",
        bars: [{ label: "CPU", pct: num("sensor.infra_garden_speaker_cpu_usage"), fill: "fill-cpu", val: (function () {
          var n = num("sensor.infra_garden_speaker_cpu_usage");
          return n == null ? "—" : Math.round(n) + "%";
        })() }]
      }) +
      hostCard({
        badge: "J",
        title: "Jetson",
        sub: "Edge compute",
        bars: [{ label: "CPU", pct: num("sensor.infra_jetson_cpu_usage"), fill: "fill-cpu", val: (function () {
          var n = num("sensor.infra_jetson_cpu_usage");
          return n == null ? "—" : Math.round(n) + "%";
        })() }]
      });

    var nvrCpu = num("sensor.nvr_mostardesigns_com_cpu_usage");
    var gpu = num("sensor.nvr_mostardesigns_com_nvidia_rtx_4000_sff_ada_generation_gpu_nvidia0_processor_usage");
    var vram = num("sensor.nvr_mostardesigns_com_nvidia_rtx_4000_sff_ada_generation_gpu_nvidia0_memory_usage");
    var ai = st("binary_sensor.codeproject_ai_server_status");
    var aiOk = ai && ai.state === "on";
    var aiBad = !ai || bad(ai.state);
    $("card-nvr").innerHTML =
      hostCard({
        badge: "NV",
        title: "NVR",
        sub: "mostardesigns.com",
        bars: [
          { label: "CPU", pct: nvrCpu, fill: "fill-ha-cpu", val: nvrCpu == null ? "—" : fmt(nvrCpu, 1) + "%" },
          { label: "GPU", pct: gpu, fill: "fill-cpu", val: gpu == null ? "—" : fmt(gpu, 1) + "%" },
          { label: "VRAM", pct: vram, fill: "fill-mem", val: vram == null ? "—" : fmt(vram, 1) + "%" }
        ],
        footer:
          '<div class="host-net"><div class="host-net-row"><span>CodeProject AI</span><span class="' +
            (aiBad ? "dot-unk" : (aiOk ? "on" : "off")) + '">' +
            (aiBad ? "—" : (aiOk ? "Online" : "Offline")) +
          "</span></div>" +
          '<div class="host-net-row"><span style="color:#4fc3f7">enp3s0 RX</span><span>' + rateText("sensor.nvr_mostardesigns_com_enp3s0_rx") + "</span></div>" +
          '<div class="host-net-row"><span style="color:#81c784">enp3s0 TX</span><span>' + rateText("sensor.nvr_mostardesigns_com_enp3s0_tx") + "</span></div></div>"
      });
  }

  function renderCameras() {
    function cam(name, fpsId, cpuId) {
      var fps = num(fpsId);
      var cpu = num(cpuId);
      return (
        '<div class="card cam-card">' +
          '<div class="card-title">' + name + "</div>" +
          '<div class="big">' + (fps == null ? "—" : fmt(fps, 1)) + ' <span class="unit">FPS</span></div>' +
          metric("CPU", cpu, "fill-cpu", cpu == null ? "—" : Math.round(cpu) + "%") +
        "</div>"
      );
    }
    $("card-cameras").innerHTML =
      cam("Back Yard", "sensor.back_yard_frigate_fps", "sensor.back_yard_pipeline_cpu") +
      cam("Garden North", "sensor.garden_north_frigate_fps", "sensor.garden_north_pipeline_cpu") +
      cam("West Side", "sensor.west_side_frigate_fps", "sensor.west_side_pipeline_cpu") +
      cam("Driveway", "sensor.driveway_frigate_fps", "sensor.driveway_pipeline_cpu") +
      cam("Garden South", "sensor.garden_south_frigate_fps", "sensor.garden_south_pipeline_cpu");
  }

  function nasCard(title, sub, md0Id, osId, cpuId, memId, diskIds, services) {
    var a = num(md0Id);
    var b = osId ? num(osId) : null;
    var cpu = cpuId ? num(cpuId) : null;
    var mem = memId ? num(memId) : null;
    var maxT = null;
    var smartBad = false;
    var disksOk = 0;
    (diskIds || []).forEach(function (id) {
      var s = st(id);
      if (!s || bad(s.state)) return;
      disksOk += 1;
      var temp = parseFloat(s.state);
      if (isFinite(temp)) maxT = maxT === null ? temp : Math.max(maxT, temp);
      var r = s.attributes && s.attributes.reallocated_sector_ct;
      if (r != null && String(r).toLowerCase() !== "unknown") {
        var n = parseFloat(r);
        if (isFinite(n) && n > 0) smartBad = true;
      }
    });
    var offline = a == null && b == null && disksOk === 0;
    var smTxt = offline ? "OMV: offline" : (smartBad ? "SMART: Check" : "SMART: OK");
    var smCol = offline || smartBad ? "#e57373" : "#81c784";
    var pills = (services || []).map(function (svc) {
      var on = st(svc.id) && st(svc.id).state === "on";
      return '<span class="svc ' + (on ? "svc-on" : "svc-off") + '">' + svc.label + "</span>";
    }).join("");
    var bars = (a != null || b != null)
      ? '<div class="seg-bar"><div class="seg-a" style="width:' + clampPct(a) + '%"></div><div class="seg-b" style="width:' + clampPct(b) + '%"></div></div>'
      : '<div class="card-sub">Filesystem: —</div>';
    return (
      '<div class="card">' +
        '<div class="card-title">' + title + "</div>" +
        '<div class="card-sub">' + sub + "</div>" +
        bars +
        '<div class="host-net-row" style="font-size:0.72rem;margin-bottom:8px"><span style="color:' + smCol + ';font-weight:600">' + smTxt +
          "</span><span>Temp: " + (maxT != null ? maxT + "°" : "—") + "</span></div>" +
        ((!offline && (cpu != null || mem != null))
          ? '<div class="host-net-row" style="font-size:0.72rem;margin-bottom:8px;opacity:0.8"><span>CPU ' +
            (cpu == null ? "—" : Math.round(cpu) + "%") + "</span><span>RAM " +
            (mem == null ? "—" : Math.round(mem) + "%") + "</span></div>"
          : "") +
        (pills ? '<div class="svc-pills">' + pills + "</div>" : "") +
      "</div>"
    );
  }

  function renderStorage() {
    $("card-storage").innerHTML =
      nasCard(
        "NAS1 (OMV)",
        "md0 + eMMC · 10.0.10.3",
        "sensor.nas1_filesystem_md0",
        "sensor.nas1_filesystem_mmcblk0p8",
        "sensor.nas1_system_cpu_load",
        "sensor.nas1_system_memory",
        ["sensor.nas1_disk_nvme0n1", "sensor.nas1_disk_nvme1n1", "sensor.nas1_disk_nvme2n1", "sensor.nas1_disk_nvme3n1"],
        [
          { id: "binary_sensor.nas1_services_smb_cifs_service", label: "SMB" },
          { id: "binary_sensor.nas1_services_nfs_service", label: "NFS" },
          { id: "binary_sensor.nas1_services_ssh_service", label: "SSH" }
        ]
      ) +
      nasCard(
        "NAS2 (OMV)",
        "md0 + OS volume",
        "sensor.nas2_filesystem",
        "sensor.nas2_filesystem_2",
        null,
        null,
        ["sensor.nas2_disk", "sensor.nas2_disk_2", "sensor.nas2_disk_3", "sensor.nas2_disk_4", "sensor.nas2_disk_5"],
        []
      );
  }

  function paint() {
    renderGateway();
    renderNetworkDevices();
    renderGaugesAndTraffic();
    renderWatchdogs();
    renderServers();
    renderCameras();
    renderStorage();
  }

  function ingestStates(list) {
    if (!list) return;
    for (var i = 0; i < list.length; i++) {
      var e = list[i];
      if (e && e.entity_id) states[e.entity_id] = e;
    }
  }

  function send(obj) {
    if (!ws || ws.readyState !== 1) return;
    ws.send(JSON.stringify(obj));
  }

  function subscribe() {
    /* Only these entities — never full get_states (too heavy for Air 2). */
    send({
      id: msgId++,
      type: "subscribe_entities",
      entity_ids: ENTITIES
    });
  }

  function connect() {
    var token = getToken();
    if (!token) {
      $("auth-gate").classList.remove("hidden");
      setConn("conn-off", "Auth required");
      return;
    }
    $("auth-gate").classList.add("hidden");
    setConn("conn-off", "Connecting…");
    if (ws) {
      try { ws.close(); } catch (e) {}
      ws = null;
    }
    ws = new WebSocket(wsUrl());
    ws.onopen = function () {};
    ws.onclose = function () {
      setConn("conn-err", "Disconnected");
      clearTimeout(reconnectTimer);
      reconnectTimer = setTimeout(connect, 3000);
    };
    ws.onerror = function () {
      setConn("conn-err", "Socket error");
    };
    ws.onmessage = function (ev) {
      var msg;
      try { msg = JSON.parse(ev.data); } catch (e) { return; }
      if (msg.type === "auth_required") {
        send({ type: "auth", access_token: token });
        return;
      }
      if (msg.type === "auth_invalid") {
        setConn("conn-err", "Auth invalid");
        $("auth-gate").classList.remove("hidden");
        return;
      }
      if (msg.type === "auth_ok") {
        setConn("conn-on", "Live");
        subscribe();
        return;
      }
      if (msg.type === "event" && msg.event) {
        if (msg.event.a || msg.event.c || msg.event.r) {
          /* compressed entity updates from subscribe_entities */
          var a = msg.event.a || {};
          Object.keys(a).forEach(function (id) {
            var cur = states[id] || { entity_id: id, attributes: {} };
            var patch = a[id] || {};
            states[id] = {
              entity_id: id,
              state: patch.s != null ? patch.s : cur.state,
              attributes: Object.assign({}, cur.attributes || {}, patch.a || {})
            };
          });
          var c = msg.event.c || {};
          Object.keys(c).forEach(function (id) {
            var cur = states[id] || { entity_id: id, attributes: {} };
            var patch = (c[id] && c[id]["+"]) || c[id] || {};
            states[id] = {
              entity_id: id,
              state: patch.s != null ? patch.s : cur.state,
              attributes: Object.assign({}, cur.attributes || {}, patch.a || {})
            };
          });
          paint();
          return;
        }
        if (msg.event.data && msg.event.data.new_state) {
          var ns = msg.event.data.new_state;
          if (ns && ns.entity_id) {
            states[ns.entity_id] = ns;
            paint();
          }
        }
      }
    };
  }

  function initAuthUi() {
    $("token-save").onclick = function () {
      var t = ($("token-input").value || "").trim();
      if (!t) return;
      setToken(t);
      connect();
    };
  }

  function init() {
    initAuthUi();
    tickClock();
    setInterval(tickClock, 15000);
    paint();
    connect();
    var ms = cfg.paintIntervalMs || 2000;
    paintTimer = setInterval(function () {
      if (Object.keys(states).length) paint();
    }, ms);
  }

  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", init);
  else init();
})();
