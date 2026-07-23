import os
from fastapi import FastAPI, Depends, Security, HTTPException, status
from fastapi.security.api_key import APIKeyHeader
from fastapi.middleware.cors import CORSMiddleware
from api.routes.sync import router as sync_router
from api.routes.chat import router as chat_router

API_KEY_NAME = "X-Omega-API-Key"
api_key_header = APIKeyHeader(name=API_KEY_NAME, auto_error=False)

def get_api_key(header_key: str = Security(api_key_header)):
    secret_key = os.getenv("OMEGA_API_KEY")
    if not secret_key:
        raise HTTPException(status_code=500, detail="OMEGA_API_KEY not configured on server.")
    if header_key == secret_key:
        return header_key
    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail="Invalid or missing X-Omega-API-Key credentials."
    )

def create_app() -> FastAPI:
    app = FastAPI(
        title="Omega Agent API",
        version="1.0.0",
        docs_url="/docs",
        openapi_url="/openapi.json"
    )

    allowed_origins = os.getenv("ALLOWED_ORIGINS", "").split(",") if os.getenv("ALLOWED_ORIGINS") else []
    app.add_middleware(
        CORSMiddleware,
        allow_origins=allowed_origins or ["http://localhost:5173"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(sync_router, dependencies=[Depends(get_api_key)])
    app.include_router(chat_router, dependencies=[Depends(get_api_key)])

    @app.get("/health", tags=["system"])
    async def health_check():
        return {"status": "healthy"}

    return app

app = create_app()
