#!/bin/bash

# Author:  Victor Bishop (Heretic)  |  https://github.com/Heretic312/devsecops-wrappers.git
# Date:  6/25/2025
# Unified Rathole controller script for Docker
# Usage: ./rathole_control.sh [start|stop] [compose|manual]

ACTION=$1
MODE=$2

if [[ -z "$ACTION" || -z "$MODE" ]]; then
  echo "Usage: $0 [start|stop] [compose|manual]"
  exit 1
fi

set -e

echo "[+] Action: $ACTION | Mode: $MODE"

if [[ "$ACTION" == "start" ]]; then
  if [[ "$MODE" == "compose" ]]; then
    if [ -f docker-compose.yml ]; then
      echo "[+] Starting Docker Compose stack..."
      docker-compose up -d
      echo "[✓] Rathole (compose) started."
    else
      echo "[!] docker-compose.yml not found."
      exit 1
    fi
  elif [[ "$MODE" == "manual" ]]; then
    echo "[+] Starting rathole-server..."
    docker run -d --name rathole-server \
      -v $(pwd)/server/config.toml:/config.toml \
      -p 2333:2333 -p 9000:9000 \
      rapiz1/rathole server /config.toml

    echo "[+] Starting rathole-client..."
    docker run -d --name rathole-client \
      -v $(pwd)/client/config.toml:/config.toml \
      --link rathole-server \
      rapiz1/rathole client /config.toml

    echo "[✓] Rathole (manual) started."
  else
    echo "[!] Invalid mode: $MODE"
    exit 1
  fi

elif [[ "$ACTION" == "stop" ]]; then
  if [[ "$MODE" == "compose" ]]; then
    if [ -f docker-compose.yml ]; then
      echo "[+] Stopping Docker Compose stack..."
      docker-compose down -v
      echo "[✓] Rathole (compose) stopped."
    else
      echo "[!] docker-compose.yml not found."
      exit 1
    fi
  elif [[ "$MODE" == "manual" ]]; then
    echo "[+] Stopping rathole-server and rathole-client..."
    docker stop rathole-server rathole-client 2>/dev/null || true
    docker rm rathole-server rathole-client 2>/dev/null || true
    echo "[✓] Rathole (manual) stopped and removed."
  else
    echo "[!] Invalid mode: $MODE"
    exit 1
  fi

  # Optional cleanup prompt
  echo "[?] Clean up unused Docker resources? (y/n): "
  read -r CLEANUP
  if [[ "$CLEANUP" == "y" ]]; then
    docker system prune -f
    echo "[✓] Docker system cleaned."
  else
    echo "[i] Skipping system prune."
  fi

else
  echo "[!] Invalid action: $ACTION. Use start or stop."
  exit 1
fi
