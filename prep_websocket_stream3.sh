#!/data/data/com.termux/files/usr/bin/bash
set -x

FRONTEND=/data/data/com.termux/files/home/omega_workspace/omega-chat-ui

echo "=== StepTrace.jsx (full) ==="
cat -n "$FRONTEND/src/StepTrace.jsx"

echo ""
echo "=== App.jsx (full) ==="
cat -n "$FRONTEND/src/App.jsx"

echo ""
echo "=== useReconnect.js (full) ==="
cat -n "$FRONTEND/src/useReconnect.js"
