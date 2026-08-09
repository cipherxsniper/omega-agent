"""
chat_server.py — HTTP bridge between the GitHub Pages chat frontend and
the real agent_loop.py tool-use loop. No new agent logic here — this is
just a thin, honest transport layer.

Background-job model added: /api/chat still works synchronously for
quick tasks, but /api/job/start launches a long-running task in a
background thread and returns immediately with a job ID. Poll
/api/job/<id> for status - this is what makes long autonomous sessions
possible instead of every task being bound to one blocking HTTP request.
"""
import os
import sys
import logging
import threading
import uuid
import time

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from flask import Flask, request, jsonify
from flask_cors import CORS

from agent.agent_loop import run_agent_task

logger = logging.getLogger("OmegaChatServer")
logging.basicConfig(level=logging.INFO)

app = Flask(__name__)

ALLOWED_ORIGIN = os.getenv("OMEGA_ALLOWED_ORIGIN", "https://YOUR-USERNAME.github.io")
CORS(app, resources={r"/api/*": {"origins": ALLOWED_ORIGIN}})

LOG_PATH = os.path.expanduser("~/.omega/logs/agent_loop_signed.log")

CWD_HINT = os.path.expanduser("~/omega_workspace") + (
    " — this contains all Omega repos as subdirectories: "
    "OMEGAOPS.AI, omega, Omega-Ecosystem-App, omega-art-studio, "
    "omega-fintech, omega-financial-core, Omega-Core, "
    "omega-agent-v2, Omega_Finacial_Network. Use paths like "
    "'OMEGAOPS.AI/omega_v10.py' relative to this root."
)

# In-memory job store. Lost on server restart - acceptable for now since
# jobs are re-startable and the todo state (via write_todos) is what's
# actually durable across restarts, not this dict.
_jobs = {}
_jobs_lock = threading.Lock()


def _run_job(job_id, message, max_steps):
    with _jobs_lock:
        _jobs[job_id]["status"] = "running"
    try:
        transcript = run_agent_task(
            message,
            max_steps=max_steps,
            signed_log=LOG_PATH,
            cwd_hint=CWD_HINT,
            require_plan=True,
        )
        final_entry = next((e for e in reversed(transcript) if e.get("final")), None)
        final_text = final_entry["content"] if final_entry else "(no final response — see transcript)"
        with _jobs_lock:
            _jobs[job_id].update({
                "status": "done",
                "response": final_text,
                "transcript": transcript,
                "finished_at": time.time(),
            })
    except Exception as e:
        logger.error(f"Job {job_id} failed: {e}", exc_info=True)
        with _jobs_lock:
            _jobs[job_id].update({
                "status": "failed",
                "error": str(e),
                "finished_at": time.time(),
            })


@app.route("/api/health", methods=["GET"])
def health():
    return jsonify({"status": "ok"})


@app.route("/api/chat", methods=["POST"])
def chat():
    """Synchronous path - unchanged behavior, for quick tasks. Blocks
    until done or max_steps is hit."""
    body = request.get_json(silent=True) or {}
    message = body.get("message", "").strip()
    max_steps = int(body.get("max_steps", 10))

    if not message:
        return jsonify({"error": "Missing 'message' in request body"}), 400

    try:
        transcript = run_agent_task(
            message,
            max_steps=max_steps,
            signed_log=LOG_PATH,
            cwd_hint=CWD_HINT,
        )
    except Exception as e:
        logger.error(f"Agent task failed: {e}", exc_info=True)
        return jsonify({"error": f"Agent execution failed: {e}"}), 500

    final_entry = next((e for e in reversed(transcript) if e.get("final")), None)
    final_text = final_entry["content"] if final_entry else "(no final response — see transcript)"

    return jsonify({
        "response": final_text,
        "transcript": transcript,
    })


@app.route("/api/job/start", methods=["POST"])
def job_start():
    """Background path - for long autonomous tasks. Returns immediately
    with a job_id instead of blocking; poll /api/job/<id> for status.
    require_plan is forced on here, since long-running tasks are exactly
    where a durable plan matters most."""
    body = request.get_json(silent=True) or {}
    message = body.get("message", "").strip()
    max_steps = int(body.get("max_steps", 100))

    if not message:
        return jsonify({"error": "Missing 'message' in request body"}), 400

    job_id = str(uuid.uuid4())
    with _jobs_lock:
        _jobs[job_id] = {
            "status": "queued",
            "message": message,
            "max_steps": max_steps,
            "started_at": time.time(),
        }

    thread = threading.Thread(target=_run_job, args=(job_id, message, max_steps), daemon=True)
    thread.start()

    return jsonify({"job_id": job_id, "status": "queued"})


@app.route("/api/job/<job_id>", methods=["GET"])
def job_status(job_id):
    with _jobs_lock:
        job = _jobs.get(job_id)
    if job is None:
        return jsonify({"error": f"No job found with id {job_id}"}), 404
    return jsonify({"job_id": job_id, **job})


@app.route("/api/job", methods=["GET"])
def job_list():
    """List all known jobs (in-memory, this process's lifetime only)."""
    with _jobs_lock:
        summary = {
            jid: {"status": j["status"], "message": j["message"][:100], "started_at": j["started_at"]}
            for jid, j in _jobs.items()
        }
    return jsonify(summary)


if __name__ == "__main__":
    port = int(os.getenv("PORT", 8420))
    app.run(host="0.0.0.0", port=port, threaded=True)
