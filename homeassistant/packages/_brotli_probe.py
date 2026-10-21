import sys
mods=[]
for m in ("brotli","brotlicffi","Compression"):
    try:
        __import__(m)
        mods.append(m+":ok")
    except Exception as e:
        mods.append(m+":"+type(e).__name__)
print(" ".join(mods))
