#!/data/data/com.termux/files/usr/bin/bash
set -x

RENDER_API_KEY="rnd_OUL7nDWkKnMEaZieUfudaS2fzgbn"
SERVICE_ID="srv-da20pelg1s2s73de3n70"

echo "=== Firing a fresh /api/chat request to generate a log entry ==="
python3 -c "
import requests
try:
    r = requests.post('https://omega-agent-backend-v2.onrender.com/api/chat', json={'message':'Hi'}, timeout=60)
    print('status', r.status_code)
    print('body', r.text[:1500])
except Exception as e:
    print('err', e)
"

sleep 3

echo "=== Pulling most recent logs ==="
curl -s -H "Authorization: Bearer $RENDER_API_KEY" \
  "https://api.render.com/v1/logs?ownerId=tea-cumojslumphs738ld8fg&resource=$SERVICE_ID&limit=60" \
  | python3 -m json.tool
