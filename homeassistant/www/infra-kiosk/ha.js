(function (global) {
  "use strict";

  var cfg = global.INFRA_KIOSK || {};
  var STORAGE_KEY = "infra_kiosk_token";
  var states = {};
  var ws = null;
  var msgId = 1;
  var reconnectTimer = null;
  var paintTimer = null;
  var onPaint = null;
  var entityIds = [];
  var pending = {};

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
    if (d == null) d = 1;
    return String(parseFloat(Number(n).toFixed(d)));
  }

  function clampPct(n) {
    if (n == null || !isFinite(n)) return 0;
    return Math.min(100, Math.max(0, n));
  }

  function setConn(mode, text) {
    var el = $("conn");
    if (!el) return;
    el.className = "conn " + mode;
    el.textContent = text;
  }

  function tickClock() {
    var el = $("clock");
    if (!el) return;
    var d = new Date();
    var hh = String(d.getHours());
    var mm = String(d.getMinutes());
    if (hh.length < 2) hh = "0" + hh;
    if (mm.length < 2) mm = "0" + mm;
    el.textContent = hh + ":" + mm;
  }

  function send(obj) {
    if (!ws || ws.readyState !== 1) return;
    ws.send(JSON.stringify(obj));
  }

  function callService(domain, service, data) {
    return new Promise(function (resolve, reject) {
      var id = msgId++;
      pending[id] = { resolve: resolve, reject: reject };
      send({
        id: id,
        type: "call_service",
        domain: domain,
        service: service,
        service_data: data || {},
        return_response: false
      });
      setTimeout(function () {
        if (pending[id]) {
          delete pending[id];
          reject(new Error("service timeout"));
        }
      }, 10000);
    });
  }

  function toggleEntity(entityId) {
    var s = st(entityId);
    if (!s) return Promise.reject(new Error("missing entity"));
    var domain = entityId.split(".")[0];
    var service = (s.state === "on" || s.state === "open") ? "turn_off" : "turn_on";
    if (domain === "valve") {
      service = (s.state === "open") ? "close_valve" : "open_valve";
    }
    if (domain === "cover") {
      service = (s.state === "open") ? "close_cover" : "open_cover";
    }
    var data = { entity_id: entityId };
    return callService(domain, service, data);
  }

  function cameraUrl(entityId) {
    return haBase() + "/api/camera_proxy/" + encodeURIComponent(entityId) + "?_=" + Date.now();
  }

  /* Still uses entity access_token so <img> works without Auth headers. */
  function cameraStillUrl(entityId, bust) {
    var pic = attr(entityId, "entity_picture");
    if (pic) {
      var url = pic.indexOf("http") === 0 ? pic : (haBase() + pic);
      if (bust) url += (url.indexOf("?") >= 0 ? "&" : "?") + "_=" + Date.now();
      return url;
    }
    var camTok = attr(entityId, "access_token");
    if (camTok) {
      return haBase() + "/api/camera_proxy/" + encodeURIComponent(entityId) +
        "?token=" + encodeURIComponent(camTok) + (bust ? "&_=" + Date.now() : "");
    }
    return null;
  }

  function cameraStreamUrl(entityId) {
    var camTok = attr(entityId, "access_token");
    if (!camTok) return null;
    return haBase() + "/api/camera_proxy_stream/" + encodeURIComponent(entityId) +
      "?token=" + encodeURIComponent(camTok);
  }

  function fetchCameraBlob(entityId) {
    var token = getToken();
    return fetch(cameraUrl(entityId), {
      headers: { Authorization: "Bearer " + token },
      cache: "no-store"
    }).then(function (r) {
      if (!r.ok) throw new Error("camera " + r.status);
      return r.blob();
    }).then(function (blob) {
      return URL.createObjectURL(blob);
    });
  }

  /* History for charts — REST keeps WS free of bulky payloads. */
  function fetchHistory(entityIds, hours) {
    var token = getToken();
    if (!token || !entityIds || !entityIds.length) {
      return Promise.resolve([]);
    }
    var end = new Date();
    var start = new Date(end.getTime() - (hours || 168) * 3600 * 1000);
    var url = haBase() + "/api/history/period/" + encodeURIComponent(start.toISOString()) +
      "?filter_entity_id=" + encodeURIComponent(entityIds.join(",")) +
      "&end_time=" + encodeURIComponent(end.toISOString()) +
      "&significant_changes_only=0";
    return fetch(url, {
      headers: { Authorization: "Bearer " + token },
      cache: "no-store"
    }).then(function (r) {
      if (!r.ok) throw new Error("history " + r.status);
      return r.json();
    });
  }

  function subscribe() {
    send({
      id: msgId++,
      type: "subscribe_entities",
      entity_ids: entityIds
    });
  }

  function paint() {
    if (typeof onPaint === "function") onPaint();
  }

  function connect() {
    var token = getToken();
    if (!token) {
      var gate = $("auth-gate");
      if (gate) gate.classList.remove("hidden");
      setConn("conn-off", "Auth required");
      return;
    }
    var gate2 = $("auth-gate");
    if (gate2) gate2.classList.add("hidden");
    setConn("conn-off", "Connecting…");
    if (ws) {
      try { ws.close(); } catch (e) {}
      ws = null;
    }
    ws = new WebSocket(wsUrl());
    ws.onclose = function () {
      setConn("conn-err", "Disconnected");
      clearTimeout(reconnectTimer);
      reconnectTimer = setTimeout(connect, 3000);
    };
    ws.onerror = function () { setConn("conn-err", "Socket error"); };
    ws.onmessage = function (ev) {
      var msg;
      try { msg = JSON.parse(ev.data); } catch (e) { return; }
      if (msg.type === "auth_required") {
        send({ type: "auth", access_token: token });
        return;
      }
      if (msg.type === "auth_invalid") {
        setConn("conn-err", "Auth invalid");
        var g = $("auth-gate");
        if (g) g.classList.remove("hidden");
        return;
      }
      if (msg.type === "auth_ok") {
        setConn("conn-on", "Live");
        subscribe();
        return;
      }
      if (msg.type === "result") {
        var p = pending[msg.id];
        if (p) {
          delete pending[msg.id];
          if (msg.success) p.resolve(msg.result);
          else p.reject(new Error((msg.error && msg.error.message) || "failed"));
        }
        return;
      }
      if (msg.type === "event" && msg.event) {
        if (msg.event.a || msg.event.c || msg.event.r) {
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
    var btn = $("token-save");
    if (!btn) return;
    btn.onclick = function () {
      var t = (($("token-input") && $("token-input").value) || "").trim();
      if (!t) return;
      setToken(t);
      connect();
    };
  }

  function markNav(active) {
    var links = document.querySelectorAll(".nav-link");
    for (var i = 0; i < links.length; i++) {
      var a = links[i];
      if (a.getAttribute("data-page") === active) a.classList.add("active");
      else a.classList.remove("active");
    }
  }

  function start(opts) {
    opts = opts || {};
    entityIds = opts.entities || [];
    onPaint = opts.paint || null;
    markNav(opts.page || "");
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

  global.KioskHA = {
    start: start,
    st: st,
    num: num,
    attr: attr,
    bad: bad,
    fmt: fmt,
    clampPct: clampPct,
    toggleEntity: toggleEntity,
    callService: callService,
    cameraStillUrl: cameraStillUrl,
    cameraStreamUrl: cameraStreamUrl,
    fetchCameraBlob: fetchCameraBlob,
    fetchHistory: fetchHistory,
    getToken: getToken,
    haBase: haBase,
    states: function () { return states; }
  };
})(window);
