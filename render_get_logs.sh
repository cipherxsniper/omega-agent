#!/data/data/com.termux/files/usr/bin/bash
set -x

RENDER_API_KEY="rnd_OUL7nDWkKnMEaZieUfudaS2fzgbn"
SERVICE_ID="srv-da20pelg1s2s73de3n70"

echo "=== Confirm env vars actually landed on the service ==="
curl -s -H "Authorization: Bearer $RENDER_API_KEY" \
  "https://api.render.com/v1/services/$SERVICE_ID/env-vars" \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print([ (e['envVar']['key'], len(e['envVar'].get('value','')) ) for e in d ])"

echo ""
echo "=== Fire one more request to generate a fresh log entry ==="
python3 -c "
import requests
try:
    r = requests.post('https://omega-agent-backend-v2.onrender.com/api/chat', json={'message':'list your tools'}, timeout=60)
    print('status', r.status_code)
except Exception as e:
    print('err', e)
"

sleep 3

echo "=== Pull recent logs ==="
curl -s -H "Authorization: Bearer $RENDER_API_KEY" \
  "https://api.render.com/v1/logs?ownerId=tea-cumojslumphs738ld8fg&resource=$SERVICE_ID&limit=100" \
  | python3 -m json.tool
