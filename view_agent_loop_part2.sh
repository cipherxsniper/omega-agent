#!/data/data/com.termux/files/usr/bin/bash
set -x

AGENT_LOOP=~/omega-agent-v2/agent/agent_loop.py
GROQ_CLIENT=~/omega-agent-v2/api/groq_client.py

echo "=== agent_loop.py lines 420-590 (model call + tool_calls extraction) ==="
sed -n '420,590p' "$AGENT_LOOP"

echo ""
echo "=== api/groq_client.py FULL FILE ==="
cat "$GROQ_CLIENT"
