#!/data/data/com.termux/files/usr/bin/bash
set -x

REPO=~/omega-agent-v2

echo "=== Contents of .omega-sync/token (checking what was exposed) ==="
cat "$REPO/.omega-sync/token"

echo ""
echo "=== Is this repo public or private? ==="
curl -s "https://api.github.com/repos/tommyleeharvey/omega-agent-v2" | python3 -c "import sys,json; d=json.load(sys.stdin); print('private:', d.get('private'))"
