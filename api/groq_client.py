import os
import requests

GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions"
GROQ_API_KEY = os.environ.get("GROQ_API_KEY")

if not GROQ_API_KEY:
    raise RuntimeError("GROQ_API_KEY not set in environment")

DEFAULT_MODEL = "openai/gpt-oss-120b"
FAST_MODEL = "llama-3.1-8b-instant"


def chat_completion(messages, model=DEFAULT_MODEL, temperature=0.3, max_tokens=2048, tools=None):
    payload = {
        "model": model,
        "messages": messages,
        "temperature": temperature,
        "max_tokens": max_tokens,
    }
    if tools:
        payload["tools"] = tools

    resp = requests.post(
        GROQ_API_URL,
        headers={
            "Authorization": f"Bearer {GROQ_API_KEY}",
            "Content-Type": "application/json",
        },
        json=payload,
        timeout=30,
    )

    if resp.status_code == 429:
        raise RuntimeError(f"Groq rate limited: {resp.text}")
    if not resp.ok:
        raise RuntimeError(f"Groq API error {resp.status_code}: {resp.text}")

    return resp.json()["choices"][0]["message"]["content"]
