#!/data/data/com.termux/files/usr/bin/bash
set -x

echo "=== Recent GitHub Actions runs for this repo ==="
curl -s "https://api.github.com/repos/tommyleeharvey/omega-agent-v2/actions/runs?per_page=5" | python3 -c "
import sys, json
d = json.load(sys.stdin)
for run in d.get('workflow_runs', []):
    print(run['created_at'], '-', run['name'], '-', run['status'], '-', run['conclusion'], '-', run['html_url'])
"

echo ""
echo "=== Does https://omega-agent-backend.onrender.com (no -v2) even exist? ==="
curl -s -o /dev/null -w "HTTP status: %{http_code}\n" "https://omega-agent-backend.onrender.com/api/health"

echo ""
echo "=== Confirm the real one still works ==="
curl -s "https://omega-agent-backend-v2.onrender.com/api/health"
