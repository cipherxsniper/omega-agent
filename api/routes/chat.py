from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Dict
from api.groq_client import chat_completion

router = APIRouter(prefix="/chat", tags=["chat"])

class ChatRequest(BaseModel):
    messages: List[Dict[str, str]]  # [{"role": "user", "content": "..."}]
    model: str = "openai/gpt-oss-120b"

@router.post("")
async def chat(payload: ChatRequest):
    if not payload.messages:
        raise HTTPException(status_code=400, detail="messages cannot be empty")
    try:
        reply = chat_completion(payload.messages, model=payload.model)
    except RuntimeError as e:
        raise HTTPException(status_code=502, detail=str(e))
    return {"reply": reply, "model": payload.model}
