#!/bin/bash
set -e

# Fix permissions on data directory (Railway mounts as root)
if [ -d "/data" ]; then
  mkdir -p /data/.openclaw /data/workspace
  chown -R node:node /data 2>/dev/null || true
fi

# Execute the main command
exec "$@"
