#!/data/data/com.termux/files/usr/bin/bash
set -x

OUT=~/omega_workspace/omega-agent-v2

echo "=== Fetch current live index.html ==="
curl -sv "https://tommyleeharvey.github.io/omega-agent-v2/" -o "$OUT/live_index.html" 2>&1 | tail -20
echo ""
echo "=== File check ==="
ls -la "$OUT/live_index.html"
cat "$OUT/live_index.html"

BUNDLE=$(grep -o 'assets/index-[A-Za-z0-9]*\.js' "$OUT/live_index.html" | head -1)
echo ""
echo "Detected bundle: $BUNDLE"

if [ -n "$BUNDLE" ]; then
  echo ""
  echo "=== Fetch that exact bundle ==="
  curl -s "https://tommyleeharvey.github.io/omega-agent-v2/$BUNDLE" -o "$OUT/live_bundle.js"
  ls -la "$OUT/live_bundle.js"

  echo ""
  echo "=== Backend URL baked into live bundle ==="
  grep -o "omega-agent-backend[a-zA-Z0-9.-]*\.onrender\.com" "$OUT/live_bundle.js" | sort -u

  echo ""
  echo "=== omegaagent\$ terminal string present? ==="
  grep -c "omegaagent" "$OUT/live_bundle.js"
fi
