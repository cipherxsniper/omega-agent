#!/bin/bash
SERVICE_ID="srv-da20pelg1s2s73de3n70"
mkdir -p ~/omega-agent-v2/tmp

echo "=== Single service fetch (baseline — known-working auth pattern) ==="
curl -s -H "Authorization: Bearer ${RENDER_API_KEY}" \
  -H "Accept: application/json" \
  "https://api.render.com/v1/services/${SERVICE_ID}" \
  -o ~/omega-agent-v2/tmp/service.json -w "HTTP_STATUS: %{http_code}\n"
head -c 500 ~/omega-agent-v2/tmp/service.json
echo ""
echo ""

echo "=== Deploys with Accept header added ==="
curl -s -H "Authorization: Bearer ${RENDER_API_KEY}" \
  -H "Accept: application/json" \
  "https://api.render.com/v1/services/${SERVICE_ID}/deploys" \
  -o ~/omega-agent-v2/tmp/deploys3.json -w "HTTP_STATUS: %{http_code}\n"
head -c 500 ~/omega-agent-v2/tmp/deploys3.json
echo ""

echo ""
echo "=== curl verbose, deploys endpoint, full headers both directions ==="
curl -sv -H "Authorization: Bearer ${RENDER_API_KEY}" \
  -H "Accept: application/json" \
  "https://api.render.com/v1/services/${SERVICE_ID}/deploys" 2>&1 | grep -E "^[<>]"
