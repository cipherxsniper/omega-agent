#!/data/data/com.termux/files/usr/bin/bash
set -x

AGENT_DIR=~/omega-agent-v2/agent

echo "=== agent/core/llm_client.py (full) ==="
cat "$AGENT_DIR/core/llm_client.py" 2>/dev/null || find ~/omega-agent-v2 -name "llm_client.py" -exec cat {} \;

echo ""
echo "=== grep for MODEL_TIER_STACK usage ==="
grep -rn "MODEL_TIER_STACK" ~/omega-agent-v2 --include="*.py"

echo ""
echo "=== grep for 'for ' loops near tool/model/response handling in agent_loop.py ==="
grep -n "^\s*for \|def run_agent_task\|on_step" "$AGENT_DIR/agent_loop.py" 2>/dev/null || find ~/omega-agent-v2 -name "agent_loop.py" -exec grep -n "^\s*for \|def run_agent_task\|on_step" {} \;

echo ""
echo "=== chat_server.py /api/chat route (full) ==="
grep -n "api/chat" -A 40 "$AGENT_DIR/chat_server.py" 2>/dev/null || find ~/omega-agent-v2 -name "chat_server.py" -exec grep -n "api/chat" -A 40 {} \;

echo ""
echo "=== Check for a .env or env var reference that might differ on Render ==="
grep -rln "os.environ\|os.getenv" ~/omega-agent-v2/agent --include="*.py"
grep -rn "GROQ_API_KEY\|os.getenv" "$AGENT_DIR/core/llm_client.py" 2>/dev/null
