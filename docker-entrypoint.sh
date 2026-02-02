#!/bin/bash
set -e

# Fix permissions on data directory (Railway mounts as root)
if [ -d "/data" ]; then
  mkdir -p /data/.openclaw /data/workspace 2>/dev/null || true
  chown -R node:node /data 2>/dev/null || true
fi

# If this is the default CMD and we have a gateway token, start the gateway with it
if [ "$1" = "node" ] && [ "$2" = "dist/index.js" ] && [ -z "$3" ]; then
  # Default CMD without arguments - start gateway with token
  if [ -n "$OPENCLAW_GATEWAY_TOKEN" ]; then
    exec node dist/index.js gateway --allow-unconfigured --port "${PORT:-8080}" --bind lan --token "$OPENCLAW_GATEWAY_TOKEN"
  else
    exec node dist/index.js gateway --allow-unconfigured --port "${PORT:-8080}" --bind lan
  fi
fi

# Execute the provided command
exec "$@"
