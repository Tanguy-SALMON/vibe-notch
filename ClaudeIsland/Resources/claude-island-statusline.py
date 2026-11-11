#!/usr/bin/env python3
"""
Claude Island status line forwarder.
- Reads the status line JSON Claude Code passes on stdin
- Forwards the rate-limit windows to ClaudeIsland.app via Unix socket
- Chains to the user's original statusLine command (if any) and prints its output
"""
import json
import os
import socket
import subprocess
import sys

SOCKET_PATH = "/tmp/claude-island.sock"
ORIG_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "claude-island-statusline.orig")


def forward(data):
    limits = data.get("rate_limits")
    if not isinstance(limits, dict):
        return
    try:
        sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        sock.settimeout(1)
        sock.connect(SOCKET_PATH)
        sock.sendall(json.dumps({"event": "RateLimits", "rate_limits": limits}).encode())
        sock.close()
    except (socket.error, OSError):
        pass


def main():
    raw = sys.stdin.read()
    try:
        forward(json.loads(raw))
    except (json.JSONDecodeError, ValueError):
        pass

    try:
        with open(ORIG_FILE) as f:
            original = f.read().strip()
    except OSError:
        original = ""
    if original:
        try:
            out = subprocess.run(original, shell=True, input=raw, capture_output=True, text=True, timeout=10)
            sys.stdout.write(out.stdout)
        except Exception:
            pass


if __name__ == "__main__":
    main()
