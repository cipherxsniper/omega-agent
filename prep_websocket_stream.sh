#!/data/data/com.termux/files/usr/bin/bash
set -x

BACKEND=~/omega-agent-v2
FRONTEND=~/omega-agent-v2/../omega-chat-ui
[ -d "$FRONTEND" ] || FRONTEND=$(find ~ -maxdepth 2 -iname "*chat-ui*" -o -iname "*frontend*" 2>/dev/null | head -1)

echo "=== Backend: full chat_server.py ==="
cat -n "$BACKEND/agent/chat_server.py"

echo ""
echo "=== Backend: run_agent_task signature + on_step call sites in agent_loop.py ==="
grep -n "def run_agent_task\|on_step" "$BACKEND/agent/agent_loop.py"

echo ""
echo "=== Backend: current requirements.txt ==="
cat "$BACKEND/requirements.txt"

echo ""
echo "=== Frontend dir detected at: $FRONTEND ==="
echo ""
echo "=== Frontend: tailwind config (theme colors) ==="
find "$FRONTEND" -maxdepth 2 -iname "tailwind.config*" -exec cat {} \;

echo ""
echo "=== Frontend: global CSS / theme variables ==="
find "$FRONTEND/src" -iname "*.css" 2>/dev/null -exec echo "--- {} ---" \; -exec cat {} \;

echo ""
echo "=== Frontend: package.json (check for existing socket.io-client, ws libs) ==="
cat "$FRONTEND/package.json" 2>/dev/null | grep -i "socket\|ws\|websocket"

echo ""
echo "=== Frontend: main chat component file listing ==="
find "$FRONTEND/src" -iname "*chat*" -o -iname "*omega*" 2>/dev/null
