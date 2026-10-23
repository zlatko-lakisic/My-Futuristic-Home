#!/usr/local/bin/python3
"""Fetch Glances processlist from the Jetson; print one JSON line for HA command_line sensor."""
import json
import sys
import urllib.request

# Jetson Glances is finicky: /api/4/processlist can 400 if the plugin is disabled or the
# build uses an older API. Try a few known endpoints before giving up.
URLS = (
    "http://172.16.90.20:61208/api/4/processlist",
    "http://172.16.90.20:61208/api/3/processlist",
    "http://172.16.90.20:61208/api/4/processes",
)
TIMEOUT = 25


def main() -> None:
    data = None
    last_err = None
    for url in URLS:
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "HomeAssistant-Jetson-proc"})
            with urllib.request.urlopen(req, timeout=TIMEOUT) as r:
                raw = r.read().decode("utf-8", errors="replace")
            data = json.loads(raw)
            break
        except Exception as e:
            last_err = f"{url.rsplit('/', 2)[-2]}/{url.rsplit('/', 1)[-1]}:{e}"
            continue
    if data is None:
        print(
            json.dumps(
                {
                    "count": 0,
                    "processes": [],
                    "processes_json": "[]",
                    "error": last_err or "no endpoint",
                }
            )
        )
        return

    if isinstance(data, dict):
        plist = data.get("processlist") or data.get("processes") or []
    elif isinstance(data, list):
        plist = data
    else:
        plist = []

    rows = []
    for x in plist:
        if not isinstance(x, dict):
            continue
        name = str(x.get("name") or "?")[:40]
        try:
            c = float(x.get("cpu_percent", x.get("cpu") or 0) or 0)
        except (TypeError, ValueError):
            c = 0.0
        try:
            m = float(x.get("memory_percent", x.get("memory") or 0) or 0)
        except (TypeError, ValueError):
            m = 0.0
        rows.append({"name": name, "cpu_percent": c, "memory_percent": m})

    rows.sort(key=lambda r: -r["cpu_percent"])
    top10 = rows[:10]
    out = {
        "count": len(rows),
        "processes": top10,
        "processes_json": json.dumps(top10),
    }
    print(json.dumps(out))


if __name__ == "__main__":
    main()
