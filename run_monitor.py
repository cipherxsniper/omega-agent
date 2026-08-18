#!/usr/bin/env python3
"""Demo runner for omega_self_monitor.py in Termux.
It simulates a user request, generates a dummy response, and logs the interaction.
Replace the dummy response generation with Omega's real response logic as needed.
"""
import time
from omega_self_monitor import log_interaction

def dummy_response(request: str) -> str:
    # Simple echo response; replace with actual reasoning chain.
    return f"Echo: {request}"

if __name__ == '__main__':
    user_input = "sample user request"
    start = time.time()
    resp = dummy_response(user_input)
    duration = time.time() - start
    log_interaction(user_input, resp, duration)
    print("Logged interaction:")
    print(f"Request: {user_input}\nResponse: {resp}\nDuration: {duration:.3f}s")
