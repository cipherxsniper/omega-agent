#!/bin/bash
set -e
SERVICE_ID="srv-da20pelg1s2s73de3n70"

echo "=== Latest deploys ==="
curl -s -H "Authorization: Bearer ${RENDER_API_KEY}" \
  "https://api.render.com/v1/services/${SERVICE_ID}/deploys?limit=5" | python3 -m json.tool

echo ""
echo "=== Latest GitHub main SHA ==="
curl -s "https://api.github.com/repos/tommyleeharvey/omega-agent-v2/commits/main" | python3 -c "import json,sys; print(json.load(sys.stdin)['sha'])"
