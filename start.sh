#!/usr/bin/env bash
# Start everything from the Mac: Docker, the container, QGroundControl, PX4 and Gazebo.
#   ./start.sh              PX4 + Gazebo window (over VNC)
#   ./start.sh --headless   PX4 + Gazebo with no window (faster)
# PX4's pxh> prompt opens in its own Terminal window. Stop everything with ./stop.sh
set -euo pipefail
cd "$(dirname "$0")"

case "${1:-}" in
  "")         SIM_CMD=sim-gui ;;
  --headless) SIM_CMD=sim ;;
  *)          echo "Usage: ./start.sh [--headless]"; exit 2 ;;
esac

# 1) Docker Desktop
if ! docker info >/dev/null 2>&1; then
  echo -n "Starting Docker Desktop"
  open -a Docker
  for _ in $(seq 1 60); do
    docker info >/dev/null 2>&1 && break
    echo -n "."; sleep 2
  done
  echo
  docker info >/dev/null 2>&1 || { echo "Docker didn't start. Open Docker Desktop and try again."; exit 1; }
fi

# 2) Container
if ! docker compose ps --status running --services 2>/dev/null | grep -qx px4; then
  echo "Starting container..."
  docker compose up -d
fi

# 3) QGroundControl: connects by itself once PX4 is up
open -a QGroundControl

# 4) PX4 + Gazebo, unless already running. Exited processes linger as zombies in this
#    container, so ignore those (state Z) when looking for a live px4.
if docker compose exec -T px4 sh -c \
     "ps -eo stat=,comm= | awk '\$1 !~ /^Z/ && \$2 == \"px4\" {found=1} END {exit !found}'"; then
  echo "PX4 is already running, so I'm not starting another. Use ./stop.sh to restart it."
else
  echo "Starting $SIM_CMD in a new Terminal window..."
  osascript -e "tell application \"Terminal\" to do script \"cd '$PWD' && docker compose exec px4 $SIM_CMD\"" \
            -e 'tell application "Terminal" to activate' >/dev/null
fi

# 5) Gazebo window
if [[ "$SIM_CMD" == sim-gui ]]; then
  ./vnc.sh
fi
