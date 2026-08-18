#!/bin/bash
echo "=== All RENDER_API_KEY lines in the source file ==="
grep -n "RENDER_API_KEY" ~/omega-agent-v2/render_find_service.sh

echo ""
echo "=== Extracted value, shown with visible boundaries ==="
KEY=$(grep -oP 'RENDER_API_KEY=\K\S+' ~/omega-agent-v2/render_find_service.sh | head -1)
echo "[${KEY}]"
echo "Length: ${#KEY}"

echo ""
echo "=== Hex dump of extracted value (spot hidden chars) ==="
echo -n "$KEY" | xxd | tail -5
