#!/bin/bash
SERVICE_ID="srv-da20pelg1s2s73de3n70"
mkdir -p ~/omega-agent-v2/tmp

echo "=== Bare deploys call, no params ==="
curl -s -H "Authorization: Bearer ${RENDER_API_KEY}" \
  "https://api.render.com/v1/services/${SERVICE_ID}/deploys" \
  -o ~/omega-agent-v2/tmp/deploys.json -w "HTTP_STATUS: %{http_code}\n"
cat ~/omega-agent-v2/tmp/deploys.json
echo ""

echo "=== With limit param, properly quoted ==="
curl -s -H "Authorization: Bearer ${RENDER_API_KEY}" \
  --data-urlencode "limit=5" \
  -G "https://api.render.com/v1/services/${SERVICE_ID}/deploys" \
  -o ~/omega-agent-v2/tmp/deploys2.json -w "HTTP_STATUS: %{http_code}\n"
cat ~/omega-agent-v2/tmp/deploys2.json
echo ""

echo "=== GitHub main SHA ==="
curl -s "https://api.github.com/repos/tommyleeharvey/omega-agent-v2/commits/main" \
  -o ~/omega-agent-v2/tmp/gh_main.json -w "HTTP_STATUS: %{http_code}\n"
python3 -c "import json; print(json.load(open('$HOME/omega-agent-v2/tmp/gh_main.json')).get('sha','NO SHA'))"
