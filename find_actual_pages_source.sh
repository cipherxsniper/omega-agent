#!/data/data/com.termux/files/usr/bin/bash
set -x

echo "=== Any existing GitHub Actions workflows in this repo? ==="
find ~/omega-agent-v2/.github -type f 2>/dev/null
cat ~/omega-agent-v2/.github/workflows/*.yml 2>/dev/null

echo ""
echo "=== Fetch the LIVE site's HTML to see which JS bundle it currently references ==="
curl -s "https://tommyleeharvey.github.io/omega-agent-v2/" | grep -o 'assets/index-[A-Za-z0-9]*\.js'

echo ""
echo "=== Compare to what we just built locally ==="
ls ~/omega-agent-v2/dist/assets/*.js 2>/dev/null

echo ""
echo "=== Check for a 'docs' folder as a Pages source ==="
find ~/omega-agent-v2 -maxdepth 1 -iname "docs"

echo ""
echo "=== Check for a CNAME file (sometimes indicates Pages setup) ==="
find ~/omega-agent-v2 -iname "CNAME" 2>/dev/null

echo ""
echo "=== Does a separate 'tommyleeharvey.github.io' repo exist? ==="
curl -s "https://api.github.com/repos/tommyleeharvey/tommyleeharvey.github.io" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('message', 'EXISTS - name: ' + d.get('name','?')))"
