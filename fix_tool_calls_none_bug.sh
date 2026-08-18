#!/data/data/com.termux/files/usr/bin/bash
set -x

AGENT_LOOP=~/omega-agent-v2/agent/agent_loop.py

echo "=== Backing up original ==="
cp "$AGENT_LOOP" "$AGENT_LOOP.bak_$(date +%s)"

echo "=== Applying fix: dedent 'break' so it runs even when on_step is None ==="
python3 - << 'PYEOF'
path = "/data/data/com.termux/files/home/omega-agent-v2/agent/agent_loop.py"

with open(path, "r") as f:
    content = f.read()

old = '''            if on_step:
                try:
                    on_step(transcript[-1])
                except Exception:
                    pass
                if signed_log:
                    sign_event(signed_log, event_type="agent_final", data={"step": step, "content": final_content[:1000]})
                break'''

new = '''            if on_step:
                try:
                    on_step(transcript[-1])
                except Exception:
                    pass
                if signed_log:
                    sign_event(signed_log, event_type="agent_final", data={"step": step, "content": final_content[:1000]})
            break'''

count = content.count(old)
print(f"Occurrences of target block found: {count}")

if count == 0:
    print("ERROR: target block not found verbatim — aborting, no changes written.")
    raise SystemExit(1)
elif count > 1:
    print("ERROR: target block matched more than once — refusing to guess, aborting.")
    raise SystemExit(1)

content = content.replace(old, new)

with open(path, "w") as f:
    f.write(content)

print("Patch applied successfully.")
PYEOF

echo ""
echo "=== Verifying: showing lines 595-620 after patch ==="
cat -n "$AGENT_LOOP" | sed -n '595,620p'
