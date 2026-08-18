#!/data/data/com.termux/files/usr/bin/bash
set -x

REPO=~/omega-agent-v2

echo "=== How is the token used in sync_server.py? ==="
cat -n "$REPO/.omega-sync/sync_server.py" | grep -n -i "token" 

echo ""
echo "=== Is the sync server currently running/exposed anywhere (check for a public URL/tunnel)? ==="
cat "$REPO/quick-tunnel-url.txt" 2>/dev/null
cat "$REPO/termux-quick-tunnel.log" 2>/dev/null | tail -20

echo ""
echo "=== Any other files referencing this token value or 'omega_sync' auth? ==="
grep -rl "omega.sync\|OMEGA_SYNC" "$REPO" --include="*.py" --include="*.sh" 2>/dev/null
