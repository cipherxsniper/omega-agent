#!/data/data/com.termux/files/usr/bin/bash
set -x

echo "=== Locating chat_server.py ==="
CHAT_SERVER=$(find ~/omega-agent-v2 -maxdepth 3 -name "chat_server.py" 2>/dev/null | head -1)
if [ -z "$CHAT_SERVER" ]; then
  echo "Not found under ~/omega-agent-v2, searching home dir..."
  CHAT_SERVER=$(find ~ -maxdepth 4 -name "chat_server.py" 2>/dev/null | grep -v omega_workspace | head -1)
fi

if [ -z "$CHAT_SERVER" ]; then
  echo "chat_server.py not found. Aborting."
  exit 1
fi

echo "Found: $CHAT_SERVER"
SERVER_DIR=$(dirname "$CHAT_SERVER")
cd "$SERVER_DIR" || exit 1

echo "=== Starting chat_server.py in background ==="
nohup python3 chat_server.py > ~/omega_workspace/omega-agent-v2/server.log 2>&1 &
SERVER_PID=$!
echo "Server PID: $SERVER_PID"
sleep 4

echo "=== Server log so far ==="
cat ~/omega_workspace/omega-agent-v2/server.log

echo "=== Firing repro request ==="
python3 ~/omega_workspace/omega-agent-v2/repro_nonetype.py

echo "=== Server log after request ==="
cat ~/omega_workspace/omega-agent-v2/server.log

echo "=== Killing server ==="
kill $SERVER_PID 2>/dev/null
