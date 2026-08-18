#!/data/data/com.termux/files/usr/bin/bash
set -x

FRONTEND=/data/data/com.termux/files/home/omega_workspace/omega-chat-ui

echo "=== Full src/ tree ==="
find "$FRONTEND/src" -type f

echo ""
echo "=== package.json raw bytes check ==="
ls -la "$FRONTEND/package.json"
cat "$FRONTEND/package.json"

echo ""
echo "=== Find whatever component renders 'trace-card' (the live trace pane) ==="
grep -rl "trace-card" "$FRONTEND/src"

echo ""
echo "=== Show that file in full ==="
TRACE_FILE=$(grep -rl "trace-card" "$FRONTEND/src" | head -1)
cat -n "$TRACE_FILE"

echo ""
echo "=== Find whatever calls /api/job/stream or EventSource ==="
grep -rn "EventSource\|job/stream\|job/start" "$FRONTEND/src"
