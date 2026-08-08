/**
 * Deepstack inference chart — fixed 0–100 ms severity scale, real hover values.
 * Values > 999 ms show as Nk (thousands) in the tooltip.
 */
class DeepstackInferenceChart extends HTMLElement {
  static getStubConfig() {
    return {
      entity: "sensor.frigate_deepstack_inference_speed",
      hours_to_show: 24,
      max_scale: 100,
      height: 128,
    };
  }

  setConfig(config) {
    if (!config || !config.entity) {
      throw new Error("entity is required");
    }
    this._config = {
      hours_to_show: 24,
      max_scale: 100,
      height: 128,
      warn: 50,
      bad: 65,
      title: "Deepstack inference (ms)",
      ...config,
    };
    this._points = [];
    this._busy = false;
    this._lastFetch = 0;
    if (!this._root) this._build();
  }

  _build() {
    this._root = this.attachShadow({ mode: "open" });
    this._root.innerHTML = `
      <style>
        :host { display: block; }
        .card {
          background: var(--ha-card-background, var(--card-background-color, #1c1c1c));
          border-radius: var(--ha-card-border-radius, 14px);
          border: 1px solid rgba(255,255,255,0.1);
          padding: 10px 12px 8px;
          box-sizing: border-box;
          color: var(--primary-text-color, #fff);
          font-family: var(--ha-font-family, sans-serif);
          position: relative;
          overflow: hidden;
        }
        .head {
          display: flex;
          justify-content: space-between;
          align-items: baseline;
          gap: 8px;
          margin-bottom: 6px;
        }
        .title { font-size: 0.88rem; font-weight: 600; opacity: 0.92; }
        .now {
          font-size: 0.72rem;
          font-weight: 700;
          font-variant-numeric: tabular-nums;
          opacity: 0.9;
        }
        .legend {
          display: flex;
          gap: 10px;
          flex-wrap: wrap;
          font-size: 0.62rem;
          opacity: 0.85;
          margin-bottom: 4px;
        }
        .legend .ok { color: #81c784; }
        .legend .warn { color: #ffb74d; }
        .legend .bad { color: #ef5350; }
        .chart-wrap {
          position: relative;
          width: 100%;
          height: var(--chart-h, 128px);
          cursor: crosshair;
        }
        svg { width: 100%; height: 100%; display: block; }
        .yaxis {
          position: absolute;
          left: 0; top: 0; bottom: 0;
          width: 28px;
          pointer-events: none;
          font-size: 0.55rem;
          opacity: 0.55;
          display: flex;
          flex-direction: column;
          justify-content: space-between;
          padding: 2px 0;
          box-sizing: border-box;
        }
        .tooltip {
          position: absolute;
          pointer-events: none;
          background: rgba(20,20,20,0.92);
          border: 1px solid rgba(255,255,255,0.18);
          border-radius: 8px;
          padding: 6px 8px;
          font-size: 0.7rem;
          line-height: 1.25;
          white-space: nowrap;
          z-index: 2;
          display: none;
          box-shadow: 0 4px 14px rgba(0,0,0,0.35);
        }
        .tooltip .t { opacity: 0.65; font-size: 0.62rem; margin-bottom: 2px; }
        .tooltip .v { font-weight: 700; font-variant-numeric: tabular-nums; }
        .empty { font-size: 0.7rem; opacity: 0.5; padding: 18px 0; text-align: center; }
      </style>
      <div class="card">
        <div class="head">
          <div class="title"></div>
          <div class="now"></div>
        </div>
        <div class="legend">
          <span class="ok">≤50 ok</span>
          <span class="warn">50–65 warn</span>
          <span class="bad">&gt;65 attention</span>
        </div>
        <div class="chart-wrap">
          <div class="yaxis"><span>100</span><span>65</span><span>50</span><span>0</span></div>
          <svg viewBox="0 0 320 128" preserveAspectRatio="none"></svg>
          <div class="tooltip"></div>
        </div>
      </div>
    `;
    this._titleEl = this._root.querySelector(".title");
    this._nowEl = this._root.querySelector(".now");
    this._svg = this._root.querySelector("svg");
    this._wrap = this._root.querySelector(".chart-wrap");
    this._tip = this._root.querySelector(".tooltip");
    this._wrap.addEventListener("pointermove", (e) => this._onMove(e));
    this._wrap.addEventListener("pointerleave", () => {
      this._tip.style.display = "none";
    });
  }

