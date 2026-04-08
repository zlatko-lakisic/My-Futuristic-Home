#!/usr/local/bin/python3
"""Fetch Glances processlist; print one JSON line for HA command_line sensor."""
import json
import sys
import urllib.request

URL = "http://10.0.10.16:61208/api/4/processlist"
TIMEOUT = 25


def main() -> None:
    try:
        req = urllib.request.Request(URL, headers={"User-Agent": "HomeAssistant-NVR-proc"})
        with urllib.request.urlopen(req, timeout=TIMEOUT) as r:
            raw = r.read().decode("utf-8", errors="replace")
        data = json.loads(raw)
    except Exception as e:
        print(
            json.dumps(
                {
                    "count": 0,
                    "processes": [],
                    "processes_json": "[]",
                    "error": str(e),
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
