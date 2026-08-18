#!/data/data/com.termux/files/usr/bin/bash
set -x

echo "=== Test the OLD backend (no -v2) with the same 'Hi' message ==="
python3 -c "
import requests
try:
    r = requests.post('https://omega-agent-backend.onrender.com/api/chat', json={'message':'Hi'}, timeout=60)
    print('status', r.status_code)
    print('body', r.text[:500])
except Exception as e:
    print('err', e)
"

echo ""
echo "=== Confirm which URL is actually baked into the LIVE deployed JS bundle ==="
curl -s "https://tommyleeharvey.github.io/omega-agent-v2/assets/index-C17T5t6E.js" | grep -o "omega-agent-backend[a-z0-9.-]*\.onrender\.com" | sort -u
