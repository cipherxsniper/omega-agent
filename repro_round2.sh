#!/data/data/com.termux/files/usr/bin/bash
set -x

echo "=== 1: Hit the LIVE Render backend directly ==="
python3 - << 'PYEOF'
import requests

BASE_URL = "https://omega-agent-backend.onrender.com"

def main():
    payload = {"message": "list your tools"}
    try:
        resp = requests.post(f"{BASE_URL}/api/chat", json=payload, timeout=60)
        print("Status:", resp.status_code)
        print("Body:", resp.text[:3000])
    except Exception as e:
        print("Request failed:", repr(e))

main()
PYEOF

echo "=== 2: Local instance - send a SECOND message to see if turn 2 breaks ==="
python3 - << 'PYEOF'
import requests

BASE_URL = "http://localhost:8420"

def send(msg):
    try:
        resp = requests.post(f"{BASE_URL}/api/chat", json={"message": msg}, timeout=30)
        print(f"--- msg: {msg!r} ---")
        print("Status:", resp.status_code)
        print("Body:", resp.text[:2000])
    except Exception as e:
        print("Request failed:", repr(e))

send("list your tools")
send("now use grep_search to find the word TODO in this repo")
PYEOF

echo "=== 3: Check what commit the running local process is actually on ==="
cd ~/omega-agent-v2 && git log --oneline -5
git status --short
