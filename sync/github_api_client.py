import httpx
import base64
import asyncio
import logging
from typing import Dict, List, Any, Optional

logger = logging.getLogger("omega.github_client")

class GitHubClient:
    """
    High-performance REST API v3 wrapper client for managing massive numbers of GitHub interactions.
    Implements standard enterprise patterns: rate-limiting safeguards, paging, exponential backoff retries.
    """
    def __init__(self, token: str, base_url: str = "https://api.github.com"):
        self.base_url = base_url
        self.headers = {
            "Authorization": f"token {token}",
            "Accept": "application/vnd.github.v3+json",
            "Content-Type": "application/json"
        }
        self.client = httpx.AsyncClient(headers=self.headers, timeout=30.0)

    async def _request(self, method: str, path: str, **kwargs) -> Any:
        url = f"{self.base_url}{path}"
        max_retries = 5
        backoff_factor = 2

        for attempt in range(max_retries):
            try:
                response = await self.client.request(method, url, **kwargs)
                
                # Check GitHub API rate limits
                remaining = response.headers.get("X-RateLimit-Remaining")
                if remaining and int(remaining) < 100:
                    reset_time = response.headers.get("X-RateLimit-Reset")
                    logger.warning(f"Rate limit running low! Remaining: {remaining}. Resets at {reset_time}")

                if response.status_code == 403 and "rate limit exceeded" in response.text.lower():
                    wait_time = int(response.headers.get("Retry-After", 60))
                    logger.warning(f"Rate limit exceeded. Backing off for {wait_time} seconds.")
                    await asyncio.sleep(wait_time)
                    continue

                response.raise_for_status()
                if response.status_code == 204:
                    return True
                return response.json()
            except httpx.HTTPStatusError as e:
                if attempt == max_retries - 1:
                    logger.error(f"HTTP Error on {method} {path}: {e.response.text}")
                    raise e
                await asyncio.sleep(backoff_factor ** attempt)
            except Exception as e:
                if attempt == max_retries - 1:
                    logger.error(f"Request failed: {e}")
                    raise e
                await asyncio.sleep(backoff_factor ** attempt)

    async def list_repos(self) -> List[Dict[str, Any]]:
        # Returns authenticated user's repositories with pagination
        repos = []
        page = 1
        while True:
            res = await self._request("GET", f"/user/repos?per_page=100&page={page}")
            if not res:
                break
            repos.extend(res)
            if len(res) < 100:
                break
            page += 1
        return repos

    async def create_repo(self, name: str, description: str = "", private: bool = True) -> Dict[str, Any]:
        data = {"name": name, "description": description, "private": private, "auto_init": True}
        return await self._request("POST", "/user/repos", json=data)

    async def delete_repo(self, owner: str, repo: str) -> bool:
        return await self._request("DELETE", f"/repos/{owner}/{repo}")

    async def get_contents(self, owner_repo: str, path: str, ref: Optional[str] = None) -> Dict[str, Any]:
        # owner_repo format "owner/repo" or just "repo" if authenticated user owns it.
        # Ensure it has owner prefix.
        path_url = f"/repos/{owner_repo}/contents/{path}"
        if ref:
            path_url += f"?ref={ref}"
        res = await self._request("GET", path_url)
        if isinstance(res, dict) and "content" in res and res.get("encoding") == "base64":
            res["decoded_content"] = base64.b64decode(res["content"]).decode("utf-8", errors="ignore")
        return res

    async def create_or_update_file(self, repo: str, path: str, message: str, content: str, sha: Optional[str] = None, branch: Optional[str] = None) -> Dict[str, Any]:
        encoded_content = base64.b64encode(content.encode("utf-8")).decode("utf-8")
        data = {
            "message": message,
            "content": encoded_content
        }
        if sha:
            data["sha"] = sha
        if branch:
            data["branch"] = branch
        return await self._request("PUT", f"/repos/{repo}/contents/{path}", json=data)

    async def delete_file(self, repo: str, path: str, message: str, sha: str, branch: Optional[str] = None) -> Dict[str, Any]:
        data = {
            "message": message,
            "sha": sha
        }
        if branch:
            data["branch"] = branch
        return await self._request("DELETE", f"/repos/{repo}/contents/{path}", json=data)

    async def list_commits(self, repo: str, sha: Optional[str] = None) -> List[Dict[str, Any]]:
        url = f"/repos/{repo}/commits"
        if sha:
            url += f"?sha={sha}"
        return await self._request("GET", url)

    async def get_commit(self, repo: str, commit_sha: str) -> Dict[str, Any]:
        return await self._request("GET", f"/repos/{repo}/commits/{commit_sha}")

    async def compare_commits(self, repo: str, base: str, head: str) -> Dict[str, Any]:
        return await self._request("GET", f"/repos/{repo}/compare/{base}...{head}")

    async def create_branch(self, repo: str, branch_name: str, source_branch: str = "main") -> Dict[str, Any]:
        # Get SHA of source branch
        ref_data = await self._request("GET", f"/repos/{repo}/git/ref/heads/{source_branch}")
        sha = ref_data["object"]["sha"]
        
        data = {
            "ref": f"refs/heads/{branch_name}",
            "sha": sha
        }
        return await self._request("POST", f"/repos/{repo}/git/refs", json=data)

    async def merge_branches(self, repo: str, base: str, head: str, commit_message: str) -> Dict[str, Any]:
        data = {
            "base": base,
            "head": head,
            "commit_message": commit_message
        }
        return await self._request("POST", f"/repos/{repo}/merges", json=data)

    async def list_pull_requests(self, repo: str, state: str = "open") -> List[Dict[str, Any]]:
        return await self._request("GET", f"/repos/{repo}/pulls?state={state}")

    async def create_pr(self, repo: str, title: str, head: str, base: str, body: str = "") -> Dict[str, Any]:
        data = {
            "title": title,
            "head": head,
            "base": base,
            "body": body
        }
        return await self._request("POST", f"/repos/{repo}/pulls", json=data)

    async def merge_pr(self, repo: str, pr_number: int, commit_title: str = "") -> Dict[str, Any]:
        data = {}
        if commit_title:
            data["commit_title"] = commit_title
        return await self._request("PUT", f"/repos/{repo}/pulls/{pr_number}/merge", json=data)

    async def close_client(self):
        await self.client.aclose()
