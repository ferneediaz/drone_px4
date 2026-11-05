#!/usr/bin/env bash
# Runs on the Mac: opens QGroundControl and the VNC viewer for code/open_all.sh in the container.
#   ./mac_open_apps.sh             open the apps
#   ./mac_open_apps.sh --install   one-time setup: let the container trigger this over SSH
# The container's key can only run this script, not get a shell on the Mac. To revoke it,
# delete the px4-container-open-apps line from ~/.ssh/authorized_keys.
set -euo pipefail
cd "$(dirname "$0")"

case "${1:-}" in
  "")
    open -a QGroundControl
    if [[ -d /Applications/TigerVNC.app && -s .vncpasswd ]]; then
      open -a TigerVNC --args -passwd "$PWD/.vncpasswd" localhost:5901
    else
      open "vnc://:px4px4@localhost:5901"
    fi
    ;;
  --install)
    DIR=code/.mac_open   # gitignored; ~/code/.mac_open in the container
    mkdir -p "$DIR" && chmod 700 "$DIR"
    [[ -f "$DIR/key" ]] || ssh-keygen -q -t ed25519 -N "" -C px4-container-open-apps -f "$DIR/key"
    whoami > "$DIR/user"
    docker cp px4:/home/px4/.vnc/passwd ./.vncpasswd >/dev/null 2>&1 || true

    mkdir -p ~/.ssh && chmod 700 ~/.ssh
    touch ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys
    if ! grep -qF "$(cat "$DIR/key.pub")" ~/.ssh/authorized_keys; then
      echo "restrict,command=\"$PWD/mac_open_apps.sh\" $(cat "$DIR/key.pub")" >> ~/.ssh/authorized_keys
    fi
    echo "Done. Inside the container, run: ~/code/open_all.sh"
    ;;
  *)
    echo "Usage: ./mac_open_apps.sh [--install]"; exit 2 ;;
esac
