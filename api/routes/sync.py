import os
import requests
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional

router = APIRouter(prefix="/sync", tags=["sync"])

GITHUB_API = "https://api.github.com"
GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN")
REPO_OWNER = os.environ.get("GITHUB_OWNER", "cipherxsniper")
REPO_NAME = os.environ.get("GITHUB_REPO", "omega-agent")

def gh_headers():
    if not GITHUB_TOKEN:
        raise HTTPException(status_code=500, detail="GITHUB_TOKEN not configured")
    return {"Authorization": f"Bearer {GITHUB_TOKEN}", "Accept": "application/vnd.github+json"}

@router.get("/status")
async def get_sync_status():
    """Real status of the omega-agent repo — actual API call, not mocked."""
    resp = requests.get(f"{GITHUB_API}/repos/{REPO_OWNER}/{REPO_NAME}", headers=gh_headers())
    if not resp.ok:
        raise HTTPException(status_code=502, detail=f"GitHub API error: {resp.status_code}")
    data = resp.json()
    return {
        "repository": f"{REPO_OWNER}/{REPO_NAME}",
        "default_branch": data.get("default_branch"),
        "pushed_at": data.get("pushed_at"),
        "open_issues": data.get("open_issues_count"),
    }

@router.get("/history")
async def get_sync_history(limit: int = 10):
    """Real commit history — actual API call."""
    resp = requests.get(
        f"{GITHUB_API}/repos/{REPO_OWNER}/{REPO_NAME}/commits",
        headers=gh_headers(),
        params={"per_page": limit},
    )
    if not resp.ok:
        raise HTTPException(status_code=502, detail=f"GitHub API error: {resp.status_code}")
    commits = resp.json()
    return {
        "records_returned": len(commits),
        "history": [
            {
                "sha": c["sha"][:7],
                "message": c["commit"]["message"].split("\n")[0],
                "author": c["commit"]["author"]["name"],
                "date": c["commit"]["author"]["date"],
            }
            for c in commits
        ],
    }
