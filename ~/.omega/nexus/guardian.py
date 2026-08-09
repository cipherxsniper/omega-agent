#!/usr/bin/env python3
"""Omega Nexus Guardian — local signed command runner."""
from __future__ import annotations
import json, os, re, subprocess, time
from pathlib import Path
from datetime import datetime, timezone

NEXUS = Path.home() / ".omega" / "nexus"
INBOX = NEXUS / "inbox"
OUTBOX = NEXUS / "outbox"
PROPOSALS = NEXUS / "proposals"
LOGS = NEXUS / "logs"
WORKSPACE = Path(os.environ.get("OMEGA_WORKSPACE", Path.home() / "omega_workspace"))

BLOCK = re.compile(
    r"(stripe|issuing|mint_card|psql.*(UPDATE|INSERT|DELETE)|git\s+push|rm\s+-rf|DROP\s+TABLE)",
    re.I,
)

def log(msg: str):
    ts = datetime.now(timezone.utc).isoformat()
    line = f"{ts} {msg}\n"
    print(line, end="")
    (LOGS / "guardian.log").open("a").write(line)

def run_safe(cmd: str, timeout: int = 30) -> dict:
    if BLOCK.search(cmd):
        return {"status": "BLOCKED", "reason": "high-risk pattern", "cmd": cmd}
    try:
        r = subprocess.run(
            cmd, shell=True, cwd=str(WORKSPACE),
            capture_output=True, text=True, timeout=timeout,
        )
        return {
            "status": "OK" if r.returncode == 0 else "ERROR",
            "returncode": r.returncode,
            "stdout": (r.stdout or "")[-4000:],
            "stderr": (r.stderr or "")[-2000:],
            "cmd": cmd,
        }
    except subprocess.TimeoutExpired:
        return {"status": "TIMEOUT", "cmd": cmd}
    except Exception as e:
        return {"status": "EXCEPTION", "error": str(e), "cmd": cmd}

def process_one(path: Path):
    try:
        data = json.loads(path.read_text())
    except Exception as e:
        log(f"bad json {path.name}: {e}")
        path.rename(path.with_suffix(".bad"))
        return
    cmd = data.get("cmd") or data.get("command")
    if not cmd:
        path.unlink(missing_ok=True)
        return
    if BLOCK.search(cmd) or data.get("require_approval"):
        dest = PROPOSALS / f"{int(time.time())}_{path.name}"
        dest.write_text(json.dumps(data, indent=2))
        result = {"status": "PROPOSED", "proposal": str(dest), "cmd": cmd}
    else:
        result = run_safe(cmd, timeout=data.get("timeout", 30))
    result["task_id"] = data.get("task_id") or path.stem
    result["processed_at"] = datetime.now(timezone.utc).isoformat()
    (OUTBOX / f"{result['task_id']}.json").write_text(json.dumps(result, indent=2))
    log(f"processed {path.name} → {result['status']}")
    path.unlink(missing_ok=True)

def main():
    log("guardian started")
    for d in (INBOX, OUTBOX, PROPOSALS, LOGS):
        d.mkdir(parents=True, exist_ok=True)
    while True:
        for p in sorted(INBOX.glob("*.json")):
            process_one(p)
        time.sleep(1.5)

if __name__ == "__main__":
    main()
