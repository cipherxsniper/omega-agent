#!/data/data/com.termux/files/usr/bin/bash
set -x

REPO=~/omega-agent-v2
WORKFLOW="$REPO/.github/workflows/deploy.yml"

cp "$WORKFLOW" "$WORKFLOW.bak_$(date +%s)"

python3 - << 'PYEOF'
path = "/data/data/com.termux/files/home/omega-agent-v2/.github/workflows/deploy.yml"
with open(path) as f:
    c = f.read()

old = "VITE_AGENT_BACKEND_URL: https://omega-agent-backend.onrender.com"
new = "VITE_AGENT_BACKEND_URL: https://omega-agent-backend-v2.onrender.com"

n = c.count(old)
print(f"matches: {n}")
if n == 1:
    with open(path, "w") as f:
        f.write(c.replace(old, new))
    print("patched")
else:
    print("ABORTED - not exactly 1 match")
PYEOF

echo ""
echo "=== Verify ==="
grep -n "VITE_AGENT_BACKEND_URL" "$WORKFLOW"

echo ""
echo "=== Commit and push to trigger redeploy ==="
cd "$REPO" && git add .github/workflows/deploy.yml && git commit -m "Fix deploy workflow: point VITE_AGENT_BACKEND_URL at the -v2 backend we've been fixing" && git push
