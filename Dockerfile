# syntax=docker/dockerfile:1

# Build stage
FROM node:22-alpine AS builder
WORKDIR /build

# Copy package files
COPY src/package*.json ./

# Install production dependencies only
RUN npm ci --only=production --no-audit --no-fund && \
    # Clean up unnecessary files in node_modules
    find node_modules -name "*.d.ts" -delete && \
    find node_modules -name "*.map" -delete && \
    find node_modules -name "*.md" -delete && \
    find node_modules -name "LICENSE*" -delete && \
    find node_modules -name "README*" -delete && \
    find node_modules -name "CHANGELOG*" -delete && \
    find node_modules -name ".npmignore" -delete && \
    find node_modules -name ".editorconfig" -delete && \
    find node_modules -name ".eslint*" -delete && \
    find node_modules -name ".prettier*" -delete && \
    find node_modules -type d -name "test" -prune -exec rm -rf {} \; 2>/dev/null || true && \
    find node_modules -type d -name "tests" -prune -exec rm -rf {} \; 2>/dev/null || true && \
    find node_modules -type d -name "docs" -prune -exec rm -rf {} \; 2>/dev/null || true && \
    find node_modules -type d -name ".github" -prune -exec rm -rf {} \; 2>/dev/null || true

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

# Remove unnecessary Node.js files
RUN rm -rf /usr/local/lib/node_modules/npm \
           /usr/local/lib/node_modules/corepack \
           /opt/yarn* \
           /usr/local/bin/npm \
           /usr/local/bin/npx \
           /usr/local/bin/corepack

EXPOSE 8080

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["./docker-entrypoint.sh"]