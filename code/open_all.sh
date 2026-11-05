#!/usr/bin/env bash
# Run inside the container: opens QGroundControl and the VNC viewer on the Mac, then starts
# PX4 + Gazebo in this terminal (the pxh> prompt). Usage: ~/code/open_all.sh [target]
# Opening the Mac apps needs one setup step on the Mac: ./mac_open_apps.sh --install
set -u

BRIDGE="$(cd "$(dirname "$0")" && pwd)/.mac_open"

if [[ ! -s "$BRIDGE/key" ]]; then
  echo "Skipping QGroundControl and VNC: on the Mac, run ./mac_open_apps.sh --install first."
elif ! command -v ssh >/dev/null; then
  echo "Skipping QGroundControl and VNC: no ssh here. Rebuild the container to get it."
elif ssh -i "$BRIDGE/key" -o IdentitiesOnly=yes -o BatchMode=yes -o ConnectTimeout=5 \
         -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile="$BRIDGE/known_hosts" \
         "$(cat "$BRIDGE/user")@host.docker.internal"; then
  echo "Opened QGroundControl and the VNC viewer on the Mac."
else
  echo "Couldn't reach the Mac. Check System Settings > General > Sharing > Remote Login is on."
fi

# Exited processes linger as zombies in this container, so ignore those (state Z).
if ps -eo stat=,comm= | awk '$1 !~ /^Z/ && $2 == "px4" {found=1} END {exit !found}'; then
  echo "PX4 is already running, so I'm not starting another."
else
  exec sim-gui "$@"
fi
