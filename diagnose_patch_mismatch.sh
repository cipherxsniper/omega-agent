#!/data/data/com.termux/files/usr/bin/bash
set -x

FRONTEND=~/omega-agent-v2

echo "=== Home.jsx: exact bytes around WorkspacePanel usage (with repr to show whitespace) ==="
python3 - << 'PYEOF'
with open("/data/data/com.termux/files/home/omega-agent-v2/src/pages/Home.jsx") as f:
    lines = f.readlines()
for i, line in enumerate(lines):
    if "WorkspacePanel" in line and "import" not in line:
        start = max(0, i - 1)
        end = min(len(lines), i + 8)
        for j in range(start, end):
            print(f"{j+1}: {repr(lines[j])}")
        print("---")
PYEOF

echo ""
echo "=== WorkspacePanel.jsx: exact bytes around terminal tab (with repr) ==="
python3 - << 'PYEOF'
with open("/data/data/com.termux/files/home/omega-agent-v2/src/components/omega/WorkspacePanel.jsx") as f:
    lines = f.readlines()
for i, line in enumerate(lines):
    if 'activeTab === "terminal"' in line:
        start = max(0, i - 1)
        end = min(len(lines), i + 25)
        for j in range(start, end):
            print(f"{j+1}: {repr(lines[j])}")
        print("---")
PYEOF
