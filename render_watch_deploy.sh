#!/data/data/com.termux/files/usr/bin/bash
set -x

RENDER_API_KEY="rnd_OUL7nDWkKnMEaZieUfudaS2fzgbn"
SERVICE_ID="srv-da20pelg1s2s73de3n70"
DEPLOY_ID="dep-da20petg1s2s73de3o1g"

echo "=== Polling deploy status (checks every 15s, up to 10 times = ~2.5 min) ==="
for i in $(seq 1 10); do
  STATUS=$(curl -s -H "Authorization: Bearer $RENDER_API_KEY" \
    "https://api.render.com/v1/services/$SERVICE_ID/deploys/$DEPLOY_ID" \
    | python3 -c "import sys,json; print(json.load(sys.stdin).get('status','unknown'))")
  echo "Attempt $i: status = $STATUS"
  if [ "$STATUS" = "live" ] || [ "$STATUS" = "build_failed" ] || [ "$STATUS" = "update_failed" ] || [ "$STATUS" = "deactivated" ]; then
    break
  fi
  sleep 15
done

echo ""
echo "=== Once live (or if it already is), hit /api/chat to confirm the fix ==="
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
