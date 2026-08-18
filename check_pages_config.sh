#!/data/data/com.termux/files/usr/bin/bash
set -x

echo "=== Current GitHub Pages configuration for omega-agent-v2 ==="
curl -s "https://api.github.com/repos/tommyleeharvey/omega-agent-v2/pages" | python3 -m json.tool

echo ""
echo "=== Does a gh-pages branch already exist? ==="
git -C ~/omega-agent-v2 ls-remote --heads origin gh-pages

echo ""
echo "=== Is 'gh-pages' npm package installed? ==="
grep -i "gh-pages" ~/omega-agent-v2/package.json
