#!/data/data/com.termux/files/usr/bin/bash
set -x

echo "=== Fetch current live index.html to find today's actual bundle filename ==="
curl -s "https://tommyleeharvey.github.io/omega-agent-v2/" -o /tmp/live_index.html
cat /tmp/live_index.html
BUNDLE=$(grep -o 'assets/index-[A-Za-z0-9]*\.js' /tmp/live_index.html | head -1)
echo ""
echo "Detected bundle: $BUNDLE"

echo ""
echo "=== Fetch that exact bundle and search for the backend URL ==="
curl -s "https://tommyleeharvey.github.io/omega-agent-v2/$BUNDLE" -o /tmp/live_bundle.js
grep -o "omega-agent-backend[a-zA-Z0-9.-]*\.onrender\.com" /tmp/live_bundle.js | sort -u

echo ""
echo "=== Also confirm the omegaagent$ terminal string made it into this live bundle ==="
grep -c "omegaagent" /tmp/live_bundle.js
