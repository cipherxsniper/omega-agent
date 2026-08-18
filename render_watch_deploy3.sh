#!/data/data/com.termux/files/usr/bin/bash
set -x

RENDER_API_KEY="rnd_OUL7nDWkKnMEaZieUfudaS2fzgbn"
SERVICE_ID="srv-da20pelg1s2s73de3n70"

echo "=== Fetching latest deploy ID for this service ==="
DEPLOY_ID=$(curl -s -H "Authorization: Bearer $RENDER_API_KEY" \
  "https://api.render.com/v1/services/$SERVICE_ID/deploys?limit=1" \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print(d[0]['deploy']['id'])")
echo "Latest deploy ID: $DEPLOY_ID"

echo "=== Polling deploy status (checks every 20s, up to 20 times = ~6.5 min) ==="
for i in $(seq 1 20); do
  STATUS=$(curl -s -H "Authorization: Bearer $RENDER_API_KEY" \
    "https://api.render.com/v1/services/$SERVICE_ID/deploys/$DEPLOY_ID" \
    | python3 -c "import sys,json; print(json.load(sys.stdin).get('status','unknown'))")
  echo "Attempt $i: status = $STATUS"
  if [ "$STATUS" = "live" ] || [ "$STATUS" = "build_failed" ] || [ "$STATUS" = "update_failed" ] || [ "$STATUS" = "deactivated" ] || [ "$STATUS" = "canceled" ]; then
    break
  fi
  sleep 20
done

echo ""
echo "=== Final status: $STATUS ==="

if [ "$STATUS" = "live" ]; then
  echo "=== Deploy is live! Testing /api/chat ==="
  python3 - << 'PYEOF'
import requests
try:
    resp = requests.post(
        "https://omega-agent-backend-v2.onrender.com/api/chat",
        json={"message": "list your tools"},
        timeout=90,
    )
    print("Status:", resp.status_code)
    print("Body:", resp.text[:1500])
except Exception as e:
    print("Request failed:", repr(e))
PYEOF
else
  echo "=== Not live yet or failed. Pulling recent build logs ==="
  curl -s -H "Authorization: Bearer $RENDER_API_KEY" \
    "https://api.render.com/v1/services/$SERVICE_ID/deploys/$DEPLOY_ID" \
    | python3 -m json.tool
fi
