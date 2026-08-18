import re

path = "/data/data/com.termux/files/home/omega-agent-v2/agent/agent_loop.py"
with open(path) as f:
    content = f.read()

old = '            tool_calls = message.get("tool_calls")\n'
new = '            tool_calls = message.get("tool_calls")\n            final_content = ""  # reset every iteration - fixes UnboundLocalError\n'

if old not in content:
    print("PATTERN NOT FOUND - aborting, no changes made")
else:
    content = content.replace(old, new, 1)
    with open(path, "w") as f:
        f.write(content)
    print("Patched: final_content now initialized at top of every loop iteration")
