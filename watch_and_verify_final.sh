#!/data/data/com.termux/files/usr/bin/bash
set -x

echo "=== Poll for the new deploy run to complete (checks every 15s, up to 20 times) ==="
for i in $(seq 1 20); do
  RESULT=$(curl -s "https://api.github.com/repos/tommyleeharvey/omega-agent-v2/actions/runs?per_page=1" | python3 -c "
import sys, json
d = json.load(sys.stdin)
run = d['workflow_runs'][0]
print(run['status'] + '|' + str(run['conclusion']))
")
  STATUS=$(echo "$RESULT" | cut -d'|' -f1)
  CONCLUSION=$(echo "$RESULT" | cut -d'|' -f2)
  echo "Attempt $i: status=$STATUS conclusion=$CONCLUSION"
  if [ "$STATUS" = "completed" ]; then
    break
  fi
  sleep 15
done

echo ""
echo "=== Fetch fresh index.html to get new bundle hash ==="
OUT=~/omega_workspace/omega-agent-v2
curl -s "https://tommyleeharvey.github.io/omega-agent-v2/" -o "$OUT/live_index2.html"
cat "$OUT/live_index2.html"

BUNDLE=$(grep -oE 'assets/index-[A-Za-z0-9_-]*\.js' "$OUT/live_index2.html" | head -1)
echo ""
echo "New bundle: $BUNDLE"

if [ -n "$BUNDLE" ]; then
  curl -s "https://tommyleeharvey.github.io/omega-agent-v2/$BUNDLE" -o "$OUT/live_bundle2.js"
  echo ""
  echo "=== Backend URL in NEW live bundle ==="
  grep -o "omega-agent-backend[a-zA-Z0-9.-]*\.onrender\.com" "$OUT/live_bundle2.js" | sort -u
  echo ""
  echo "=== omegaagent present? ==="
  grep -c "omegaagent" "$OUT/live_bundle2.js"
fi
