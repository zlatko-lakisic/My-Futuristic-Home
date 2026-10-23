#!/usr/local/bin/python3
import json,urllib.request
out={}
for name,url in {
  "garden":"http://192.168.89.27:61208/api/4/cpu",
  "jetson":"http://172.16.90.20:61208/api/4/cpu",
  "nvr":"http://10.0.10.16:61208/api/4/cpu",
  "mqtt":"http://192.168.89.26:1883/",
  "frigate":"http://192.168.89.37:5000/api/version",
}.items():
  try:
    with urllib.request.urlopen(url, timeout=5) as r:
      out[name]={"ok":True,"code":r.status,"body":r.read()[:40].decode(errors="replace")}
  except Exception as e:
    out[name]={"ok":False,"error":str(e)[:120]}
print(json.dumps(out))
