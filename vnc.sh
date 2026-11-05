#!/usr/bin/env bash
# Open the container's VNC desktop (Gazebo GUI) from the Mac.
#   ./vnc.sh         start the container if needed, open the VNC viewer
#   ./vnc.sh --sim   same, and also launch `sim-gui` in a new Terminal window
set -euo pipefail
cd "$(dirname "$0")"

PORT=5901
PASS=px4px4

# 1) Make sure the container is running
if ! docker compose ps --status running --services 2>/dev/null | grep -qx px4; then
  echo "Starting container..."
  docker compose up -d
fi

# 2) Wait for the VNC server inside the container
echo -n "Waiting for VNC on localhost:$PORT"
for _ in $(seq 1 20); do
  nc -z localhost "$PORT" 2>/dev/null && break
  echo -n "."; sleep 1
done
echo
if ! nc -z localhost "$PORT" 2>/dev/null; then
  echo "VNC isn't reachable. Check the log with:"
  echo "  docker compose exec px4 cat /tmp/xvnc.log"
  exit 1
fi

# 3) Optionally start the simulator with the Gazebo window (interactive pxh> in its own Terminal)
if [[ "${1:-}" == "--sim" ]]; then
  echo "Launching sim-gui in a new Terminal window..."
  osascript -e "tell application \"Terminal\" to do script \"cd '$PWD' && docker compose exec px4 sim-gui\"" >/dev/null
fi

# 4) Open a viewer: TigerVNC (no password prompt) or macOS Screen Sharing as fallback
TIGER_BIN=$(ls /Applications/TigerVNC.app/Contents/MacOS/* 2>/dev/null | head -n 1 || true)
if [[ -n "$TIGER_BIN" ]]; then
  docker compose cp px4:/home/px4/.vnc/passwd ./.vncpasswd >/dev/null 2>&1 || true
  if [[ -s ./.vncpasswd ]]; then
    nohup "$TIGER_BIN" -passwd ./.vncpasswd "localhost:$PORT" >/dev/null 2>&1 &
  else
    nohup "$TIGER_BIN" "localhost:$PORT" >/dev/null 2>&1 &
    echo "Password: $PASS"
  fi
  echo "Opened TigerVNC Viewer -> localhost:$PORT"
else
  open "vnc://:${PASS}@localhost:${PORT}"
  echo "Opened macOS Screen Sharing -> localhost:$PORT"
fi
