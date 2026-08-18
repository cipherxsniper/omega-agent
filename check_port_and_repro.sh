#!/data/data/com.termux/files/usr/bin/bash
set -x

echo "=== What is listening on 8420? ==="
netstat -tlnp 2>/dev/null | grep 8420
if [ $? -ne 0 ]; then
  echo "netstat unavailable or nothing found, trying fuser..."
  fuser 8420/tcp 2>/dev/null
fi

echo "=== PIDs of any chat_server.py processes ==="
ps aux | grep chat_server.py | grep -v grep

echo "=== Firing repro request against port 8420 (whatever is already running) ==="
python3 - << 'PYEOF'
import requests

BASE_URL = "http://localhost:8420"

def main():
    payload = {"message": "list your tools"}
    try:
        resp = requests.post(f"{BASE_URL}/api/chat", json=payload, timeout=30)
        print("Status:", resp.status_code)
        print("Body:", resp.text[:3000])
    except Exception as e:
        print("Request failed:", repr(e))

main()
PYEOF

echo "=== Recent output from the already-running process (if we can find its log) ==="
find ~/omega-agent-v2 -maxdepth 2 -iname "*.log" -newer ~/omega-agent-v2/agent/chat_server.py 2>/dev/null
