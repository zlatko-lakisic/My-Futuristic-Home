(function () {
  "use strict";
  var H = window.KioskHA;

var ENTITIES = [
    "binary_sensor.mikrotik_home_ether1_connection",
    "update.mikrotik_home_hap_ac_routeros_update",
    "sensor.mikrotik_home_hap_ac_uptime",
    "sensor.mikrotik_home_hap_ac_cpu_load",
    "sensor.mikrotik_home_hap_ac_memory_usage",
    "sensor.mikrotik_home_ether1_rx",
    "sensor.mikrotik_home_ether1_tx",
    "sensor.ookla_speedtest_download",
    "sensor.ookla_speedtest_upload",
    "sensor.ookla_speedtest_ping",
    "sensor.ookla_speedtest_server",
    "sensor.ookla_speedtest_last_test",
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
    "sensor.mikrotik_mostar_environment_publicip",
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
    "sensor.qemu_nginx_prod_100_memory_used_percentage",
    "sensor.qemu_mariadb_101_cpu_used",
    "sensor.qemu_mariadb_101_memory_used_percentage",
    "sensor.qemu_gitlab2_102_cpu_used",
    "sensor.qemu_gitlab2_102_memory_used_percentage",
    "sensor.qemu_active_directory_104_cpu_used",
    "sensor.qemu_active_directory_104_memory_used_percentage",
    "sensor.infra_garden_speaker_cpu_usage",
    "sensor.infra_garden_speaker_memory_usage",
    "sensor.infra_garden_speaker_nic_rx",
    "sensor.infra_garden_speaker_nic_tx",
    "sensor.infra_glances_hosts",
    "sensor.infra_gateway_cpu_usage",
    "sensor.infra_gateway_memory_usage",
    "sensor.infra_gateway_disk_usage",
    "sensor.infra_gateway_nic_rx",
    "sensor.infra_gateway_nic_tx",
    "sensor.infra_gateway_uptime",
    "sensor.infra_jetson_cpu_usage",
    "sensor.infra_jetson_memory_usage",
    "sensor.infra_jetson_memory_use",
    "sensor.infra_jetson_disk_usage",
    "sensor.infra_jetson_gpu_usage",
    "sensor.infra_jetson_nic_rx",
    "sensor.infra_jetson_nic_tx",
    "sensor.infra_jetson_uptime",
    "sensor.nvr_mostardesigns_com_cpu_usage",
    "sensor.nvr_mostardesigns_com_memory_usage",
    "sensor.nvr_mostardesigns_com_etc_hostname_disk_usage",
    "sensor.nvr_glances_top_processes",
    "sensor.nvr_mostardesigns_com_nvidia_rtx_4000_sff_ada_generation_gpu_nvidia0_processor_usage",
    "sensor.nvr_mostardesigns_com_nvidia_rtx_4000_sff_ada_generation_gpu_nvidia0_memory_usage",
    "binary_sensor.codeproject_ai_server_status",
    "sensor.codeproject_ai_server_state",
    "sensor.frigate_deepstack_inference_speed",
    "sensor.nvr_mostardesigns_com_br_9229c4b7924f_rx",
    "sensor.nvr_mostardesigns_com_br_9229c4b7924f_tx",
    "sensor.nvr_mostardesigns_com_enp3s0_rx",
    "sensor.nvr_mostardesigns_com_enp3s0_tx",
    "sensor.nvr_mostardesigns_com_enp7s0_rx",
    "sensor.nvr_mostardesigns_com_enp7s0_tx",
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
    "sensor.nas2_system_cpu_load",
    "sensor.nas2_system_memory",
    "sensor.nas2_disk",
    "sensor.nas2_disk_2",
    "sensor.nas2_disk_3",
    "sensor.nas2_disk_4",
    "sensor.nas2_disk_5",
    "binary_sensor.nas2_services_smb_cifs_service",
    "binary_sensor.nas2_services_nfs_service",
    "binary_sensor.nas2_services_ssh_service"
  ];

  function $(id) { return document.getElementById(id); }
  function st(id) { return H.st(id); }
  function num(id) { return H.num(id); }
  function attr(id, key) { return H.attr(id, key); }
  function bad(v) { return H.bad(v); }
  function fmt(n, d) { return H.fmt(n, d); }
  function clampPct(n) { return H.clampPct(n); }

  function wanIp(id) {
    var raw = attr(id, "client_ip_address");
    if (bad(raw)) return "—";
    var s = String(raw);
    return s.indexOf("/") >= 0 ? s.split("/")[0] : s;
  }

  /* Mostar WAN: ether1 client_ip is often "unknown"; Environment PublicIP is authoritative. */
  function mostarWanIp() {
    var pub = st("sensor.mikrotik_mostar_environment_publicip");
    if (pub && !bad(pub.state)) return String(pub.state).trim();
    return wanIp("binary_sensor.mikrotik_mostar_ether1_connection");
  }

  function uptime(id) {
    var s = st(id);
    var iso = s && s.state;
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
    var ul = String(u).trim().toLowerCase();
    if (ul === "b/s" || ul === "bytes/s" || ul === "byte/s") {
      if (v > 9999) return fmt(v / 1000000, 2) + " MB/s";
      return fmt(v / 1000, 2) + " KB/s";
    }
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

function setHtml(id, html) {
    var el = $(id);
    if (!el) return;
    /* Skip no-op rewrites — full innerHTML thrash blinks on iPad Safari. */
    if (el.getAttribute("data-html") === html) return;
    el.setAttribute("data-html", html);
    el.innerHTML = html;
  }

  function renderGateway() {
    var onlineSt = st("binary_sensor.mikrotik_home_ether1_connection");
    var online = onlineSt && onlineSt.state === "on";
    var unknown = !onlineSt || bad(onlineSt.state);
    /* Hero markup (incl. router art) is static in index.html — only touch the WAN IP text. */
    var wanEl = $("gateway-wan-ip");
    if (wanEl) {
      wanEl.textContent = "WAN IP · " + wanIp("binary_sensor.mikrotik_home_ether1_connection");
    }

    var upd = st("update.mikrotik_home_hap_ac_routeros_update");
    var fw = (upd && (upd.attributes && upd.attributes.installed_version)) || (upd && upd.state) || "—";
    var pillClass = unknown ? "pill-muted" : (online ? "pill-ok" : "pill-bad");
    var pillText = unknown ? "Gateway —" : (online ? "Gateway Online" : "Gateway Offline");
    setHtml(
      "card-gateway-status",
      '<div class="pills">' +
        '<span class="pill ' + pillClass + '">' + pillText + "</span>" +
        '<span class="pill">F/W: ' + fw + "</span>" +
        '<span class="pill">Uptime: ' + uptime("sensor.mikrotik_home_hap_ac_uptime") + "</span>" +
      "</div>"
    );
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
        extra: '<div class="mono">WAN IP · ' + mostarWanIp() + "</div>",
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
    // Fanless CSS326 board temp (°F): ~131–176 normal, ~185+ concern. Scale 110→194°F to bar %.
    var swTempPct = swCpu == null ? 0 : ((swCpu - 110) / (194 - 110)) * 100;
    var swTempFill = swCpu == null ? "fill-cpu"
      : (swCpu >= 185 ? "fill-temp-hot" : (swCpu >= 176 ? "fill-temp-warm" : "fill-temp-ok"));
    var perimeter =
      deviceCard({
        title: "CSS326 · perimeter",
        sub: "SwitchOS · " + (swBad ? "—" : (linksOk ? (portsUp + "/" + portsTotal + " up") : "No links")),
        dot: swBad ? "dot-unk" : (linksOk ? "dot-ok" : "dot-bad"),
        body:
          metric("Temp", swTempPct, swTempFill, swCpu == null ? "—" : Math.round(swCpu) + "°") +
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

  function speedtestMeta() {
    var dl = st("sensor.ookla_speedtest_download");
    var ul = st("sensor.ookla_speedtest_upload");
    var ping = st("sensor.ookla_speedtest_ping");
    var last = st("sensor.ookla_speedtest_last_test");
    var srv = st("sensor.ookla_speedtest_server");
    if ((!dl || bad(dl.state)) && (!ul || bad(ul.state))) return "";
    var whenRaw = (last && !bad(last.state) ? last.state : null) ||
      (dl && dl.last_updated) || (ul && ul.last_updated);
    var when = "—";
    if (whenRaw) {
      var d = new Date(whenRaw);
      if (!isNaN(d.getTime())) {
        when = d.toLocaleString("en-US", { month: "short", day: "numeric", hour: "numeric", minute: "2-digit" });
      }
    }
    var dlN = num("sensor.ookla_speedtest_download");
    var ulN = num("sensor.ookla_speedtest_upload");
    var pingN = num("sensor.ookla_speedtest_ping");
    var dlU = (dl && dl.attributes && dl.attributes.unit_of_measurement) || "Mbit/s";
    var ulU = (ul && ul.attributes && ul.attributes.unit_of_measurement) || "Mbit/s";
    var pingU = (ping && ping.attributes && ping.attributes.unit_of_measurement) || "ms";
    var server = (srv && !bad(srv.state)) ? String(srv.state) : "";
    return (
      '<div class="speedtest-meta">' +
        '<div class="speedtest-head"><span>Speed test</span><span>' + escHtml(when) + "</span></div>" +
        '<div class="speedtest-row">' +
          '<span style="color:#4fc3f7">↓ ' + (dlN == null ? "—" : fmt(dlN, 1)) + " " + escHtml(dlU) + "</span>" +
          '<span style="color:#81c784">↑ ' + (ulN == null ? "—" : fmt(ulN, 1)) + " " + escHtml(ulU) + "</span>" +
          '<span style="color:#ffb74d">' + (pingN == null ? "—" : fmt(pingN, 0)) + " " + escHtml(pingU) + "</span>" +
        "</div>" +
        '<div class="traffic-meta">' + escHtml(server || "Ookla Speedtest") + "</div>" +
      "</div>"
    );
  }

  function trafficCard(title, rxId, txId, extraHtml) {
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
        (extraHtml || '<div class="traffic-meta">live · no sparkline</div>') +
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
      trafficCard("WAN (ISP)", "sensor.mikrotik_home_ether1_rx", "sensor.mikrotik_home_ether1_tx",
        speedtestMeta() + '<div class="traffic-meta">live throughput</div>') +
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

  function pctBar(label, pct, grad, thick) {
    var v = clampPct(pct);
    return (
      '<div class="bar-row' + (thick ? " thick" : "") + '">' +
        '<div class="bar-head"><span>' + label + "</span><span>" +
          (pct == null || !isFinite(pct) ? "—" : fmt(pct, 2) + "%") +
        "</span></div>" +
        '<div class="bar-track"><div class="bar-fill" style="width:' + v + "%;background:" + grad + '"></div></div>' +
      "</div>"
    );
  }

  function escHtml(s) {
    return String(s)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  function parseProcList() {
    var s = st("sensor.nvr_glances_top_processes");
    if (!s || bad(s.state)) return [];
    var raw = s.attributes && (s.attributes.processes != null ? s.attributes.processes : s.attributes.processes_json);
    if (typeof raw === "string") {
      try { raw = JSON.parse(raw); } catch (e) { return []; }
    }
    return Array.isArray(raw) ? raw : [];
  }

  var NIC_IFACES = [
    { name: "br-9229c4b7924f", rx: "sensor.nvr_mostardesigns_com_br_9229c4b7924f_rx", tx: "sensor.nvr_mostardesigns_com_br_9229c4b7924f_tx" },
    { name: "enp3s0", rx: "sensor.nvr_mostardesigns_com_enp3s0_rx", tx: "sensor.nvr_mostardesigns_com_enp3s0_tx" },
    { name: "enp7s0", rx: "sensor.nvr_mostardesigns_com_enp7s0_rx", tx: "sensor.nvr_mostardesigns_com_enp7s0_tx" }
  ];
  var nicHistory = {};
  var nicBusy = false;
  var nicLastAt = 0;

  function downsample(vals, n) {
    if (!vals || !vals.length) return [];
    if (vals.length <= n) return vals.slice();
    var out = [];
    for (var i = 0; i < n; i++) {
      var idx = Math.floor((i / (n - 1)) * (vals.length - 1));
      out.push(vals[idx]);
    }
    return out;
  }

  /* Keep peaks when compressing history (inference spikes). */
  function downsampleMax(vals, n) {
    if (!vals || !vals.length) return [];
    if (vals.length <= n) return vals.slice();
    var out = [];
    var bucket = vals.length / n;
    for (var i = 0; i < n; i++) {
      var start = Math.floor(i * bucket);
      var end = Math.floor((i + 1) * bucket);
      if (end <= start) end = start + 1;
      var m = 0;
      for (var j = start; j < end && j < vals.length; j++) {
        if (vals[j] > m) m = vals[j];
      }
      out.push(m);
    }
    return out;
  }

  function historySeries(raw, entityId, mode) {
    var series = null;
    if (!raw || !raw.length) return [];
    for (var i = 0; i < raw.length; i++) {
      if (raw[i] && raw[i].length && raw[i][0] && raw[i][0].entity_id === entityId) {
        series = raw[i];
        break;
      }
    }
    if (!series) return [];
    var pts = [];
    series.forEach(function (pt) {
      if (!pt || pt.state == null) return;
      var n = parseFloat(pt.state);
      if (!isFinite(n)) return;
      pts.push(Math.max(0, n));
    });
    return mode === "max" ? downsampleMax(pts, 96) : downsample(pts, 48);
  }

  function sparkSvg(rxVals, txVals) {
    var W = 280;
    var H = 56;
    var all = rxVals.concat(txVals);
    var maxY = 0;
    all.forEach(function (v) { if (v > maxY) maxY = v; });
    if (maxY <= 0) maxY = 1;
    function path(vals, fill) {
      if (!vals.length) return "";
      var n = vals.length;
      var d = "";
      vals.forEach(function (v, i) {
        var x = n <= 1 ? W / 2 : (i / (n - 1)) * W;
        var y = H - (v / maxY) * (H - 4) - 2;
        d += (i === 0 ? "M" : "L") + x.toFixed(1) + " " + y.toFixed(1) + " ";
      });
      if (fill) {
        d += "L" + W + " " + H + " L0 " + H + " Z";
        return '<path d="' + d + '" fill="' + fill + '" stroke="none"/>';
      }
      return '<path d="' + d + '" fill="none" stroke="#ab47bc" stroke-width="1.5"/>';
    }
    return (
      '<svg viewBox="0 0 ' + W + " " + H + '" preserveAspectRatio="none">' +
        path(rxVals, "rgba(255,167,38,0.28)") +
        path(txVals, null) +
      "</svg>"
    );
  }

  /* Single-series spark with fixed severity scale (ms):
     ≤50 ok, 50–65 warn, >65 critical. Plot clipped to 100; labels keep real values. */
  function fmtInferenceMs(v) {
    if (v == null || !isFinite(v)) return "—";
    if (Math.abs(v) > 999) {
      var k = v / 1000;
      var s = Number.isInteger(k) ? String(k) : k.toFixed(1).replace(/\.0$/, "");
      return s + "k ms";
    }
    return Math.round(v) + " ms";
  }

  function sparkSvgInference(vals) {
    var W = 280;
    var H = 72;
    var WARN = 50;
    var BAD = 65;
    var maxY = 100;
    function yAt(v) {
      return H - (Math.min(Math.max(v, 0), maxY) / maxY) * (H - 4) - 2;
    }
    var bands =
      '<rect x="0" y="' + yAt(WARN).toFixed(1) + '" width="' + W + '" height="' +
        (yAt(0) - yAt(WARN)).toFixed(1) + '" fill="rgba(129,199,132,0.22)"/>' +
      '<rect x="0" y="' + yAt(BAD).toFixed(1) + '" width="' + W + '" height="' +
        (yAt(WARN) - yAt(BAD)).toFixed(1) + '" fill="rgba(255,183,77,0.28)"/>' +
      '<rect x="0" y="0" width="' + W + '" height="' +
        yAt(BAD).toFixed(1) + '" fill="rgba(239,83,80,0.22)"/>' +
      '<line x1="0" y1="' + yAt(WARN).toFixed(1) + '" x2="' + W + '" y2="' + yAt(WARN).toFixed(1) +
        '" stroke="rgba(255,183,77,0.55)" stroke-width="1" stroke-dasharray="3 3"/>' +
      '<line x1="0" y1="' + yAt(BAD).toFixed(1) + '" x2="' + W + '" y2="' + yAt(BAD).toFixed(1) +
        '" stroke="rgba(239,83,80,0.65)" stroke-width="1" stroke-dasharray="3 3"/>';
    if (!vals || !vals.length) {
      return '<svg viewBox="0 0 ' + W + " " + H + '" preserveAspectRatio="none">' + bands + "</svg>";
    }
    var n = vals.length;
    var segments = "";
    for (var i = 1; i < n; i++) {
      var v0 = vals[i - 1];
      var v1 = vals[i];
      var x0 = ((i - 1) / (n - 1)) * W;
      var x1 = (i / (n - 1)) * W;
      var mid = Math.max(v0, v1);
      var stroke = mid >= BAD ? "#ef5350" : (mid >= WARN ? "#ffb74d" : "#81c784");
      segments +=
        '<line x1="' + x0.toFixed(1) + '" y1="' + yAt(v0).toFixed(1) +
        '" x2="' + x1.toFixed(1) + '" y2="' + yAt(v1).toFixed(1) +
        '" stroke="' + stroke + '" stroke-width="1.8" stroke-linecap="round"/>';
    }
    return (
      '<svg viewBox="0 0 ' + W + " " + H + '" preserveAspectRatio="none">' +
        bands + segments +
      "</svg>"
    );
  }

  function inferenceSeverity(ms) {
    if (ms == null || !isFinite(ms)) return { key: "unk", color: "#9e9e9e", label: "—" };
    if (ms >= 65) return { key: "bad", color: "#ef5350", label: "attention" };
    if (ms >= 50) return { key: "warn", color: "#ffb74d", label: "warning" };
    return { key: "ok", color: "#81c784", label: "ok" };
  }

  var inferenceHistory = [];
  var inferenceBusy = false;
  var inferenceLastAt = 0;
  var INFERENCE_ENTITY = "sensor.frigate_deepstack_inference_speed";

  function loadInferenceHistory(force) {
    var now = Date.now();
    if (inferenceBusy) return;
    if (!force && inferenceLastAt && now - inferenceLastAt < 120000) return;
    inferenceBusy = true;
    H.fetchHistory([INFERENCE_ENTITY], 24).then(function (raw) {
      // Keep real values for peak/labels; sparkline clips plot to 100.
      inferenceHistory = historySeries(raw, INFERENCE_ENTITY, "max");
      inferenceLastAt = Date.now();
      inferenceBusy = false;
      renderGpuAi();
    }).catch(function () {
      inferenceBusy = false;
    });
  }

  function loadNicHistory(force) {
    var now = Date.now();
    if (nicBusy) return;
    if (!force && nicLastAt && now - nicLastAt < 120000) return;
    nicBusy = true;
    var ids = [];
    NIC_IFACES.forEach(function (nic) {
      ids.push(nic.rx);
      ids.push(nic.tx);
    });
    H.fetchHistory(ids, 6).then(function (raw) {
      NIC_IFACES.forEach(function (nic) {
        nicHistory[nic.name] = {
          rx: historySeries(raw, nic.rx),
          tx: historySeries(raw, nic.tx)
        };
      });
      nicLastAt = Date.now();
      nicBusy = false;
      renderNvrNics();
    }).catch(function () {
      nicBusy = false;
    });
  }

  function renderNvrNics() {
    var el = $("card-nvr-nics");
    if (!el) return;
    el.innerHTML = NIC_IFACES.map(function (nic) {
      var hist = nicHistory[nic.name] || { rx: [], tx: [] };
      return (
        '<div class="card nic-card">' +
          '<div class="card-title">' + nic.name + "</div>" +
          '<div class="nic-rates">' +
            '<span class="rx">● Download ' + rateText(nic.rx) + "</span>" +
            '<span class="tx">● Upload ' + rateText(nic.tx) + "</span>" +
          "</div>" +
          '<div class="nic-spark">' + sparkSvg(hist.rx, hist.tx) + "</div>" +
        "</div>"
      );
    }).join("");
  }

  function renderServers() {
    var cpu = num("sensor.homeassistant_cpu_usage");
    var mem = num("sensor.homeassistant_memory_usage");
    var disk = num("sensor.homeassistant_data_disk_usage");
    var memMiB = num("sensor.homeassistant_memory_use");

    var vms = [
      ["nginx-prod (100)", "sensor.qemu_nginx_prod_100_cpu_used", "sensor.qemu_nginx_prod_100_memory_used_percentage",
        "linear-gradient(90deg,#66bb6a,#43a047)", "linear-gradient(90deg,#81c784,#2e7d32)"],
      ["mariadb (101)", "sensor.qemu_mariadb_101_cpu_used", "sensor.qemu_mariadb_101_memory_used_percentage",
        "linear-gradient(90deg,#ffa726,#fb8c00)", "linear-gradient(90deg,#ffcc80,#e65100)"],
      ["gitlab (102)", "sensor.qemu_gitlab2_102_cpu_used", "sensor.qemu_gitlab2_102_memory_used_percentage",
        "linear-gradient(90deg,#42a5f5,#1e88e5)", "linear-gradient(90deg,#90caf9,#0d47a1)"],
      ["kubernetes-test (104)", "sensor.qemu_active_directory_104_cpu_used", "sensor.qemu_active_directory_104_memory_used_percentage",
        "linear-gradient(90deg,#ab47bc,#8e24aa)", "linear-gradient(90deg,#ce93d8,#4a148c)"]
    ];
    var vmHtml = vms.map(function (row) {
      var c = num(row[1]);
      var m = num(row[2]);
      return (
        '<div class="vm-block">' +
          '<div class="vm-title">' + row[0] + "</div>" +
          pctBar("CPU", c, row[3], true) +
          pctBar("Mem", m, row[4], true) +
        "</div>"
      );
    }).join("");

    var gsCpu = num("sensor.infra_garden_speaker_cpu_usage");
    var gsMem = num("sensor.infra_garden_speaker_memory_usage");
    var gsBlob = attr("sensor.infra_glances_hosts", "garden_speaker") || {};
    var gsOnline = gsBlob.ok === true || gsCpu != null;
    var gsStatusTxt = gsOnline ? "online" : "offline";
    var gsStatusCol = gsOnline ? "#81c784" : "#ef5350";
    var gsUpTxt = gsBlob.uptime ? String(gsBlob.uptime) : "—";

    var gwCpu = num("sensor.infra_gateway_cpu_usage");
    var gwMem = num("sensor.infra_gateway_memory_usage");
    var gwDisk = num("sensor.infra_gateway_disk_usage");
    var gwBlob = attr("sensor.infra_glances_hosts", "gateway") || {};
    var gwOnline = gwBlob.ok === true || gwCpu != null;
    var gwStatusTxt = gwOnline ? "online" : "offline";
    var gwStatusCol = gwOnline ? "#81c784" : "#ef5350";
    var gwUp = st("sensor.infra_gateway_uptime");
    var gwUpTxt = "—";
    if (gwUp && !bad(gwUp.state)) {
      gwUpTxt = String(gwUp.state);
    } else if (gwBlob.uptime) {
      gwUpTxt = String(gwBlob.uptime);
    }

    var jCpu = num("sensor.infra_jetson_cpu_usage");
    var jMem = num("sensor.infra_jetson_memory_usage");
    var jDisk = num("sensor.infra_jetson_disk_usage");
    var jGpu = num("sensor.infra_jetson_gpu_usage");
    var jMemMiB = num("sensor.infra_jetson_memory_use");
    var jBlob = attr("sensor.infra_glances_hosts", "jetson") || {};
    var jOnline = jBlob.ok === true || jCpu != null;
    var jStatusTxt = jOnline ? "online" : "offline";
    var jStatusCol = jOnline ? "#81c784" : "#ef5350";
    var jUp = st("sensor.infra_jetson_uptime");
    var jUpTxt = "—";
    if (jUp && !bad(jUp.state)) {
      var uu = jUp.attributes && jUp.attributes.unit_of_measurement;
      jUpTxt = uu ? jUp.state + " " + uu : String(jUp.state);
    } else if (jBlob.uptime) {
      jUpTxt = String(jBlob.uptime);
    }

    $("card-servers").innerHTML =
      '<div class="card">' +
        '<div class="host-head">' +
          '<div class="host-badge">HA</div>' +
          '<div class="host-card-body">' +
            '<div class="card-title">Home Assistant host</div>' +
            '<div class="card-sub">Glances · homeassistant</div>' +
            pctBar("CPU", cpu, "linear-gradient(90deg,#42a5f5,#1e88e5)") +
            pctBar("Memory", mem, "linear-gradient(90deg,#26c6da,#00838f)") +
            (memMiB != null ? '<div class="host-extra">' + fmt(memMiB, 1) + " MiB in use</div>" : "") +
            pctBar("Disk (/data)", disk, "linear-gradient(90deg,#7e57c2,#5e35b1)") +
            '<div class="host-net"><div class="card-sub" style="margin-bottom:6px;font-weight:600;opacity:0.85">Network (enp1s0)</div>' +
            '<div class="host-net-row"><span style="color:#4fc3f7">Download</span><span>' + rateText("sensor.homeassistant_enp1s0_rx") + "</span></div>" +
            '<div class="host-net-row"><span style="color:#81c784">Upload</span><span>' + rateText("sensor.homeassistant_enp1s0_tx") + "</span></div></div>" +
          "</div>" +
        "</div>" +
      "</div>" +
      '<div class="card">' +
        '<div class="host-head">' +
          '<div class="host-badge" style="background:rgba(229,112,0,0.18);color:#E57000">PX</div>' +
          '<div class="host-card-body">' +
            '<div class="card-title">Proxmox QEMU (CPU &amp; memory)</div>' +
            vmHtml +
          "</div>" +
        "</div>" +
      "</div>" +
      '<div class="card">' +
        '<div class="host-head">' +
          '<div class="host-badge" style="background:rgba(102,187,106,0.18);color:#66bb6a">GS</div>' +
          '<div class="host-card-body">' +
            '<div class="card-title">Garden speaker</div>' +
            '<div class="card-sub">Glances · garden-speaker (host)</div>' +
            pctBar("CPU", gsCpu, "linear-gradient(90deg,#66bb6a,#43a047)") +
            pctBar("Memory", gsMem, "linear-gradient(90deg,#26a69a,#00695c)") +
            '<div class="host-net"><div class="card-sub" style="margin-bottom:6px;font-weight:600;opacity:0.85">Network</div>' +
            '<div class="host-net-row"><span style="color:#4fc3f7">Download</span><span>' + rateText("sensor.infra_garden_speaker_nic_rx") + "</span></div>" +
            '<div class="host-net-row"><span style="color:#81c784">Upload</span><span>' + rateText("sensor.infra_garden_speaker_nic_tx") + "</span></div>" +
            '<div class="host-net-row" style="margin-top:6px;padding-top:6px;border-top:1px solid rgba(255,255,255,0.06);font-size:0.72rem">' +
              '<span style="color:#b0bec5">Status</span><span style="color:' + gsStatusCol + ';font-weight:600">' +
              escHtml(gsStatusTxt) + "</span></div>" +
            '<div class="host-net-row" style="font-size:0.72rem">' +
              '<span style="color:#b0bec5">Uptime</span><span>' + escHtml(gsUpTxt) + "</span></div></div>" +
          "</div>" +
        "</div>" +
      "</div>" +
      '<div class="card">' +
        '<div class="host-head">' +
          '<div class="host-badge" style="background:rgba(41,182,246,0.18);color:#29b6f6">GW</div>' +
          '<div class="host-card-body">' +
            '<div class="card-title">Gateway</div>' +
            '<div class="card-sub">Glances · traefik (host)</div>' +
            pctBar("CPU", gwCpu, "linear-gradient(90deg,#29b6f6,#0277bd)") +
            pctBar("Memory", gwMem, "linear-gradient(90deg,#26c6da,#00838f)") +
            pctBar("Disk (/)", gwDisk, "linear-gradient(90deg,#7e57c2,#5e35b1)") +
            '<div class="host-net"><div class="card-sub" style="margin-bottom:6px;font-weight:600;opacity:0.85">Network</div>' +
            '<div class="host-net-row"><span style="color:#4fc3f7">Download</span><span>' + rateText("sensor.infra_gateway_nic_rx") + "</span></div>" +
            '<div class="host-net-row"><span style="color:#81c784">Upload</span><span>' + rateText("sensor.infra_gateway_nic_tx") + "</span></div>" +
            '<div class="host-net-row" style="margin-top:6px;padding-top:6px;border-top:1px solid rgba(255,255,255,0.06);font-size:0.72rem">' +
              '<span style="color:#b0bec5">Status</span><span style="color:' + gwStatusCol + ';font-weight:600">' +
              escHtml(gwStatusTxt) + "</span></div>" +
            '<div class="host-net-row" style="font-size:0.72rem">' +
              '<span style="color:#b0bec5">Uptime</span><span>' + escHtml(gwUpTxt) + "</span></div></div>" +
          "</div>" +
        "</div>" +
      "</div>" +
      '<div class="card">' +
        '<div class="host-head">' +
          '<div class="host-badge" style="background:rgba(118,185,0,0.18);color:#76B900">JO</div>' +
          '<div class="host-card-body">' +
            '<div class="card-title">Jetson Orin</div>' +
            '<div class="card-sub">Glances · omega-jetson-orin</div>' +
            pctBar("CPU", jCpu, "linear-gradient(90deg,#8bc34a,#558b2f)") +
            pctBar("Memory", jMem, "linear-gradient(90deg,#26c6da,#00838f)") +
            (jMemMiB != null ? '<div class="host-extra">' + fmt(jMemMiB, 1) + " MiB in use</div>" : "") +
            pctBar("Disk (/)", jDisk, "linear-gradient(90deg,#7e57c2,#5e35b1)") +
            pctBar("GPU (Orin)", jGpu, "linear-gradient(90deg,#aed581,#33691e)") +
            '<div class="host-net"><div class="card-sub" style="margin-bottom:6px;font-weight:600;opacity:0.85">Network</div>' +
            '<div class="host-net-row"><span style="color:#4fc3f7">Download</span><span>' + rateText("sensor.infra_jetson_nic_rx") + "</span></div>" +
            '<div class="host-net-row"><span style="color:#81c784">Upload</span><span>' + rateText("sensor.infra_jetson_nic_tx") + "</span></div>" +
            '<div class="host-net-row" style="margin-top:6px;padding-top:6px;border-top:1px solid rgba(255,255,255,0.06);font-size:0.72rem">' +
              '<span style="color:#b0bec5">Status</span><span style="color:' + jStatusCol + ';font-weight:600">' +
              escHtml(jStatusTxt) + "</span></div>" +
            '<div class="host-net-row" style="font-size:0.72rem">' +
              '<span style="color:#b0bec5">Uptime</span><span>' + escHtml(jUpTxt) + "</span></div></div>" +
          "</div>" +
        "</div>" +
      "</div>";

    var nvrCpu = num("sensor.nvr_mostardesigns_com_cpu_usage");
    var nvrMem = num("sensor.nvr_mostardesigns_com_memory_usage");
    var nvrDisk = num("sensor.nvr_mostardesigns_com_etc_hostname_disk_usage");
    var procs = parseProcList();
    var procHtml = "";
    if (procs.length) {
      procHtml =
        '<div class="proc-head"><span>Process</span><span>CPU</span><span>Mem</span></div>' +
        procs.map(function (p) {
          var pc = Math.min(100, Math.max(0, Number(p.cpu_percent != null ? p.cpu_percent : p.cpu) || 0));
          var pm = Math.min(100, Math.max(0, Number(p.memory_percent != null ? p.memory_percent : p.memory) || 0));
          var nm = escHtml(String(p.name || "?").slice(0, 36));
          return (
            '<div class="proc-row">' +
              '<span class="proc-name">' + nm + "</span>" +
              '<span class="proc-cpu">' + fmt(pc, 2) + "%</span>" +
              '<span class="proc-mem">' + fmt(pm, 2) + "%</span>" +
            "</div>"
          );
        }).join("");
    } else {
      procHtml = '<div class="card-sub" style="margin-top:10px;padding-top:8px;border-top:1px solid rgba(255,255,255,0.08)">No process rows</div>';
    }

    $("card-nvr").innerHTML =
      '<div class="card">' +
        pctBar("NVR CPU", nvrCpu, "linear-gradient(90deg,#ff8a80,#ff4757)") +
        pctBar("NVR RAM", nvrMem, "linear-gradient(90deg,#64b5f6,#378ADD)") +
        pctBar("Host disk (/)", nvrDisk, "linear-gradient(90deg,#aed581,#7cb342)") +
        procHtml +
      "</div>";

    renderNvrNics();
    if (H.getToken()) loadNicHistory(false);
    renderGpuAi();
    if (H.getToken()) loadInferenceHistory(false);
  }

  function renderGpuAi() {
    var gpu = num("sensor.nvr_mostardesigns_com_nvidia_rtx_4000_sff_ada_generation_gpu_nvidia0_processor_usage");
    var vram = num("sensor.nvr_mostardesigns_com_nvidia_rtx_4000_sff_ada_generation_gpu_nvidia0_memory_usage");
    var aiBin = st("binary_sensor.codeproject_ai_server_status");
    var aiRun = st("sensor.codeproject_ai_server_state");
    var aiActive = (aiBin && aiBin.state === "on") || (aiRun && aiRun.state === "running");
    var aiOffline = !aiActive;
    var inf = num(INFERENCE_ENTITY);
    var sev = inferenceSeverity(inf);
    var infTxt = fmtInferenceMs(inf);
    var histMax = 0;
    inferenceHistory.forEach(function (v) { if (v > histMax) histMax = v; });
    var peakSev = inferenceSeverity(histMax > 0 ? histMax : null);
    var histMaxTxt = histMax > 0 ? fmtInferenceMs(histMax) + " peak" : "24h";

    $("card-gpu").innerHTML =
      '<div class="gpu-gauges">' +
        ring(gpu, "Compute", ringColor(clampPct(gpu))) +
        '<div class="card gauge-card"><div class="ring" style="--pct:' + clampPct(vram) + ";--ring:" +
          (clampPct(vram) >= 67 ? "#ff9800" : (clampPct(vram) >= 34 ? "#e65100" : "#bf360c")) +
          '"><div class="ring-val">' + (vram == null ? "—" : fmt(vram, 1) + "%") +
          '</div></div><div class="gauge-label">Memory</div></div>' +
      "</div>" +
      '<div class="card ai-pill ' + (aiOffline ? "off" : "on") + '">' +
        '<span class="ai-dot"></span>' +
        (aiOffline ? "AI Server Offline" : "AI Server Active") +
      "</div>" +
      '<div class="card nic-card ai-inference-card">' +
        '<div class="card-title">Deepstack inference</div>' +
        '<div class="nic-rates">' +
          '<span style="color:' + sev.color + '">● Now ' + infTxt +
            (sev.key !== "unk" ? " · " + sev.label : "") + "</span>" +
          '<span style="color:' + peakSev.color + '">● ' + histMaxTxt + "</span>" +
        "</div>" +
        '<div class="ai-inf-legend">' +
          '<span class="ok">≤50 ok</span>' +
          '<span class="warn">50–65 warn</span>' +
          '<span class="bad">&gt;65 attention</span>' +
        "</div>" +
        '<div class="nic-spark nic-spark-tall">' + sparkSvgInference(inferenceHistory) + "</div>" +
      "</div>";
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
        "sensor.nas2_system_cpu_load",
        "sensor.nas2_system_memory",
        ["sensor.nas2_disk", "sensor.nas2_disk_2", "sensor.nas2_disk_3", "sensor.nas2_disk_4", "sensor.nas2_disk_5"],
        [
          { id: "binary_sensor.nas2_services_smb_cifs_service", label: "SMB" },
          { id: "binary_sensor.nas2_services_nfs_service", label: "NFS" },
          { id: "binary_sensor.nas2_services_ssh_service", label: "SSH" }
        ]
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

  setInterval(function () {
    if (H.getToken()) {
      loadNicHistory(true);
      loadInferenceHistory(true);
    }
  }, 180000);

  H.start({
    page: "infrastructure",
    entities: ENTITIES,
    paint: paint
  });
})();
