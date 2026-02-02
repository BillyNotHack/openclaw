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

# Create config file with Control UI settings (allow token-only auth, skip device pairing)
CONFIG_DIR="/data/.openclaw"
CONFIG_FILE="$CONFIG_DIR/openclaw.json"
mkdir -p "$CONFIG_DIR" 2>/dev/null || true
if [ ! -f "$CONFIG_FILE" ]; then
  echo "[entrypoint] Creating config with Control UI auth settings..."
  cat > "$CONFIG_FILE" << 'EOFCONFIG'
{
  "gateway": {
    "controlUi": {
      "allowInsecureAuth": true
    }
  }
}
EOFCONFIG
  chown node:node "$CONFIG_FILE" 2>/dev/null || true
else
  echo "[entrypoint] Config file already exists at $CONFIG_FILE"
fi

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
