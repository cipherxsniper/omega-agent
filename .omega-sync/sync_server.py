#!/data/data/com.termux/files/usr/bin/python3
import hashlib
import hmac
import io
import json
import os
import pathlib
import secrets
import tarfile
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

ROOT = pathlib.Path(os.environ["OMEGA_SYNC_ROOT"]).resolve()
TOKEN = pathlib.Path(os.environ["OMEGA_SYNC_TOKEN"]).read_text().strip()
PORT = int(os.environ.get("OMEGA_SYNC_PORT", "8787"))
MAX_BYTES = 8 * 1024 * 1024
ALLOWED = {
    "agent/chat_server.py",
    "src/lib/localEntities.js",
    "src/pages/Home.jsx",
}

class Handler(BaseHTTPRequestHandler):
    server_version = "OmegaScopedSync/1.0"

    def log_message(self, fmt, *args):
        print("[sync] " + fmt % args, flush=True)

    def send_json(self, status, body):
        encoded = json.dumps(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(encoded)))
        self.end_headers()
        self.wfile.write(encoded)

    def authorized(self):
        value = self.headers.get("Authorization", "")
        supplied = value.removeprefix("Bearer ").strip()
        return bool(supplied) and hmac.compare_digest(supplied, TOKEN)

    def do_GET(self):
        if not self.authorized():
            self.send_json(401, {"error": "unauthorized"})
            return
        if self.path == "/sync/health":
            self.send_json(200, {"status": "ok", "service": "omega-scoped-sync", "allowlist": sorted(ALLOWED)})
            return
        self.send_json(404, {"error": "not_found"})

    def do_POST(self):
        if not self.authorized():
            self.send_json(401, {"error": "unauthorized"})
            return
        if self.path != "/sync/apply":
            self.send_json(404, {"error": "not_found"})
            return
        try:
            length = int(self.headers.get("Content-Length", "0"))
        except ValueError:
            length = 0
        if length <= 0 or length > MAX_BYTES:
            self.send_json(413, {"error": "invalid_or_oversized_payload"})
            return
        payload = self.rfile.read(length)
        archive = tarfile.open(fileobj=io.BytesIO(payload), mode="r:gz")
        members = [m for m in archive.getmembers() if m.isfile()]
        names = {m.name.lstrip("./") for m in members}
        if names != ALLOWED:
            self.send_json(400, {"error": "archive_must_contain_exact_allowlist", "received": sorted(names), "required": sorted(ALLOWED)})
            return
        staged = ROOT / ".omega-sync-staged-" + secrets.token_hex(8)
        staged.mkdir(mode=0o700)
        try:
            for member in members:
                name = member.name.lstrip("./")
                if name not in ALLOWED or "/../" in f"/{name}" or name.startswith("../"):
                    raise ValueError("unsafe archive path")
                target = staged / name
                target.parent.mkdir(parents=True, exist_ok=True)
                source = archive.extractfile(member)
                if source is None:
                    raise ValueError("missing file data")
                target.write_bytes(source.read())
                target.chmod(0o600)
            for name in sorted(ALLOWED):
                source = staged / name
                target = ROOT / name
                backup = target.with_suffix(target.suffix + ".sync-backup")
                if target.exists():
                    target.replace(backup)
                source.replace(target)
            self.send_json(200, {"status": "applied", "files": sorted(ALLOWED), "timestamp": time.time()})
        except Exception as exc:
            self.send_json(500, {"error": str(exc)})
        finally:
            for path in sorted(staged.rglob("*"), reverse=True):
                if path.is_file():
                    path.unlink(missing_ok=True)
                elif path.is_dir():
                    path.rmdir()
            staged.rmdir()

ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
