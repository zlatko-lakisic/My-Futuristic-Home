"""Replace hardcoded Portainer container grid in infrastructure.yaml with auto-entities.

After the dashboard uses auto-entities, refresh embedded TITLES/ICONS/COLORS with:

  python patch_infrastructure_containers.py sync-maps
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

import gen_portainer_cards as g

ROOT = Path(__file__).resolve().parents[1]
YAML_PATH = ROOT / "homeassistant" / "dashboards" / "infrastructure.yaml"

TITLES_JS = json.dumps(g.TITLES, ensure_ascii=False)
ICONS_JS = json.dumps(g.ICONS, ensure_ascii=False)
COLORS_JS = json.dumps(g.COLORS, ensure_ascii=False)

# Lines 1177–5976 (1-based): container layout-card block to replace.
START_IDX = 1176
END_IDX = 5976

NEW_BLOCK = """                  - type: custom:auto-entities
                    card:
                      type: custom:layout-card
                      layout_type: custom:grid-layout
                      layout:
                        grid-template-columns: repeat(auto-fit, minmax(min(100%, 260px), 1fr))
                        grid-gap: 6px
                        place-items: stretch
                        align-items: stretch
                      grid_options:
                        columns: full
                    card_param: cards
                    sort:
                      method: name
                      ignore_case: true
                    filter:
                      include:
                        - domain: sensor
                          entity_id: '/sensor\\..*_cpu_usage_total$/'
                          options:
                            type: custom:button-card
                            show_icon: false
                            show_name: false
                            show_state: false
                            show_label: false
                            variables:
                              restart_btn: |
                                [[[
                                  const id = entity.entity_id;
                                  const slug = id.replace('sensor.', '').replace('_cpu_usage_total', '');
                                  return `button.${slug}_restart_container`;
                                ]]]
                            tap_action:
                              action: more-info
                            styles:
                              card:
                                - background-color: '#1c1c1c'
                                - border: 1px solid rgba(255, 255, 255, 0.1)
                                - border-radius: 10px
                                - padding: 6px 8px
                                - box-shadow: none
                              grid:
                                - grid-template-columns: 1fr auto
                                - grid-template-areas: '"c rs"'
                                - align-items: start
                              custom_fields:
                                c:
                                  - width: 100%
                                rs:
                                  - width: 32px
                                  - justify-self: end
                            custom_fields:
                              c: |
                                [[[
                                  const slug = entity.entity_id.replace('sensor.', '').replace('_cpu_usage_total', '');
                                  const cpuE = `sensor.${slug}_cpu_usage_total`;
                                  const memE = `sensor.${slug}_memory_usage_percentage`;
                                  const stE = `sensor.${slug}_state`;
                                  const fmt = (n) => String(parseFloat((Math.round(n * 100) / 100).toFixed(2)));
                                  const cpu = Math.min(100, Math.max(0, parseFloat(hass.states[cpuE]?.state) || 0));
                                  const mem = Math.min(100, Math.max(0, parseFloat(hass.states[memE]?.state) || 0));
                                  const st = hass.states[stE]?.state ?? '-';
                                  const TITLES = __TITLES__;
                                  const ICONS = __ICONS__;
                                  const COLORS = __COLORS__;
                                  const title = TITLES[slug] || slug.replace(/_/g, ' ').replace(/\\b\\w/g, (c) => c.toUpperCase());
                                  const icon = ICONS[slug] || 'mdi:docker';
                                  const color = COLORS[slug] || '#90caf9';
                                  return `<div style="display:flex;gap:8px;align-items:flex-start;font-family:var(--ha-font-family,sans-serif);color:#fff;">
                                    <ha-icon icon="${icon}" style="flex-shrink:0;color:${color};--mdc-icon-size:20px;"></ha-icon>
                                    <div style="flex:1;min-width:0;">
                                      <div style="display:flex;justify-content:space-between;align-items:baseline;gap:6px;">
                                        <div style="font-weight:700;font-size:0.76rem;">${title}</div>
                                        <div style="font-size:0.58rem;opacity:0.75;max-width:52%;text-align:right;word-break:break-word;">${st}</div>
                                      </div>
                                      <div style="margin-top:5px;display:flex;flex-direction:column;gap:5px;">
                                        <div style="font-size:0.54rem;opacity:0.85;">
                                          <div style="display:flex;justify-content:space-between;margin-bottom:2px;">
                                            <span style="color:#ffb74d;font-weight:600;">CPU</span><span>${fmt(cpu)}%</span>
                                          </div>
                                          <div style="height:5px;background:rgba(255,255,255,0.1);border-radius:3px;overflow:hidden;">
                                            <div style="width:${cpu}%;height:100%;background:linear-gradient(90deg,#ffb74d,#f57c00);"></div>
                                          </div>
                                        </div>
                                        <div style="font-size:0.54rem;opacity:0.85;">
                                          <div style="display:flex;justify-content:space-between;margin-bottom:2px;">
                                            <span style="color:#4fc3f7;font-weight:600;">Mem</span><span>${fmt(mem)}%</span>
                                          </div>
                                          <div style="height:5px;background:rgba(255,255,255,0.1);border-radius:3px;overflow:hidden;">
                                            <div style="width:${mem}%;height:100%;background:linear-gradient(90deg,#4fc3f7,#0288d1);"></div>
                                          </div>
                                        </div>
                                      </div>
                                    </div>
                                  </div>`;
                                ]]]
                              rs:
                                card:
                                  type: custom:button-card
                                  entity: '[[[ return variables.restart_btn ]]]'
                                  show_icon: true
                                  icon: mdi:restart
                                  show_name: false
                                  show_state: false
                                  show_label: false
                                  tap_action:
                                    action: call-service
                                    service: button.press
                                    target:
                                      entity_id: '[[[ return variables.restart_btn ]]]'
                                  styles:
                                    card:
                                      - width: 32px
                                      - height: 32px
                                      - padding: 2px
                                      - border-radius: 8px
                                      - border: 1px solid rgba(255, 255, 255, 0.12)
                                      - background-color: rgba(255, 255, 255, 0.06)
                                      - box-shadow: none
                                    icon:
                                      - width: 16px
                                      - height: 16px
                                      - color: rgba(255, 255, 255, 0.85)
