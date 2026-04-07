"""Emit YAML fragment for infrastructure dashboard Portainer container cards."""
from __future__ import annotations

import sys
from pathlib import Path

# From HA MCP: button.<slug>_restart_container
SLUGS = [
    "akaunting",
    "akaunting_db",
    "codeproject_ai_server",
    "compreface_admin",
    "compreface_api",
    "compreface_core",
    "compreface_postgres_db",
    "compreface_ui",
    "crowdsec",
    "double_take",
    "fail2ban_traefik",
    "flaresolverr",
    "frigate",
    "frigate_plate_recognizer",
    "grafana",
    "hdhrdvr",
    "influx_db2",
    "jackett",
    "kong_gateway",
    "mailserver",
    "nextcloud_aio_apache",
    "nextcloud_aio_calcardbackup",
    "nextcloud_aio_clamav",
    "nextcloud_aio_collabora",
    "nextcloud_aio_database",
    "nextcloud_aio_fail2ban",
    "nextcloud_aio_imaginary",
    "nextcloud_aio_mastercontainer",
    "nextcloud_aio_nextcloud",
    "nextcloud_aio_notify_push",
    "nextcloud_aio_redis",
    "nextcloud_aio_talk",
    "nextcloud_aio_talk_recording",
    "nextcloud_aio_watchtower",
    "nextcloud_aio_whiteboard",
    "nvr_telegraf_mqtt_1",
    "pihole",
    "plex",
    "portainer",
    "portainer_edge_agent",
    "prowlarr",
    "qbittorrent",
    "radarr",
    "roundcube",
    "sonarr",
    "telegraf_traefik_logs",
    "traefik",
    "traefik_mdns_repeater_1",
    "traefik_warpgate_init_1",
    "unifi_db",
    "unifi_network_application",
    "warpgate",
]

TITLES = {
    "hdhrdvr": "HDHomeRun DVR",
    "qbittorrent": "qBittorrent",
    "portainer": "Portainer CE",
    "portainer_edge_agent": "Portainer Edge Agent",
    "codeproject_ai_server": "CodeProject AI Server",
    "influx_db2": "InfluxDB 2",
    "nvr_telegraf_mqtt_1": "NVR Telegraf MQTT",
    "frigate_plate_recognizer": "Frigate (plates)",
    "nextcloud_aio_mastercontainer": "Nextcloud AIO (master)",
    "nextcloud_aio_apache": "Nextcloud AIO · Apache",
    "nextcloud_aio_nextcloud": "Nextcloud AIO · App",
    "nextcloud_aio_imaginary": "Nextcloud AIO · Imaginary",
    "nextcloud_aio_talk_recording": "Nextcloud AIO · Talk recording",
    "nextcloud_aio_clamav": "Nextcloud AIO · ClamAV",
    "nextcloud_aio_redis": "Nextcloud AIO · Redis",
    "nextcloud_aio_database": "Nextcloud AIO · Database",
    "nextcloud_aio_whiteboard": "Nextcloud AIO · Whiteboard",
    "nextcloud_aio_notify_push": "Nextcloud AIO · Notify push",
    "nextcloud_aio_talk": "Nextcloud AIO · Talk",
    "nextcloud_aio_collabora": "Nextcloud AIO · Collabora",
    "nextcloud_aio_fail2ban": "Nextcloud AIO · Fail2ban",
    "nextcloud_aio_calcardbackup": "Nextcloud AIO · Cal/card backup",
    "nextcloud_aio_watchtower": "Nextcloud AIO · Watchtower",
    "fail2ban_traefik": "Fail2ban (Traefik)",
    "telegraf_traefik_logs": "Telegraf (Traefik logs)",
    "traefik_warpgate_init_1": "Traefik · Warpgate init",
    "traefik_mdns_repeater_1": "Traefik · mDNS repeater",
    "unifi_network_application": "UniFi Network App",
    "unifi_db": "UniFi DB",
    "kong_gateway": "Kong Gateway",
    "akaunting_db": "Akaunting DB",
}

ICONS = {
    "plex": "mdi:plex",
    "radarr": "mdi:download",
    "sonarr": "mdi:television-classic",
    "qbittorrent": "mdi:download-network",
    "prowlarr": "mdi:radar",
    "jackett": "mdi:folder-download",
    "flaresolverr": "mdi:flash",
    "hdhrdvr": "mdi:television-guide",
    "portainer": "mdi:docker",
    "portainer_edge_agent": "mdi:docker",
    "frigate": "mdi:cctv",
    "frigate_plate_recognizer": "mdi:car",
    "grafana": "mdi:chart-timeline",
    "influx_db2": "mdi:database-clock",
    "traefik": "mdi:server-network",
    "pihole": "mdi:dns",
    "unifi_network_application": "mdi:access-point",
    "unifi_db": "mdi:database",
    "nextcloud_aio_nextcloud": "mdi:cloud",
    "nextcloud_aio_apache": "mdi:web",
    "mailserver": "mdi:email-server",
    "roundcube": "mdi:email",
    "akaunting": "mdi:cash-register",
    "crowdsec": "mdi:shield-account",
    "warpgate": "mdi:lock-smart",
    "kong_gateway": "mdi:api",
    "codeproject_ai_server": "mdi:robot",
    "double_take": "mdi:face-recognition",
    "compreface_ui": "mdi:face-recognition",
    "compreface_admin": "mdi:account-cog",
    "compreface_api": "mdi:api",
    "compreface_core": "mdi:chip",
    "compreface_postgres_db": "mdi:database",
}

