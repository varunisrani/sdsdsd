# syntax=docker/dockerfile:1

# Build stage
FROM node:22-alpine AS builder
WORKDIR /build

# Copy package files
COPY src/package*.json ./

# Install production dependencies only
RUN npm ci --only=production --no-audit --no-fund && \
    # Remove only test directories - don't break packages
    find node_modules -type d -name "test" -prune -exec rm -rf {} \; 2>/dev/null || true && \
    find node_modules -type d -name "tests" -prune -exec rm -rf {} \; 2>/dev/null || true

# Install Claude SDK separately to control its installation
RUN npm install -g @anthropic-ai/claude-code --production && \
    npm cache clean --force

# Runtime stage
FROM node:22-alpine
WORKDIR /app

# Install only tini for signal handling (28KB)
RUN apk --no-cache add tini && \
    rm -rf /var/cache/apk/*

# Copy Claude SDK from builder
COPY --from=builder /usr/local/lib/node_modules/@anthropic-ai/claude-code /usr/local/lib/node_modules/@anthropic-ai/claude-code

# Copy production dependencies from builder
COPY --from=builder /build/node_modules ./node_modules

# Copy application files
COPY src/index.mjs src/package.json ./
COPY scripts/docker-entrypoint.sh ./

# Set executable permissions
RUN chmod +x docker-entrypoint.sh

# Keep npm for debugging if needed - it's already installed

EXPOSE 8080

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["./docker-entrypoint.sh"]