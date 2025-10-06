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
    npm install -g tsx @anthropic-ai/claude-agent-sdk

# Create non-root user for security
RUN adduser -u 10001 -D -s /bin/bash appuser

# Copy server dependencies
COPY --from=server-builder /server/node_modules ./node_modules

# Copy built web assets
COPY --from=web-builder /web/dist ./web/dist

# Copy server files
COPY server.ts package.json tsconfig.json ./

# Copy Claude settings file
COPY .claude/settings.json ./claude-settings.json

# Set up permissions and settings
RUN mkdir -p /home/appuser/.claude && \
    cp ./claude-settings.json /home/appuser/.claude/settings.json && \
    chown -R appuser:appuser /home/appuser /app

# Switch to non-root user
USER appuser
ENV HOME=/home/appuser

# Volume for persistent Claude settings
VOLUME ["/home/appuser/.claude"]

EXPOSE 8080

# Copy fixed entrypoint script
COPY docker-entrypoint-fixed.sh ./
RUN chmod +x docker-entrypoint-fixed.sh

# Use the fixed entrypoint
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["./docker-entrypoint-fixed.sh"]

# Render.com needs port 10000
ENV PORT=10000

# Set RENDER environment variable for deployment detection
ENV RENDER=true

# Set GLM-4.6 environment variables for Claude SDK compatibility
ENV ANTHROPIC_API_KEY=""
ENV ANTHROPIC_BASE_URL=""