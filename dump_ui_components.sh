#!/data/data/com.termux/files/usr/bin/bash
set -x

SRC=~/omega-agent-v2/src

echo "=== JobsPanel.jsx (full) ==="
cat "$SRC/components/omega/JobsPanel.jsx"

echo ""
echo "=== TypingIndicator.jsx (full) ==="
cat "$SRC/components/omega/TypingIndicator.jsx"

echo ""
echo "=== transcriptAdapter.js (full) ==="
cat "$SRC/lib/transcriptAdapter.js"

echo ""
echo "=== omega-system.js (full) ==="
cat "$SRC/lib/omega-system.js"
