#!/bin/bash
SERVICE_ID="srv-da20pelg1s2s73de3n70"

echo "=== Raw response + HTTP status ==="
curl -sv -H "Authorization: Bearer ${RENDER_API_KEY}" \
  "https://api.render.com/v1/services/${SERVICE_ID}/deploys?limit=5" \
  -o /tmp/render_deploys.json -w "\nHTTP_STATUS: %{http_code}\n" 2>&1 | tail -20

echo ""
echo "=== Body saved to /tmp/render_deploys.json ==="
cat /tmp/render_deploys.json
echo ""

echo ""
echo "=== GitHub main SHA (separate, no auth needed) ==="
curl -s "https://api.github.com/repos/tommyleeharvey/omega-agent-v2/commits/main" -o /tmp/gh_main.json -w "HTTP_STATUS: %{http_code}\n"
python3 -c "import json; print(json.load(open('/tmp/gh_main.json')).get('sha','NO SHA — see raw file'))" 2>&1
