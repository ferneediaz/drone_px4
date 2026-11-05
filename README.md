# PX4 SITL in Docker (Ubuntu 22.04)

Inside the container: Ubuntu 22.04, PX4 v1.16.2, Gazebo Harmonic, MAVSDK Python, MAVProxy.
On the Mac (already installed): Docker Desktop, QGroundControl, VS Code.

## First time (20-40 min build)
Docker Desktop > Settings > Resources: give it at least 8 GB RAM and 4+ CPUs.

    cd ~/workspace/px4-docker
    docker compose up -d --build

## Quick start (from a Mac terminal)
    ./start.sh              # Docker, QGroundControl, PX4 and the Gazebo window
    ./start.sh --headless   # same, with no Gazebo window (faster)
    ./stop.sh               # stop PX4 and Gazebo
    ./stop.sh --all         # also stop the container

## VS Code Dev Container (recommended)
Open ~/workspace/px4-docker in VS Code -> Cmd+Shift+P -> "Dev Containers: Reopen in Container".
Then Cmd+Shift+P -> "Tasks: Run Task" -> PX4: sim / sim-gui / MAVSDK test.
F5 debugs the open Python file. ./vnc.sh still runs from a Mac terminal.
PX4 source is at /home/px4/PX4-Autopilot (File > Add Folder to Workspace to browse it).

## Every day (without VS Code)
    docker compose up -d          # start
    docker compose exec px4 bash  # shell inside Ubuntu
    sim                           # PX4 + Gazebo, headless (fast)
    sim-gui                       # same, with the Gazebo window on VNC
    docker compose down           # stop

- QGroundControl (Mac): just open it - it connects automatically on UDP 14550.
- Gazebo window: ./vnc.sh opens the VNC viewer (localhost:5901, password px4px4).
  ./vnc.sh --sim also starts sim-gui in a new Terminal window.
- MAVSDK test (second shell, while sim runs): python3 ~/code/takeoff_land.py
- ~/workspace/px4-docker/code on the Mac = ~/code in the container. Edit in VS Code.
- PX4 shell commands: type them at the `pxh>` prompt (e.g. `commander takeoff`).
- Claude Code: run `claude` in any container shell. Sign in once; the login is kept in the
  px4-claude-config volume across rebuilds (`docker volume rm px4-claude-config` clears it).

## Hardware later
Cube Orange flashing and the USB telemetry radio go through QGroundControl on the Mac,
not the container (Docker Desktop on macOS can't pass USB devices through).