COLORS = {
    "plex": "#e5a00d",
    "radarr": "#66bb6a",
    "sonarr": "#42a5f5",
    "qbittorrent": "#ef5350",
    "prowlarr": "#ab47bc",
    "jackett": "#ff9800",
    "flaresolverr": "#ff7043",
    "hdhrdvr": "#5c6bc0",
    "portainer": "#13b0d3",
    "portainer_edge_agent": "#13b0d3",
    "frigate": "#43a047",
    "grafana": "#f57c00",
    "influx_db2": "#e91e63",
    "traefik": "#7986cb",
    "pihole": "#4caf50",
}


def title_for(slug: str) -> str:
    if slug in TITLES:
        return TITLES[slug]
    return slug.replace("_", " ").title()


def esc_js_single(s: str) -> str:
    return s.replace("\\", "\\\\").replace("'", "\\'")


def card_yaml(slug: str) -> str:
    title = title_for(slug)
    icon = ICONS.get(slug, "mdi:docker")
    color = COLORS.get(slug, "#90caf9")
    cpu = f"sensor.{slug}_cpu_usage_total"
    mem = f"sensor.{slug}_memory_usage_percentage"
    st = f"sensor.{slug}_state"
    btn = f"button.{slug}_restart_container"
    # +4 spaces: nested under layout-card → cards
    return f"""                      - type: custom:button-card
                        entity: {cpu}
                        show_icon: false
                        show_name: false
                        show_state: false
                        show_label: false
                        triggers_update:
                          - {mem}
                          - {st}
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
                              const fmt = (n) => String(parseFloat((Math.round(n * 100) / 100).toFixed(2)));
                              const cpu = Math.min(100, Math.max(0, parseFloat(hass.states['{esc_js_single(cpu)}']?.state) || 0));
                              const mem = Math.min(100, Math.max(0, parseFloat(hass.states['{esc_js_single(mem)}']?.state) || 0));
                              const st = hass.states['{esc_js_single(st)}']?.state ?? '-';
                              const color = '{color}';
                              return `<div style="display:flex;gap:8px;align-items:flex-start;font-family:var(--ha-font-family,sans-serif);color:#fff;">
                                <ha-icon icon="{icon}" style="flex-shrink:0;color:${{color}};--mdc-icon-size:20px;"></ha-icon>
                                <div style="flex:1;min-width:0;">
                                  <div style="display:flex;justify-content:space-between;align-items:baseline;gap:6px;">
                                    <div style="font-weight:700;font-size:0.76rem;">{title}</div>
                                    <div style="font-size:0.58rem;opacity:0.75;max-width:52%;text-align:right;word-break:break-word;">${{st}}</div>
                                  </div>
                                  <div style="margin-top:5px;display:flex;flex-direction:column;gap:5px;">
                                    <div style="font-size:0.54rem;opacity:0.85;">
                                      <div style="display:flex;justify-content:space-between;margin-bottom:2px;">
                                        <span style="color:#ffb74d;font-weight:600;">CPU</span><span>${{fmt(cpu)}}%</span>
                                      </div>
                                      <div style="height:5px;background:rgba(255,255,255,0.1);border-radius:3px;overflow:hidden;">
                                        <div style="width:${{cpu}}%;height:100%;background:linear-gradient(90deg,#ffb74d,#f57c00);"></div>
                                      </div>
                                    </div>
                                    <div style="font-size:0.54rem;opacity:0.85;">
                                      <div style="display:flex;justify-content:space-between;margin-bottom:2px;">
                                        <span style="color:#4fc3f7;font-weight:600;">Mem</span><span>${{fmt(mem)}}%</span>
                                      </div>
                                      <div style="height:5px;background:rgba(255,255,255,0.1);border-radius:3px;overflow:hidden;">
                                        <div style="width:${{mem}}%;height:100%;background:linear-gradient(90deg,#4fc3f7,#0288d1);"></div>
                                      </div>
                                    </div>
                                  </div>
                                </div>
                              </div>`;
                            ]]]
                          rs:
                            card:
                              type: custom:button-card
                              entity: {btn}
                              show_icon: true
                              icon: mdi:restart
                              show_name: false
                              show_state: false
                              show_label: false
                              tap_action:
                                action: call-service
                                service: button.press
                                target:
                                  entity_id: {btn}
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
"""


def main() -> None:
    slugs = sorted(SLUGS, key=title_for)
    header = """              - type: vertical-stack
                cards:
                  - type: heading
                    heading_style: subtitle
                    heading: Container Infrastructure
                  - type: custom:layout-card
                    layout_type: custom:grid-layout
                    layout:
                      grid-template-columns: repeat(6, minmax(0, 1fr))
                      grid-gap: 6px
                      place-items: stretch
                      align-items: stretch
                      mediaquery:
                        '(max-width: 1600px)':
                          grid-template-columns: repeat(4, minmax(0, 1fr))
                        '(max-width: 1100px)':
                          grid-template-columns: repeat(2, minmax(0, 1fr))
                        '(max-width: 640px)':
                          grid-template-columns: 100%
                    grid_options:
                      columns: full
                    cards:
"""
    text = header + "\n".join(card_yaml(s) for s in slugs)
    out = Path(__file__).resolve().parent / "_portainer_cards_fragment.yaml"
    out.write_text(text, encoding="utf-8")
    if sys.stdout.encoding and sys.stdout.encoding.lower().startswith("utf"):
        print(text)
    else:
        print(f"Wrote {out} ({len(slugs)} containers)", file=sys.stderr)


if __name__ == "__main__":
    main()
