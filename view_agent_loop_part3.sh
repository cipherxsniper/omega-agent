#!/data/data/com.termux/files/usr/bin/bash
set -x

AGENT_LOOP=~/omega-agent-v2/agent/agent_loop.py

echo "=== agent_loop.py lines 1-260 (imports, sign_event, ActionExecutor/_execute_tool_call) ==="
sed -n '1,260p' "$AGENT_LOOP"

echo ""
echo "=== Check for a /api/health or version endpoint in chat_server.py ==="
grep -n "def health\|/api/health\|COMMIT\|__version__\|git rev-parse" ~/omega-agent-v2/agent/chat_server.py

echo ""
echo "=== Local git SHA vs what /api/health (if any) on Render reports ==="
git -C ~/omega-agent-v2 rev-parse HEAD
