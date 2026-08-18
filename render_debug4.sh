#!/bin/bash
export RENDER_API_KEY=$(grep -oP 'RENDER_API_KEY=\K\S+' ~/omega-agent-v2/render_find_service.sh | head -1)

echo "Key length in THIS script: ${#RENDER_API_KEY}"
if [ -z "$RENDER_API_KEY" ]; then
  echo "STILL EMPTY — key not found in render_find_service.sh via grep, check that file's actual variable name"
  exit 1
fi

SERVICE_ID="srv-da20pelg1s2s73de3n70"
mkdir -p ~/omega-agent-v2/tmp

echo "=== Deploys call with confirmed-loaded key ==="
curl -s -H "Authorization: Bearer ${RENDER_API_KEY}" \
  "https://api.render.com/v1/services/${SERVICE_ID}/deploys?limit=5" \
  -o ~/omega-agent-v2/tmp/deploys4.json -w "HTTP_STATUS: %{http_code}\n"
python3 -m json.tool ~/omega-agent-v2/tmp/deploys4.json
