#!/data/data/com.termux/files/usr/bin/bash
set -x
echo "=== Is .env gitignored (confirming it never reached Render via git push)? ==="
cat ~/omega-agent-v2/.gitignore 2>/dev/null | grep -i env
git -C ~/omega-agent-v2 check-ignore -v .env 2>&1
