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
RUN npm ci --only=production

# Runtime stage
FROM node:22-alpine
WORKDIR /app

# Install runtime dependencies
RUN apk --no-cache add tini bash git && \
    npm install -g tsx @anthropic-ai/claude-code

# Create non-root user for security
RUN adduser -u 10001 -D -s /bin/bash appuser

# Copy server dependencies
COPY --from=server-builder /server/node_modules ./node_modules

# Copy built web assets
COPY --from=web-builder /web/dist ./web/dist

# Copy server files
COPY server.ts package.json tsconfig.json ./
COPY scripts/docker-entrypoint.sh ./

# Copy Claude settings file
COPY .claude/settings.json ./claude-settings.json

# Set up permissions and settings
RUN mkdir -p /home/appuser/.claude && \
    cp ./claude-settings.json /home/appuser/.claude/settings.json && \
    chown -R appuser:appuser /home/appuser /app && \
    chmod +x docker-entrypoint.sh

# Switch to non-root user
USER appuser
ENV HOME=/home/appuser

# Volume for persistent Claude settings
VOLUME ["/home/appuser/.claude"]

EXPOSE 8080

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["./docker-entrypoint.sh"]