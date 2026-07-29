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
    "valve.vegitable_garden_timer_zucchini_and_eggplant_zone_zone",
    "sensor.irrigation_7d_east_lawn",
    "sensor.irrigation_7d_east_flower_bed",
    "sensor.irrigation_7d_back_lawn",
    "sensor.irrigation_7d_slope_kitchen_left",
    "sensor.irrigation_7d_front_yard",
    "sensor.irrigation_7d_peppers_kale",
    "sensor.irrigation_7d_tomato",
    "sensor.irrigation_7d_zucchini_eggplant"
  ].concat(CAMERAS.map(function (c) { return c.id; }));

  var snapCache = {};
  var snapBusy = {};

  function $(id) { return document.getElementById(id); }
  function st(id) { return H.st(id); }
  function num(id) { return H.num(id); }
  function bad(v) { return H.bad(v); }
  function fmt(n, d) { return H.fmt(n, d); }
  function clampPct(n) { return H.clampPct(n); }

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

  function statTile(iconColor, label) {
    return (
      '<div class="card stat-tile">' +
        '<div class="stat-dot" style="background:' + iconColor + '"></div>' +
        '<div class="stat-text">' + label + "</div>" +
      "</div>"
    );
  }

  function gateTile(title, entityId) {
    var s = st(entityId);
    var unknown = !s || bad(s.state);
    var open = s && (s.state === "on" || s.state === "open");
    var cls = unknown ? "pill-muted" : (open ? "pill-bad" : "pill-ok");
    var txt = unknown ? "—" : (open ? "Open" : "Closed");
    return (
      '<div class="card">' +
        '<div class="card-title">' + title + "</div>" +
        '<div class="pills" style="min-height:auto;margin-top:10px">' +
          '<span class="pill ' + cls + '">' + txt + "</span>" +
        "</div>" +
      "</div>"
    );
  }

  function camCard(cam) {
    var url = snapCache[cam.id];
    return (
      '<div class="card cam-snap" data-camera="' + cam.id + '">' +
        '<div class="cam-label">' + cam.name + "</div>" +
        '<div class="cam-frame">' +
          (url
            ? '<img src="' + url + '" alt="' + cam.name + '" />'
            : '<span class="cam-placeholder">Tap to load snapshot</span>') +
        "</div>" +
      "</div>"
    );
  }

  function loadSnap(entityId, el) {
    if (snapBusy[entityId]) return;
    snapBusy[entityId] = true;
    var frame = el.querySelector(".cam-frame");
    if (frame) frame.innerHTML = '<span class="cam-placeholder">Loading…</span>';
    H.fetchCameraBlob(entityId).then(function (url) {
      if (snapCache[entityId]) {
        try { URL.revokeObjectURL(snapCache[entityId]); } catch (e) {}
      }
      snapCache[entityId] = url;
      snapBusy[entityId] = false;
      paintCams();
    }).catch(function () {
      snapBusy[entityId] = false;
      if (frame) frame.innerHTML = '<span class="cam-placeholder">Snapshot failed · tap retry</span>';
    });
  }

  function paintCams() {
    var primary = CAMERAS[0];
    var primaryEl = $("cam-back_yard_2");
    if (primaryEl) {
      var url = snapCache[primary.id];
      primaryEl.setAttribute("data-camera", primary.id);
      primaryEl.innerHTML =
        '<div class="cam-label">' + primary.name + "</div>" +
        '<div class="cam-frame">' +
          (url ? '<img src="' + url + '" alt="' + primary.name + '" />' : '<span class="cam-placeholder">Tap to load snapshot</span>') +
        "</div>";
    }
    $("card-by-cams").innerHTML = CAMERAS.slice(1).map(camCard).join("");
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

  function hoursTile(title, entityId) {
    var n = num(entityId);
    return (
      '<div class="card">' +
        '<div class="card-title">' + title + "</div>" +
        '<div class="big">' + (n == null ? "—" : fmt(n, 2)) + ' <span class="unit">h</span></div>' +
      "</div>"
    );
  }

  function paint() {
    $("card-by-stats").innerHTML =
      statTile("#43a047", countLabel("sensor.back_yard_person_count", "Person", "People")) +
      statTile("#fdd835", countLabel("sensor.back_yard_dog_count", "Dog Detected", "Dogs Detected")) +
      statTile("#ff6e40", faceLabel());

    paintCams();

    $("card-by-gates").innerHTML =
      gateTile("East Side Door", "binary_sensor.east_side_door_door") +
      gateTile("West Side Gate", "binary_sensor.west_side_gate_door") +
      gateTile("Fence Gate", "binary_sensor.fence_gate_door");

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

    $("card-by-irr-7d").innerHTML =
      hoursTile("East lawn", "sensor.irrigation_7d_east_lawn") +
      hoursTile("East flower bed", "sensor.irrigation_7d_east_flower_bed") +
      hoursTile("Back lawn", "sensor.irrigation_7d_back_lawn") +
      hoursTile("Slope / kitchen", "sensor.irrigation_7d_slope_kitchen_left") +
      hoursTile("Front yard", "sensor.irrigation_7d_front_yard") +
      hoursTile("Peppers / kale", "sensor.irrigation_7d_peppers_kale") +
      hoursTile("Tomato", "sensor.irrigation_7d_tomato") +
      hoursTile("Zucchini / eggplant", "sensor.irrigation_7d_zucchini_eggplant");
  }

  function onClick(ev) {
    var t = ev.target;
    while (t && t !== document.body) {
      if (t.getAttribute && t.getAttribute("data-toggle")) {
        var id = t.getAttribute("data-toggle");
        H.toggleEntity(id).catch(function () {});
        return;
      }
      if (t.classList && t.classList.contains("cam-snap")) {
        var cam = t.getAttribute("data-camera");
        if (cam) loadSnap(cam, t);
        return;
      }
      t = t.parentNode;
    }
  }

  document.addEventListener("click", onClick);

  /* Auto-refresh primary snapshot slowly once loaded. */
  setInterval(function () {
    var primary = CAMERAS[0].id;
    if (snapCache[primary]) {
      var el = document.querySelector('[data-camera="' + primary + '"]');
      if (el) loadSnap(primary, el);
    }
  }, 30000);

  H.start({
    page: "backyard",
    entities: ENTITIES,
    paint: paint
  });
})();