  getCardSize() {
    return 3;
  }

  set hass(hass) {
    this._hass = hass;
    if (!this._config) return;
    const st = hass.states[this._config.entity];
    const raw = st ? parseFloat(st.state) : NaN;
    const nowVal = Number.isFinite(raw) ? raw : null;
    this._titleEl.textContent = this._config.title;
    this._nowEl.textContent = nowVal == null ? "—" : this._fmt(nowVal);
    this._nowEl.style.color = this._sevColor(nowVal);
    this._wrap.style.setProperty("--chart-h", `${this._config.height}px`);
    this._maybeFetch();
  }

  _fmt(v) {
    if (v == null || !Number.isFinite(v)) return "—";
    if (Math.abs(v) > 999) {
      const k = v / 1000;
      const s = Number.isInteger(k) ? String(k) : k.toFixed(1).replace(/\.0$/, "");
      return `${s}k ms`;
    }
    return `${Math.round(v)} ms`;
  }

  _sevColor(v) {
    if (v == null || !Number.isFinite(v)) return "#9e9e9e";
    if (v >= this._config.bad) return "#ef5350";
    if (v >= this._config.warn) return "#ffb74d";
    return "#81c784";
  }

  async _maybeFetch() {
    const now = Date.now();
    if (this._busy) return;
    if (this._lastFetch && now - this._lastFetch < 60000 && this._points.length) {
      this._draw();
      return;
    }
    this._busy = true;
    try {
      const hours = this._config.hours_to_show || 24;
      const end = new Date();
      const start = new Date(end.getTime() - hours * 3600 * 1000);
      const result = await this._hass.connection.sendMessagePromise({
        type: "history/history_during_period",
        start_time: start.toISOString(),
        end_time: end.toISOString(),
        significant_changes_only: false,
        minimal_response: true,
        no_attributes: true,
        entity_ids: [this._config.entity],
      });
      const series = (result && result[this._config.entity]) || [];
      const pts = [];
      for (const row of series) {
        const n = parseFloat(row.s != null ? row.s : row.state);
        if (!Number.isFinite(n)) continue;
        const t = new Date(row.lu ? row.lu * 1000 : row.last_changed || row.last_updated).getTime();
        if (!Number.isFinite(t)) continue;
        pts.push({ t, v: Math.max(0, n) });
      }
      // Downsample keeping peaks so spikes remain visible
      this._points = this._downsampleMax(pts, 120);
      this._lastFetch = Date.now();
      this._draw();
    } catch (err) {
      // Fallback: older history API shape
      try {
        const hours = this._config.hours_to_show || 24;
        const end = new Date();
        const start = new Date(end.getTime() - hours * 3600 * 1000);
        const raw = await this._hass.connection.sendMessagePromise({
          type: "history/get_history",
          start_time: start.toISOString(),
          end_time: end.toISOString(),
          entity_ids: [this._config.entity],
          significant_changes_only: false,
        });
        const series = (raw && raw[0]) || [];
        const pts = [];
        for (const row of series) {
          const n = parseFloat(row.state);
          if (!Number.isFinite(n)) continue;
          const t = new Date(row.last_changed || row.last_updated).getTime();
          if (!Number.isFinite(t)) continue;
          pts.push({ t, v: Math.max(0, n) });
        }
        this._points = this._downsampleMax(pts, 120);
        this._lastFetch = Date.now();
        this._draw();
      } catch (e2) {
        this._points = [];
        this._draw();
      }
    } finally {
      this._busy = false;
    }
  }

  _downsampleMax(pts, n) {
    if (!pts.length) return [];
    if (pts.length <= n) return pts.slice();
    const out = [];
    const bucket = pts.length / n;
    for (let i = 0; i < n; i++) {
      const a = Math.floor(i * bucket);
      const b = Math.floor((i + 1) * bucket);
      let best = pts[a];
      for (let j = a; j < b && j < pts.length; j++) {
        if (pts[j].v > best.v) best = pts[j];
      }
      out.push(best);
    }
    return out;
  }

