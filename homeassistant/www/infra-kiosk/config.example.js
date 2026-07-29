/* Copy to config.js on the HA host (not committed). */
window.INFRA_KIOSK = {
  /* Leave empty to use same host as this page (recommended). */
  haUrl: "",
  /* Long-lived token — or leave empty and enter once in the UI. */
  token: "",
  /* How often to redraw bars if no WS event (ms). */
  paintIntervalMs: 2000
};
