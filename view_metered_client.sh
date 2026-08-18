#!/data/data/com.termux/files/usr/bin/bash
set -x

echo "=== Does api/metered_chat_completion.py exist? ==="
find ~/omega-agent-v2 -iname "metered_chat_completion.py"

echo ""
echo "=== Full contents, if it exists ==="
cat ~/omega-agent-v2/api/metered_chat_completion.py 2>/dev/null

echo ""
echo "=== Confirm which chat_completion actually got imported at runtime ==="
cd ~/omega-agent-v2 && python3 -c "
import sys, os
sys.path.append(os.path.dirname(os.path.abspath('agent/agent_loop.py')))
try:
    from api.metered_chat_completion import chat_completion
    print('IMPORTED FROM: api.metered_chat_completion')
    print(chat_completion)
except Exception as e:
    print('metered_chat_completion import failed:', repr(e))
    from api.groq_client import chat_completion
    print('IMPORTED FROM: api.groq_client (fallback)')
"
