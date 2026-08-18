#!/data/data/com.termux/files/usr/bin/bash
set -x

OUT=~/omega_workspace/omega-agent-v2

curl -s "https://tommyleeharvey.github.io/omega-agent-v2/assets/index-BSww-zR5.js" -o "$OUT/live_bundle.js"
ls -la "$OUT/live_bundle.js"

echo ""
echo "=== Backend URL baked into live bundle ==="
grep -o "omega-agent-backend[a-zA-Z0-9.-]*\.onrender\.com" "$OUT/live_bundle.js" | sort -u

echo ""
echo "=== omegaagent\$ terminal string present? ==="
grep -c "omegaagent" "$OUT/live_bundle.js"
