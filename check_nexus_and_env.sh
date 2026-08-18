#!/data/data/com.termux/files/usr/bin/bash
set -x

echo "=== metered_llm.py contents ==="
find ~ -maxdepth 4 -iname "metered_llm.py" -exec cat {} \;

echo ""
echo "=== Is GROQ_API_KEY set in THIS local shell? (do not print the value) ==="
if [ -n "$GROQ_API_KEY" ]; then echo "SET locally"; else echo "NOT SET locally"; fi

echo ""
echo "=== Does the agent-v2 repo have a Procfile / render.yaml / start command that exports env vars? ==="
find ~/omega-agent-v2 -maxdepth 2 \( -iname "render.yaml" -o -iname "Procfile" -o -iname "*.env*" \)
cat ~/omega-agent-v2/render.yaml 2>/dev/null
cat ~/omega-agent-v2/Procfile 2>/dev/null
