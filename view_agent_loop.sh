#!/data/data/com.termux/files/usr/bin/bash
set -x

AGENT_LOOP=~/omega-agent-v2/agent/agent_loop.py

echo "=== Lines 320-420 (start of run_agent_task, early setup) ==="
sed -n '320,420p' "$AGENT_LOOP"

echo ""
echo "=== Lines 590-690 (tail end, where 'result' and final return live) ==="
sed -n '590,690p' "$AGENT_LOOP"

echo ""
echo "=== All 'return' statements in the file with line numbers ==="
grep -n "return" "$AGENT_LOOP"

echo ""
echo "=== Where is 'result' assigned? ==="
grep -n "result\s*=" "$AGENT_LOOP"
