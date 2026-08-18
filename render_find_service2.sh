#!/data/data/com.termux/files/usr/bin/bash
set -x

RENDER_API_KEY="rnd_OUL7nDWkKnMEaZieUfudaS2fzgbn"

echo "=== Page 2, using cursor from last result ==="
curl -s -H "Authorization: Bearer $RENDER_API_KEY" \
  "https://api.render.com/v1/services?limit=20&cursor=QLwGFuxUmuJjdnRkczc4czczZXBvbnNn" \
  | python3 -m json.tool

echo ""
echo "=== Also try filtering by name directly ==="
curl -s -H "Authorization: Bearer $RENDER_API_KEY" \
  "https://api.render.com/v1/services?name=omega" \
  | python3 -m json.tool

echo ""
echo "=== Confirm which Render account/owner this API key belongs to ==="
curl -s -H "Authorization: Bearer $RENDER_API_KEY" \
  "https://api.render.com/v1/owners" \
  | python3 -m json.tool
