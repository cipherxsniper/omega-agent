#!/data/data/com.termux/files/usr/bin/python3
"""
Drop-in bridge: agent_loop can call chat_completion that prefers
OpenRouter via ~/.omega/nexus/metered_llm, falls back to Groq if configured.

Install:
  cp to omega-agent-v2/api/ and change agent_loop import OR
  PYTHONPATH includes nexus and use:
    from metered_chat_completion import chat_completion
"""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional

NEXUS = Path.home() / ".omega" / "nexus"
sys.path.insert(0, str(NEXUS))


def chat_completion(
    messages: List[Dict[str, Any]],
    model: Optional[str] = None,
    temperature: float = 0.3,
    max_tokens: int = 2048,
    tools: Optional[list] = None,
    **kwargs,
) -> Dict[str, Any]:
    """Return OpenAI-shaped dict like Groq client for agent_loop compatibility."""
    # Prefer metered OpenRouter
    try:
        from metered_llm import chat as metered_chat

        # tools not fully supported in thin metered wrapper yet — plain complete
        if not tools:
            est = max(0.01, (max_tokens / 1000.0) * 0.02)
            r = metered_chat(
                messages=[{"role": m.get("role"), "content": m.get("content") or ""} for m in messages],
                model=model or os.environ.get("OPENROUTER_DEFAULT_MODEL") or "openai/gpt-4o-mini",
                max_tokens=max_tokens,
                estimated_cost=est,
            )
            if r.get("ok"):
                return {
                    "choices": [{"message": {"role": "assistant", "content": r["text"]}, "finish_reason": "stop"}],
                    "usage": r.get("usage") or {},
                    "model": r.get("model"),
                    "id": r.get("id"),
                    "omega_metered": True,
                    "omega_spend": r.get("spend"),
                }
            # budget gate or 402 — surface clearly
            return {
                "choices": [{"message": {"role": "assistant", "content": "[METERED_BLOCKED] %s" % json.dumps(r)[:500]}, "finish_reason": "stop"}],
                "error": r,
                "omega_metered": True,
            }
    except Exception as e:
        blocked = str(e)

    # Fallback: original groq if key works
    try:
        from api.groq_client import chat_completion as groq_chat

        return groq_chat(messages, model=model, temperature=temperature, max_tokens=max_tokens, tools=tools, **kwargs)
    except Exception as e2:
        return {
            "choices": [{"message": {"role": "assistant", "content": "[NO_LLM] metered failed; groq failed: %s / %s" % (blocked if "blocked" in dir() else "", e2)}, "finish_reason": "stop"}],
            "error": str(e2),
        }


if __name__ == "__main__":
    out = chat_completion([{"role": "user", "content": "Reply exactly: METERED_ADAPTER_OK"}], max_tokens=20)
    print(json.dumps(out, indent=2, default=str)[:1500])
