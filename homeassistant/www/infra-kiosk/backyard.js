(function () {
  "use strict";
  var H = window.KioskHA;

  var CAMERAS = [
    { id: "camera.back_yard_2", name: "Back Yard", primary: true },
    { id: "camera.east_side", name: "East Side" },
    { id: "camera.west_side_2", name: "West Side" },
    { id: "camera.garden_south_2", name: "Garden South" },
    { id: "camera.garden_north_2", name: "Garden North" }
  ];

  var IRR_ZONES = [
    { id: "sensor.irrigation_7d_east_lawn", name: "East lawn", color: "#3498db" },
    { id: "sensor.irrigation_7d_east_flower_bed", name: "East flower bed", color: "#2980b9" },
    { id: "sensor.irrigation_7d_back_lawn", name: "Back lawn", color: "#1abc9c" },
    { id: "sensor.irrigation_7d_slope_kitchen_left", name: "Slope kitchen left", color: "#16a085" },
    { id: "sensor.irrigation_7d_front_yard", name: "Front yard", color: "#27ae60" },
    { id: "sensor.irrigation_7d_peppers_kale", name: "Peppers & kale", color: "#e67e22" },
    { id: "sensor.irrigation_7d_tomato", name: "Tomato", color: "#d35400" },
    { id: "sensor.irrigation_7d_zucchini_eggplant", name: "Zucchini & eggplant", color: "#f39c12" }
  ];

  var ENTITIES = [
    "sensor.back_yard_person_count",
    "sensor.back_yard_dog_count",
    "sensor.back_yard_last_recognized_face",
    "binary_sensor.east_side_door_door",
    "binary_sensor.west_side_gate_door",
    "binary_sensor.fence_gate_door",
    "sensor.garden_controller_indoor_temperature",
    "sensor.garden_controller_indoor_humidity",
    "sensor.garden_controller_indoor_dewpoint",
    "sensor.garden_controller_absolute_pressure",
    "sensor.garden_controller_soil_moisture_1",
    "sensor.garden_controller_soil_moisture_2",
    "sensor.garden_controller_soil_moisture_3",
    "sensor.garden_controller_soil_moisture_4",
    "sensor.garden_controller_soil_moisture_6",
    "light.garden_lights_light",
    "light.garden_lights_light_2",
    "light.smart_patio_plug_light",
    "light.smart_patio_plug_light_2",
    "switch.soffet_lights_socket_1",
    "switch.porch_light",
    "switch.flood_lights_2",
    "switch.light_switch_4",
    "valve.east_lawn_timer_east_lawn_zone_zone",
    "valve.east_lawn_timer_flower_bed_zone_zone",
    "valve.flower_garden_back_lawn_time_back_lawn_zone_zone",
    "valve.flower_garden_back_lawn_time_slope_kitchen_left_zone",
    "valve.front_yard_controller_front_yard_zone",
    "valve.vegitable_garden_timer_peppers_kale_zone_zone",
    "valve.vegitable_garden_timer_tomato_zone_zone",
    "valve.vegitable_garden_timer_zucchini_and_eggplant_zone_zone"
  ].concat(IRR_ZONES.map(function (z) { return z.id; }))
    .concat(CAMERAS.map(function (c) { return c.id; }));

  var liveEntity = null;
  var snapBust = 0;
  var lastStillKey = {};
  var chartBusy = false;
  var chartLastAt = 0;
  var chartSeries = null;

  function $(id) { return document.getElementById(id); }
  function st(id) { return H.st(id); }
  function num(id) { return H.num(id); }
  function bad(v) { return H.bad(v); }
  function fmt(n, d) { return H.fmt(n, d); }
  function clampPct(n) { return H.clampPct(n); }

  function stillKey(entityId) {
    return String(H.attr(entityId, "access_token") || H.attr(entityId, "entity_picture") || "") + "|" + snapBust;
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

  function countLabel(id, one, many) {
    var n = num(id);
    if (n == null) n = 0;
    n = Math.max(0, Math.round(n));
    return n === 1 ? "1 " + one : n + " " + many;
  }

  function faceLabel() {
    var s = st("sensor.back_yard_last_recognized_face");
    if (!s || bad(s.state)) return "Facial Match: Unknown";
    return "Facial Match: " + s.state;
  }

  function statTile(color, glyph, label) {
    return (
      '<div class="card stat-tile">' +
        '<div class="stat-icon" style="background:' + color + '">' +
          '<span>' + glyph + "</span>" +
        "</div>" +
        '<div class="stat-text">' + label + "</div>" +
      "</div>"
    );
  }

  function gateTile(title, entityId) {
    var s = st(entityId);
    var unknown = !s || bad(s.state);
    var closed = s && s.state === "off";
    var open = !unknown && !closed;
    var cls = unknown ? "gate-unk" : (open ? "gate-open" : "gate-closed");
    var txt = unknown ? "—" : (closed ? "Closed" : "Open");
    var warn = open ? '<span aria-hidden="true">⚠</span>' : "";
    return (
      '<div class="card gate-card">' +
        '<div class="card-title">' + title + "</div>" +
        '<div class="gate-status ' + cls + '">' + warn + "<span>" + txt + "</span></div>" +
      "</div>"
    );
  }

  function camStillHtml(cam, extraClass) {
    var url = H.cameraStillUrl(cam.id, !!snapBust);
    lastStillKey[cam.id] = stillKey(cam.id);
    return (
      '<div class="card cam-snap' + (extraClass ? " " + extraClass : "") +
        '" data-camera="' + cam.id + '" data-name="' + cam.name + '"' +
        (cam.primary ? ' id="cam-primary"' : "") + ">" +
        '<div class="cam-label">' + cam.name + "</div>" +
        '<div class="cam-frame">' +
          (url
            ? '<img src="' + url + '" alt="' + cam.name + '" loading="lazy" />'
            : '<span class="cam-placeholder">Waiting for camera…</span>') +
        "</div>" +
      "</div>"
    );
  }

  function updateCamImg(el, cam) {
    if (!el) return;
    var key = stillKey(cam.id);
    var url = H.cameraStillUrl(cam.id, !!snapBust);
    var img = el.querySelector("img");
    if (!url) {
      if (!el.querySelector(".cam-placeholder")) {
        var frame = el.querySelector(".cam-frame");
        if (frame) frame.innerHTML = '<span class="cam-placeholder">Waiting for camera…</span>';
      }
      lastStillKey[cam.id] = key;
      return;
    }
    if (lastStillKey[cam.id] === key && img) return;
    lastStillKey[cam.id] = key;
    var frameEl = el.querySelector(".cam-frame");
    if (img) img.src = url;
    else if (frameEl) frameEl.innerHTML = '<img src="' + url + '" alt="' + cam.name + '" />';
  }

  function paintCams(force) {
    var primary = CAMERAS[0];
    var primaryEl = $("cam-primary");
    if (primaryEl) {
      if (force || !primaryEl.querySelector("img")) {
        primaryEl.outerHTML = camStillHtml(primary, "by-primary");
      } else {
        updateCamImg($("cam-primary"), primary);
      }
    }
    var grid = $("card-by-cams");
    if (!grid) return;
    if (force || !grid.children.length) {
      grid.innerHTML = CAMERAS.slice(1).map(function (cam) {
        return camStillHtml(cam, "");
      }).join("");
      return;
    }
    CAMERAS.slice(1).forEach(function (cam) {
      updateCamImg(grid.querySelector('[data-camera="' + cam.id + '"]'), cam);
    });
  }

  function openLive(entityId, name) {
    var stream = H.cameraStreamUrl(entityId) || H.cameraStillUrl(entityId, true);
    if (!stream) return;
    liveEntity = entityId;
    var modal = $("cam-modal");
    var img = $("cam-modal-img");
    var title = $("cam-modal-title");
    if (title) title.textContent = name || entityId;
    if (img) {
      img.removeAttribute("src");
      img.src = stream;
    }
    if (modal) modal.classList.remove("hidden");
  }

  function closeLive() {
    liveEntity = null;
    var modal = $("cam-modal");
    var img = $("cam-modal-img");
    if (img) {
      img.removeAttribute("src");
      try { img.src = ""; } catch (e) {}
    }
    if (modal) modal.classList.add("hidden");
  }

  function toggleTile(entityId, title) {
    var s = st(entityId);
    var unknown = !s || bad(s.state);
    var on = s && (s.state === "on" || s.state === "open");
    var cls = unknown ? "toggle unk" : (on ? "toggle on" : "toggle off");
    var state = unknown ? "—" : (on ? "ON" : "OFF");
    if (entityId.indexOf("valve.") === 0) state = unknown ? "—" : (on ? "OPEN" : "CLOSED");
    return (
      '<button type="button" class="card ' + cls + '" data-toggle="' + entityId + '">' +
        '<div class="card-title">' + title + "</div>" +
        '<div class="toggle-state">' + state + "</div>" +
      "</button>"
    );
  }

  function dayKeys(days) {
    var out = [];
    var now = new Date();
    for (var i = days - 1; i >= 0; i--) {
      var d = new Date(now.getFullYear(), now.getMonth(), now.getDate() - i);
      var y = d.getFullYear();
      var m = String(d.getMonth() + 1);
      var day = String(d.getDate());
      if (m.length < 2) m = "0" + m;
      if (day.length < 2) day = "0" + day;
      out.push(y + "-" + m + "-" + day);
    }
    return out;
  }

  function aggregateHistory(raw, entityId, keys) {
    var byDay = {};
    keys.forEach(function (k) { byDay[k] = null; });
    var series = null;
    if (!raw || !raw.length) return keys.map(function () { return 0; });
    for (var i = 0; i < raw.length; i++) {
      if (raw[i] && raw[i].length && raw[i][0] && raw[i][0].entity_id === entityId) {
        series = raw[i];
        break;
      }
    }
    if (!series) return keys.map(function () { return 0; });
    series.forEach(function (pt) {
      if (!pt || pt.state == null) return;
      var n = parseFloat(pt.state);
      if (!isFinite(n)) return;
      var ts = pt.last_changed || pt.last_updated;
      if (!ts) return;
      var key = String(ts).slice(0, 10);
      if (!(key in byDay)) return;
      /* history_stats hours — take daily max, chart as minutes */
      var mins = n * 60;
      if (byDay[key] == null || mins > byDay[key]) byDay[key] = mins;
    });
    return keys.map(function (k) { return byDay[k] == null ? 0 : byDay[k]; });
  }

  function renderChart(seriesMap) {
    var wrap = $("irr-chart");
    var legend = $("irr-chart-legend");
    var status = $("irr-chart-status");
    if (!wrap) return;
    var keys = dayKeys(7);
    var W = 640;
    var H = 220;
    var padL = 36;
    var padR = 10;
    var padT = 12;
    var padB = 28;
    var plotW = W - padL - padR;
    var plotH = H - padT - padB;
    var maxY = 0;
    IRR_ZONES.forEach(function (z) {
      var vals = seriesMap[z.id] || [];
      vals.forEach(function (v) { if (v > maxY) maxY = v; });
    });
    if (maxY <= 0) maxY = 10;
    maxY = Math.ceil(maxY / 5) * 5;

    function xAt(i) {
      return padL + (keys.length <= 1 ? plotW / 2 : (i / (keys.length - 1)) * plotW);
    }
    function yAt(v) {
      return padT + plotH - (v / maxY) * plotH;
    }

    var grid = "";
    for (var g = 0; g <= 4; g++) {
      var gy = padT + (plotH * g) / 4;
      var gv = maxY - (maxY * g) / 4;
      grid +=
        '<line x1="' + padL + '" y1="' + gy + '" x2="' + (W - padR) + '" y2="' + gy +
        '" stroke="rgba(255,255,255,0.08)" stroke-width="1"/>' +
        '<text x="' + (padL - 6) + '" y="' + (gy + 3) +
        '" text-anchor="end" fill="rgba(255,255,255,0.45)" font-size="10">' +
        Math.round(gv) + "</text>";
    }
    var xLabels = "";
    keys.forEach(function (k, i) {
      var label = k.slice(5);
      xLabels +=
        '<text x="' + xAt(i) + '" y="' + (H - 8) +
        '" text-anchor="middle" fill="rgba(255,255,255,0.5)" font-size="10">' +
        label + "</text>";
    });

    var lines = "";
    IRR_ZONES.forEach(function (z) {
      var vals = seriesMap[z.id] || keys.map(function () { return 0; });
      var pts = vals.map(function (v, i) { return xAt(i) + "," + yAt(v); }).join(" ");
      lines +=
        '<polyline fill="none" stroke="' + z.color + '" stroke-width="2" points="' + pts + '"/>';
    });

    wrap.innerHTML =
      '<svg viewBox="0 0 ' + W + " " + H + '" preserveAspectRatio="none" aria-label="Irrigation chart">' +
        grid + lines + xLabels +
      "</svg>";

    if (legend) {
      legend.innerHTML = IRR_ZONES.map(function (z) {
        return (
          '<span><i class="chart-swatch" style="background:' + z.color + '"></i>' +
          z.name + "</span>"
        );
      }).join("");
    }
    if (status) status.textContent = "Updated";
  }

  function loadIrrChart(force) {
    var now = Date.now();
    if (chartBusy) return;
    if (!force && chartSeries && now - chartLastAt < 120000) {
      renderChart(chartSeries);
      return;
    }
    chartBusy = true;
    var status = $("irr-chart-status");
    if (status && !chartSeries) status.textContent = "Loading…";
    H.fetchHistory(IRR_ZONES.map(function (z) { return z.id; }), 168).then(function (raw) {
      var keys = dayKeys(7);
      var map = {};
      IRR_ZONES.forEach(function (z) {
        map[z.id] = aggregateHistory(raw, z.id, keys);
      });
      chartSeries = map;
      chartLastAt = Date.now();
      chartBusy = false;
      renderChart(map);
    }).catch(function () {
      chartBusy = false;
      if (status) status.textContent = "History unavailable";
      if (!chartSeries) {
        var keys = dayKeys(7);
        var fallback = {};
        IRR_ZONES.forEach(function (z) {
          var n = num(z.id);
          fallback[z.id] = keys.map(function (_, i) {
            return i === keys.length - 1 && n != null ? n * 60 : 0;
          });
        });
        renderChart(fallback);
      }
    });
  }

  function paint() {
    $("card-by-stats").innerHTML =
      statTile("#43a047", "P", countLabel("sensor.back_yard_person_count", "Person", "People")) +
      statTile("#fdd835", "D", countLabel("sensor.back_yard_dog_count", "Dog Detected", "Dogs Detected")) +
      statTile("#ff6e40", "F", faceLabel());

    paintCams(false);

    $("card-by-gates").innerHTML =
      gateTile("East Gate", "binary_sensor.east_side_door_door") +
      gateTile("West Gate", "binary_sensor.west_side_gate_door") +
      gateTile("Back Gate", "binary_sensor.fence_gate_door");

    var temp = num("sensor.garden_controller_indoor_temperature");
    var hum = num("sensor.garden_controller_indoor_humidity");
    var dew = num("sensor.garden_controller_indoor_dewpoint");
    var press = num("sensor.garden_controller_absolute_pressure");
    $("card-by-env").innerHTML =
      '<div class="card gauge-card">' +
        '<div class="ring" style="--pct:' + clampPct(((temp == null ? 0 : temp) + 10) / 1.2) + ';--ring:#fb8c00">' +
          '<div class="ring-val">' + (temp == null ? "—" : Math.round(temp) + "°") + "</div></div>" +
        '<div class="gauge-label">TEMP</div>' +
        '<div class="card-sub">Dewpoint ' + (dew == null ? "—" : fmt(dew, 1) + "°F") + "</div>" +
      "</div>" +
      '<div class="card gauge-card">' +
        '<div class="ring" style="--pct:' + clampPct(hum) + ';--ring:#42a5f5">' +
          '<div class="ring-val">' + (hum == null ? "—" : Math.round(hum) + "%") + "</div></div>" +
        '<div class="gauge-label">HUMIDITY</div>' +
        '<div class="card-sub">Abs pressure ' + (press == null ? "—" : fmt(press, 0) + " hPa") + "</div>" +
      "</div>";

    var soils = [
      ["Eggplant", "sensor.garden_controller_soil_moisture_1", "fill-cpu"],
      ["Peppers and Kale", "sensor.garden_controller_soil_moisture_3", "fill-rx"],
      ["Flower Bed", "sensor.garden_controller_soil_moisture_2", "fill-clients"],
      ["Zucchini", "sensor.garden_controller_soil_moisture_6", "fill-cpu"],
      ["Tomatoes", "sensor.garden_controller_soil_moisture_4", "fill-ha-cpu"]
    ];
    $("card-by-soil").innerHTML = soils.map(function (row) {
      var v = num(row[1]);
      return metric(row[0], v, row[2], v == null ? "—" : Math.round(v) + "%");
    }).join("");

    $("card-by-lights").innerHTML =
      toggleTile("light.garden_lights_light", "Garden lights 1") +
      toggleTile("light.garden_lights_light_2", "Garden lights 2") +
      toggleTile("light.smart_patio_plug_light", "Patio plug 1") +
      toggleTile("light.smart_patio_plug_light_2", "Patio plug 2") +
      toggleTile("switch.soffet_lights_socket_1", "Soffit lights") +
      toggleTile("switch.porch_light", "Porch light") +
      toggleTile("switch.flood_lights_2", "Flood lights") +
      toggleTile("switch.light_switch_4", "Light switch");

    $("card-by-valves-lawn").innerHTML =
      toggleTile("valve.east_lawn_timer_east_lawn_zone_zone", "East lawn") +
      toggleTile("valve.east_lawn_timer_flower_bed_zone_zone", "East flower bed") +
      toggleTile("valve.flower_garden_back_lawn_time_back_lawn_zone_zone", "Back lawn") +
      toggleTile("valve.flower_garden_back_lawn_time_slope_kitchen_left_zone", "Slope / kitchen") +
      toggleTile("valve.front_yard_controller_front_yard_zone", "Front yard");

    $("card-by-valves-veg").innerHTML =
      toggleTile("valve.vegitable_garden_timer_peppers_kale_zone_zone", "Peppers / kale") +
      toggleTile("valve.vegitable_garden_timer_tomato_zone_zone", "Tomato") +
      toggleTile("valve.vegitable_garden_timer_zucchini_and_eggplant_zone_zone", "Zucchini / eggplant");

    if (H.getToken()) loadIrrChart(false);
  }

  function onClick(ev) {
    var t = ev.target;
    while (t && t !== document.body) {
      if (t.id === "cam-modal-close" || t.id === "cam-modal") {
        closeLive();
        return;
      }
      if (t.classList && t.classList.contains("modal-panel")) return;
      if (t.getAttribute && t.getAttribute("data-toggle")) {
        H.toggleEntity(t.getAttribute("data-toggle")).catch(function () {});
        return;
      }
      if (t.classList && t.classList.contains("cam-snap")) {
        openLive(t.getAttribute("data-camera"), t.getAttribute("data-name"));
        return;
      }
      t = t.parentNode;
    }
  }

  document.addEventListener("click", onClick);
  document.addEventListener("keydown", function (ev) {
    if (ev.key === "Escape") closeLive();
  });

  setInterval(function () {
    if (liveEntity) return;
    snapBust = Date.now();
    paintCams(false);
  }, 20000);

  setInterval(function () {
    if (H.getToken()) loadIrrChart(true);
  }, 300000);

  H.start({
    page: "backyard",
    entities: ENTITIES,
    paint: paint
  });
})();
