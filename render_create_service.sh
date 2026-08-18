#!/data/data/com.termux/files/usr/bin/bash
set -x

RENDER_API_KEY="rnd_OUL7nDWkKnMEaZieUfudaS2fzgbn"
OWNER_ID="tea-cumojslumphs738ld8fg"
ENV_FILE=~/omega-agent-v2/.env

python3 << 'PYEOF'
import os
import json
import urllib.request

RENDER_API_KEY = "rnd_OUL7nDWkKnMEaZieUfudaS2fzgbn"
OWNER_ID = "tea-cumojslumphs738ld8fg"
ENV_FILE = os.path.expanduser("~/omega-agent-v2/.env")

# Read local secrets without printing them
env_vals = {}
with open(ENV_FILE) as f:
    for line in f:
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, v = line.split("=", 1)
        env_vals[k.strip()] = v.strip().strip('"').strip("'")

groq_key = env_vals.get("GROQ_API_KEY", "")
proofchain_key = env_vals.get("AGENTPROOF_SIGNING_KEY", "")  # closest match found earlier

payload = {
    "type": "web_service",
    "name": "omega-agent-backend-v2",
    "ownerId": OWNER_ID,
    "repo": "https://github.com/tommyleeharvey/omega-agent-v2",
    "branch": "main",
    "serviceDetails": {
        "env": "python",
        "plan": "free",
        "region": "oregon",
        "envSpecificDetails": {
            "buildCommand": "pip install -r requirements.txt",
            "startCommand": "gunicorn agent.chat_server:app --bind 0.0.0.0:$PORT --timeout 120",
        },
    },
    "envVars": [
        {"key": "GROQ_API_KEY", "value": groq_key},
        {"key": "PROOFCHAIN_KEYFILE", "value": proofchain_key},
        {"key": "OMEGA_ALLOWED_ORIGIN", "value": "https://tommyleeharvey.github.io"},
    ],
}

req = urllib.request.Request(
    "https://api.render.com/v1/services",
    data=json.dumps(payload).encode(),
    headers={
        "Authorization": f"Bearer {RENDER_API_KEY}",
        "Content-Type": "application/json",
    },
    method="POST",
)

try:
    with urllib.request.urlopen(req, timeout=30) as r:
        print("Status:", r.status)
        print(json.dumps(json.loads(r.read().decode()), indent=2))
except urllib.error.HTTPError as e:
    print("HTTP Error:", e.code)
    print(e.read().decode())
PYEOF
