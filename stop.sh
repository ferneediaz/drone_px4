#!/usr/bin/env bash
# Stop PX4 and Gazebo.
#   ./stop.sh         stop the simulation, keep the container running
#   ./stop.sh --all   also stop the container
set -euo pipefail
cd "$(dirname "$0")"

case "${1:-}" in
  ""|--all) ;;
  *) echo "Usage: ./stop.sh [--all]"; exit 2 ;;
esac

if docker compose ps --status running --services 2>/dev/null | grep -qx px4; then
  # Run pkill directly, not through `sh -c`: with -f it would match and kill that shell too.
  docker compose exec -T px4 pkill -x px4 || true
  docker compose exec -T px4 pkill -f "gz sim" || true
  echo "Simulation stopped."
fi

if [[ "${1:-}" == "--all" ]]; then
  docker compose down
fi
