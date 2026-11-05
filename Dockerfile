# PX4 SITL + Gazebo Harmonic + MAVSDK on Ubuntu 22.04 (runs natively on Apple Silicon / arm64)
FROM ubuntu:22.04

ARG PX4_VERSION=v1.16.2
ARG USERNAME=px4
ARG VNC_PASSWORD=px4px4

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Taipei \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# Base tools + a tiny VNC desktop for the Gazebo GUI
RUN apt-get update && apt-get install -y --no-install-recommends \
        sudo git ca-certificates curl wget lsb-release gnupg tzdata locales \
        python3 python3-pip python3-dev build-essential nano less iproute2 \
        tigervnc-standalone-server tigervnc-common tigervnc-tools fluxbox xterm \
        mesa-utils libgl1-mesa-dri dbus-x11 \
    && rm -rf /var/lib/apt/lists/*

# Non-root user with passwordless sudo (PX4's setup script expects sudo)
RUN useradd -m -s /bin/bash ${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
    && echo 'Defaults env_keep += "DEBIAN_FRONTEND TZ"' >> /etc/sudoers.d/${USERNAME}

COPY --chmod=755 scripts/entrypoint.sh scripts/sim scripts/sim-gui /usr/local/bin/

USER ${USERNAME}
WORKDIR /home/${USERNAME}
ENV PATH=/home/${USERNAME}/.local/bin:${PATH}

# PX4 Autopilot source (pinned stable release)
RUN git clone --recursive -b ${PX4_VERSION} https://github.com/PX4/PX4-Autopilot.git

# PX4's official dependency script: toolchain + Gazebo Harmonic (skip NuttX/Pixhawk toolchain)
RUN bash ./PX4-Autopilot/Tools/setup/ubuntu.sh --no-nuttx \
    && sudo rm -rf /var/lib/apt/lists/*

# Pre-build SITL so the first `sim` starts fast
RUN cd PX4-Autopilot && make px4_sitl

# MAVSDK Python + MAVProxy (used to forward MAVLink to QGroundControl on the Mac)
RUN python3 -m pip install --user --no-cache-dir mavsdk aioconsole MAVProxy

# VNC password for the Gazebo GUI desktop
RUN mkdir -p ~/.vnc && echo "${VNC_PASSWORD}" | vncpasswd -f > ~/.vnc/passwd && chmod 600 ~/.vnc/passwd

# Claude Code CLI. Login and settings live in CLAUDE_CONFIG_DIR, a volume in docker-compose.yml.
# The directory is created here so the volume is owned by the non-root user.
ENV CLAUDE_CONFIG_DIR=/home/${USERNAME}/.claude
RUN mkdir -p "${CLAUDE_CONFIG_DIR}" \
    && curl -fsSL https://claude.ai/install.sh | bash \
    && claude --version

EXPOSE 5901
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["sleep", "infinity"]
