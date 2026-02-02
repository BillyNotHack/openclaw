FROM node:22-bookworm AS base

# Cache bust: 2026-02-02-v8 - enable channel plugins by default
ARG CACHEBUST=1

# Install Bun (required for build scripts)
RUN echo "Build timestamp: $(date)" && curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

RUN corepack enable

# Install system libraries (some plugins may need browser automation)
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    libnss3 libnspr4 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 \
    libxkbcommon0 libxcomposite1 libxdamage1 libxfixes3 libxrandr2 \
    libgbm1 libasound2 libpango-1.0-0 libcairo2 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

ARG OPENCLAW_DOCKER_APT_PACKAGES=""
RUN if [ -n "$OPENCLAW_DOCKER_APT_PACKAGES" ]; then \
      apt-get update && \
      DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends $OPENCLAW_DOCKER_APT_PACKAGES && \
      apt-get clean && \
      rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*; \
    fi

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml .npmrc ./
COPY ui/package.json ./ui/package.json
COPY patches ./patches
COPY scripts ./scripts

# Copy extension package.json files (workspace packages must exist before pnpm install)
COPY extensions/ ./extensions/

RUN pnpm install --frozen-lockfile

# Install Playwright browser (optional, for browser automation plugins)
RUN pnpm exec playwright-core install chromium && pnpm exec playwright-core install-deps chromium

COPY . .
RUN OPENCLAW_A2UI_SKIP_MISSING=1 pnpm build
# Force pnpm for UI build (Bun may fail on ARM/Synology architectures)
ENV OPENCLAW_PREFER_PNPM=1
RUN pnpm ui:build

ENV NODE_ENV=production
# Explicitly set bundled plugins directory (auto-discovery may fail in Docker)
ENV OPENCLAW_BUNDLED_PLUGINS_DIR=/app/extensions

# Allow non-root user to write temp files during runtime/tests.
RUN chown -R node:node /app

# Copy entrypoint script (handles volume permissions for Railway/cloud deployments)
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Note: USER node is removed to allow entrypoint to fix volume permissions
# The entrypoint runs as root briefly to fix /data permissions, then the app runs

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["node", "dist/index.js"]
