#!/data/data/com.termux/files/usr/bin/bash
set -x

AGENT_LOOP=~/omega-agent-v2/agent/agent_loop.py

echo "=== Lines 434-625 with exact line numbers (cat -n) ==="
cat -n "$AGENT_LOOP" | sed -n '434,625p'
