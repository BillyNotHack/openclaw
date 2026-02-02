#!/bin/bash
set -e

# Fix permissions on data directory (Railway mounts as root)
if [ -d "/data" ]; then
  mkdir -p /data/.openclaw /data/workspace 2>/dev/null || true
  chown -R node:node /data 2>/dev/null || true
fi

# Debug: log startup info
echo "[entrypoint] Starting with args: $@"
echo "[entrypoint] OPENCLAW_GATEWAY_TOKEN is ${OPENCLAW_GATEWAY_TOKEN:+set}${OPENCLAW_GATEWAY_TOKEN:-unset}"
echo "[entrypoint] PORT=${PORT:-8080}"

# If no args or default CMD, start gateway with proper auth
if [ $# -eq 0 ] || { [ "$1" = "node" ] && [ "$2" = "dist/index.js" ] && [ -z "$3" ]; }; then
  echo "[entrypoint] Starting gateway with token auth..."
  if [ -n "$OPENCLAW_GATEWAY_TOKEN" ]; then
    exec node dist/index.js gateway --allow-unconfigured --port "${PORT:-8080}" --bind lan --token "$OPENCLAW_GATEWAY_TOKEN"
  else
    echo "[entrypoint] WARNING: No OPENCLAW_GATEWAY_TOKEN set!"
    exec node dist/index.js gateway --allow-unconfigured --port "${PORT:-8080}" --bind lan
  fi
fi

# Execute the provided command
exec "$@"
