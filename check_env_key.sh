#!/data/data/com.termux/files/usr/bin/bash
set -x

ENV_FILE=~/omega-agent-v2/.env

echo "=== Does .env exist? ==="
ls -la "$ENV_FILE" 2>/dev/null

echo "=== Is GROQ_API_KEY present? (value hidden, just checking it's non-empty) ==="
if grep -q "^GROQ_API_KEY=." "$ENV_FILE" 2>/dev/null; then
  echo "GROQ_API_KEY is present and non-empty in .env"
else
  echo "GROQ_API_KEY is MISSING or empty in .env"
fi

echo "=== Full list of keys defined (names only, no values) ==="
grep -oE "^[A-Z_]+=" "$ENV_FILE" 2>/dev/null
