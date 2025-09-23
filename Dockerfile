# syntax=docker/dockerfile:1

# Web build stage
FROM node:22-alpine AS web-builder
WORKDIR /web
COPY web/package*.json ./
RUN npm ci
COPY web/ ./
RUN npm run build

# Server dependencies stage
FROM node:22-alpine AS server-builder
WORKDIR /server
COPY package*.json ./
RUN npm ci --only=production --no-audit --no-fund && \
    find node_modules -type d -name "test" -prune -exec rm -rf {} \; 2>/dev/null || true && \
    find node_modules -type d -name "tests" -prune -exec rm -rf {} \; 2>/dev/null || true

# Install Claude SDK separately
RUN npm install -g @anthropic-ai/claude-code --production && \
    npm cache clean --force

# Runtime stage
FROM node:22-alpine
WORKDIR /app

# Install tini for signal handling and tsx for TypeScript execution
RUN apk --no-cache add tini && \
    npm install -g tsx && \
    rm -rf /var/cache/apk/*

# Copy Claude SDK from server-builder
COPY --from=server-builder /usr/local/lib/node_modules/@anthropic-ai/claude-code /usr/local/lib/node_modules/@anthropic-ai/claude-code

# Copy server dependencies
COPY --from=server-builder /server/node_modules ./node_modules

# Copy built web assets
COPY --from=web-builder /web/dist ./web/dist

# Copy server files
COPY server.ts package.json tsconfig.json ./
COPY scripts/docker-entrypoint.sh ./

# Set executable permissions
RUN chmod +x docker-entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["./docker-entrypoint.sh"]