""".replace("__TITLES__", TITLES_JS).replace("__ICONS__", ICONS_JS).replace("__COLORS__", COLORS_JS)


def sync_embedded_maps() -> None:
    """Rewrite const TITLES/ICONS/COLORS inside the Container Infrastructure button-card template."""
    raw = YAML_PATH.read_text(encoding="utf-8")
    if "heading: Container Infrastructure" not in raw:
        raise SystemExit(f"Missing Container Infrastructure section in {YAML_PATH}")
    t_js = json.dumps(g.TITLES, ensure_ascii=False)
    i_js = json.dumps(g.ICONS, ensure_ascii=False)
    c_js = json.dumps(g.COLORS, ensure_ascii=False)

    def sub(prefix: str, payload: str, text: str) -> str:
        pattern = re.compile(
            rf"^([ \t]*){re.escape(prefix)} = .+$",
            re.MULTILINE,
        )

        def repl(m: re.Match[str]) -> str:
            indent = m.group(1)
            return f"{indent}{prefix} = {payload};"

        new_text, n = pattern.subn(repl, text, count=1)
        if n != 1:
            raise SystemExit(f"Expected exactly one {prefix} line to replace, got {n}")
        return new_text

    out = raw
    out = sub("const TITLES", t_js, out)
    out = sub("const ICONS", i_js, out)
    out = sub("const COLORS", c_js, out)
    YAML_PATH.write_text(out, encoding="utf-8")
    print(f"Synced TITLES/ICONS/COLORS in {YAML_PATH} from gen_portainer_cards.")


def main() -> None:
    raw = YAML_PATH.read_text(encoding="utf-8")
    if "heading: Container Infrastructure" in raw and "custom:auto-entities" in raw.split(
        "heading: Container Infrastructure", 1
    )[1][:4000]:
        raise SystemExit(
            f"{YAML_PATH} already has auto-entities under Container Infrastructure; "
            "not patching (line-based splice would corrupt the file)."
        )
    lines = raw.splitlines(keepends=True)
    if len(lines) < END_IDX:
        raise SystemExit(f"File shorter than expected: {len(lines)} lines")
    head = "".join(lines[:START_IDX])
    tail = "".join(lines[END_IDX:])
    out = head + NEW_BLOCK + "\n" + tail
    YAML_PATH.write_text(out, encoding="utf-8")
    print(f"Patched {YAML_PATH}: removed lines {START_IDX + 1}–{END_IDX}, inserted auto-entities block.")


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "sync-maps":
        sync_embedded_maps()
    else:
        main()
