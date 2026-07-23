#!/bin/bash
set -e

ENV_FILE=""
if [ -f .env ]; then
  ENV_FILE=".env"
elif [ -f "$HOME/.env" ]; then
  ENV_FILE="$HOME/.env"
else
  echo "No .env found in current dir or \$HOME"
  exit 1
fi

echo "Using $ENV_FILE"
export $(grep -v '^#' "$ENV_FILE" | xargs)

if [ -z "$GROQ_API_KEY" ]; then
  echo "GROQ_API_KEY not set inside $ENV_FILE"
  exit 1
fi

curl -s https://api.groq.com/openai/v1/models \
  -H "Authorization: Bearer $GROQ_API_KEY" \
  | python3 -m json.tool
