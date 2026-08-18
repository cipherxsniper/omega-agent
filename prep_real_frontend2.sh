#!/data/data/com.termux/files/usr/bin/bash
set -x

FRONTEND=~/omega-agent-v2

echo "=== Home.jsx (main page, likely owns layout/panel switching) ==="
cat -n "$FRONTEND/src/pages/Home.jsx"

echo ""
echo "=== Sidebar.jsx ==="
cat -n "$FRONTEND/src/components/omega/Sidebar.jsx"

echo ""
echo "=== JobsPanel.jsx ==="
cat -n "$FRONTEND/src/components/omega/JobsPanel.jsx"

echo ""
echo "=== WorkspacePanel.jsx ==="
cat -n "$FRONTEND/src/components/omega/WorkspacePanel.jsx"

echo ""
echo "=== localEntities.js (full, this is what calls /api/chat) ==="
cat -n "$FRONTEND/src/lib/localEntities.js"

echo ""
echo "=== transcriptAdapter.js ==="
cat -n "$FRONTEND/src/lib/transcriptAdapter.js"
