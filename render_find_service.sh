#!/data/data/com.termux/files/usr/bin/bash
set -x

RENDER_API_KEY="rnd_OUL7nDWkKnMEaZieUfudaS2fzgbn"

curl -s -H "Authorization: Bearer $RENDER_API_KEY" \
  "https://api.render.com/v1/services?limit=20" \
  | python3 -m json.tool
