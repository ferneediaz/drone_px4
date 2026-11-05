#!/usr/bin/env bash
# 1) VNC desktop on :1 (port 5901) so the Gazebo GUI can be viewed from the Mac
if [ "${ENABLE_VNC:-1}" = "1" ]; then
  Xvnc :1 -geometry "${VNC_GEOMETRY:-1600x900}" -depth 24 \
       -rfbauth "$HOME/.vnc/passwd" -localhost no -AlwaysShared \
       >/tmp/xvnc.log 2>&1 &
  sleep 1
  DISPLAY=:1 fluxbox >/tmp/fluxbox.log 2>&1 &
fi

# 2) PX4 sends its ground-station MAVLink to udp 14550 *inside* the container.
#    MAVProxy relays it out to QGroundControl running natively on the Mac.
if [ "${ENABLE_QGC_FORWARD:-1}" = "1" ]; then
  mkdir -p /tmp/mavproxy
  mavproxy.py --master=udpin:127.0.0.1:14550 \
              --out=udp:"${GCS_HOST:-host.docker.internal}":14550 \
              --daemon --non-interactive --state-basedir=/tmp/mavproxy \
              >/tmp/mavproxy.log 2>&1 &
fi

exec "$@"
