# file: omega_self_monitor.py
"""Self‑monitoring utilities for Omega.

Features:
- Record a timestamp, request text, response text, and processing time.
- Append each record as a JSON line to `omega_metrics.log`.
- Provide a helper to load recent metrics for analysis.
"""
import json
import time
from pathlib import Path
from typing import Dict, Any, List

LOG_FILE = Path("omega_metrics.log")

def _ensure_log_file():
    """Create the log file if it does not exist."""
    if not LOG_FILE.exists():
        LOG_FILE.touch()

def log_interaction(request: str, response: str, duration_sec: float) -> None:
    """Append a single interaction record to the log.

    Args:
        request: The raw user input.
        response: The raw assistant output.
        duration_sec: Processing time in seconds.
    """
    _ensure_log_file()
    record: Dict[str, Any] = {
        "timestamp": time.time(),
        "request": request,
        "response": response,
        "duration_sec": duration_sec,
        "request_len": len(request),
        "response_len": len(response),
    }
    with LOG_FILE.open("a", encoding="utf-8") as f:
        f.write(json.dumps(record) + "\n")

def load_recent(n: int = 100) -> List[Dict[str, Any]]:
    """Load the most recent *n* interaction records.

    Returns:
        A list of dictionaries ordered from newest to oldest.
    """
    if not LOG_FILE.exists():
        return []
    with LOG_FILE.open("r", encoding="utf-8") as f:
        lines = f.readlines()[-n:]
    return [json.loads(line) for line in reversed(lines)]

# Example usage within Omega's main loop (pseudo‑code):
#
# import time
# from omega_self_monitor import log_interaction
#
# def handle_request(user_input):
#     start = time.time()
#     response = generate_response(user_input)  # existing reasoning chain
#     duration = time.time() - start
#     log_interaction(user_input, response, duration)
#     return response
