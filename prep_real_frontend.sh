#!/data/data/com.termux/files/usr/bin/bash
set -x

FRONTEND=~/omega-agent-v2

echo "=== Full omega components directory ==="
find "$FRONTEND/src/components/omega" -type f

echo ""
echo "=== Full src tree (excluding node_modules) ==="
find "$FRONTEND/src" -type f

echo ""
echo "=== package.json ==="
cat "$FRONTEND/package.json"

echo ""
echo "=== Any tailwind config ==="
find "$FRONTEND" -maxdepth 1 -iname "tailwind.config*" -exec cat {} \;

echo ""
echo "=== Any global CSS with theme tokens (search broadly) ==="
find "$FRONTEND/src" -iname "*.css" -exec echo "--- {} ---" \; -exec cat {} \;

echo ""
echo "=== ChatInput.jsx itself, to confirm this is the live component ==="
cat -n "$FRONTEND/src/components/omega/ChatInput.jsx"

echo ""
echo "=== Search for existing EventSource/WebSocket/job-stream usage in this app ==="
grep -rn "EventSource\|WebSocket\|job/stream\|job/start\|api/chat" "$FRONTEND/src"
