import os
from fastapi import FastAPI, Depends, Security, HTTPException, status
from fastapi.security.api_key import APIKeyHeader
from fastapi.middleware.cors import CORSMiddleware
from api.routes.sync import router as sync_router

# API configurations
API_KEY_NAME = "X-Omega-API-Key"
api_key_header = APIKeyHeader(name=API_KEY_NAME, auto_error=False)

def get_api_key(header_key: str = Security(api_key_header)):
    """Simple API Key validation middleware."""
    secret_key = os.getenv("OMEGA_API_KEY", "omega-super-secret-sync-token")
    if header_key == secret_key:
        return header_key
    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail="Invalid or missing X-Omega-API-Key credentials."
    )

def create_app() -> FastAPI:
    app = FastAPI(
        title="OMEGA AGENT 2-Way Sync Engine",
        description="Enterprise grade production-ready orchestration synchronization API between Base44 and GitHub.",
        version="1.0.0",
        docs_url="/docs",
        openapi_url="/openapi.json"
    )

    # Middleware Setup
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Include routes with security dependency
    app.include_router(sync_router, dependencies=[Depends(get_api_key)])

    @app.get("/health", tags=["system"])
    async def health_check():
        """Health probe endpoint."""
        return {
            "status": "healthy",
            "uptime": "nominal",
            "api_key_auth": "enabled",
            "sync_services": "active"
        }

    return app

app = create_app()