  _draw() {
    const W = 320;
    const H = 128;
    const padL = 30;
    const padR = 6;
    const padT = 4;
    const padB = 4;
    const plotW = W - padL - padR;
    const plotH = H - padT - padB;
    const maxY = this._config.max_scale || 100;
    const warn = this._config.warn;
    const bad = this._config.bad;
    const yAt = (v) => padT + plotH - (Math.min(Math.max(v, 0), maxY) / maxY) * plotH;

    const band = (y0, y1, fill) =>
      `<rect x="${padL}" y="${Math.min(y0, y1).toFixed(1)}" width="${plotW}" height="${Math.abs(y1 - y0).toFixed(1)}" fill="${fill}"/>`;

    let body =
      band(yAt(0), yAt(warn), "rgba(129,199,132,0.22)") +
      band(yAt(warn), yAt(bad), "rgba(255,183,77,0.28)") +
      band(yAt(bad), yAt(maxY), "rgba(239,83,80,0.22)") +
      `<line x1="${padL}" y1="${yAt(warn).toFixed(1)}" x2="${W - padR}" y2="${yAt(warn).toFixed(1)}" stroke="rgba(255,183,77,0.7)" stroke-width="1" stroke-dasharray="3 3"/>` +
      `<line x1="${padL}" y1="${yAt(bad).toFixed(1)}" x2="${W - padR}" y2="${yAt(bad).toFixed(1)}" stroke="rgba(239,83,80,0.75)" stroke-width="1" stroke-dasharray="3 3"/>`;

    const pts = this._points;
    if (!pts.length) {
      this._svg.innerHTML = body;
      return;
    }
    const t0 = pts[0].t;
    const t1 = pts[pts.length - 1].t || t0 + 1;
    const span = Math.max(1, t1 - t0);
    const xAt = (t) => padL + ((t - t0) / span) * plotW;

    let d = "";
    pts.forEach((p, i) => {
      const x = xAt(p.t);
      const y = yAt(p.v);
      d += `${i === 0 ? "M" : "L"}${x.toFixed(1)} ${y.toFixed(1)} `;
    });
    body += `<path d="${d}" fill="none" stroke="#eceff1" stroke-width="2" stroke-linejoin="round" stroke-linecap="round"/>`;
    this._svg.innerHTML = body;
    this._plotMeta = { padL, padR, plotW, t0, span, pts, W };
  }

  _onMove(ev) {
    if (!this._plotMeta || !this._plotMeta.pts.length) return;
    const { padL, plotW, t0, span, pts, W } = this._plotMeta;
    const rect = this._wrap.getBoundingClientRect();
    const xPx = ev.clientX - rect.left;
    const rel = Math.min(1, Math.max(0, (xPx / rect.width) * W - padL) / plotW);
    const t = t0 + rel * span;
    let best = pts[0];
    let bestDist = Math.abs(pts[0].t - t);
    for (let i = 1; i < pts.length; i++) {
      const d = Math.abs(pts[i].t - t);
      if (d < bestDist) {
        bestDist = d;
        best = pts[i];
      }
    }
    const when = new Date(best.t);
    const timeStr = when.toLocaleString(undefined, {
      month: "short",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
    this._tip.innerHTML = `<div class="t">${timeStr}</div><div class="v" style="color:${this._sevColor(best.v)}">${this._fmt(best.v)}</div>`;
    this._tip.style.display = "block";
    const tipW = this._tip.offsetWidth || 90;
    const left = Math.min(rect.width - tipW - 4, Math.max(4, xPx + 10));
    this._tip.style.left = `${left}px`;
    this._tip.style.top = `8px`;
  }
}

customElements.define("deepstack-inference-chart", DeepstackInferenceChart);

window.customCards = window.customCards || [];
window.customCards.push({
  type: "deepstack-inference-chart",
  name: "Deepstack Inference Chart",
  description: "Severity-scaled inference speed with real hover values (k for thousands).",
});
