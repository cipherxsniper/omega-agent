import requests
import json

BASE_URL = "http://localhost:5000"  # adjust if chat_server.py binds elsewhere

def main():
    payload = {"message": "list your tools"}
    try:
        resp = requests.post(f"{BASE_URL}/api/chat", json=payload, timeout=30)
        print("Status:", resp.status_code)
        print("Body:", resp.text)
    except Exception as e:
        print("Request failed:", repr(e))

if __name__ == "__main__":
    main()
