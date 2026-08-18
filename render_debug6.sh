#!/bin/bash
KEY=$(grep -oP 'RENDER_API_KEY="\K[^"]+' ~/omega-agent-v2/render_find_service.sh | head -1)
export RENDER_API_KEY="$KEY"

echo "Key: [${RENDER_API_KEY}]"
echo "Length: ${#RENDER_API_KEY}"

SERVICE_ID="srv-da20pelg1s2s73de3n70"
mkdir -p ~/omega-agent-v2/tmp

echo ""
echo "=== Deploys call ==="
curl -s -H "Authorization: Bearer ${RENDER_API_KEY}" \
  "https://api.render.com/v1/services/${SERVICE_ID}/deploys?limit=5" \
  -o ~/omega-agent-v2/tmp/deploys6.json -w "HTTP_STATUS: %{http_code}\n"
python3 -m json.tool ~/omega-agent-v2/tmp/deploys6.json
